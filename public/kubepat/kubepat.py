#!/usr/bin/env python3

import os
import subprocess
import yaml
import multiprocessing
import logging
import re
from datetime import datetime
from pathlib import Path
import time
import argparse

# Set up logging
logging.basicConfig(
    level=logging.INFO,
    format='%(asctime)s [%(levelname)s] %(message)s',
    handlers=[
        logging.FileHandler('kubepat.log'),
        logging.StreamHandler()
    ]
)
logger = logging.getLogger(__name__)

def run_command(command, cwd=None, capture_output=True, check=True):
    """Execute a shell command with error handling."""
    try:
        result = subprocess.run(
            command,
            cwd=cwd,
            capture_output=capture_output,
            text=True,
            check=check
        )
        return result
    except subprocess.CalledProcessError as e:
        logger.error(f"Command failed: {' '.join(command)}")
        logger.debug(f"Error output: {e.stderr}")
        raise

def get_git_commit_id():
    """Fetch the short Git commit ID for default tagging."""
    try:
        return run_command(['git', 'rev-parse', '--short', 'HEAD']).stdout.strip()
    except subprocess.CalledProcessError:
        logger.error("Failed to fetch Git commit ID.")
        return "unknown"

def pull_git_branch(branch):
    """Pull the specified Git branch."""
    try:
        logger.info(f"Pulling branch: {branch}")
        run_command(['git', 'pull', 'origin', branch])
        logger.info(f"Successfully pulled branch: {branch}")
    except subprocess.CalledProcessError:
        logger.error(f"Failed to pull branch: {branch}")
        raise

def validate_dockerfile(service_path):
    """Check if a Dockerfile exists in the service directory."""
    dockerfile_path = Path(service_path) / "Dockerfile"
    if not dockerfile_path.is_file():
        logger.error(f"No Dockerfile found in {service_path}")
        return False
    return True

def validate_image_name(image_name):
    """Validate that the image name is Docker-compatible."""
    if not re.match(r'^[a-z0-9][a-z0-9._-]*$', image_name):
        logger.error(f"Invalid image name '{image_name}'.")
        return False
    return True

def switch_gcloud_k8s_context(context_config, config_name):
    """Switch GCloud project and Kubernetes context."""
    try:
        project_id = context_config["project_id"]
        account = context_config["account"]
        cluster_name = context_config.get("cluster_name")
        region = context_config.get("region")
        kube_context_alias = context_config.get("kube_context_alias", config_name)
        namespace = context_config.get("namespace")

        # Check GCloud authentication
        if run_command(['gcloud', 'auth', 'list', '--format=value(account)'], capture_output=True).stdout.find(account) == -1:
            logger.info(f"Authenticating account: {account}")
            run_command(['gcloud', 'auth', 'login', account, '--no-launch-browser'])

        # Set GCloud project and region
        run_command(['gcloud', 'config', 'set', 'project', project_id])
        if region:
            run_command(['gcloud', 'config', 'set', 'compute/region', region])

        if cluster_name and region:
            # Update kubectl credentials
            run_command([
                'gcloud', 'container', 'clusters', 'get-credentials', cluster_name,
                '--region', region, '--project', project_id
            ])
            # Rename and switch kubectl context
            gke_context = f"gke_{project_id}_{region}_{cluster_name}"
            run_command(['kubectx', f"{kube_context_alias}={gke_context}"])
            run_command(['kubectx', kube_context_alias])
            if namespace:
                run_command(['kubens', namespace])
        logger.info(f"Switched to context: {config_name}, project: {project_id}, context: {kube_context_alias}")
    except subprocess.CalledProcessError:
        logger.error(f"Failed to switch context: {config_name}")
        raise

