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
typeset -A CONFIGS
SCRIPT_DIR="${0:a:h}"  # ← CORRECT: Works when sourced from anywhere
CONFIG_FILE="$SCRIPT_DIR/gcloud-kubectl-switch.conf"

if [[ -f "$CONFIG_FILE" ]]; then
  source "$CONFIG_FILE"
else
  echo "Warning: Configuration file not found at '$CONFIG_FILE'."
  echo "Creating an example config. Please edit it."
  cat > "$CONFIG_FILE" << 'EOF'
CONFIGS=(
  [example]="your-gcp-project-id|user@example.com|your-cluster-name|us-central1|example-ctx|default"
)
EOF
  source "$CONFIG_FILE"
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
    (( ${#alias} > max_alias_len )) && max_alias_len=${#alias}
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
  local first_alias
  for first_alias in ${(ko)CONFIGS}; do
    break
  done
  if [[ -n "$first_alias" ]]; then
    echo "To switch, use: switch $first_alias"
  fi
}

check_account_authenticated() {
  local ACCOUNT=$1
  gcloud auth list --format="value(account)" | grep -q "^$ACCOUNT$"
  return $?
}

switch_project() {
  local CONFIG_NAME=$1
  if [[ -z "${CONFIGS[$CONFIG_NAME]}" ]]; then
    echo "Error: Configuration '$CONFIG_NAME' not found."
    echo "Available: ${(k)CONFIGS}"
    echo "Edit '$CONFIG_FILE' to add new configurations."
    return 1
  fi

  IFS='|' read -r PROJECT_ID ACCOUNT CLUSTER_NAME REGION KUBE_CONTEXT_ALIAS NAMESPACE <<< "${CONFIGS[$CONFIG_NAME]}"
  [[ -z "$KUBE_CONTEXT_ALIAS" ]] && KUBE_CONTEXT_ALIAS="$CONFIG_NAME"

  if ! gcloud config configurations list --format="value(name)" | grep -q "^$CONFIG_NAME$"; then
    echo "Creating gcloud configuration: $CONFIG_NAME"
    gcloud config configurations create "$CONFIG_NAME" || return 1
  fi

  echo "Switching to gcloud config: $CONFIG_NAME"
  gcloud config configurations activate "$CONFIG_NAME" || return 1

  if ! check_account_authenticated "$ACCOUNT"; then
    echo "Account $ACCOUNT not authenticated. Logging in..."
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
    echo "No service account key found for $PROJECT_ID; skipping ADC."
  fi

  if [[ -n "$CLUSTER_NAME" ]]; then
    for cmd in kubectl kubectx kubens; do
      if ! command -v $cmd &> /dev/null; then
        echo "Error: '$cmd' is not installed."
        return 1
      fi
    done

    echo "Fetching kubectl credentials for: $CLUSTER_NAME"
    gcloud container clusters get-credentials "$CLUSTER_NAME" \
      --region "$REGION" --project "$PROJECT_ID" --dns-endpoint || return 1

    local GKE_CONTEXT_NAME="gke_${PROJECT_ID}_${REGION}_${CLUSTER_NAME}"
    echo "Renaming context: $GKE_CONTEXT_NAME → $KUBE_CONTEXT_ALIAS"
    kubectx "$KUBE_CONTEXT_ALIAS=$GKE_CONTEXT_NAME" &>/dev/null || true

    echo "Switching kubectl context to: $KUBE_CONTEXT_ALIAS"
    kubectx "$KUBE_CONTEXT_ALIAS" || return 1

    run_post_switch_summary "$CONFIG_NAME" "$PROJECT_ID" "$KUBE_CONTEXT_ALIAS" "$NAMESPACE"
  else
    echo -e "\nSuccessfully switched gcloud to: $CONFIG_NAME, project: $PROJECT_ID"
  fi
}

run_post_switch_summary() {
  local CONFIG_NAME=$1 PROJECT_ID=$2 KUBE_CONTEXT_ALIAS=$3 NAMESPACE=$4
  echo -e "\nSuccessfully switched:"
  echo "   Config: $CONFIG_NAME"
  echo "   Project: $PROJECT_ID"
  echo "   Context: $KUBE_CONTEXT_ALIAS"
  if [[ -n "$NAMESPACE" ]]; then
    echo "   Namespace: $NAMESPACE"
    kubens "$NAMESPACE" 2>/dev/null || echo "Warning: Failed to switch namespace."
  fi
  echo "   Current namespace:"
  kubens
}

# --- MAIN LOGIC: Only define `switch` when sourced ---
# This prevents errors when sourced via Oh My Zsh

# Are we being *sourced* (not executed)?
if [[ $ZSH_EVAL_CONTEXT == *file* ]] || [[ -n "$ZSH_SCRIPT" && "$ZSH_SCRIPT" != "$0" ]]; then
  # SOURCED → define function
  switch() {
    if [[ "$1" == "--show" ]] || [[ "$1" == "--list" ]]; then
      show_configurations
      return
    fi
    [[ -z "$1" ]] && {
      echo "Usage: switch <alias>"
      echo "Available: switch --show"
      show_configurations
      return 1
    }
    switch_project "$1"
  }
else
  # EXECUTED directly → allow --show only
  if [[ "$1" == "--show" ]]; then
    show_configurations
  else
    echo "Error: This script must be *sourced*, not executed."
    echo "Run: source $0"
    echo
    echo "To list configs:"
    echo "  source $0 && switch --show"
    exit 1
  fi
fi
