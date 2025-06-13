#!/bin/bash

# Jenkins GitHub Integration Setup Script

JENKINS_URL="http://localhost:8080"
GITHUB_TOKEN="$1"
JENKINS_USER="admin"
JENKINS_PASS="admin"

# Wait for Jenkins to be ready
echo "Waiting for Jenkins to be ready..."
until curl -s ${JENKINS_URL} > /dev/null; do
    sleep 5
done

# Get Jenkins CLI
echo "Downloading Jenkins CLI..."
curl -s ${JENKINS_URL}/jnlpJars/jenkins-cli.jar -o jenkins-cli.jar

# Create credentials.xml for GitHub token
cat > github-credentials.xml << EOF
<com.cloudbees.plugins.credentials.impl.UsernamePasswordCredentialsImpl>
  <scope>GLOBAL</scope>
  <id>github-token</id>
  <description>GitHub Personal Access Token</description>
  <username>github-token</username>
  <password>${GITHUB_TOKEN}</password>
</com.cloudbees.plugins.credentials.impl.UsernamePasswordCredentialsImpl>
EOF

# Install required plugins
echo "Installing GitHub plugins..."
java -jar jenkins-cli.jar -s ${JENKINS_URL} -auth ${JENKINS_USER}:${JENKINS_PASS} install-plugin github github-branch-source github-oauth git -restart

# Wait for restart
sleep 30

# Create credentials
echo "Creating GitHub credentials..."
java -jar jenkins-cli.jar -s ${JENKINS_URL} -auth ${JENKINS_USER}:${JENKINS_PASS} create-credentials-by-xml system::system::jenkins _ < github-credentials.xml

# Clean up
rm -f jenkins-cli.jar github-credentials.xml

echo "GitHub integration configured successfully!"
echo "You can now create jobs using the credential ID: github-token"