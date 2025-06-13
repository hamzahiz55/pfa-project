#!/bin/bash

# Script to generate kubeconfig for CI/CD ServiceAccount
# This creates a kubeconfig that can be used by Jenkins or GitHub Actions

NAMESPACE="aws-s3-manager"
SERVICE_ACCOUNT="cicd-deployer-sa"
CLUSTER_NAME="aws-s3-manager-cluster"
OUTPUT_FILE="cicd-kubeconfig.yaml"

# Colors for output
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

echo -e "${BLUE}===============================================${NC}"
echo -e "${BLUE}    Generating CI/CD Kubeconfig               ${NC}"
echo -e "${BLUE}===============================================${NC}"

# Check if kubectl is available
if ! command -v kubectl &> /dev/null; then
    echo -e "${RED}✗ kubectl is not installed.${NC}"
    exit 1
fi

# Check if namespace exists
if ! kubectl get namespace $NAMESPACE &> /dev/null; then
    echo -e "${RED}✗ Namespace $NAMESPACE does not exist.${NC}"
    echo -e "${YELLOW}Deploy the application first: ./deploy-k8s.sh${NC}"
    exit 1
fi

# Check if service account exists
if ! kubectl get serviceaccount $SERVICE_ACCOUNT -n $NAMESPACE &> /dev/null; then
    echo -e "${RED}✗ ServiceAccount $SERVICE_ACCOUNT does not exist.${NC}"
    echo -e "${YELLOW}Deploy to production first: kubectl apply -k k8s/environments/production${NC}"
    exit 1
fi

echo -e "${YELLOW}Generating kubeconfig for $SERVICE_ACCOUNT...${NC}"

# Get the service account token secret name
SECRET_NAME=$(kubectl get serviceaccount $SERVICE_ACCOUNT -n $NAMESPACE -o jsonpath='{.secrets[0].name}' 2>/dev/null)

# For Kubernetes 1.24+, we need to create a token if no secret exists
if [ -z "$SECRET_NAME" ]; then
    echo -e "${YELLOW}Creating service account token...${NC}"
    # Create a long-lived token
    kubectl apply -f - <<EOF
apiVersion: v1
kind: Secret
metadata:
  name: ${SERVICE_ACCOUNT}-token
  namespace: ${NAMESPACE}
  annotations:
    kubernetes.io/service-account.name: ${SERVICE_ACCOUNT}
type: kubernetes.io/service-account-token
EOF
    SECRET_NAME="${SERVICE_ACCOUNT}-token"
    sleep 2
fi

# Get the token
TOKEN=$(kubectl get secret $SECRET_NAME -n $NAMESPACE -o jsonpath='{.data.token}' | base64 -d)

# Get the cluster CA certificate
CA_CERT=$(kubectl get secret $SECRET_NAME -n $NAMESPACE -o jsonpath='{.data.ca\.crt}')

# Get the API server endpoint
API_SERVER=$(kubectl config view --minify -o jsonpath='{.clusters[0].cluster.server}')

# Get current cluster name
CURRENT_CLUSTER=$(kubectl config view --minify -o jsonpath='{.clusters[0].name}')

# Create the kubeconfig file
cat > $OUTPUT_FILE <<EOF
apiVersion: v1
kind: Config
clusters:
- name: $CLUSTER_NAME
  cluster:
    certificate-authority-data: $CA_CERT
    server: $API_SERVER
contexts:
- name: $SERVICE_ACCOUNT@$CLUSTER_NAME
  context:
    cluster: $CLUSTER_NAME
    namespace: $NAMESPACE
    user: $SERVICE_ACCOUNT
current-context: $SERVICE_ACCOUNT@$CLUSTER_NAME
users:
- name: $SERVICE_ACCOUNT
  user:
    token: $TOKEN
EOF

echo -e "${GREEN}✓ Kubeconfig generated successfully: $OUTPUT_FILE${NC}"
echo -e "${YELLOW}This file contains sensitive credentials. Handle with care!${NC}"
echo ""
echo -e "${BLUE}To use this kubeconfig:${NC}"
echo "export KUBECONFIG=$PWD/$OUTPUT_FILE"
echo "kubectl get pods"
echo ""
echo -e "${BLUE}For Jenkins:${NC}"
echo "1. Create a 'Secret file' credential in Jenkins"
echo "2. Upload this file: $OUTPUT_FILE"
echo "3. Use withCredentials in Jenkinsfile to access it"
echo ""
echo -e "${BLUE}For GitHub Actions:${NC}"
echo "1. Base64 encode the file: base64 -i $OUTPUT_FILE"
echo "2. Add as a secret named KUBE_CONFIG_DATA"
echo "3. Decode in workflow and save to file"
echo ""
echo -e "${RED}Security Warning:${NC}"
echo "- This token has limited permissions in the $NAMESPACE namespace only"
echo "- Rotate regularly and store securely"
echo "- Never commit to version control"