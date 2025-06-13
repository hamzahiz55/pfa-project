#!/bin/bash

# Colors for output
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

echo -e "${BLUE}===============================================${NC}"
echo -e "${BLUE}    cert-manager Installation                 ${NC}"
echo -e "${BLUE}===============================================${NC}"

# Check if kubectl is available
if ! command -v kubectl &> /dev/null; then
    echo -e "${RED}✗ kubectl is not installed.${NC}"
    exit 1
fi
echo -e "${GREEN}✓ kubectl is installed${NC}"

# Check if cluster is accessible
if ! kubectl cluster-info &> /dev/null 2>&1; then
    echo -e "${RED}✗ Cannot connect to Kubernetes cluster.${NC}"
    exit 1
fi
echo -e "${GREEN}✓ Connected to Kubernetes cluster${NC}"

# Check if cert-manager is already installed
echo -e "\n${YELLOW}Checking for existing cert-manager...${NC}"
if kubectl get namespace cert-manager &> /dev/null 2>&1; then
    echo -e "${GREEN}✓ cert-manager namespace exists${NC}"
    
    # Check if it's running
    if kubectl get pods -n cert-manager | grep -q "Running"; then
        echo -e "${GREEN}✓ cert-manager is running${NC}"
        kubectl get pods -n cert-manager
        
        # Check version
        VERSION=$(kubectl get deployment cert-manager -n cert-manager -o jsonpath='{.spec.template.spec.containers[0].image}' | cut -d':' -f2)
        echo -e "${GREEN}Current version: $VERSION${NC}"
        
        read -p "Do you want to reinstall? (y/N): " -n 1 -r
        echo
        if [[ ! $REPLY =~ ^[Yy]$ ]]; then
            exit 0
        fi
    else
        echo -e "${RED}✗ cert-manager pods are not running properly${NC}"
    fi
else
    echo -e "${YELLOW}cert-manager is not installed${NC}"
fi

# Install cert-manager
echo -e "\n${YELLOW}Installing cert-manager...${NC}"

# Install CRDs first
echo -e "${YELLOW}Installing cert-manager CRDs...${NC}"
kubectl apply -f https://github.com/cert-manager/cert-manager/releases/download/v1.13.2/cert-manager.crds.yaml

# Create namespace
kubectl create namespace cert-manager --dry-run=client -o yaml | kubectl apply -f -

# Add Helm label to disable resource validation
kubectl label namespace cert-manager cert-manager.io/disable-validation=true --overwrite

# Install cert-manager
echo -e "${YELLOW}Installing cert-manager components...${NC}"
kubectl apply -f https://github.com/cert-manager/cert-manager/releases/download/v1.13.2/cert-manager.yaml

# Wait for deployment
echo -e "\n${YELLOW}Waiting for cert-manager to be ready...${NC}"
kubectl wait --for=condition=available --timeout=300s deployment/cert-manager -n cert-manager
kubectl wait --for=condition=available --timeout=300s deployment/cert-manager-cainjector -n cert-manager
kubectl wait --for=condition=available --timeout=300s deployment/cert-manager-webhook -n cert-manager

# Verify installation
echo -e "\n${YELLOW}Verifying cert-manager installation...${NC}"
sleep 10

# Test with a simple certificate
cat <<EOF | kubectl apply -f -
apiVersion: v1
kind: Namespace
metadata:
  name: cert-manager-test
---
apiVersion: cert-manager.io/v1
kind: Issuer
metadata:
  name: test-selfsigned
  namespace: cert-manager-test
spec:
  selfSigned: {}
---
apiVersion: cert-manager.io/v1
kind: Certificate
metadata:
  name: selfsigned-cert
  namespace: cert-manager-test
spec:
  dnsNames:
    - example.com
  secretName: selfsigned-cert-tls
  issuerRef:
    name: test-selfsigned
EOF

# Wait for certificate
echo -e "${YELLOW}Testing certificate issuance...${NC}"
sleep 15

if kubectl get certificate selfsigned-cert -n cert-manager-test -o jsonpath='{.status.conditions[0].status}' | grep -q "True"; then
    echo -e "${GREEN}✓ cert-manager is working correctly!${NC}"
    
    # Clean up test resources
    kubectl delete namespace cert-manager-test
else
    echo -e "${RED}✗ cert-manager test failed${NC}"
    kubectl describe certificate selfsigned-cert -n cert-manager-test
    kubectl delete namespace cert-manager-test
    exit 1
fi

# Create ClusterIssuers
echo -e "\n${YELLOW}Creating ClusterIssuers...${NC}"

# Let's Encrypt Staging ClusterIssuer
cat <<EOF | kubectl apply -f -
apiVersion: cert-manager.io/v1
kind: ClusterIssuer
metadata:
  name: letsencrypt-staging
spec:
  acme:
    # You must replace this email address with your own.
    # Let's Encrypt will use this to contact you about expiring
    # certificates, and issues related to your account.
    email: admin@example.com
    server: https://acme-staging-v02.api.letsencrypt.org/directory
    privateKeySecretRef:
      # Secret resource that will be used to store the account's private key.
      name: letsencrypt-staging
    # Add a single challenge solver, HTTP01 using nginx
    solvers:
    - http01:
        ingress:
          class: nginx
EOF

# Let's Encrypt Production ClusterIssuer
cat <<EOF | kubectl apply -f -
apiVersion: cert-manager.io/v1
kind: ClusterIssuer
metadata:
  name: letsencrypt-prod
spec:
  acme:
    # You must replace this email address with your own.
    # Let's Encrypt will use this to contact you about expiring
    # certificates, and issues related to your account.
    email: admin@example.com
    server: https://acme-v02.api.letsencrypt.org/directory
    privateKeySecretRef:
      # Secret resource that will be used to store the account's private key.
      name: letsencrypt-prod
    # Add a single challenge solver, HTTP01 using nginx
    solvers:
    - http01:
        ingress:
          class: nginx
EOF

echo -e "\n${GREEN}✓ cert-manager installation complete!${NC}"
echo -e "\n${BLUE}cert-manager Status:${NC}"
kubectl get pods -n cert-manager

echo -e "\n${BLUE}ClusterIssuers:${NC}"
kubectl get clusterissuer

echo -e "\n${YELLOW}Next Steps:${NC}"
echo "1. Update the email address in ClusterIssuers:"
echo "   kubectl edit clusterissuer letsencrypt-staging"
echo "   kubectl edit clusterissuer letsencrypt-prod"
echo ""
echo "2. Update your ingress.yaml to use HTTPS:"
echo "   - Add cert-manager.io/cluster-issuer annotation"
echo "   - Add tls section to ingress spec"
echo ""
echo "3. Example ingress configuration:"
echo "   annotations:"
echo "     cert-manager.io/cluster-issuer: \"letsencrypt-prod\""
echo "   tls:"
echo "   - hosts:"
echo "     - your-domain.com"
echo "     secretName: your-domain-tls"
echo ""
echo -e "${YELLOW}Important Notes:${NC}"
echo "- Use letsencrypt-staging for testing to avoid rate limits"
echo "- Switch to letsencrypt-prod for production domains"
echo "- Ensure your domain DNS points to the ingress controller"
echo "- NGINX Ingress Controller must be installed and working"