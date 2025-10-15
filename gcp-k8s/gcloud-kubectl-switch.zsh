#!/bin/zsh

# gcloud-kubectl-switch.zsh
# Purpose: Streamline switching between Google Cloud projects and Kubernetes clusters in Zsh
#
# See README.md for full documentation and setup instructions.

# --- Dependency Check ---
if ! command -v gcloud &> /dev/null; then
  echo "Error: gcloud is not installed. Please install the Google Cloud SDK to use this script."
  echo "https://cloud.google.com/sdk/docs/install"
  (return 2>/dev/null) && return 1 || exit 1
fi

# --- Configurations ---
# Keep personal configs separate from git-tracked script
typeset -A CONFIGS

SCRIPT_DIR=$(cd -- "$(dirname -- "${(%):-%x}")" &> /dev/null && pwd)
CONFIG_FILE="$SCRIPT_DIR/gcloud-kubectl-switch.conf"

if [[ -f "$CONFIG_FILE" ]]; then
  source "$CONFIG_FILE"
else
  echo "Warning: Configuration file not found at '$CONFIG_FILE'."
  echo "Please create it with your settings. Loading an example configuration."
  CONFIGS=(
    example-config "your-gcp-project-id|user@example.com|your-real-cluster-name|us-central1|your-short-name|your-namespace"
  )
fi

# --- Functions ---

show_configurations() {
  if (( ${#CONFIGS[@]} == 0 )); then
    echo "No configurations found in '$CONFIG_FILE'."
    echo "Please add configurations to use the script."
    return
  fi

  echo "Available configurations from '$CONFIG_FILE':"
  echo

  local max_alias_len=0
  for alias in ${(k)CONFIGS}; do
    if (( ${#alias} > max_alias_len )); then
      max_alias_len=${#alias}
    fi
  done
  max_alias_len=$((max_alias_len + 2))

  printf "%-${max_alias_len}s %s\n" "ALIAS" "PROJECT ID"
  printf "%s\n" "-----------------------------------------------------------------"
  for alias in ${(ko)CONFIGS}; do
    local project_id
    IFS='|' read -r project_id _ <<< "${CONFIGS[$alias]}"
    printf "%-${max_alias_len}s %s\n" "$alias" "$project_id"
  done

  echo
  local first_alias=${(ko)CONFIGS[1]}
  if [[ -n "$first_alias" ]]; then
    echo "To switch, use: switch $first_alias"
  fi
}

check_account_authenticated() {
  local ACCOUNT=$1
  gcloud auth list --format="value(account)" | grep -q "$ACCOUNT"
  return $?
}

switch_project() {
  local CONFIG_NAME=$1

  if [[ -z "${CONFIGS[$CONFIG_NAME]}" ]]; then
    echo "Error: Configuration '$CONFIG_NAME' not found."
    echo "Available configurations: ${(k)CONFIGS}"
    echo "Edit the CONFIGS array in '$CONFIG_FILE' to add new configurations."
    return 1
  fi

  IFS='|' read -r PROJECT_ID ACCOUNT CLUSTER_NAME REGION KUBE_CONTEXT_ALIAS NAMESPACE <<< "${CONFIGS[$CONFIG_NAME]}"

  if [[ -z "$KUBE_CONTEXT_ALIAS" ]]; then
    KUBE_CONTEXT_ALIAS="$CONFIG_NAME"
  fi

  if ! gcloud config configurations list --format="value(name)" | grep -q "^$CONFIG_NAME$"; then
    echo "Creating new gcloud configuration: $CONFIG_NAME"
    gcloud config configurations create "$CONFIG_NAME" || return 1
  fi

  echo "Switching to gcloud config: $CONFIG_NAME"
  gcloud config configurations activate "$CONFIG_NAME" || return 1

  if ! check_account_authenticated "$ACCOUNT"; then
    echo "Account $ACCOUNT not authenticated. Initiating gcloud auth login..."
    gcloud auth login "$ACCOUNT" --no-launch-browser || return 1
  fi
  gcloud config set account "$ACCOUNT" || return 1
  gcloud config set project "$PROJECT_ID" || return 1
  gcloud config set compute/region "$REGION" || return 1

  if [[ -f ~/.config/gcloud/$PROJECT_ID-key.json ]]; then
    echo "Setting GOOGLE_APPLICATION_CREDENTIALS for $PROJECT_ID"
    export GOOGLE_APPLICATION_CREDENTIALS=~/.config/gcloud/$PROJECT_ID-key.json
    gcloud auth application-default set-quota-project "$PROJECT_ID" || true
  else
    echo "No service account key found for $PROJECT_ID; skipping ADC setup."
  fi

  if [[ -n "$CLUSTER_NAME" ]]; then
    for cmd in kubectl kubectx kubens; do
      if ! command -v $cmd &> /dev/null; then
        echo "Error: Dependency '$cmd' is not installed. Please install it."
        return 1
      fi
    done

    echo "Updating kubectl credentials for cluster: $CLUSTER_NAME"
    gcloud container clusters get-credentials "$CLUSTER_NAME" --region "$REGION" --project "$PROJECT_ID" --dns-endpoint || return 1

    local GKE_CONTEXT_NAME="gke_${PROJECT_ID}_${REGION}_${CLUSTER_NAME}"
    echo "Standardizing context name to '$KUBE_CONTEXT_ALIAS'..."
    kubectx "$KUBE_CONTEXT_ALIAS=$GKE_CONTEXT_NAME" &>/dev/null

    echo "Switching kubectl context to: $KUBE_CONTEXT_ALIAS"
    kubectx "$KUBE_CONTEXT_ALIAS" || return 1

    run_post_switch_summary "$CONFIG_NAME" "$PROJECT_ID" "$KUBE_CONTEXT_ALIAS" "$NAMESPACE"
  else
    echo "No cluster name provided. Skipping Kubernetes steps."
    echo -e "\nSuccessfully switched gcloud config to: $CONFIG_NAME, project: $PROJECT_ID"
  fi
}

run_post_switch_summary() {
  local CONFIG_NAME=$1
  local PROJECT_ID=$2
  local KUBE_CONTEXT_ALIAS=$3
  local NAMESPACE=$4

  echo -e "\nSuccessfully switched to config: $CONFIG_NAME, project: $PROJECT_ID, context: $KUBE_CONTEXT_ALIAS"

  if [[ -n "$NAMESPACE" ]]; then
    echo "Attempting to switch to namespace: $NAMESPACE"
    kubens "$NAMESPACE" || echo "Warning: Failed to switch to namespace '$NAMESPACE'."
  fi

  echo "Current namespace is:"
  kubens
}

# --- Main Logic ---

if [[ "${(%):-%x}" == "$0" ]]; then
  if [[ "$1" == "--show" ]]; then
    show_configurations
  else
    echo "Error: Invalid command. This script is meant to be sourced."
    echo "Usage: source gcloud-kubectl-switch.zsh"
    echo
    echo "To list available configurations, run:"
    echo "  $0 --show"
    exit 1
  fi
else
  switch() {
    if [[ "$1" == "--show" ]] || [[ "$1" == "--list" ]]; then
      show_configurations
      return
    fi
    if [[ -z "$1" ]]; then
      echo "Usage: switch <alias-name>"
      echo "To see available aliases, run: switch --show"
      echo
      show_configurations
      return 1
    fi
    switch_project "$1"
  }
fi