def patch_kubernetes_workload(image_full_name, service_config, context_config):
    """Patch Kubernetes workload with the new image."""
    try:
        deployment = service_config.get("deployment")
        container = service_config.get("container")
        namespace = context_config.get("namespace")
        if not deployment or not container:
            logger.error("Deployment or container name missing in service config.")
            return None, None

        # Get current image tag
        cmd = ['kubectl', 'get', 'deployment', deployment, '-o', 'jsonpath={.spec.template.spec.containers[?(@.name=="' + container + '")].image}']
        if namespace:
            cmd.extend(['-n', namespace])
        current_image = run_command(cmd).stdout.strip()
        prev_tag = current_image.split(':')[-1] if ':' in current_image else "latest"

        # Patch the deployment
        run_command([
            'kubectl', 'set', 'image', f"deployment/{deployment}",
            f"{container}={image_full_name}", '-n', namespace
        ] if namespace else [
            'kubectl', 'set', 'image', f"deployment/{deployment}",
            f"{container}={image_full_name}"
        ])
        logger.info(f"Patched deployment {deployment} with image {image_full_name}")
        return deployment, prev_tag
    except subprocess.CalledProcessError:
        logger.error(f"Failed to patch deployment for image: {image_full_name}")
        return None, None

def check_pod_status(deployment, namespace, timeout=300):
    """Check pod status after patching."""
    start_time = time.time()
    cmd = ['kubectl', 'get', 'pods', '-l', f"app={deployment}", '-o', 'jsonpath={.items[*].status.phase}']
    if namespace:
        cmd.extend(['-n', namespace])

    while time.time() - start_time < timeout:
        try:
            output = run_command(cmd).stdout.strip()
            logger.info(f"Pod status: {output}")
            if all(status == 'Running' for status in output.split()):
                logger.info("All pods are in Running state.")
                return True
            time.sleep(10)
        except subprocess.CalledProcessError:
            logger.error("Failed to check pod status.")
            time.sleep(10)
    logger.error("Timeout waiting for pods to reach Running state.")
    return False

def rollback_deployment(deployment, container, prev_tag, image_base, namespace):
    """Rollback to previous image tag."""
    try:
        image_full_name = f"{image_base}:{prev_tag}"
        cmd = ['kubectl', 'set', 'image', f"deployment/{deployment}", f"{container}={image_full_name}"]
        if namespace:
            cmd.extend(['-n', namespace])
        run_command(cmd)
        logger.info(f"Rolled back to previous image: {image_full_name}")
    except subprocess.CalledProcessError:
        logger.error("Failed to rollback deployment.")

def build_and_push_docker_image(args):
    """Build, push, and patch a Docker image for a service."""
    service_path, image_name, tag, project_id, gar_name, region, use_gar, push_to_gar, service_config, context_config = args
    service_name = Path(service_path).name
    image_name = image_name or service_name
    image_name_lower = image_name.lower()

    if not validate_image_name(image_name_lower):
        return {"service": service_path, "image": image_name_lower, "status": "failed"}

    image_full_name = (
        f"{region}-docker.pkg.dev/{project_id}/{gar_name}/{image_name_lower}:{tag}"
        if use_gar else f"{image_name_lower}:{tag}"
    )

    logs_dir = Path("logs")
    logs_dir.mkdir(exist_ok=True)
    log_file = logs_dir / f"{service_name}.log"

    # Build image
    try:
        logger.info(f"Building image: {image_full_name}")
        result = run_command(["docker", "build", "-t", image_full_name, "."], cwd=service_path)
        logger.info(f"Successfully built {image_full_name}")
        build_result = {"service": service_path, "image": image_full_name, "status": "success"}
    except subprocess.CalledProcessError as e:
        with open(log_file, "w") as f:
            f.write(f"Build output for {image_full_name} ({datetime.now()}):\n{e.stderr}")
        logger.info(f"Build logs saved to {log_file}")
        return {"service": service_path, "image": image_full_name, "status": "failed"}

    # Push image
    if use_gar and push_to_gar and build_result["status"] == "success":
        try:
            logger.info(f"Pushing image: {image_full_name}")
            push_result = run_command(["docker", "push", image_full_name])
            build_result["push_status"] = "success"
        except subprocess.CalledProcessError as e:
            with open(log_file, "a") as f:
                f.write(f"\nPush output for {image_full_name} ({datetime.now()}):\n{e.stderr}")
            logger.info(f"Push logs saved to {log_file}")
            build_result["push_status"] = "failed"

    # Patch workload
    if build_result["status"] == "success":
        deployment, prev_tag = patch_kubernetes_workload(image_full_name, service_config, context_config)
        if deployment:
            logger.info("Waiting for pod status...")
            if not check_pod_status(deployment, context_config.get("namespace")):
                choice = input(f"Pods not in Running state. Revert to previous tag ({prev_tag})? [y/N]: ").lower()
                if choice == 'y':
                    rollback_deployment(deployment, service_config.get("container"), prev_tag, image_full_name.rsplit(':', 1)[0], context_config.get("namespace"))

    return build_result

