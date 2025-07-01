#!/bin/bash

# gcloud-kubectl-switch.sh
# Purpose: Streamline switching between Google Cloud projects and Kubernetes clusters
# Usage: source ~/scripts/gcloud-kubectl-switch.sh <config-name>
# Example: After sourcing in your .bashrc/.zshrc, use aliases: switch-addy, switch-kb-uat
# Features:
# - Switches gcloud configurations and kubectl contexts in one command
# - Auto-creates gcloud configurations for new entries
# - Prompts gcloud auth login for unauthenticated accounts
# - Optionally sets Application Default Credentials (ADC) for Terraform/client libraries
# - Supports managing VMs, buckets, and other GCP resources
# - Designed for DevOps engineers managing multiple projects

# Check dependencies
for cmd in gcloud kubectl kubectx kubens; do
  if ! command -v $cmd &> /dev/null; then
    echo "Error: $cmd is not installed. Install it to use this script."
    echo "For gcloud: https://cloud.google.com/sdk/docs/install"
    echo "For kubectl: https://kubernetes.io/docs/tasks/tools/"
    echo "For kubectx: brew install kubectx (macOS) or equivalent"
    exit 1
  fi
done

# This script is designed to be committed to version control.
# Your personal configurations should be stored in a separate file.
declare -A CONFIGS

# Load user configurations from a separate file to keep secrets out of git.
# The config file should be in the same directory as the script.
SCRIPT_DIR=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" &> /dev/null && pwd)
CONFIG_FILE="$SCRIPT_DIR/gcloud-kubectl-switch.conf"

if [[ -f "$CONFIG_FILE" ]]; then
  source "$CONFIG_FILE"
else
  # Provide an example configuration if the file doesn't exist.
  # This makes the script usable out-of-the-box for new users.
  echo "Warning: Configuration file not found at '$CONFIG_FILE'."
  echo "Please create it with your settings. Loading an example configuration."
  CONFIGS=(
    ["example-config"]="your-gcp-project-id|user@example.com|your-real-cluster-name|us-central1|your-short-name"
  )
fi

# Function to check if an account is authenticated
check_account_authenticated() {
  local ACCOUNT=$1
  gcloud auth list --format="value(account)" | grep -q "$ACCOUNT"
  return $?
}

# Function to switch gcloud and kubectl context
switch_project() {
  local CONFIG_NAME=$1

  # Check if config exists
  if [[ -z "${CONFIGS[$CONFIG_NAME]}" ]]; then
    echo "Error: Configuration '$CONFIG_NAME' not found."
    echo "Available configurations: ${!CONFIGS[@]}"
    echo "Edit the CONFIGS array in '$CONFIG_FILE' to add new configurations."
    return 1
  fi

  # Parse configuration
  IFS='|' read -r PROJECT_ID ACCOUNT CLUSTER_NAME REGION KUBE_CONTEXT_ALIAS <<< "${CONFIGS[$CONFIG_NAME]}"

  # Default the kube context alias to the config name if not provided, for backward compatibility
  if [[ -z "$KUBE_CONTEXT_ALIAS" ]]; then
    KUBE_CONTEXT_ALIAS="$CONFIG_NAME"
  fi

  # Check if gcloud configuration exists, create if not
  if ! gcloud config configurations list --format="value(name)" | grep -q "^$CONFIG_NAME$"; then
    echo "Creating new gcloud configuration: $CONFIG_NAME"
    gcloud config configurations create "$CONFIG_NAME" || {
      echo "Failed to create gcloud config: $CONFIG_NAME"
      return 1
    }
  fi

  # Activate gcloud configuration
  echo "Switching to gcloud config: $CONFIG_NAME"
  gcloud config configurations activate "$CONFIG_NAME" || {
    echo "Failed to activate gcloud config: $CONFIG_NAME"
    return 1
  }

  # Set project and region
  gcloud config set project "$PROJECT_ID" || {
    echo "Failed to set project: $PROJECT_ID"
    return 1
  }
  gcloud config set compute/region "$REGION" || {
    echo "Failed to set region: $REGION"
    return 1
  }

  # Check if account is authenticated, prompt login if not
  if ! check_account_authenticated "$ACCOUNT"; then
    echo "Account $ACCOUNT not authenticated. Initiating gcloud auth login..."
    gcloud auth login "$ACCOUNT" --no-launch-browser || {
      echo "Authentication failed for $ACCOUNT. Run 'gcloud auth login $ACCOUNT' manually."
      return 1
    }
  fi
  gcloud config set account "$ACCOUNT" || {
    echo "Failed to set account: $ACCOUNT"
    return 1
  }

  # Optionally set ADC if a service account key exists
  if [[ -f ~/.config/gcloud/$PROJECT_ID-key.json ]]; then
    echo "Setting GOOGLE_APPLICATION_CREDENTIALS for $PROJECT_ID"
    export GOOGLE_APPLICATION_CREDENTIALS=~/.config/gcloud/$PROJECT_ID-key.json
    gcloud auth application-default set-quota-project "$PROJECT_ID" || {
      echo "Failed to set ADC quota project: $PROJECT_ID"
    }
  else
    echo "No service account key found for $PROJECT_ID; skipping ADC setup."
    echo "If using Terraform, create a service account key (see guide below)."
  fi

  # Update kubectl credentials
  echo "Updating kubectl credentials for cluster: $CLUSTER_NAME"
  gcloud container clusters get-credentials "$CLUSTER_NAME" --region "$REGION" --project "$PROJECT_ID" || {
    echo "Failed to update kubectl credentials for $CLUSTER_NAME. Check cluster status:"
    echo "gcloud container clusters list --project $PROJECT_ID"
    return 1
  }

  # Rename and switch kubectl context for simplicity.
  # gcloud creates a long context name (gke_PROJECT_REGION_CLUSTER).
  # This script renames it to the short config name (e.g., 'muxly-old') for easy use.
  local GKE_CONTEXT_NAME="gke_${PROJECT_ID}_${REGION}_${CLUSTER_NAME}"
  echo "Standardizing context name to '$KUBE_CONTEXT_ALIAS'..."
  kubectx "$KUBE_CONTEXT_ALIAS=$GKE_CONTEXT_NAME" &>/dev/null # Suppress output, rename silently

  echo "Switching kubectl context to: $KUBE_CONTEXT_ALIAS"
  kubectx "$KUBE_CONTEXT_ALIAS" || {
    echo "Failed to switch kubectl context to '$KUBE_CONTEXT_ALIAS'. Ensure kubectx is installed."
    echo "You can list available contexts with 'kubectx'."
    return 1
  }

  # # Optional: List VMs and buckets
  # echo -e "\nVMs in $PROJECT_ID:"
  # gcloud compute instances list --project "$PROJECT_ID" || echo "No VMs found or access denied."
  # echo -e "\nBuckets in $PROJECT_ID:"
  # gsutil ls -p "$PROJECT_ID" || echo "No buckets found or gsutil not configured."

  # echo -e "\nSuccessfully switched to config: $CONFIG_NAME, project: $PROJECT_ID, cluster: $CLUSTER_NAME"
  # echo -n "Current namespace is: "
  # kubens
}

