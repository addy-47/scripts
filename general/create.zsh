#!/usr/bin/env zsh

# Environment variables
K8S_DIR="./inra/kubernetes/refactor"
SERVICE_NAME="shipment-analysis"

echo "creating iles or ${SERVICE_NAME}"... 

#  the backend coniguration
echo "Creating  backend coniguration..."
touch   ${K8S_DIR}/backendconig/${SERVICE_NAME}-backendconig.yaml 

#  the deployment
echo "Creating  deployment..."
touch  ${K8S_DIR}/deployments/${SERVICE_NAME}-deployment.yaml 

#  the service
echo "Creating  service..."
touch  ${K8S_DIR}/services/${SERVICE_NAME}-service.yaml 


echo "${SERVICE_NAME} service files created  successully!"