def main(config_path, max_processes, branch, context_name):
    """Main function to orchestrate kubepat operations."""
    # Load configuration
    try:
        with open(config_path, "r") as f:
            config = yaml.safe_load(f)
    except (FileNotFoundError, yaml.YAMLError) as e:
        logger.error(f"Failed to load {config_path}: {e}")
        return

    # Extract configurations
    services_dir = config.get("services_dir")
    contexts = config.get("contexts", {})
    services = config.get("services", [])
    global_config = config.get("global", {})
    use_gar = os.getenv("USE_GAR", str(global_config.get("use_gar", True))).lower() == "true"
    push_to_gar = os.getenv("PUSH_TO_GAR", str(global_config.get("push_to_gar", use_gar))).lower() == "true"
    max_processes = max_processes or global_config.get("max_processes", multiprocessing.cpu_count() // 2)
    default_branch = global_config.get("branch")
    default_tag = global_config.get("global_tag", get_git_commit_id())

    # Validate context
    if context_name not in contexts:
        logger.error(f"Context {context_name} not found. Available: {list(contexts.keys())}")
        return
    context_config = contexts[context_name]
    project_id = context_config.get("project_id")
    gar_name = context_config.get("gar_name")
    region = context_config.get("region")

    # Validate GAR settings
    if use_gar and not all([project_id, gar_name, region]):
        logger.error("Missing GAR fields in context: project_id, gar_name, region")
        return

    # Check dependencies
    for cmd in ['gcloud', 'kubectl', 'kubectx', 'kubens', 'docker']:
        if run_command(['which', cmd], check=False).returncode != 0:
            logger.error(f"Dependency {cmd} not installed.")
            return

    # Pull Git branch
    branch = branch or default_branch
    if branch:
        pull_git_branch(branch)

    # Switch context
    switch_gcloud_k8s_context(context_config, context_name)

    # Prepare build tasks
    build_tasks = []
    if services:
        for service in services:
            service_path = service.get("name")
            if not service_path or not validate_dockerfile(service_path):
                continue
            image_name = service.get("image_name")
            tag = service.get("tag", default_tag)
            build_tasks.append((
                service_path, image_name, tag, project_id, gar_name, region,
                use_gar, push_to_gar, service, context_config
            ))
    elif services_dir:
        for dockerfile_path in Path(services_dir).rglob("Dockerfile"):
            service_path = str(dockerfile_path.parent)
            build_tasks.append((
                service_path, None, default_tag, project_id, gar_name, region,
                use_gar, push_to_gar, {}, context_config
            ))

    if not build_tasks:
        logger.error("No valid services found.")
        return

    # Execute builds in parallel
    logger.info(f"Starting builds for {len(build_tasks)} services")
    with multiprocessing.Pool(processes=max_processes) as pool:
        results = pool.map(build_and_push_docker_image, build_tasks)

    # Summarize results
    successes = [r for r in results if r["status"] == "success"]
    failures = [r for r in results if r["status"] == "failed"]
    push_failures = [r for r in results if r.get("push_status") == "failed"]

    logger.info(f"\nSummary:\nTotal: {len(build_tasks)}\nSuccess: {len(successes)}\nFailed Builds: {len(failures)}")
    if failures:
        logger.info("Failed builds:")
        for f in failures:
            logger.info(f"- {f['service']}: {f['image']}")
    if push_failures:
        logger.info("Failed pushes:")
        for f in push_failures:
            logger.info(f"- {f['service']}: {f['image']}")

if __name__ == "__main__":
    parser = argparse.ArgumentParser(description="Kubepat: Build, push, and patch Kubernetes workloads")
    parser.add_argument("--config", default="kubepat.yaml", help="Path to kubepat.yaml")
    parser.add_argument("--max-processes", type=int, default=None, help="Max parallel builds")
    parser.add_argument("--branch", help="Git branch to pull")
    parser.add_argument("--context", required=True, help="GCloud/Kubernetes context to use")
    args = parser.parse_args()
    main(args.config, args.max_processes, args.branch, args.context)