#!/bin/bash

# Colors
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
NC='\033[0m'

echo -e "${YELLOW}Checking Kubernetes Setup...${NC}"
echo "============================"

# Check kubectl
if ! command -v kubectl &> /dev/null; then
    echo -e "${RED}✗ kubectl is not installed${NC}"
    echo "Install kubectl from: https://kubernetes.io/docs/tasks/tools/"
    exit 1
else
    echo -e "${GREEN}✓ kubectl is installed${NC}"
fi

# Check if we can connect to a cluster
if kubectl cluster-info &> /dev/null 2>&1; then
    echo -e "${GREEN}✓ Connected to Kubernetes cluster${NC}"
    kubectl cluster-info | grep "Kubernetes" | head -1
    
    # Show current context
    CURRENT_CONTEXT=$(kubectl config current-context)
    echo -e "${GREEN}✓ Current context: ${CURRENT_CONTEXT}${NC}"
else
    echo -e "${RED}✗ Cannot connect to Kubernetes cluster${NC}"
    echo ""
    echo -e "${YELLOW}Please ensure one of the following:${NC}"
    echo "1. Docker Desktop: Enable Kubernetes in Settings > Kubernetes"
    echo "2. Minikube: Run 'minikube start'"
    echo "3. Kind: Run 'kind create cluster'"
    echo ""
    
    # Check for Docker Desktop
    if [[ "$OSTYPE" == "darwin"* ]] || [[ "$OSTYPE" == "msys" ]] || [[ "$OSTYPE" == "cygwin" ]]; then
        if command -v docker &> /dev/null && docker info &> /dev/null; then
            echo -e "${YELLOW}Docker Desktop detected. To enable Kubernetes:${NC}"
            echo "1. Open Docker Desktop"
            echo "2. Go to Settings/Preferences"
            echo "3. Click on Kubernetes"
            echo "4. Check 'Enable Kubernetes'"
            echo "5. Click 'Apply & Restart'"
            echo "6. Wait for Kubernetes to start (can take a few minutes)"
        fi
    fi
    
    # Check for minikube
    if command -v minikube &> /dev/null; then
        echo ""
        echo -e "${YELLOW}Minikube detected. To start:${NC}"
        echo "minikube start"
    fi
    
    exit 1
fi

# Check nodes
echo ""
echo -e "${YELLOW}Kubernetes Nodes:${NC}"
kubectl get nodes

# Check for NGINX Ingress Controller
echo ""
echo -e "${YELLOW}Checking for NGINX Ingress Controller...${NC}"
if kubectl get namespace ingress-nginx &> /dev/null 2>&1; then
    if kubectl get pods -n ingress-nginx 2>/dev/null | grep -q "Running"; then
        echo -e "${GREEN}✓ NGINX Ingress Controller is installed and running${NC}"
    else
        echo -e "${YELLOW}⚠ NGINX Ingress Controller namespace exists but pods are not running${NC}"
        echo "  Run: ./setup-nginx-ingress.sh"
    fi
else
    echo -e "${YELLOW}⚠ NGINX Ingress Controller is not installed${NC}"
    echo "  Run: ./setup-nginx-ingress.sh"
fi

# Check for Metrics Server
echo ""
echo -e "${YELLOW}Checking for Metrics Server...${NC}"
if kubectl get deployment metrics-server -n kube-system &> /dev/null 2>&1; then
    if kubectl top nodes &> /dev/null 2>&1; then
        echo -e "${GREEN}✓ Metrics Server is installed and working${NC}"
    else
        echo -e "${YELLOW}⚠ Metrics Server is installed but not responding${NC}"
        echo "  Run: ./setup-metrics-server.sh"
    fi
else
    echo -e "${YELLOW}⚠ Metrics Server is not installed (required for HPA)${NC}"
    echo "  Run: ./setup-metrics-server.sh"
fi

# Check for cert-manager
echo ""
echo -e "${YELLOW}Checking for cert-manager...${NC}"
if kubectl get namespace cert-manager &> /dev/null 2>&1; then
    if kubectl get pods -n cert-manager 2>/dev/null | grep -q "Running"; then
        echo -e "${GREEN}✓ cert-manager is installed and running${NC}"
    else
        echo -e "${YELLOW}⚠ cert-manager namespace exists but pods are not running${NC}"
        echo "  Run: ./setup-cert-manager.sh"
    fi
else
    echo -e "${YELLOW}⚠ cert-manager is not installed (required for TLS)${NC}"
    echo "  Run: ./setup-cert-manager.sh"
fi

echo ""
echo -e "${GREEN}✓ Kubernetes is ready!${NC}"
echo ""
echo -e "${YELLOW}Next steps:${NC}"
echo "1. Install NGINX Ingress: ./setup-nginx-ingress.sh (if not installed)"
echo "2. Install Metrics Server: ./setup-metrics-server.sh (if not installed)"
echo "3. Install cert-manager: ./setup-cert-manager.sh (if not installed)"
echo "4. Run: ./deploy-k8s.sh"
echo "5. Access app at: http://localhost:30080"