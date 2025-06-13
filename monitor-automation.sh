#!/bin/bash

echo "🔄 Monitoring Automatic Pipeline Execution..."
echo "=============================================="

while true; do
    echo -e "\n⏰ $(date '+%H:%M:%S')"
    
    # Check ArgoCD Status
    echo "📋 ArgoCD Status:"
    kubectl get applications -n argocd --no-headers | awk '{print "  - " $1 ": " $2 " (" $3 ")"}'
    
    # Check Jenkins Status
    echo "🏗️  Jenkins Status:"
    BUILDS=$(curl -s -u admin:admin "http://localhost:8080/job/aws-s3-manager-pipeline/api/json" | grep -o '"number":[0-9]*' | tail -1 | cut -d: -f2)
    echo "  - Latest Build: #$BUILDS"
    
    # Check if new build started
    if [ "$BUILDS" = "4" ]; then
        echo "🎉 SUCCESS: Jenkins Build #4 started automatically!"
        break
    fi
    
    sleep 30
done