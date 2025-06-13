#!/bin/bash

# Colors for output
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

echo -e "${BLUE}===============================================${NC}"
echo -e "${BLUE}    Checking Storage Configuration            ${NC}"
echo -e "${BLUE}===============================================${NC}"

# Check if kubectl is available
if ! command -v kubectl &> /dev/null; then
    echo -e "${RED}✗ kubectl is not installed.${NC}"
    exit 1
fi

# Check default storage class
echo -e "\n${YELLOW}Checking default StorageClass...${NC}"
DEFAULT_SC=$(kubectl get storageclass -o json | jq -r '.items[] | select(.metadata.annotations."storageclass.kubernetes.io/is-default-class" == "true") | .metadata.name')

if [ -n "$DEFAULT_SC" ]; then
    echo -e "${GREEN}✓ Default StorageClass: $DEFAULT_SC${NC}"
else
    echo -e "${YELLOW}⚠ No default StorageClass found${NC}"
fi

# List all storage classes
echo -e "\n${YELLOW}Available StorageClasses:${NC}"
kubectl get storageclass

# Check PVCs
echo -e "\n${YELLOW}Persistent Volume Claims:${NC}"
kubectl get pvc -A | grep -E "(NAMESPACE|aws-s3-manager)"

# Check PVs
echo -e "\n${YELLOW}Persistent Volumes:${NC}"
kubectl get pv | grep -E "(NAME|aws-s3-manager)"

# Check storage provisioner
echo -e "\n${YELLOW}Storage Provisioners:${NC}"
kubectl get storageclass -o json | jq -r '.items[] | "\(.metadata.name): \(.provisioner)"'

# Cluster-specific recommendations
echo -e "\n${BLUE}Storage Recommendations:${NC}"

if kubectl get nodes -o wide | grep -q "minikube"; then
    echo -e "${YELLOW}Minikube detected:${NC}"
    echo "- Default provisioner: k8s.io/minikube-hostpath"
    echo "- Data is stored in minikube VM/container"
    echo "- Data persists across pod restarts but not minikube restarts"
elif kubectl get nodes -o wide | grep -q "docker-desktop"; then
    echo -e "${YELLOW}Docker Desktop detected:${NC}"
    echo "- Default provisioner: docker.io/hostpath"
    echo "- Data is stored in Docker Desktop VM"
    echo "- Data persists across pod restarts"
elif kubectl get nodes -o wide | grep -q "eks.amazonaws.com"; then
    echo -e "${YELLOW}EKS detected:${NC}"
    echo "- Recommended: Use ebs.csi.aws.com provisioner"
    echo "- Install EBS CSI driver if not present"
    echo "- Use gp3 volumes for better price/performance"
elif kubectl get nodes -o wide | grep -q "gke"; then
    echo -e "${YELLOW}GKE detected:${NC}"
    echo "- Default provisioner: pd.csi.storage.gke.io"
    echo "- Use pd-ssd for production databases"
    echo "- Enable regional-pd for high availability"
elif kubectl get nodes -o wide | grep -q "aks"; then
    echo -e "${YELLOW}AKS detected:${NC}"
    echo "- Default provisioner: disk.csi.azure.com"
    echo "- Use Premium_LRS for production databases"
    echo "- Enable ZRS for zone-redundant storage"
fi

# Check if postgres PVC exists and is bound
echo -e "\n${YELLOW}PostgreSQL Storage Status:${NC}"
PVC_STATUS=$(kubectl get pvc postgres-pvc -n aws-s3-manager -o jsonpath='{.status.phase}' 2>/dev/null)
if [ "$PVC_STATUS" == "Bound" ]; then
    echo -e "${GREEN}✓ PostgreSQL PVC is bound${NC}"
    kubectl get pvc postgres-pvc -n aws-s3-manager
elif [ -n "$PVC_STATUS" ]; then
    echo -e "${YELLOW}⚠ PostgreSQL PVC status: $PVC_STATUS${NC}"
    kubectl describe pvc postgres-pvc -n aws-s3-manager | grep -A5 "Events:"
else
    echo -e "${YELLOW}PostgreSQL PVC not found (will be created on deployment)${NC}"
fi

echo -e "\n${BLUE}Storage Tips:${NC}"
echo "1. Always use 'Retain' reclaim policy for production databases"
echo "2. Enable volume expansion for growing databases"
echo "3. Use SSD storage classes for better database performance"
echo "4. Implement regular backups (see postgres-backup-cronjob.yaml)"
echo "5. Monitor PVC usage to prevent out-of-space issues"