#!/usr/bin/env bash
set -euo pipefail

# ==============================================================================
# KubeWatch Automated Deployment Script
# Deploys KubeWatch + Google Chat Adapter into dedicated namespace: kubewatch
# ==============================================================================

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
NAMESPACE="kubewatch"

if [ -z "${GCHAT_WEBHOOK_URL:-}" ]; then
  echo "[ERROR] GCHAT_WEBHOOK_URL environment variable must be set before running this script!"
  echo "Example: export GCHAT_WEBHOOK_URL='https://chat.googleapis.com/v1/spaces/.../messages?key=...&token=...'"
  exit 1
fi

echo "================================================="
echo "[INFO] Starting KubeWatch Deployment"
echo "[INFO] Target Namespace: ${NAMESPACE}"
echo "================================================="

# 1. Apply Namespace
echo "[INFO] Creating/ensuring namespace '${NAMESPACE}'..."
kubectl apply -f "${SCRIPT_DIR}/00-namespace.yaml"

# 2. Create or Update Google Chat Webhook Secret
echo "[INFO] Creating secret 'gchat-webhook-secret' in namespace '${NAMESPACE}'..."
kubectl create secret generic gchat-webhook-secret \
  --namespace="${NAMESPACE}" \
  --from-literal=url="${GCHAT_WEBHOOK_URL}" \
  --dry-run=client -o yaml | kubectl apply -f -

# 3. Apply RBAC, Adapter, Config, and KubeWatch Manifests
echo "[INFO] Applying RBAC permissions..."
kubectl apply -f "${SCRIPT_DIR}/01-rbac.yaml"

echo "[INFO] Applying KubeWatch Google Chat Adapter..."
kubectl apply -f "${SCRIPT_DIR}/03-adapter-deployment.yaml"

echo "[INFO] Applying KubeWatch Configuration..."
kubectl apply -f "${SCRIPT_DIR}/04-kubewatch-config.yaml"

echo "[INFO] Applying KubeWatch Deployment..."
kubectl apply -f "${SCRIPT_DIR}/05-kubewatch.yaml"

# 4. Wait for Rollout Status
echo "[INFO] Waiting for deployments to become ready in namespace '${NAMESPACE}'..."
kubectl rollout status deployment/kubewatch-gchat-adapter -n "${NAMESPACE}" --timeout=120s
kubectl rollout status deployment/kubewatch -n "${NAMESPACE}" --timeout=120s

echo "================================================="
echo "[INFO] ✓ KubeWatch successfully deployed to namespace '${NAMESPACE}'"
echo "================================================="
