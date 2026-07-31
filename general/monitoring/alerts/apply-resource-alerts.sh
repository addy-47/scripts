#!/usr/bin/env bash
# =============================================================================
# apply-resource-alerts.sh
#
# Idempotent automation script to create / reuse Notification Channels, Uptime Checks,
# and Alert Policies for VMs, GKE/K3s, and Domains across GCP projects without duplicates.
#
# Usage:
#   PROJECT_ID="muxly-h4" DOMAIN_HOSTS="maitri-dev.muxly.app demo.muxly.app" ./apply-resource-alerts.sh
# =============================================================================

set -euo pipefail

# =============================================================================
# CONFIGURATION VARIABLES (Override via Environment or Arguments)
# =============================================================================
PROJECT="${1:-${PROJECT_ID:-muxly-h4}}"
APP_PREFIX="${APP_PREFIX:-muxly-h4}"
DOMAIN_HOSTS="${DOMAIN_HOSTS:-maitri-dev.muxly.app demo.muxly.app cli.muxly.app ap-legislative.muxly.app}"
GCHAT_SPACE_ID="${GCHAT_SPACE_ID:-spaces/AAQA5tB5xFE}"
CLUSTER_NAME="${CLUSTER_NAME:-maitri-cluster}"  # Set to "" or "none" if no GKE cluster
CLUSTER_LOCATION="${CLUSTER_LOCATION:-asia-south1}"
K8S_NAMESPACE="${K8S_NAMESPACE:-prod}"

# Tier Selection: "alert-only" (standard single warning per metric) vs "all"
ALERT_TIER="${ALERT_TIER:-alert-only}"
APPLY_VM_ALERTS="${APPLY_VM_ALERTS:-true}"

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
CHANNELS_DIR="${SCRIPT_DIR}/notification-channels"
POLICIES_DIR="${SCRIPT_DIR}/policies"
TEMP_DIR="${SCRIPT_DIR}/.tmp-policies"

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

log_info()  { echo -e "${GREEN}[INFO]${NC} $1"; }
log_warn()  { echo -e "${YELLOW}[WARN]${NC} $1"; }
log_error() { echo -e "${RED}[ERROR]${NC} $1"; }

cleanup() {
  rm -rf "${TEMP_DIR}"
}
trap cleanup EXIT

check_prereqs() {
  if ! command -v gcloud &>/dev/null; then
    log_error "gcloud CLI not found. Please install and authenticate."
    exit 1
  fi

  if ! gcloud projects describe "${PROJECT}" &>/dev/null; then
    log_error "Cannot access project '${PROJECT}'. Check permissions or project ID."
    exit 1
  fi

  log_info "================================================="
  log_info "Target Project      : ${PROJECT}"
  log_info "Application Prefix  : ${APP_PREFIX}"
  log_info "Domain Hosts        : ${DOMAIN_HOSTS}"
  log_info "GChat Space         : ${GCHAT_SPACE_ID}"
  log_info "GKE Cluster         : ${CLUSTER_NAME:-NONE} (${CLUSTER_LOCATION})"
  log_info "Alert Tier Selection: ${ALERT_TIER}"
  log_info "================================================="
}

# =============================================================================
# IDEMPOTENT JSON LOOKUP HELPERS (Python JSON parsing for 100% exact matches)
# =============================================================================
find_gchat_channel() {
  gcloud alpha monitoring channels list --project="${PROJECT}" --format="json" 2>/dev/null | python3 -c '
import json, sys
data = json.load(sys.stdin)
space_id = sys.argv[1]
for c in data:
    if c.get("type") == "google_chat" and c.get("labels", {}).get("space") == space_id:
        print(c["name"])
        break
' "${GCHAT_SPACE_ID}"
}

find_email_channel() {
  local email_addr="$1"
  gcloud alpha monitoring channels list --project="${PROJECT}" --format="json" 2>/dev/null | python3 -c '
import json, sys
data = json.load(sys.stdin)
target_email = sys.argv[1]
for c in data:
    if c.get("type") == "email" and c.get("labels", {}).get("email_address") == target_email:
        print(c["name"])
        break
' "${email_addr}"
}

