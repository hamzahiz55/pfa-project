# Kubernetes Deployment for AWS S3 Manager

This directory contains Kubernetes manifests for deploying the AWS S3 Manager application.

## Structure

```
k8s/
├── namespace.yaml              # Namespace definition
├── rbac.yaml                 # RBAC configurations (ServiceAccounts, Roles)
├── configmap.yaml             # Non-sensitive configuration
├── secret.yaml                # Sensitive configuration (base64 encoded)
├── postgres-deployment.yaml   # PostgreSQL database deployment
├── postgres-service.yaml      # PostgreSQL service
├── app-deployment.yaml        # Main application deployment
├── app-service.yaml          # Application service
├── ingress.yaml              # Ingress rules
├── network-policies.yaml     # Network security policies
├── hpa.yaml                  # HorizontalPodAutoscaler configuration
├── storage-class.yaml        # Storage classes for persistent volumes
├── postgres-backup-cronjob.yaml  # Automated database backups
├── ingress-tls.yaml         # TLS-enabled ingress configuration
├── kustomization.yaml        # Base kustomization file
└── environments/             # Environment-specific configurations
    ├── staging/
    │   ├── kustomization.yaml
    │   └── app-service-patch.yaml  # Staging service override
    └── production/
        ├── kustomization.yaml
        └── app-service-patch.yaml  # Production service override
```

## Prerequisites

1. Kubernetes cluster (1.19+)
2. kubectl configured
3. kustomize installed
4. NGINX Ingress Controller
5. cert-manager (for TLS certificates)

## Configuration

### 1. Update Secrets

Before deploying, update the `secret.yaml` file with your base64-encoded values:

```bash
# Encode your values
echo -n "your-aws-access-key" | base64
echo -n "your-aws-secret-key" | base64
echo -n "your-s3-bucket-name" | base64
echo -n "your-sns-topic-arn" | base64
echo -n "your-sqs-queue-url" | base64
```

### 2. Update Ingress

Modify `ingress.yaml` to use your domain:
- Replace `aws-s3-manager.example.com` with your actual domain

### 3. Update Registry

In `kustomization.yaml`, update the image registry:
- Replace `your-registry.com` with your Docker registry

## Deployment

### Manual Deployment

```bash
# Deploy to staging
kubectl apply -k k8s/environments/staging/

# Deploy to production
kubectl apply -k k8s/environments/production/
```

### Using Jenkins

The Jenkinsfile automates the deployment process:
- Builds and tests the application
- Creates Docker images
- Deploys to staging (develop branch)
- Deploys to production with approval (main branch)

## Health Checks

The application includes comprehensive health probes:

### Application Health Probes
- **Startup Probe**: Allows up to 5 minutes for initial startup
- **Readiness Probe**: Checks `/api/health` every 10 seconds
- **Liveness Probe**: Checks `/api/health` every 30 seconds

### PostgreSQL Health Probes
- Uses `pg_isready` command to verify database availability
- Readiness check every 10 seconds
- Liveness check every 30 seconds

### Health Endpoint
The `/api/health` endpoint returns:
- Overall status (ok/degraded)
- Database connectivity status
- AWS configuration status
- Uptime and environment info

## Network Security

NetworkPolicies are configured to enforce pod-to-pod communication rules:

### Default Policies
1. **Default Deny All**: Blocks all traffic by default
2. **Allow DNS**: Permits DNS resolution for all pods
3. **PostgreSQL Access**: Only allows app pods to connect to database
4. **App Access**: Allows ingress controller and internal service traffic

### Checking NetworkPolicy Support
```bash
# Check if your cluster supports NetworkPolicy
./check-network-policy-support.sh
```

### Common CNI Plugins with NetworkPolicy Support
- **Calico**: Full support (recommended)
- **Cilium**: Full support with additional features
- **Weave Net**: Full support
- **Canal**: Flannel + Calico combination

### Important Notes
- Docker Desktop: NetworkPolicies are created but NOT enforced
- Minikube: Requires `--cni=calico` flag for enforcement
- Cloud providers: May require additional CNI installation

## RBAC Security

Role-Based Access Control is configured for least-privilege access:

### ServiceAccounts
- **aws-s3-manager-sa**: Application pods service account
- **postgres-sa**: PostgreSQL pods service account
- **cicd-deployer-sa**: CI/CD deployment service account (production only)

### Permissions
1. **Application Pods**:
   - Read ConfigMaps and Secrets
   - List Services and Endpoints for discovery
   - No write permissions

2. **Database Pods**:
   - Read ConfigMaps and Secrets only
   - Minimal permissions for security

3. **CI/CD Account** (Production):
   - Deploy and update applications
   - Manage ConfigMaps and Secrets
   - Update Ingress rules

### Generating CI/CD Kubeconfig
```bash
# Generate kubeconfig for Jenkins/GitHub Actions
./generate-cicd-kubeconfig.sh
```

This creates a kubeconfig file with limited permissions for automated deployments.

## Auto-Scaling

HorizontalPodAutoscaler (HPA) automatically scales pods based on metrics:

