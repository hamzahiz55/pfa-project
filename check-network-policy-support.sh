#!/bin/bash

# Colors for output
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

echo -e "${BLUE}===============================================${NC}"
echo -e "${BLUE}    Checking NetworkPolicy Support            ${NC}"
echo -e "${BLUE}===============================================${NC}"

# Check if kubectl is available
if ! command -v kubectl &> /dev/null; then
    echo -e "${RED}✗ kubectl is not installed.${NC}"
    exit 1
fi

# Check if NetworkPolicy API is available
echo -e "\n${YELLOW}Checking NetworkPolicy API availability...${NC}"
if kubectl api-resources | grep -q "networkpolicies"; then
    echo -e "${GREEN}✓ NetworkPolicy API is available${NC}"
else
    echo -e "${RED}✗ NetworkPolicy API is not available${NC}"
    exit 1
fi

# Check for CNI plugin that supports NetworkPolicy
echo -e "\n${YELLOW}Checking for CNI plugin with NetworkPolicy support...${NC}"

# Check for common CNI plugins
CNI_FOUND=false
if kubectl get pods -n kube-system | grep -q "calico"; then
    echo -e "${GREEN}✓ Calico CNI detected - NetworkPolicy is supported${NC}"
    CNI_FOUND=true
elif kubectl get pods -n kube-system | grep -q "weave"; then
    echo -e "${GREEN}✓ Weave Net CNI detected - NetworkPolicy is supported${NC}"
    CNI_FOUND=true
elif kubectl get pods -n kube-system | grep -q "cilium"; then
    echo -e "${GREEN}✓ Cilium CNI detected - NetworkPolicy is supported${NC}"
    CNI_FOUND=true
elif kubectl get pods -n kube-system | grep -q "canal"; then
    echo -e "${GREEN}✓ Canal CNI detected - NetworkPolicy is supported${NC}"
    CNI_FOUND=true
elif kubectl get pods -n kube-system | grep -q "flannel"; then
    echo -e "${YELLOW}⚠ Flannel CNI detected - NetworkPolicy is NOT supported by default${NC}"
    echo -e "${YELLOW}  Consider using Calico with Flannel (Canal) for NetworkPolicy support${NC}"
fi

# Check for cloud provider CNIs
if kubectl get nodes -o wide | grep -q "eks.amazonaws.com"; then
    if kubectl get daemonset -n kube-system aws-node &> /dev/null; then
        echo -e "${YELLOW}⚠ AWS VPC CNI detected - NetworkPolicy requires additional setup${NC}"
        echo -e "${YELLOW}  Install Calico for NetworkPolicy support on EKS:${NC}"
        echo "  kubectl apply -f https://docs.projectcalico.org/manifests/calico-vxlan.yaml"
    fi
elif kubectl get nodes -o wide | grep -q "gke"; then
    echo -e "${GREEN}✓ GKE cluster - NetworkPolicy is supported when enabled${NC}"
    echo -e "${YELLOW}  Ensure NetworkPolicy is enabled in your GKE cluster${NC}"
elif kubectl get nodes -o wide | grep -q "aks"; then
    echo -e "${GREEN}✓ AKS cluster - NetworkPolicy can be enabled${NC}"
    echo -e "${YELLOW}  Ensure NetworkPolicy is enabled with Azure CNI or Calico${NC}"
fi

# Docker Desktop check
if kubectl get nodes -o wide | grep -q "docker-desktop"; then
    echo -e "${YELLOW}⚠ Docker Desktop detected - NetworkPolicy is NOT enforced${NC}"
    echo -e "${YELLOW}  NetworkPolicies will be created but not enforced${NC}"
    CNI_FOUND=false
fi

# Minikube check
if kubectl get nodes -o wide | grep -q "minikube"; then
    echo -e "${YELLOW}⚠ Minikube detected - checking CNI configuration...${NC}"
    if minikube addons list | grep -q "cni.*enabled"; then
        echo -e "${GREEN}✓ CNI addon is enabled${NC}"
        echo -e "${YELLOW}  To enable NetworkPolicy support, use Calico:${NC}"
        echo "  minikube start --cni=calico"
    else
        echo -e "${YELLOW}  NetworkPolicy requires CNI plugin like Calico${NC}"
        echo "  Restart minikube with: minikube start --cni=calico"
    fi
fi

echo -e "\n${BLUE}Summary:${NC}"
if [ "$CNI_FOUND" = true ]; then
    echo -e "${GREEN}✓ Your cluster supports NetworkPolicy${NC}"
    echo -e "${GREEN}  You can apply NetworkPolicies and they will be enforced${NC}"
else
    echo -e "${YELLOW}⚠ NetworkPolicy enforcement is not confirmed${NC}"
    echo -e "${YELLOW}  NetworkPolicies can be created but may not be enforced${NC}"
    echo -e "${YELLOW}  Consider installing a CNI plugin that supports NetworkPolicy${NC}"
fi

echo -e "\n${BLUE}To test NetworkPolicy after deployment:${NC}"
echo "1. Deploy the application with NetworkPolicies"
echo "2. Try to access pods directly to verify policies are enforced"
echo "3. Check logs for connection issues"

echo -e "\n${BLUE}Common CNI plugins with NetworkPolicy support:${NC}"
echo "- Calico: Full NetworkPolicy support"
echo "- Cilium: Full NetworkPolicy support + additional features"
echo "- Weave Net: Full NetworkPolicy support"
echo "- Canal: Flannel + Calico for NetworkPolicy"