find_uptime_check() {
  local domain="$1"
  gcloud monitoring uptime list-configs --project="${PROJECT}" --format="json" 2>/dev/null | python3 -c '
import json, sys
data = json.load(sys.stdin)
target_domain = sys.argv[1]
for u in data:
    host = u.get("monitoredResource", {}).get("labels", {}).get("host")
    if host == target_domain:
        print(u["name"])
        break
' "${domain}"
}

find_alert_policy() {
  local display_name="$1"
  gcloud alpha monitoring policies list --project="${PROJECT}" --format="json" 2>/dev/null | python3 -c '
import json, sys
data = json.load(sys.stdin)
target_name = sys.argv[1]
for p in data:
    if p.get("displayName") == target_name:
        print(p["name"])
        break
' "${display_name}"
}

create_notification_channels() {
  mkdir -p "${TEMP_DIR}"
  EMAIL_IDS=()
  GCHAT_ID=""

  log_info "====== Processing Notification Channels (Idempotent) ======"

  # 1. Process GChat Channel
  EXISTING_GCHAT=$(find_gchat_channel)

  if [[ -n "${EXISTING_GCHAT}" ]]; then
    GCHAT_ID="${EXISTING_GCHAT}"
    log_info "  ✓ Reusing existing Google Chat Channel: ${GCHAT_ID}"
  else
    GChat_TEMPLATE="${CHANNELS_DIR}/gchat-space.json"
    if [[ -f "${GChat_TEMPLATE}" ]]; then
      TEMP_GChat="${TEMP_DIR}/gchat-space.json"
      sed "s|<GCHAT_SPACE_NAME>|${GCHAT_SPACE_ID}|g" "${GChat_TEMPLATE}" > "${TEMP_GChat}"

      log_info "Creating Google Chat channel..."
      GCHAT_OUTPUT=$(gcloud alpha monitoring channels create \
        --channel-content-from-file="${TEMP_GChat}" \
        --project="${PROJECT}" \
        --format="value(name)" 2>&1)
      GCHAT_ID=$(echo "${GCHAT_OUTPUT}" | tail -1 | xargs)
      log_info "  ✓ Created GChat Channel ID: ${GCHAT_ID}"
    fi
  fi

  # 2. Process Email Channels
  for FILEPATH in "${CHANNELS_DIR}"/email-*.json; do
    if [[ ! -f "${FILEPATH}" ]]; then
      continue
    fi
    FILE="$(basename "${FILEPATH}")"
    EMAIL_ADDR=$(grep -oP '"email_address":\s*"\K[^"]+' "${FILEPATH}" || true)

    if [[ -z "${EMAIL_ADDR}" ]]; then
      continue
    fi

    EXISTING_EMAIL=$(find_email_channel "${EMAIL_ADDR}")

    if [[ -n "${EXISTING_EMAIL}" ]]; then
      log_info "  ✓ Reusing Email Channel (${EMAIL_ADDR}): ${EXISTING_EMAIL}"
      EMAIL_IDS+=("\"${EXISTING_EMAIL}\"")
    else
      log_info "Creating Email channel for: ${EMAIL_ADDR}"
      EMAIL_OUTPUT=$(gcloud alpha monitoring channels create \
        --channel-content-from-file="${FILEPATH}" \
        --project="${PROJECT}" \
        --format="value(name)" 2>&1)
      E_ID=$(echo "${EMAIL_OUTPUT}" | tail -1 | xargs)
      log_info "  ✓ Created Email Channel ID (${FILE}): ${E_ID}"
      EMAIL_IDS+=("\"${E_ID}\"")
    fi
  done

  # Build Channel Array Strings for Policy JSONs
  ALL_CHANNELS_ARRAY="\"${GCHAT_ID}\""
  for eid in "${EMAIL_IDS[@]}"; do
    ALL_CHANNELS_ARRAY="${ALL_CHANNELS_ARRAY}, ${eid}"
  done

  echo "GCHAT_ID=\"${GCHAT_ID}\"" > "${TEMP_DIR}/env.txt"
  echo "ALL_CHANNELS_ARRAY='${ALL_CHANNELS_ARRAY}'" >> "${TEMP_DIR}/env.txt"
}

