#!/bin/bash

# Colors for output
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

echo -e "${YELLOW}Jenkins Setup Script${NC}"
echo "===================="

# Check if Docker is running
if ! docker info &> /dev/null; then
    echo -e "${RED}Docker is not running. Please start Docker first.${NC}"
    exit 1
fi

echo -e "${GREEN}✓ Docker is running${NC}"

# Start Jenkins
echo -e "\n${YELLOW}Starting Jenkins...${NC}"
docker compose -f jenkins-docker-compose.yml up -d

# Wait for Jenkins to start
echo -e "\n${YELLOW}Waiting for Jenkins to start...${NC}"
sleep 30

# Get initial admin password
echo -e "\n${GREEN}Jenkins is starting up!${NC}"
echo -e "${YELLOW}Access Jenkins at: http://localhost:8080${NC}"

# Try to get the initial admin password
if docker exec jenkins cat /var/jenkins_home/secrets/initialAdminPassword 2>/dev/null; then
    echo -e "\n${YELLOW}Initial Admin Password:${NC}"
    docker exec jenkins cat /var/jenkins_home/secrets/initialAdminPassword
else
    echo -e "\n${YELLOW}Note: Initial setup may be required. Check http://localhost:8080${NC}"
fi

echo -e "\n${YELLOW}Jenkins Setup Instructions:${NC}"
echo "1. Open http://localhost:8080 in your browser"
echo "2. Install suggested plugins"
echo "3. Create an admin user"
echo "4. Configure Jenkins URL (keep default)"
echo ""
echo -e "${YELLOW}To create a pipeline job:${NC}"
echo "1. Click 'New Item'"
echo "2. Enter name: 'aws-s3-manager-pipeline'"
echo "3. Select 'Pipeline' and click OK"
echo "4. In Pipeline section:"
echo "   - Definition: Pipeline script from SCM"
echo "   - SCM: Git"
echo "   - Repository URL: file:///mnt/c/aws-s3-manager-main (or your git repo)"
echo "   - Script Path: Jenkinsfile.local"
echo "5. Save and Build Now"
echo ""
echo -e "${YELLOW}Useful commands:${NC}"
echo "- View logs: docker logs jenkins"
echo "- Stop Jenkins: docker compose -f jenkins-docker-compose.yml down"
echo "- Remove all: docker compose -f jenkins-docker-compose.yml down -v"