### Prerequisites
```bash
# Install metrics-server for resource metrics
./setup-metrics-server.sh
```

### HPA Configuration
- **Base**: 2-10 replicas, 70% CPU, 80% memory
- **Staging**: 1-3 replicas, 80% CPU, 85% memory  
- **Production**: 3-20 replicas, 65% CPU, 75% memory

### Scaling Behavior
- **Scale Up**: Aggressive (up to 200% in production)
- **Scale Down**: Conservative (5-10% gradual reduction)

### Monitoring HPA
```bash
# Check HPA status
kubectl get hpa -n aws-s3-manager

# Detailed HPA information
kubectl describe hpa aws-s3-manager-hpa -n aws-s3-manager

# Watch scaling in real-time
kubectl get hpa -n aws-s3-manager -w
```

### Manual Scaling Override
```bash
# Temporarily override HPA
kubectl scale deployment/aws-s3-manager -n aws-s3-manager --replicas=5

# HPA will take over again based on metrics
```

## Storage Management

Persistent storage is configured for PostgreSQL with proper StorageClasses:

### Storage Classes
- **local-storage**: For development (hostpath)
- **standard-storage**: Default class with GP2/standard disks
- **fast-ssd**: High-performance SSD for production
- **postgres-production-storage**: Production-optimized with encryption

### Storage Configuration by Environment
- **Development**: 10GB standard storage
- **Staging**: 20GB standard storage  
- **Production**: 100GB high-performance SSD with encryption

### Checking Storage
```bash
# Check storage configuration and recommendations
./check-storage.sh

# View storage classes
kubectl get storageclass

# Check persistent volumes
kubectl get pv,pvc -n aws-s3-manager
```

### Database Backups
Automated daily backups are configured for production:

```bash
# Check backup CronJob
kubectl get cronjob -n aws-s3-manager

# Manual backup
kubectl create job --from=cronjob/postgres-backup manual-backup-$(date +%s) -n aws-s3-manager

# View backup logs
kubectl logs -l app=postgres-backup -n aws-s3-manager
```

### Cloud Provider Specific
For cloud deployments, use the appropriate provisioner:
- **AWS EKS**: `ebs.csi.aws.com` with GP3 volumes
- **Google GKE**: `pd.csi.storage.gke.io` with SSD disks
- **Azure AKS**: `disk.csi.azure.com` with Premium_LRS

## TLS/SSL Certificates

Automated TLS certificate management using cert-manager:

### Installing cert-manager
```bash
# Install cert-manager with Let's Encrypt support
./setup-cert-manager.sh
```

### Certificate Issuers
- **letsencrypt-staging**: For testing (higher rate limits)
- **letsencrypt-prod**: For production domains

### TLS Configuration
1. **Update email address** in ClusterIssuers:
   ```bash
   kubectl edit clusterissuer letsencrypt-prod
   ```

2. **Configure DNS** to point to your ingress controller

3. **Use TLS-enabled ingress**:
   ```yaml
   annotations:
     cert-manager.io/cluster-issuer: "letsencrypt-prod"
   tls:
   - hosts:
     - your-domain.com
     secretName: your-domain-tls
   ```

### Checking Certificates
```bash
# Check certificate status
./check-tls-certs.sh

# View certificates
kubectl get certificates -n aws-s3-manager

# Check certificate details
kubectl describe certificate <cert-name> -n aws-s3-manager
```

### Troubleshooting TLS
```bash
# Check cert-manager logs
kubectl logs -n cert-manager deployment/cert-manager

# Check ACME challenges
kubectl get challenges -n aws-s3-manager

# Test domain accessibility
curl -I https://your-domain.com
```

### Important Notes
- Use staging issuer first to avoid rate limits
- Ensure DNS points to ingress controller IP
- Domain must be publicly accessible for Let's Encrypt validation
- Certificates auto-renew 30 days before expiry

## Monitoring

Check deployment status:
```bash
# View pods
kubectl get pods -n aws-s3-manager

# View services
kubectl get services -n aws-s3-manager

# View ingress
kubectl get ingress -n aws-s3-manager

# Check application logs
kubectl logs -n aws-s3-manager -l app=aws-s3-manager-app

# Check health
curl https://your-domain.com/api/health

# Check pod health status
kubectl describe pod -n aws-s3-manager <pod-name>
```

## Scaling

```bash
# Scale application
kubectl scale deployment aws-s3-manager-app -n aws-s3-manager --replicas=5

# Enable autoscaling
kubectl autoscale deployment aws-s3-manager-app -n aws-s3-manager --min=2 --max=10 --cpu-percent=80
```

## Troubleshooting

1. **Pods not starting**: Check logs with `kubectl logs`
2. **Database connection issues**: Verify PostgreSQL is running and secrets are correct
3. **Ingress not working**: Check NGINX Ingress Controller and DNS configuration
4. **Health checks failing**: Ensure the `/api/health` endpoint is accessible

## Security Notes

- Never commit actual secrets to Git
- Use sealed-secrets or external secret management for production
- Regularly update base images
- Enable network policies for production environments