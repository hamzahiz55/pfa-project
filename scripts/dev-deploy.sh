#!/bin/bash

# Quick Development Deployment Script
# For rapid iteration during development

# Colors
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

echo -e "${BLUE}🚀 Quick Development Deployment${NC}"
echo "================================"

# Configuration
IMAGE_NAME="aws-s3-manager"
NAMESPACE="aws-s3-manager"

# Quick checks
if ! kubectl cluster-info &> /dev/null; then
    echo "❌ Kubernetes cluster not accessible"
    exit 1
fi

echo -e "${YELLOW}📦 Building image...${NC}"
docker build -t ${IMAGE_NAME}:dev .

echo -e "${YELLOW}🔄 Updating deployment...${NC}"
kubectl set image deployment/aws-s3-manager-app aws-s3-manager=${IMAGE_NAME}:dev -n ${NAMESPACE}

echo -e "${YELLOW}⏳ Waiting for rollout...${NC}"
kubectl rollout status deployment/aws-s3-manager-app -n ${NAMESPACE} --timeout=120s

echo -e "${GREEN}✅ Quick deployment completed!${NC}"
echo -e "🌐 Access: http://localhost:30080"

# Show pod status
kubectl get pods -n ${NAMESPACE}