# Define aliases for each configuration
for config in "${!CONFIGS[@]}"; do
  alias switch-$config="switch_project $config"
done

# Guide for Users
# ==================
# Purpose: Simplify switching between multiple GCP projects and Kubernetes clusters.
# Setup Instructions:
# 1. Save this script as '~/scripts/gcloud-kubectl-switch.sh'.
# 2. Make executable: chmod +x ~/scripts/gcloud-kubectl-switch.sh
# 3. Create a config file named 'gcloud-kubectl-switch.conf' in the same directory.
# 4. Add your configurations to 'gcloud-kubectl-switch.conf' (see format below).
# 5. IMPORTANT: Add 'gcloud-kubectl-switch.conf' to your .gitignore file to keep secrets safe.
# 6. Add to shell: echo "source ~/scripts/gcloud-kubectl-switch.sh" >> ~/.bashrc
# 7. Reload shell: source ~/.bashrc (or open a new terminal)
# 8. Use the aliases generated from your config file (e.g., switch-my-proj).
#
# Adding a New Configuration:
# - Edit your personal 'gcloud-kubectl-switch.conf' file.
# - Format: ["config-name"]="project-id|account|real-cluster-name|gke-region|desired-kube-context-name"
#   Example: ["new-config"]="my-project|user@domain.com|my-gke-cluster-1|us-central1|my-proj"
# - Save and reload shell: source ~/.bashrc
# - The script will:
#   - Create a new gcloud configuration automatically.
#   - Prompt for authentication if the account isn't logged in.
#   - Fetch kubectl credentials for the cluster.
# - New alias (e.g., switch-new-config) will be available.
#
# Optional: Application Default Credentials (ADC) for Terraform/Client Libraries:
# - Create a service account: gcloud iam service-accounts create terraform-sa --project <project-id>
# - Grant roles: gcloud projects add-iam-policy-binding <project-id> \
#     --member=serviceAccount:terraform-sa@<project-id>.iam.gserviceaccount.com \
#     --role=roles/editor
# - Generate key: gcloud iam service-accounts keys create ~/.config/gcloud/<project-id>-key.json \
#     --iam-account terraform-sa@<project-id>.iam.gserviceaccount.com
# - The script auto-sets GOOGLE_APPLICATION_CREDENTIALS if the key exists.
#
# Managing Additional GCP Resources:
# - VMs: The script lists VMs after switching (gcloud compute instances list).
# - Buckets: The script lists buckets (gsutil ls).
# - Extend the script in the switch_project function to manage other resources, e.g.:
#   echo "Firestore databases in $PROJECT_ID:"
#   gcloud firestore databases list --project "$PROJECT_ID"
#
# Troubleshooting:
# - Permission errors: Grant roles/container.clusterAdmin:
#   gcloud projects add-iam-policy-binding <project-id> \
#     --member=user:<account> --role=roles/container.clusterAdmin
# - Timeouts: Check cluster status: gcloud container clusters list --project <project-id>
# - Private clusters: Ensure VPN/network access: curl -k https://<cluster-ip>:443
# - Missing dependencies: Install gcloud, kubectl, kubectx (see links above).
#
# Share this script to simplify multi-project GCP and Kubernetes workflows!
# Created by Adhbhut Gupta, optimized for DevOps efficiency.
