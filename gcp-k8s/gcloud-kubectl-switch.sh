#!/bin/bash

# gcloud-kubectl-switch.sh
# Purpose: Streamline switching between Google Cloud projects and Kubernetes clusters
#
# See README.md for full documentation and setup instructions.

# Check for gcloud, the core dependency. Other dependencies are checked as needed.
if ! command -v gcloud &> /dev/null; then
  echo "Error: gcloud is not installed. Please install the Google Cloud SDK to use this script."
  echo "https://cloud.google.com/sdk/docs/install"
  # Handle exit for both sourced and executed scripts
  (return 2>/dev/null) && return 1 || exit 1
fi

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
    ["example-config"]="your-gcp-project-id|user@example.com|your-real-cluster-name|us-central1|your-short-name|your-namespace"
  )
fi

# Function to display all available configurations in a clean format
show_configurations() {
  # Check if the CONFIGS array is empty
  if [ ${#CONFIGS[@]} -eq 0 ] || [[ -z "${!CONFIGS[*]}" ]]; then
    echo "No configurations found in '$CONFIG_FILE'."
    echo "Please add configurations to use the script."
    return
  fi

  echo "Available configurations from '$CONFIG_FILE':"
  echo

  # Find the longest alias name for formatting
  local max_alias_len=0
  for alias in "${!CONFIGS[@]}"; do
    if (( ${#alias} > max_alias_len )); then
      max_alias_len=${#alias}
    fi
  done
  max_alias_len=$((max_alias_len + 2)) # Add padding

  # Print header and sorted list of configurations
  printf "%-${max_alias_len}s %s\n" "ALIAS" "PROJECT ID"
  printf "%s\n" "-----------------------------------------------------------------"
  for alias in $(echo "${!CONFIGS[@]}" | tr ' ' '\n' | sort); do
    local project_id
    IFS='|' read -r project_id _ <<< "${CONFIGS[$alias]}"
    printf "%-${max_alias_len}s %s\n" "$alias" "$project_id"
  done

  echo
  local first_alias
  first_alias=$(echo "${!CONFIGS[@]}" | tr ' ' '\n' | sort | head -n 1)
  if [[ -n "$first_alias" ]]; then
    echo "To switch, use: switch $first_alias"
  fi
}

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
  IFS='|' read -r PROJECT_ID ACCOUNT CLUSTER_NAME REGION KUBE_CONTEXT_ALIAS NAMESPACE <<< "${CONFIGS[$CONFIG_NAME]}"

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

  # Set project and region
  gcloud config set project "$PROJECT_ID" || {
    echo "Failed to set project: $PROJECT_ID"
    return 1
  }
  gcloud config set compute/region "$REGION" || {
    echo "Failed to set region: $REGION"
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

  # If a cluster name is provided, handle all Kubernetes-related actions.
  if [[ -n "$CLUSTER_NAME" ]]; then
    # Check Kubernetes-related dependencies only when they are needed.
    for cmd in kubectl kubectx kubens; do
      if ! command -v $cmd &> /dev/null; then
        echo "Error: Dependency '$cmd' is not installed, but is required for Kubernetes operations."
        echo "Please install it to switch Kubernetes contexts and namespaces."
        return 1
      fi
    done

    # Update kubectl credentials
    echo "Updating kubectl credentials for cluster: $CLUSTER_NAME"
    gcloud container clusters get-credentials "$CLUSTER_NAME" --region "$REGION" --project "$PROJECT_ID" || {
      echo "Failed to update kubectl credentials for $CLUSTER_NAME. Check cluster status:"
      echo "gcloud container clusters list --project $PROJECT_ID"
      return 1
    }

    # Rename and switch kubectl context for simplicity.
    # gcloud creates a long context name (gke_PROJECT_REGION_CLUSTER).
    # This script renames it to the short config name for easy use.
    local GKE_CONTEXT_NAME="gke_${PROJECT_ID}_${REGION}_${CLUSTER_NAME}"
    echo "Standardizing context name to '$KUBE_CONTEXT_ALIAS'..."
    kubectx "$KUBE_CONTEXT_ALIAS=$GKE_CONTEXT_NAME" &>/dev/null # Suppress output, rename silently

    echo "Switching kubectl context to: $KUBE_CONTEXT_ALIAS"
    kubectx "$KUBE_CONTEXT_ALIAS" || {
      echo "Failed to switch kubectl context to '$KUBE_CONTEXT_ALIAS'. Ensure kubectx is installed."
      echo "You can list available contexts with 'kubectx'."
      return 1
    }

    run_post_switch_summary "$CONFIG_NAME" "$PROJECT_ID" "$KUBE_CONTEXT_ALIAS" "$NAMESPACE"
  else
    echo "No cluster name provided in configuration. Skipping Kubernetes steps."
    echo -e "\nSuccessfully switched gcloud config to: $CONFIG_NAME, project: $PROJECT_ID"
  fi
}

# Function to display a summary after a successful switch
run_post_switch_summary() {
  local CONFIG_NAME=$1
  local PROJECT_ID=$2
  local KUBE_CONTEXT_ALIAS=$3
  local NAMESPACE=$4

  echo -e "\nSuccessfully switched to config: $CONFIG_NAME, project: $PROJECT_ID, context: $KUBE_CONTEXT_ALIAS"

  # If a namespace is defined in the config, try to switch to it.
  if [[ -n "$NAMESPACE" ]]; then
    echo "Attempting to switch to namespace: $NAMESPACE"
    kubens "$NAMESPACE" || echo "Warning: Failed to switch to namespace '$NAMESPACE'. It may not exist."
  fi

  echo -n "Current namespace is: "
  kubens

  # Optional: Uncomment the lines below to see a list of VMs and buckets after every switch.
  # echo -e "\nVMs in $PROJECT_ID:"
  # gcloud compute instances list --project "$PROJECT_ID" --format="table(name,zone,status)" || echo "No VMs found or access denied."
}


# --- Main Logic ---
# This script can be sourced to create aliases or executed with --show to list them.

# Check if the script is being executed directly or sourced
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
  # EXECUTED: Handle command-line arguments for direct execution.
  if [[ "$1" == "--show" ]]; then
    show_configurations
  else
    echo "Error: Invalid command. This script is meant to be sourced into your shell."
    echo "Usage: source gcloud-kubectl-switch.sh"
    echo
    echo "To list available configurations, run:"
    echo "  $0 --show"
    exit 1
  fi
else
  # SOURCED: Define a single 'switch' function for a more intuitive CLI.
  switch() {
    # Handle --show or --list flags to display configurations
    if [[ "$1" == "--show" ]] || [[ "$1" == "--list" ]]; then
      show_configurations
      return
    fi

    # Provide usage instructions if no argument is given
    if [[ -z "$1" ]]; then
      echo "Usage: switch <alias-name>"
      echo "To see available aliases, run: switch --show"
      echo
      show_configurations # Also show the list for convenience
      return 1
    fi

    # Call the main switch_project function with the provided alias
    switch_project "$1"
  }
fi
