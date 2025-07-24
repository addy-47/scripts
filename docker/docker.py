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

def build_docker_image(args):
    """Build a Docker image for a given service."""
    service_path, image_name, tag, project_id, gar_name, region = args
    image_full_name = f"{region}-docker.pkg.dev/{project_id}/{gar_name}/{image_name}:{tag}"
    
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
        return {"service": service_path, "image": image_full_name, "status": "success", "output": result.stdout}
    except subprocess.CalledProcessError as e:
        logger.error(f"Failed to build {image_full_name}: {e.stderr}")
        return {"service": service_path, "image": image_full_name, "status": "failed", "output": e.stderr}

def main():
    # Parse command-line arguments
    parser = argparse.ArgumentParser(description="Build multiple Docker images in parallel.")
    parser.add_argument("--max-processes", type=int, help="Maximum number of parallel builds")
    args = parser.parse_args()

    # Load configuration from services.yaml
    try:
        with open("services.yaml", "r") as f:
            config = yaml.safe_load(f)
    except FileNotFoundError:
        logger.error("services.yaml not found in project root.")
        return
    except yaml.YAMLError as e:
        logger.error(f"Error parsing services.yaml: {e}")
        return

    # Extract configuration
    services_dir = config.get("services_dir")
    project_id = config.get("project_id")
    gar_name = config.get("gar_name")
    region = config.get("region")
    global_tag = config.get("global_tag")
    max_processes = config.get("max_processes", multiprocessing.cpu_count() // 2)
    services = config.get("services", [])

    # Override max_processes from command-line if provided
    if args.max_processes:
        max_processes = args.max_processes

    if not all([project_id, gar_name, region]):
        logger.error("Missing required fields in services.yaml: project_id, gar_name, region")
        return

    # Get default tag (short Git commit ID) if global_tag is not specified
    default_tag = global_tag or get_git_commit_id()

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
            # Derive image name from the last directory in the path
            image_name = Path(service_path).name
            tag = service.get("tag", default_tag)
            build_tasks.append((service_path, image_name, tag, project_id, gar_name, region))
    elif services_dir:
        # Recursively discover services with Dockerfiles
        services_dir_path = Path(services_dir)
        if not services_dir_path.exists():
            logger.error(f"Services directory {services_dir} does not exist.")
            return
        for dockerfile_path in services_dir_path.rglob("Dockerfile"):
            service_path = str(dockerfile_path.parent)
            image_name = Path(service_path).name
            tag = default_tag
            build_tasks.append((service_path, image_name, tag, project_id, gar_name, region))
    else:
        logger.error("Either services_dir or services must be specified in services.yaml.")
        return

    if not build_tasks:
        logger.error("No valid services found to build.")
        return

    # Build images in parallel
    logger.info(f"Starting parallel builds for {len(build_tasks)} services with max_processes={max_processes}")
    with multiprocessing.Pool(processes=max_processes) as pool:
        results = pool.map(build_docker_image, build_tasks)

    # Summarize results
    successes = [r for r in results if r["status"] == "success"]
    failures = [r for r in results if r["status"] == "failed"]
    
    logger.info(f"\nBuild Summary:")
    logger.info(f"Total services: {len(build_tasks)}")
    logger.info(f"Successful builds: {len(successes)}")
    logger.info(f"Failed builds: {len(failures)}")
    if failures:
        logger.info("Failed services:")
        for failure in failures:
            logger.info(f"- {failure['service']}: {failure['image']}")

if __name__ == "__main__":
    main()