#!/bin/bash

echo "🚀 Quick Deploy to Kubernetes"
echo "============================="

# Check if Kubernetes is ready
if ! kubectl get nodes &> /dev/null; then
    echo "❌ Kubernetes is not ready. Please:"
    echo "1. Enable Kubernetes in Docker Desktop, OR"
    echo "2. Run: ./setup-minikube.sh"
    exit 1
fi

echo "✅ Kubernetes is ready!"

# Build and deploy
echo "🔨 Building Docker image..."
docker build -t aws-s3-manager:latest .

echo "📦 Deploying to Kubernetes..."
./deploy-k8s.sh

echo ""
echo "🎉 Deployment complete!"
echo "📱 Access your app at: http://localhost:30080"
echo ""
echo "📊 Check status: kubectl get all -n aws-s3-manager"
echo "📝 View logs: kubectl logs -f deployment/aws-s3-manager -n aws-s3-manager"