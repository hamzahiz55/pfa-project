#!/bin/bash

# Colors for output
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

echo -e "${BLUE}===============================================${NC}"
echo -e "${BLUE}    AWS S3 Manager - Kubernetes Deployment    ${NC}"
echo -e "${BLUE}===============================================${NC}"

# Check prerequisites
echo -e "\n${YELLOW}Checking prerequisites...${NC}"

# Check if kubectl is available
if ! command -v kubectl &> /dev/null; then
    echo -e "${RED}✗ kubectl is not installed.${NC}"
    echo -e "${YELLOW}Please install kubectl first:${NC}"
    echo "For Docker Desktop: Enable Kubernetes in Docker Desktop settings"
    echo "For Minikube: https://minikube.sigs.k8s.io/docs/start/"
    exit 1
fi
echo -e "${GREEN}✓ kubectl is installed${NC}"

# Check if cluster is accessible
if ! kubectl cluster-info &> /dev/null 2>&1; then
    echo -e "${RED}✗ Cannot connect to Kubernetes cluster.${NC}"
    echo -e "${YELLOW}Please ensure one of the following:${NC}"
    echo "- Docker Desktop: Enable Kubernetes in Settings"
    echo "- Minikube: Run 'minikube start'"
    echo "- Run './check-k8s-setup.sh' for detailed help"
    exit 1
fi
echo -e "${GREEN}✓ Connected to Kubernetes cluster${NC}"

# Check if Docker is available
if ! command -v docker &> /dev/null; then
    echo -e "${RED}✗ Docker is not installed.${NC}"
    exit 1
fi
echo -e "${GREEN}✓ Docker is installed${NC}"

# Check if Docker is running
if ! docker info &> /dev/null 2>&1; then
    echo -e "${RED}✗ Docker is not running.${NC}"
    echo "Please start Docker Desktop"
    exit 1
fi
echo -e "${GREEN}✓ Docker is running${NC}"

echo -e "${GREEN}✓ Kubernetes cluster is accessible${NC}"

# Build Docker image
echo -e "\n${YELLOW}Building Docker image...${NC}"
docker build -t aws-s3-manager:latest .

# For minikube, load the image
if command -v minikube &> /dev/null && minikube status &> /dev/null; then
    echo -e "${YELLOW}Loading image into minikube...${NC}"
    minikube image load aws-s3-manager:latest
fi

# Create namespace
echo -e "\n${YELLOW}Creating namespace...${NC}"
kubectl create namespace aws-s3-manager --dry-run=client -o yaml | kubectl apply -f -

# Apply Kubernetes resources
echo -e "\n${YELLOW}Applying Kubernetes resources...${NC}"
kubectl apply -f k8s/secret.yaml
kubectl apply -f k8s/configmap.yaml
kubectl apply -f k8s/postgres-deployment.yaml
kubectl apply -f k8s/postgres-service.yaml
kubectl apply -f k8s/app-deployment.yaml
kubectl apply -f k8s/app-service.yaml

# Wait for deployments
echo -e "\n${YELLOW}Waiting for deployments to be ready...${NC}"
kubectl wait --for=condition=available --timeout=300s deployment/postgres -n aws-s3-manager
kubectl wait --for=condition=available --timeout=300s deployment/aws-s3-manager -n aws-s3-manager

# Show status
echo -e "\n${GREEN}Deployment complete!${NC}"
echo -e "\n${YELLOW}Current status:${NC}"
kubectl get all -n aws-s3-manager

# Get access URL
if command -v minikube &> /dev/null && minikube status &> /dev/null; then
    MINIKUBE_IP=$(minikube ip)
    echo -e "\n${GREEN}Access the application at: http://${MINIKUBE_IP}:30080${NC}"
else
    echo -e "\n${GREEN}Access the application at: http://localhost:30080${NC}"
fi

echo -e "\n${YELLOW}Useful commands:${NC}"
echo "- Check logs: kubectl logs -f deployment/aws-s3-manager -n aws-s3-manager"
echo "- Check pods: kubectl get pods -n aws-s3-manager"
echo "- Delete all: kubectl delete namespace aws-s3-manager"