create_uptime_checks_and_policies() {
  if [[ -z "${DOMAIN_HOSTS:-}" || "${DOMAIN_HOSTS}" == "none" ]]; then
    log_warn "No DOMAIN_HOSTS specified. Skipping Uptime Checks."
    return 0
  fi

  log_info "====== Processing Uptime Checks and Downtime Policies ======"
  source "${TEMP_DIR}/env.txt"

  IFS=', ' read -r -a DOMAIN_ARRAY <<< "${DOMAIN_HOSTS}"
  UPTIME_POLICY_TEMPLATE="${POLICIES_DIR}/uptime/domain-downtime-policy.json"

  for DOMAIN in "${DOMAIN_ARRAY[@]}"; do
    if [[ -z "${DOMAIN}" ]]; then continue; fi

    DOMAIN_SLUG=$(echo "${DOMAIN}" | tr '.' '-')
    UPTIME_NAME="${APP_PREFIX}-${DOMAIN_SLUG}-uptime"

    log_info "Processing Domain Uptime: ${DOMAIN}"

    EXISTING_UPTIME=$(find_uptime_check "${DOMAIN}")

    if [[ -n "${EXISTING_UPTIME}" ]]; then
      UPTIME_ID=$(echo "${EXISTING_UPTIME}" | awk -F'/' '{print $NF}')
      log_info "  ✓ Reusing Uptime Check for ${DOMAIN}: ${UPTIME_ID}"
    else
      UPTIME_OUTPUT=$(gcloud monitoring uptime create "${UPTIME_NAME}" \
        --resource-type="uptime-url" \
        --resource-labels="host=${DOMAIN},project_id=${PROJECT}" \
        --protocol="https" \
        --path="/" \
        --port=443 \
        --period=1 \
        --timeout=10 \
        --validate-ssl=true \
        --project="${PROJECT}" \
        --format="value(name)" 2>&1)

      UPTIME_ID=$(echo "${UPTIME_OUTPUT}" | tail -1 | xargs | awk -F'/' '{print $NF}')
      log_info "  ✓ Created Uptime Check ID for ${DOMAIN}: ${UPTIME_ID}"
    fi

    # Downtime Alert Policy
    POLICY_DISPLAY_NAME="${APP_PREFIX}-${DOMAIN_SLUG}-domain-downtime"
    EXISTING_POLICY=$(find_alert_policy "${POLICY_DISPLAY_NAME}")

    if [[ -n "${EXISTING_POLICY}" ]]; then
      log_info "  ✓ Downtime Policy for ${DOMAIN} already exists: ${EXISTING_POLICY}"
    elif [[ -f "${UPTIME_POLICY_TEMPLATE}" ]]; then
      TEMP_POLICY="${TEMP_DIR}/uptime-${DOMAIN_SLUG}.json"
      cp "${UPTIME_POLICY_TEMPLATE}" "${TEMP_POLICY}"

      sed -i "s|<APP_PREFIX>|${APP_PREFIX}-${DOMAIN_SLUG}|g" "${TEMP_POLICY}"
      sed -i "s|<PROJECT_ID>|${PROJECT}|g" "${TEMP_POLICY}"
      sed -i "s|<DOMAIN_HOST>|${DOMAIN}|g" "${TEMP_POLICY}"
      sed -i "s|<UPTIME_CHECK_ID>|${UPTIME_ID}|g" "${TEMP_POLICY}"
      sed -i "s|<GCHAT_CHANNEL_ID>|${GCHAT_ID}|g" "${TEMP_POLICY}"
      sed -i "s|<NOTIFICATION_CHANNELS>|${ALL_CHANNELS_ARRAY}|g" "${TEMP_POLICY}"

      POLICY_OUTPUT=$(gcloud alpha monitoring policies create \
        --policy-from-file="${TEMP_POLICY}" \
        --project="${PROJECT}" \
        --format="value(name)" 2>&1)

      log_info "  ✓ Created Downtime Policy for ${DOMAIN}: ${POLICY_OUTPUT}"
    fi
  done
}

