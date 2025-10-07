#!/usr/bin/env python3

import os
import subprocess
import sys

def run_command(cmd, check=True, capture_output=False, text=True, **kwargs):
    """Run a shell command and return the result."""
    try:
        result = subprocess.run(cmd, shell=True, check=check, capture_output=capture_output, text=text, **kwargs)
        return result
    except subprocess.CalledProcessError as e:
        print(f"Command failed: {' '.join(cmd) if isinstance(cmd, list) else cmd}")
        if capture_output:
            print(f"Error: {e.stderr}")
        raise

def check_dependency(cmd):
    """Check if a command is available."""
    try:
        subprocess.run([cmd, '--version'], capture_output=True, check=True)
        return True
    except (subprocess.CalledProcessError, FileNotFoundError):
        return False

def check_account_authenticated(account):
    """Check if an account is authenticated."""
    try:
        result = run_command("gcloud auth list --format='value(account)'", capture_output=True)
        accounts = result.stdout.strip().split('\n')
        return account in accounts
    except:
        return False

def switch_config(config_name, config_values):
    """Switch to the specified configuration."""
    # Check for gcloud dependency
    if not check_dependency('gcloud'):
        print("Error: gcloud is not installed. Please install the Google Cloud SDK to use this script.")
        print("https://cloud.google.com/sdk/docs/install")
        return

    # Parse configuration
    project_id = config_values[0]
    account = config_values[1]
    cluster_name = config_values[2] if len(config_values) > 2 else ""
    region = config_values[3] if len(config_values) > 3 else ""
    kube_context_alias = config_values[4] if len(config_values) > 4 and config_values[4] else config_name
    namespace = config_values[5] if len(config_values) > 5 else ""

    # Check if gcloud configuration exists, create if not
    try:
        result = run_command(f"gcloud config configurations list --format='value(name)'", capture_output=True)
        configs = result.stdout.strip().split('\n')
        if config_name not in configs:
            print(f"Creating new gcloud configuration: {config_name}")
            run_command(f"gcloud config configurations create {config_name}")
    except:
        print(f"Failed to create gcloud config: {config_name}")
        return

    # Activate gcloud configuration
    print(f"Switching to gcloud config: {config_name}")
    run_command(f"gcloud config configurations activate {config_name}")

    # Check if account is authenticated, prompt login if not
    if not check_account_authenticated(account):
        print(f"Account {account} not authenticated. Initiating gcloud auth login...")
        try:
            run_command(f"gcloud auth login {account} --no-launch-browser")
        except:
            print(f"Authentication failed for {account}. Run 'gcloud auth login {account}' manually.")
            return

    run_command(f"gcloud config set account {account}")
    run_command(f"gcloud config set project {project_id}")
    run_command(f"gcloud config set compute/region {region}")

    # Optionally set ADC if a service account key exists
    key_path = os.path.expanduser(f"~/.config/gcloud/{project_id}-key.json")
    if os.path.exists(key_path):
        print(f"Setting GOOGLE_APPLICATION_CREDENTIALS for {project_id}")
        os.environ['GOOGLE_APPLICATION_CREDENTIALS'] = key_path
        try:
            run_command(f"gcloud auth application-default set-quota-project {project_id}")
        except:
            print(f"Failed to set ADC quota project: {project_id}")
    else:
        print(f"No service account key found for {project_id}; skipping ADC setup.")
        print("If using Terraform, create a service account key (see guide below).")

    # If a cluster name is provided, handle all Kubernetes-related actions.
    if cluster_name:
        # Check Kubernetes-related dependencies
        for cmd in ['kubectl', 'kubectx', 'kubens']:
            if not check_dependency(cmd):
                print(f"Error: Dependency '{cmd}' is not installed, but is required for Kubernetes operations.")
                print("Please install it to switch Kubernetes contexts and namespaces.")
                return

        # Update kubectl credentials
        print(f"Updating kubectl credentials for cluster: {cluster_name}")
        try:
            run_command(f"gcloud container clusters get-credentials {cluster_name} --region {region} --project {project_id} --dns-endpoint")
        except:
            print(f"Failed to update kubectl credentials for {cluster_name}. Check cluster status:")
            print(f"gcloud container clusters list --project {project_id}")
            return

        # Rename and switch kubectl context
        gke_context_name = f"gke_{project_id}_{region}_{cluster_name}"
        print(f"Standardizing context name to '{kube_context_alias}'...")
        run_command(f"kubectx {kube_context_alias}={gke_context_name}", capture_output=True)  # Suppress output

        print(f"Switching kubectl context to: {kube_context_alias}")
        run_command(f"kubectx {kube_context_alias}")

        run_post_switch_summary(config_name, project_id, kube_context_alias, namespace)
    else:
        print("No cluster name provided in configuration. Skipping Kubernetes steps.")
        print(f"Successfully switched gcloud config to: {config_name}, project: {project_id}")

def run_post_switch_summary(config_name, project_id, kube_context_alias, namespace):
    """Display a summary after a successful switch."""
    print(f"\nSuccessfully switched to config: {config_name}, project: {project_id}, context: {kube_context_alias}")

    # If a namespace is defined in the config, try to switch to it.
    if namespace:
        print(f"Attempting to switch to namespace: {namespace}")
        try:
            run_command(f"kubens {namespace}")
        except:
            print(f"Warning: Failed to switch to namespace '{namespace}'. It may not exist.")

    print("Current namespace is:")
    run_command("kubens")

    # Optional: Uncomment to see VMs and buckets
    # print(f"\nVMs in {project_id}:")
    # run_command(f"gcloud compute instances list --project {project_id} --format='table(name,zone,status)'", check=False)
