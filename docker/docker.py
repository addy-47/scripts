import os
import subprocess
import yaml
import multiprocessing
import logging
import argparse
from datetime import datetime
from pathlib import Path

# Set up logging to file and console
logging.basicConfig(
    level=logging.INFO,
    format='%(asctime)s [%(levelname)s] %(message)s',
    handlers=[
        logging.FileHandler('build.log'),
        logging.StreamHandler()
    ]
)
logger = logging.getLogger(__name__)

def get_git_commit_id():
    """Fetch the short Git commit ID for default tagging."""
    try:
        result = subprocess.run(
            ['git', 'rev-parse', '--short', 'HEAD'],
            capture_output=True, text=True, check=True
        )
        return result.stdout.strip()
    except subprocess.CalledProcessError:
        logger.error("Failed to fetch Git commit ID. Ensure this is a Git repository.")
        return "unknown"

def validate_dockerfile(service_path):
    """Check if a Dockerfile exists in the service directory."""
    dockerfile_path = Path(service_path) / "Dockerfile"
    if not dockerfile_path.is_file():
        logger.error(f"No Dockerfile found in {service_path}")
        return False
    return True

def build_and_push_docker_image(args):
    """Build and optionally push a Docker image for a given service."""
    service_path, image_name, tag, project_id, gar_name, region, use_gar, push_to_gar = args
    service_name = Path(service_path).name
    # Convert image name to lowercase to comply with Docker/GAR naming rules
    image_name_lower = image_name.lower()
    if image_name != image_name_lower:
        logger.info(f"Converted image name '{image_name}' to lowercase: '{image_name_lower}'")
    
    image_full_name = (
        f"{region}-docker.pkg.dev/{project_id}/{gar_name}/{image_name_lower}:{tag}"
        if use_gar
        else f"{image_name_lower}:{tag}"
    )
    
    # Create logs directory if it doesn't exist
    logs_dir = Path("logs")
    logs_dir.mkdir(exist_ok=True)
    log_file = logs_dir / f"{service_name}.log"

    # Build the image
    try:
        logger.info(f"Building image for {service_path}: {image_full_name}")
        result = subprocess.run(
            ["docker", "build", "-t", image_full_name, "."],
            cwd=service_path,
            capture_output=True,
            text=True,
            check=True
        )
        logger.info(f"Successfully built {image_full_name}")
        build_result = {
            "service": service_path,
            "image": image_full_name,
            "status": "success",
            "build_output": result.stdout
        }
    except subprocess.CalledProcessError as e:
        logger.error(f"Failed to build {image_full_name}")
        with open(log_file, "w") as f:
            f.write(f"Build output for {image_full_name} ({datetime.now()}):\n")
            f.write(e.stdout)
            f.write("\nErrors:\n")
            f.write(e.stderr)
        logger.info(f"Detailed build logs saved to {log_file}")
        return {
            "service": service_path,
            "image": image_full_name,
            "status": "failed",
            "build_output": e.stderr
        }

    # Push to GAR if enabled and build was successful
    if use_gar and push_to_gar and build_result["status"] == "success":
        try:
            logger.info(f"Pushing image to GAR: {image_full_name}")
            push_result = subprocess.run(
                ["docker", "push", image_full_name],
                capture_output=True,
                text=True,
                check=True
            )
            logger.info(f"Successfully pushed {image_full_name}")
            build_result["push_status"] = "success"
            build_result["push_output"] = push_result.stdout
        except subprocess.CalledProcessError as e:
            logger.error(f"Failed to push {image_full_name}")
            with open(log_file, "a") as f:
                f.write(f"\nPush output for {image_full_name} ({datetime.now()}):\n")
                f.write(e.stdout)
                f.write("\nErrors:\n")
                f.write(e.stderr)
            logger.info(f"Detailed push logs saved to {log_file}")
            build_result["push_status"] = "failed"
            build_result["push_output"] = e.stderr

    return build_result

