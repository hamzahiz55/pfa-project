#!/bin/bash

# USAGE: Replace YOUR_NEW_TOKEN with the actual token from GitHub
NEW_TOKEN="YOUR_NEW_TOKEN_HERE"

echo "🔧 Updating Git Remote and Jenkins with new token..."

# Update git remote
git remote set-url origin https://tahavv:${NEW_TOKEN}@github.com/tahavv/aws-s3-manager.git

echo "✅ Git remote updated"

# Test the connection
echo "🔍 Testing Git connection..."
git ls-remote origin HEAD

if [ $? -eq 0 ]; then
    echo "✅ Git connection successful!"
    
    # Push the commits
    echo "🚀 Pushing commits to GitHub..."
    git push origin new-new-branch
    
    if [ $? -eq 0 ]; then
        echo "🎉 SUCCESS: Commits pushed to GitHub!"
        echo "📋 What happens next:"
        echo "  - ArgoCD will detect changes within 3 minutes"
        echo "  - Jenkins will detect changes within 5 minutes"
        echo "  - Both will trigger automatically!"
    else
        echo "❌ Push failed. Check token permissions."
    fi
else
    echo "❌ Git connection failed. Check token permissions."
fi