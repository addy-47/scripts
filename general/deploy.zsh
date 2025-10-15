#!/usr/bin/env zsh

# Environment variables
K8S_DIR="./infra/k8s"
NAMESPACE="demo"  # Change this if your service runs in a different namespace
SERVICE_NAME="general-chat-crud"

echo "Starting deployment of general-chat service..."

# Function to check if kubectl command was successful
check_status() {
  if [ $? -ne 0 ]; then
    echo "Error: $1"
    exit 1
  fi
}

# Apply the backend configuration
echo "Applying backend configuration..."
kubectl apply -f ${K8S_DIR}/backendconfig/${SERVICE_NAME}-backendconfig.yaml -n ${NAMESPACE}
check_status "Failed to apply backend configuration"

# Apply the deployment
echo "Applying deployment..."
kubectl apply -f ${K8S_DIR}/deployments/${SERVICE_NAME}-deployment.yaml -n ${NAMESPACE}
check_status "Failed to apply deployment"

# Apply the service
echo "Applying service..."
kubectl apply -f ${K8S_DIR}/services/${SERVICE_NAME}-service.yaml -n ${NAMESPACE}
check_status "Failed to apply service"

# Update the ingress
echo "Applying ingress configuration..."
kubectl apply -f ${K8S_DIR}/ingress.yaml -n ${NAMESPACE}
check_status "Failed to apply ingress configuration"

echo "${SERVICE_NAME} service deployed successfully!"