#!/bin/bash

# USAGE: ./switch-to-personal-repo.sh YOUR_USERNAME YOUR_REPO_NAME YOUR_TOKEN
# Example: ./switch-to-personal-repo.sh myusername aws-s3-manager-pipeline ghp_1234567890

USERNAME="$1"
REPO_NAME="$2"
TOKEN="$3"

if [ -z "$USERNAME" ] || [ -z "$REPO_NAME" ] || [ -z "$TOKEN" ]; then
    echo "❌ Usage: $0 USERNAME REPO_NAME TOKEN"
    echo "Example: $0 myusername aws-s3-manager-pipeline ghp_1234567890"
    exit 1
fi

REPO_URL="https://github.com/${USERNAME}/${REPO_NAME}.git"
AUTHENTICATED_URL="https://${USERNAME}:${TOKEN}@github.com/${USERNAME}/${REPO_NAME}.git"

echo "🔧 Switching to personal repository..."
echo "📍 New Repository: ${REPO_URL}"

# 1. Update git remote
echo "📝 Updating git remote..."
git remote set-url origin "${AUTHENTICATED_URL}"

# 2. Test connection
echo "🔍 Testing connection..."
if git ls-remote origin HEAD &>/dev/null; then
    echo "✅ Git connection successful!"
else
    echo "❌ Git connection failed. Please check your credentials."
    exit 1
fi

# 3. Push all branches
echo "🚀 Pushing code to your repository..."
git push -u origin new-new-branch

if [ $? -eq 0 ]; then
    echo "✅ Code pushed successfully!"
    
    # 4. Update Jenkins configuration
    echo "🏗️  Updating Jenkins configuration..."
    echo "Manual step: Update Jenkins pipeline repository URL to: ${REPO_URL}"
    
    # 5. Update ArgoCD configuration
    echo "🔄 Updating ArgoCD configuration..."
    kubectl patch application aws-s3-manager-app -n argocd --type merge -p "{\"spec\":{\"source\":{\"repoURL\":\"${REPO_URL}\"}}}"
    
    echo "🎉 SUCCESS! Your personal repository is set up!"
    echo ""
    echo "📋 Next Steps:"
    echo "1. Update Jenkins pipeline URL manually: ${REPO_URL}"
    echo "2. Both ArgoCD and Jenkins will monitor your repository"
    echo "3. Make any change and push to see full automation!"
    echo ""
    echo "🔗 Access Points:"
    echo "- ArgoCD: http://localhost:32385"
    echo "- Jenkins: http://localhost:8080"
    echo "- Your Repository: ${REPO_URL}"
    
else
    echo "❌ Push failed. Please check permissions."
fi