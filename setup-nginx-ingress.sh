#!/bin/bash

# Colors for output
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

echo -e "${BLUE}===============================================${NC}"
echo -e "${BLUE}    NGINX Ingress Controller Installation     ${NC}"
echo -e "${BLUE}===============================================${NC}"

# Function to check if a command exists
command_exists() {
    command -v "$1" >/dev/null 2>&1
}

# Function to wait for deployment
wait_for_deployment() {
    local namespace=$1
    local deployment=$2
    local timeout=${3:-300}
    
    echo -e "${YELLOW}Waiting for $deployment in namespace $namespace...${NC}"
    kubectl wait --for=condition=available --timeout=${timeout}s deployment/$deployment -n $namespace
}

# Check prerequisites
echo -e "\n${YELLOW}Checking prerequisites...${NC}"

if ! command_exists kubectl; then
    echo -e "${RED}✗ kubectl is not installed.${NC}"
    exit 1
fi
echo -e "${GREEN}✓ kubectl is installed${NC}"

if ! kubectl cluster-info &> /dev/null 2>&1; then
    echo -e "${RED}✗ Cannot connect to Kubernetes cluster.${NC}"
    exit 1
fi
echo -e "${GREEN}✓ Connected to Kubernetes cluster${NC}"

# Detect cluster type
CLUSTER_TYPE="unknown"
if kubectl get nodes -o wide | grep -q "minikube"; then
    CLUSTER_TYPE="minikube"
    echo -e "${GREEN}✓ Detected Minikube cluster${NC}"
elif kubectl get nodes -o wide | grep -q "docker-desktop"; then
    CLUSTER_TYPE="docker-desktop"
    echo -e "${GREEN}✓ Detected Docker Desktop cluster${NC}"
elif kubectl get nodes -o wide | grep -q "eks.amazonaws.com"; then
    CLUSTER_TYPE="eks"
    echo -e "${GREEN}✓ Detected EKS cluster${NC}"
elif kubectl get nodes -o wide | grep -q "gke"; then
    CLUSTER_TYPE="gke"
    echo -e "${GREEN}✓ Detected GKE cluster${NC}"
elif kubectl get nodes -o wide | grep -q "aks"; then
    CLUSTER_TYPE="aks"
    echo -e "${GREEN}✓ Detected AKS cluster${NC}"
else
    echo -e "${YELLOW}⚠ Could not detect cluster type, proceeding with generic installation${NC}"
fi

# Check if NGINX Ingress is already installed
if kubectl get namespace ingress-nginx &> /dev/null 2>&1; then
    echo -e "${YELLOW}⚠ NGINX Ingress namespace already exists${NC}"
    read -p "Do you want to reinstall? (y/N): " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        echo -e "${YELLOW}Skipping NGINX Ingress installation${NC}"
        exit 0
    fi
fi

# Install NGINX Ingress Controller based on cluster type
echo -e "\n${YELLOW}Installing NGINX Ingress Controller...${NC}"

case $CLUSTER_TYPE in
    minikube)
        echo -e "${YELLOW}Enabling NGINX Ingress addon for Minikube...${NC}"
        minikube addons enable ingress
        wait_for_deployment kube-system ingress-nginx-controller
        ;;
    docker-desktop)
        echo -e "${YELLOW}Installing NGINX Ingress for Docker Desktop...${NC}"
        kubectl apply -f https://raw.githubusercontent.com/kubernetes/ingress-nginx/controller-v1.8.1/deploy/static/provider/cloud/deploy.yaml
        wait_for_deployment ingress-nginx ingress-nginx-controller
        ;;
    eks|gke|aks|*)
        echo -e "${YELLOW}Installing NGINX Ingress for cloud provider...${NC}"
        kubectl apply -f https://raw.githubusercontent.com/kubernetes/ingress-nginx/controller-v1.8.1/deploy/static/provider/cloud/deploy.yaml
        wait_for_deployment ingress-nginx ingress-nginx-controller
        ;;
