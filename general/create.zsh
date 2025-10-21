#!/usr/bin/env zsh

# Environment variables
K8S_DIR="./infra/k8s"
SERVICE_NAME="data360-crud"

echo "creating files for ${SERVICE_NAME}"...

#  the backend configuration
echo "Creating  backend configuration..."
touch   ${K8S_DIR}/backendconfig/${SERVICE_NAME}-backendconfig.yaml

#  the deployment
echo "Creating  deployment..."
touch  ${K8S_DIR}/deployments/${SERVICE_NAME}-deployment.yaml 

#  the service
echo "Creating  service..."
touch  ${K8S_DIR}/services/${SERVICE_NAME}-service.yaml 


echo "${SERVICE_NAME} service files created  successully!"
