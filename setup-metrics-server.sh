#!/bin/bash

# Colors for output
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

echo -e "${BLUE}===============================================${NC}"
echo -e "${BLUE}    Metrics Server Installation               ${NC}"
echo -e "${BLUE}===============================================${NC}"

# Check if kubectl is available
if ! command -v kubectl &> /dev/null; then
    echo -e "${RED}✗ kubectl is not installed.${NC}"
    exit 1
fi
echo -e "${GREEN}✓ kubectl is installed${NC}"

# Check if metrics-server is already installed
echo -e "\n${YELLOW}Checking for existing metrics-server...${NC}"
if kubectl get deployment metrics-server -n kube-system &> /dev/null 2>&1; then
    echo -e "${GREEN}✓ Metrics Server is already installed${NC}"
    
    # Check if it's running
    if kubectl get pods -n kube-system | grep metrics-server | grep -q Running; then
        echo -e "${GREEN}✓ Metrics Server is running${NC}"
        
        # Test metrics API
        echo -e "\n${YELLOW}Testing metrics API...${NC}"
        if kubectl top nodes &> /dev/null 2>&1; then
            echo -e "${GREEN}✓ Metrics API is working${NC}"
            kubectl top nodes
            exit 0
        else
            echo -e "${YELLOW}⚠ Metrics API is not responding${NC}"
        fi
    else
        echo -e "${RED}✗ Metrics Server is not running properly${NC}"
    fi
    
    read -p "Do you want to reinstall? (y/N): " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        exit 0
    fi
fi

# Detect cluster type
CLUSTER_TYPE="unknown"
METRICS_SERVER_ARGS=""

if kubectl get nodes -o wide | grep -q "minikube"; then
    CLUSTER_TYPE="minikube"
    echo -e "${GREEN}✓ Detected Minikube cluster${NC}"
    METRICS_SERVER_ARGS="--kubelet-insecure-tls"
elif kubectl get nodes -o wide | grep -q "docker-desktop"; then
    CLUSTER_TYPE="docker-desktop"
    echo -e "${GREEN}✓ Detected Docker Desktop cluster${NC}"
    METRICS_SERVER_ARGS="--kubelet-insecure-tls"
elif kubectl get nodes -o wide | grep -q "kind"; then
    CLUSTER_TYPE="kind"
    echo -e "${GREEN}✓ Detected Kind cluster${NC}"
    METRICS_SERVER_ARGS="--kubelet-insecure-tls --kubelet-preferred-address-types=InternalIP"
else
    echo -e "${YELLOW}⚠ Could not detect cluster type${NC}"
fi

# Install metrics-server
echo -e "\n${YELLOW}Installing Metrics Server...${NC}"

# Download the manifest
kubectl apply -f https://github.com/kubernetes-sigs/metrics-server/releases/latest/download/components.yaml

# Wait for deployment
echo -e "${YELLOW}Waiting for deployment...${NC}"
sleep 5

# Patch deployment for local clusters if needed
if [ -n "$METRICS_SERVER_ARGS" ]; then
    echo -e "${YELLOW}Patching metrics-server for local cluster...${NC}"
    kubectl patch deployment metrics-server -n kube-system --type='json' -p='[
        {
            "op": "add",
            "path": "/spec/template/spec/containers/0/args/-",
            "value": "--kubelet-insecure-tls"
        }
    ]'
    
    if [ "$CLUSTER_TYPE" == "kind" ]; then
        kubectl patch deployment metrics-server -n kube-system --type='json' -p='[
            {
                "op": "add",
                "path": "/spec/template/spec/containers/0/args/-",
                "value": "--kubelet-preferred-address-types=InternalIP"
            }
        ]'
    fi
fi

# Wait for rollout
echo -e "${YELLOW}Waiting for metrics-server to be ready...${NC}"
kubectl rollout status deployment/metrics-server -n kube-system --timeout=300s

# Verify installation
echo -e "\n${YELLOW}Verifying installation...${NC}"
sleep 10

if kubectl top nodes &> /dev/null 2>&1; then
    echo -e "${GREEN}✓ Metrics Server installed successfully!${NC}"
    echo -e "\n${BLUE}Node metrics:${NC}"
    kubectl top nodes
    echo -e "\n${BLUE}Pod metrics will be available in a few minutes${NC}"
else
    echo -e "${RED}✗ Metrics API is not yet available${NC}"
    echo -e "${YELLOW}This might take a few minutes. Try running:${NC}"
    echo "kubectl top nodes"
    echo "kubectl top pods -n aws-s3-manager"
fi

echo -e "\n${BLUE}HorizontalPodAutoscaler (HPA) can now use CPU and memory metrics${NC}"
echo -e "${YELLOW}To check HPA status:${NC}"
echo "kubectl get hpa -n aws-s3-manager"
echo "kubectl describe hpa aws-s3-manager-hpa -n aws-s3-manager"