process_policy_directory() {
  local SUBDIR="$1"
  local TARGET_DIR="${POLICIES_DIR}/${SUBDIR}"

  if [[ ! -d "${TARGET_DIR}" ]]; then
    return 0
  fi

  log_info "====== Processing Policies in: ${SUBDIR} ======"
  source "${TEMP_DIR}/env.txt"

  for SOURCE in "${TARGET_DIR}"/*.json; do
    if [[ ! -f "${SOURCE}" ]]; then
      continue
    fi
    FILE="$(basename "${SOURCE}")"

    # Skip multi-tier info policies when ALERT_TIER="alert-only"
    if [[ "${ALERT_TIER}" == "alert-only" && ("${FILE}" == *"-info-"* || "${FILE}" == *"-info-warning-"*) ]]; then
      log_warn "  Skipping multi-tier policy in alert-only mode: ${FILE}"
      continue
    fi

    TEMP_POLICY="${TEMP_DIR}/${FILE}"
    cp "${SOURCE}" "${TEMP_POLICY}"

    # Replace placeholders FIRST
    sed -i "s|<APP_PREFIX>|${APP_PREFIX}|g" "${TEMP_POLICY}"
    sed -i "s|<PROJECT_ID>|${PROJECT}|g" "${TEMP_POLICY}"
    sed -i "s|<CLUSTER_NAME>|${CLUSTER_NAME:-}|g" "${TEMP_POLICY}"
    sed -i "s|<CLUSTER_LOCATION>|${CLUSTER_LOCATION:-}|g" "${TEMP_POLICY}"
    sed -i "s|<K8S_NAMESPACE>|${K8S_NAMESPACE:-}|g" "${TEMP_POLICY}"
    sed -i "s|<GCHAT_CHANNEL_ID>|${GCHAT_ID}|g" "${TEMP_POLICY}"
    sed -i "s|<NOTIFICATION_CHANNELS>|${ALL_CHANNELS_ARRAY}|g" "${TEMP_POLICY}"

    # Extract display name AFTER placeholder replacements!
    POLICY_DISPLAY_NAME=$(python3 -c 'import json, sys; print(json.load(open(sys.argv[1]))["displayName"])' "${TEMP_POLICY}")

    EXISTING_POLICY=$(find_alert_policy "${POLICY_DISPLAY_NAME}")

    if [[ -n "${EXISTING_POLICY}" ]]; then
      log_info "  ✓ Policy already exists (${POLICY_DISPLAY_NAME}): ${EXISTING_POLICY}"
    else
      log_info "Creating policy template: ${FILE}"
      POLICY_OUTPUT=$(gcloud alpha monitoring policies create \
        --policy-from-file="${TEMP_POLICY}" \
        --project="${PROJECT}" \
        --format="value(name)" 2>&1)

      log_info "  ✓ Created Policy: ${POLICY_OUTPUT}"
    fi
  done
}

create_alert_policies() {
  # 1. Apply VM Policies
  if [[ "${APPLY_VM_ALERTS}" == "true" ]]; then
    process_policy_directory "vm"
  fi

  # 2. Apply K8s Policies (Only if CLUSTER_NAME is provided and not "none")
  if [[ -n "${CLUSTER_NAME:-}" && "${CLUSTER_NAME}" != "none" ]]; then
    process_policy_directory "k8s"
  else
    log_warn "No GKE cluster specified. Skipping K8s cluster policies."
  fi
}

verify_resources() {
  log_info "====== Verification ======"
  log_info "Uptime Checks in ${PROJECT}:"
  gcloud monitoring uptime list-configs --project="${PROJECT}" --format="table(name, displayName, monitoredResource.labels.host)"
  log_info "Notification Channels in ${PROJECT}:"
  gcloud alpha monitoring channels list --project="${PROJECT}" --format="table(name, displayName, type, enabled)"
  log_info "Alert Policies in ${PROJECT}:"
  gcloud alpha monitoring policies list --project="${PROJECT}" --format="table(name, displayName, severity, enabled)"
}

main() {
  check_prereqs
  create_notification_channels
  create_uptime_checks_and_policies
  create_alert_policies
  verify_resources
}

main "$@"
