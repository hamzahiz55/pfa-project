#!/bin/bash

# Colors
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
NC='\033[0m'

echo -e "${YELLOW}Setting up Minikube...${NC}"

# Check if minikube is installed
if ! command -v minikube &> /dev/null; then
    echo -e "${RED}Minikube is not installed.${NC}"
    echo -e "${YELLOW}To install minikube on Windows:${NC}"
    echo "1. Download from: https://minikube.sigs.k8s.io/docs/start/"
    echo "2. Or use chocolatey: choco install minikube"
    echo "3. Or use winget: winget install Kubernetes.minikube"
    exit 1
fi

echo -e "${GREEN}✓ Minikube is installed${NC}"

# Start minikube
echo -e "${YELLOW}Starting minikube...${NC}"
minikube start --driver=docker

# Enable addons
echo -e "${YELLOW}Enabling useful addons...${NC}"
minikube addons enable dashboard
minikube addons enable ingress

# Check status
echo -e "${GREEN}✓ Minikube is ready!${NC}"
minikube status

echo -e "\n${YELLOW}Useful commands:${NC}"
echo "- View dashboard: minikube dashboard"
echo "- Get minikube IP: minikube ip"
echo "- Stop minikube: minikube stop"
echo "- Delete cluster: minikube delete"