def main():
    # Parse command-line arguments
    parser = argparse.ArgumentParser(description="Build and optionally push multiple Docker images in parallel.")
    parser.add_argument("--config", default="services.yaml", help="Path to services.yaml")
    parser.add_argument("--max-processes", type=int, help="Maximum number of parallel builds")
    args = parser.parse_args()

    # Load configuration from services.yaml
    try:
        with open(args.config, "r") as f:
            config = yaml.safe_load(f)
    except FileNotFoundError:
        logger.error(f"{args.config} not found.")
        return
    except yaml.YAMLError as e:
        logger.error(f"Error parsing {args.config}: {e}")
        return

    # Extract configuration
    services_dir = config.get("services_dir")
    project_id = config.get("project_id")
    gar_name = config.get("gar_name")
    region = config.get("region")
    global_tag = config.get("global_tag")
    max_processes = config.get("max_processes", multiprocessing.cpu_count() // 2)
    services = config.get("services", [])
    use_gar = os.getenv("USE_GAR", str(config.get("use_gar", True))).lower() == "true"
    push_to_gar = os.getenv("PUSH_TO_GAR", str(config.get("push_to_gar", use_gar))).lower() == "true"

    # Override max_processes from command-line if provided
    if args.max_processes:
        max_processes = args.max_processes

    # Validate GAR settings if use_gar is True
    if use_gar and not all([project_id, gar_name, region]):
        logger.error("Missing required fields in services.yaml for GAR: project_id, gar_name, region")
        return

    # Check GAR authentication if pushing is enabled
    if use_gar and push_to_gar:
        try:
            subprocess.run(
                ["gcloud", "auth", "print-access-token"],
                capture_output=True,
                text=True,
                check=True
            )
        except subprocess.CalledProcessError:
            logger.error("GAR authentication not set up. Run 'gcloud auth configure-docker {region}-docker.pkg.dev'.")
            return

    # Prepare list of services to build
    build_tasks = []
    if services:
        # Explicitly listed services
        for service in services:
            service_path = service.get("name")
            if not service_path:
                logger.error("Service name missing in services list.")
                continue
            if not validate_dockerfile(service_path):
                continue
            image_name = Path(service_path).name
            tag = service.get("tag", global_tag or get_git_commit_id())
            build_tasks.append((service_path, image_name, tag, project_id, gar_name, region, use_gar, push_to_gar))
    elif services_dir:
        # Recursively discover services with Dockerfiles
        services_dir_path = Path(services_dir)
        if not services_dir_path.exists():
            logger.error(f"Services directory {services_dir} does not exist.")
            return
        for dockerfile_path in services_dir_path.rglob("Dockerfile"):
            service_path = str(dockerfile_path.parent)
            image_name = Path(service_path).name
            tag = global_tag or get_git_commit_id()
            build_tasks.append((service_path, image_name, tag, project_id, gar_name, region, use_gar, push_to_gar))
    else:
        logger.error("Either services_dir or services must be specified in services.yaml.")
        return

    if not build_tasks:
        logger.error("No valid services found to build.")
        return

    # Build and push images in parallel
    logger.info(f"Starting parallel builds for {len(build_tasks)} services with max_processes={max_processes}")
    with multiprocessing.Pool(processes=max_processes) as pool:
        results = pool.map(build_and_push_docker_image, build_tasks)

    # Summarize results
    successes = [r for r in results if r["status"] == "success"]
    failures = [r for r in results if r["status"] == "failed"]
    push_failures = [r for r in results if r.get("push_status") == "failed"]
    
    logger.info(f"\nBuild Summary:")
    logger.info(f"Total services: {len(build_tasks)}")
    logger.info(f"Successful builds: {len(successes)}")
    logger.info(f"Failed builds: {len(failures)}")
    if failures:
        logger.info("Failed builds:")
        for failure in failures:
            logger.info(f"- {failure['service']}: {failure['image']}")
    if push_failures:
        logger.info("Failed pushes:")
        for failure in push_failures:
            logger.info(f"- {failure['service']}: {failure['image']}")

if __name__ == "__main__":
    main()