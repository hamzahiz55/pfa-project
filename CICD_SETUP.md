# CI/CD Setup for AWS S3 Manager

This document outlines the CI/CD pipeline setup for the AWS S3 Manager application.

## 🚀 Available CI/CD Options

### 1. **Local Scripts (Immediate Use)**
- **Quick Deploy**: `./scripts/dev-deploy.sh`
- **Full Pipeline**: `./scripts/build-and-deploy.sh`
- **Makefile Commands**: `make help` to see all options

### 2. **GitHub Actions (Cloud)**
- **Main Pipeline**: `.github/workflows/ci-cd.yml`
- **Kubernetes Deploy**: `.github/workflows/k8s-deploy.yml`
- Triggers on push to main/develop branches

### 3. **Jenkins (Advanced)**
- **Setup**: `./setup-jenkins.sh`
- **Access**: http://localhost:8080
- **Pipeline**: Uses `Jenkinsfile.local`

## 📋 Quick Commands

### Development Workflow
```bash
# Quick development cycle
make dev-deploy          # Build and deploy to K8s
make k8s-status          # Check deployment status
make k8s-logs            # View application logs

# Local development
make dev                 # Start local dev server
make test                # Run tests
make lint                # Run linting
```

### Full CI/CD Pipeline
```bash
# Complete pipeline (test, build, deploy)
make deploy              # Full CI/CD pipeline
./scripts/build-and-deploy.sh  # Or run directly

# Monitor deployment
make monitor             # Watch deployment status
make check-health        # Quick health check
```

### Kubernetes Management
```bash
make k8s-setup           # Initial Kubernetes setup
make k8s-status          # Check all resources
make k8s-clean           # Clean up everything
make restart             # Restart application
make scale REPLICAS=3    # Scale to 3 replicas
```

## 🔧 Pipeline Features

### ✅ What's Included
- **Automated Testing**: Runs tests (when configured)
- **Code Quality**: Linting and formatting checks
- **Docker Build**: Multi-stage optimized builds
- **Security Scanning**: Trivy vulnerability scans
- **Kubernetes Deployment**: Automated K8s deployments
- **Health Checks**: Application health verification
- **Rollback Support**: Kubernetes rollback capabilities
- **Environment Management**: Staging/Production separation

### 📊 Pipeline Stages

1. **🧪 Test & Lint**
   - Install dependencies
   - Run unit tests
   - Code quality checks

2. **🐳 Build**
   - Docker image build
   - Multi-architecture support
   - Image optimization

3. **🔒 Security**
   - Vulnerability scanning
   - Dependency checks
   - Security reports

4. **🚀 Deploy**
   - Kubernetes deployment
   - Rolling updates
   - Health verification

5. **📈 Monitor**
   - Deployment status
   - Application health
   - Performance metrics

## 🌍 Environment Setup

### Local Development
```bash
# Prerequisites
docker --version        # Docker installed
kubectl version         # Kubernetes access
make --version          # Make utility

# Setup
make k8s-setup          # Deploy to local K8s
make dev                # Start local development
```

### GitHub Actions
```bash
# Required secrets in GitHub repository:
DOCKER_USERNAME         # Docker Hub username
DOCKER_PASSWORD         # Docker Hub password

# Optional secrets:
KUBECONFIG             # Kubernetes config for deployment
AWS_ACCESS_KEY_ID      # AWS credentials
AWS_SECRET_ACCESS_KEY  # AWS credentials
```

### Jenkins Setup
```bash
# Start Jenkins
make jenkins-setup

# Access Jenkins
open http://localhost:8080

# Required plugins:
- Docker Pipeline
- Kubernetes
- Git
- Blue Ocean (optional)
```

## 🔄 Deployment Strategies

### 1. **Rolling Updates** (Default)
- Zero-downtime deployments
- Gradual replacement of old pods
- Automatic rollback on failure

### 2. **Blue-Green** (Advanced)
- Complete environment switch
- Instant rollback capability
- Requires additional setup

### 3. **Canary** (Pro)
- Progressive traffic shifting
- Risk mitigation
- A/B testing support

## 📱 Monitoring & Alerts

### Health Checks
```bash
# Application health
curl http://localhost:30080/api/debug-env

# Kubernetes health
kubectl get pods -n aws-s3-manager

# Resource usage
kubectl top pods -n aws-s3-manager
```

### Logs & Debugging
```bash
# Application logs
make k8s-logs

# Pod events
kubectl describe pods -n aws-s3-manager

# Service status
kubectl get svc -n aws-s3-manager
```

## 🔧 Troubleshooting

### Common Issues

1. **Image Pull Errors**
   ```bash
   # Check image exists
   docker images | grep aws-s3-manager
   
   # Rebuild if needed
   make build
   ```

2. **Pod Not Ready**
   ```bash
   # Check pod status
   kubectl describe pod <pod-name> -n aws-s3-manager
   
   # Check logs
   kubectl logs <pod-name> -n aws-s3-manager
   ```

3. **Service Not Accessible**
   ```bash
   # Check service
   kubectl get svc -n aws-s3-manager
   
   # Port forward if needed
   kubectl port-forward svc/aws-s3-manager-service 8080:80 -n aws-s3-manager
   ```

### Recovery Commands
```bash
# Restart deployment
make restart

# Clean and redeploy
make k8s-clean
make k8s-setup

# Scale down and up
make scale REPLICAS=0
make scale REPLICAS=2
```

## 📚 Additional Resources

- [Kubernetes Documentation](https://kubernetes.io/docs/)
- [Docker Documentation](https://docs.docker.com/)
- [GitHub Actions Documentation](https://docs.github.com/en/actions)
- [Jenkins Documentation](https://jenkins.io/doc/)

---

**Need Help?** Run `make help` for quick commands or check the troubleshooting section above.