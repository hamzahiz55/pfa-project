#!/bin/bash

echo "🔧 Quick Jenkins Fix Script"
echo "=========================="

# Create the exact credential Jenkins needs
cat > /tmp/github-credential.xml << 'EOF'
<org.jenkinsci.plugins.plaincredentials.impl.StringCredentialsImpl>
  <scope>GLOBAL</scope>
  <id>github-token-new</id>
  <description>GitHub Token for New Repository</description>
  <secret>YOUR_GITHUB_TOKEN_HERE</secret>
</org.jenkinsci.plugins.plaincredentials.impl.StringCredentialsImpl>
EOF

# Try to create credential via Jenkins CLI
docker exec jenkins sh -c '
# Install jenkins-cli if not present
if [ ! -f /tmp/jenkins-cli.jar ]; then
    curl -s http://localhost:8080/jnlpJars/jenkins-cli.jar -o /tmp/jenkins-cli.jar
fi

# Create credential
echo "Creating GitHub credential..."
java -jar /tmp/jenkins-cli.jar -s http://localhost:8080 -auth admin:admin create-credentials-by-xml system::system::jenkins _ < /tmp/github-credential.xml
'

echo "✅ Credential created. Now testing repository access..."

# Test if we can access the repository
if curl -H "Authorization: token YOUR_GITHUB_TOKEN_HERE" -s https://api.github.com/repos/hamzahizi55/aws-s3-manager-new > /dev/null; then
    echo "✅ Repository is accessible"
else
    echo "❌ Repository access failed - check if repo exists and is public"
fi

echo ""
echo "📋 Manual Steps Still Needed:"
echo "1. Go to: http://localhost:8080/job/aws-s3-manager-pipeline/configure"
echo "2. Change Repository URL to: https://github.com/hamzahizi55/aws-s3-manager-new.git"
echo "3. Select Credentials: github-token-new"
echo "4. Change Branch to: */master"
echo "5. Save and Build Now"