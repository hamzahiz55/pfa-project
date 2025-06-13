#!/bin/bash

# Colors for output
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

echo -e "${BLUE}===============================================${NC}"
echo -e "${BLUE}    Starting All Services Automatically      ${NC}"
echo -e "${BLUE}===============================================${NC}"

# Function to check if a service is running
check_service() {
    local service_name=$1
    local check_command=$2
    
    echo -e "${YELLOW}Checking $service_name...${NC}"
    if eval $check_command > /dev/null 2>&1; then
        echo -e "${GREEN}✓ $service_name is already running${NC}"
        return 0
    else
        echo -e "${YELLOW}⚠ $service_name is not running${NC}"
        return 1
    fi
}

# Check and start Docker
if ! docker info > /dev/null 2>&1; then
    echo -e "${RED}✗ Docker is not running. Please start Docker Desktop first.${NC}"
    exit 1
fi
echo -e "${GREEN}✓ Docker is running${NC}"

# Check and start Kubernetes
echo -e "\n${YELLOW}=== Kubernetes Setup ===${NC}"
if ! check_service "Kubernetes cluster" "kubectl cluster-info"; then
    echo -e "${YELLOW}Please enable Kubernetes in Docker Desktop and try again${NC}"
    exit 1
fi

# Check if app is deployed in Kubernetes
if ! check_service "Kubernetes app" "kubectl get pods -n aws-s3-manager"; then
    echo -e "${YELLOW}Deploying to Kubernetes...${NC}"
    ./deploy-k8s.sh
    if [ $? -eq 0 ]; then
        echo -e "${GREEN}✓ Kubernetes deployment successful${NC}"
    else
        echo -e "${RED}✗ Kubernetes deployment failed${NC}"
    fi
fi

# Check and start Jenkins
echo -e "\n${YELLOW}=== Jenkins Setup ===${NC}"
if ! check_service "Jenkins" "curl -s http://localhost:8080"; then
    echo -e "${YELLOW}Starting Jenkins...${NC}"
    ./setup-jenkins.sh > /dev/null 2>&1 &
    
    # Wait for Jenkins to start
    echo -e "${YELLOW}Waiting for Jenkins to start (this may take a moment)...${NC}"
    for i in {1..30}; do
        if curl -s http://localhost:8080 > /dev/null 2>&1; then
            echo -e "${GREEN}✓ Jenkins is now running${NC}"
            break
        fi
        sleep 2
        echo -n "."
    done
    echo ""
fi

echo -e "\n${GREEN}✓ All services are ready!${NC}"
echo -e "\n${BLUE}Access URLs:${NC}"
echo -e "🌐 Development: http://localhost:3000"
echo -e "☸️  Kubernetes: http://localhost:30080"
echo -e "🔧 Jenkins: http://localhost:8080"

echo -e "\n${YELLOW}Starting Next.js development server...${NC}"