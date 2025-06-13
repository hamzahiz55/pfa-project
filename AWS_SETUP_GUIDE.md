# AWS S3 Manager - AWS Setup Guide

## 🚨 Current Issue: AWS Credentials Not Configured

Your application is working perfectly, but you're seeing errors because the AWS credentials are set to placeholder values.

## ✅ Quick Solution: Demo Mode

**Immediate Fix**: Go to http://localhost:30080 and **enable "Demo Mode"** checkbox in the Files section. This will use mock data and allow you to test the application without AWS.

## 🔧 Long-term Solution: Configure Real AWS Credentials

### Step 1: Create AWS Resources

1. **Create an S3 Bucket**:
   ```bash
   # Using AWS CLI (if installed)
   aws s3 mb s3://your-bucket-name-here
   
   # Or create via AWS Console:
   # https://console.aws.amazon.com/s3/
   ```

2. **Create IAM User with S3 Permissions**:
   - Go to AWS IAM Console
   - Create new user with programmatic access
   - Attach policy with these permissions:
   ```json
   {
     "Version": "2012-10-17",
     "Statement": [
       {
         "Effect": "Allow",
         "Action": [
           "s3:GetObject",
           "s3:PutObject",
           "s3:DeleteObject",
           "s3:ListBucket"
         ],
         "Resource": [
           "arn:aws:s3:::your-bucket-name-here",
           "arn:aws:s3:::your-bucket-name-here/*"
         ]
       }
     ]
   }
   ```

3. **Save Access Keys**: Copy the Access Key ID and Secret Access Key

### Step 2: Update Kubernetes Secrets

1. **Encode your credentials**:
   ```bash
   # Replace with your actual values
   echo -n "AKIAEXAMPLE123456789" | base64  # Your Access Key ID
   echo -n "wJalrXUtnFEMI/K7MDENG/bPxRfiCYEXAMPLEKEY" | base64  # Your Secret Key
   echo -n "your-bucket-name-here" | base64  # Your bucket name
   ```

2. **Update the secret file**:
   ```bash
   # Edit k8s/secret.yaml
   nano k8s/secret.yaml
   ```
   
   Replace these lines with your base64-encoded values:
   ```yaml
   data:
     AWS_ACCESS_KEY_ID: <your-base64-access-key>
     AWS_SECRET_ACCESS_KEY: <your-base64-secret-key>
     AWS_S3_BUCKET_NAME: <your-base64-bucket-name>
     NEXT_PUBLIC_S3_BUCKET_NAME: <your-base64-bucket-name>
   ```

3. **Apply the updated secrets**:
   ```bash
   kubectl apply -f k8s/secret.yaml
   ./scripts/dev-deploy.sh
   ```

### Step 3: Test the Application

1. **Go to**: http://localhost:30080
2. **Disable "Demo Mode"** (uncheck the checkbox)
3. **Click "Refresh"** to fetch files from your S3 bucket
4. **Try uploading a file** to test the complete flow

## 🔍 Verification Commands

```bash
# Check if secrets are applied
kubectl get secrets -n aws-s3-manager

# Check application logs
kubectl logs -f deployment/aws-s3-manager-app -n aws-s3-manager

# Test S3 connectivity (if AWS CLI is installed)
aws s3 ls s3://your-bucket-name-here
```

## 🚨 Troubleshooting

### Common Issues:

1. **"InvalidAccessKeyId"**: Check that Access Key ID is correct
2. **"SignatureDoesNotMatch"**: Check that Secret Access Key is correct
3. **"NoSuchBucket"**: Check that bucket name is correct and bucket exists
4. **"AccessDenied"**: Check that IAM user has correct permissions

### Debug Steps:

1. **Check Kubernetes secrets**:
   ```bash
   kubectl describe secret aws-s3-manager-secrets -n aws-s3-manager
   ```

2. **Check environment variables in pod**:
   ```bash
   kubectl exec deployment/aws-s3-manager-app -n aws-s3-manager -- printenv | grep AWS
   ```

3. **Check application logs**:
   ```bash
   kubectl logs deployment/aws-s3-manager-app -n aws-s3-manager --tail=50
   ```

## 💡 Development Tips

- **Use Demo Mode** during development to avoid AWS costs
- **Test with small files** first to verify upload functionality
- **Monitor AWS CloudWatch** for S3 access logs
- **Set up S3 bucket notifications** for real-time updates (optional)

## 📚 Additional Resources

- [AWS S3 Documentation](https://docs.aws.amazon.com/s3/)
- [AWS IAM Best Practices](https://docs.aws.amazon.com/IAM/latest/UserGuide/best-practices.html)
- [Kubernetes Secrets Documentation](https://kubernetes.io/docs/concepts/configuration/secret/)

---

**Current Status**: ✅ Application is working, just needs AWS credentials for S3 functionality.
**Quick Fix**: Enable "Demo Mode" in the application UI.
**Full Fix**: Follow this guide to configure real AWS credentials.