esac

# Verify installation
echo -e "\n${YELLOW}Verifying NGINX Ingress installation...${NC}"

# Check pods
if kubectl get pods -n ingress-nginx 2>/dev/null | grep -q "Running"; then
    echo -e "${GREEN}✓ NGINX Ingress pods are running${NC}"
else
    echo -e "${RED}✗ NGINX Ingress pods are not running${NC}"
    kubectl get pods -n ingress-nginx
    exit 1
fi

# Check service
if kubectl get svc -n ingress-nginx 2>/dev/null | grep -q "ingress-nginx-controller"; then
    echo -e "${GREEN}✓ NGINX Ingress service is created${NC}"
else
    echo -e "${RED}✗ NGINX Ingress service not found${NC}"
    exit 1
fi

# Get LoadBalancer/NodePort information
echo -e "\n${BLUE}NGINX Ingress Controller Information:${NC}"

case $CLUSTER_TYPE in
    minikube)
        MINIKUBE_IP=$(minikube ip)
        echo -e "${GREEN}Ingress is available at: http://$MINIKUBE_IP${NC}"
        echo -e "${YELLOW}Note: You may need to add entries to /etc/hosts for your domains${NC}"
        echo -e "${YELLOW}Example: echo '$MINIKUBE_IP aws-s3-manager.local' | sudo tee -a /etc/hosts${NC}"
        ;;
    docker-desktop)
        echo -e "${GREEN}Ingress is available at: http://localhost${NC}"
        echo -e "${YELLOW}Note: You may need to add entries to /etc/hosts for your domains${NC}"
        echo -e "${YELLOW}Example: echo '127.0.0.1 aws-s3-manager.local' | sudo tee -a /etc/hosts${NC}"
        ;;
    *)
        echo -e "${YELLOW}Waiting for LoadBalancer IP/hostname...${NC}"
        kubectl get svc -n ingress-nginx ingress-nginx-controller
        echo -e "${YELLOW}Note: It may take a few minutes for the LoadBalancer to be provisioned${NC}"
        echo -e "${YELLOW}Run the following to check status:${NC}"
        echo "kubectl get svc -n ingress-nginx ingress-nginx-controller"
        ;;
esac

# Create a test ingress to verify functionality
echo -e "\n${YELLOW}Creating test ingress...${NC}"
cat <<EOF | kubectl apply -f -
apiVersion: v1
kind: Namespace
metadata:
  name: ingress-test
---
apiVersion: apps/v1
kind: Deployment
metadata:
  name: test-app
  namespace: ingress-test
spec:
  replicas: 1
  selector:
    matchLabels:
      app: test-app
  template:
    metadata:
      labels:
        app: test-app
    spec:
      containers:
      - name: nginx
        image: nginx:alpine
        ports:
        - containerPort: 80
---
apiVersion: v1
kind: Service
metadata:
  name: test-app-service
  namespace: ingress-test
spec:
  selector:
    app: test-app
  ports:
    - port: 80
      targetPort: 80
---
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: test-ingress
  namespace: ingress-test
  annotations:
    nginx.ingress.kubernetes.io/rewrite-target: /
spec:
  ingressClassName: nginx
  rules:
  - host: test.local
    http:
      paths:
      - path: /
        pathType: Prefix
        backend:
          service:
            name: test-app-service
            port:
              number: 80
EOF

echo -e "\n${GREEN}✓ NGINX Ingress Controller installation complete!${NC}"
echo -e "\n${YELLOW}Test the installation:${NC}"
echo "1. Add test.local to your /etc/hosts file pointing to the ingress IP"
echo "2. Visit http://test.local to see the test page"
echo "3. Clean up test resources: kubectl delete namespace ingress-test"

echo -e "\n${YELLOW}Next steps:${NC}"
echo "1. Update your ingress.yaml with your actual domain"
echo "2. Configure DNS to point to the ingress controller"
echo "3. Install cert-manager for TLS certificates (run ./setup-cert-manager.sh)"