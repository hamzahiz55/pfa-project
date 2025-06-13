#!/bin/bash

# Colors for output
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

echo -e "${BLUE}===============================================${NC}"
echo -e "${BLUE}    AWS S3 Manager - Production Mode          ${NC}"
echo -e "${BLUE}===============================================${NC}"

# Check if Docker is running
if ! docker info &> /dev/null 2>&1; then
    echo -e "${RED}✗ Docker is not running. Please start Docker first.${NC}"
    exit 1
fi

# Check if .env.production exists
if [ ! -f ".env.production" ]; then
    echo -e "${RED}✗ .env.production file not found!${NC}"
    echo -e "${YELLOW}Please create .env.production with your production configuration.${NC}"
    exit 1
fi

echo -e "${YELLOW}Starting production services...${NC}"

# Start services
docker-compose -f docker-compose.yml up --build -d

if [ $? -eq 0 ]; then
    echo -e "${GREEN}✓ Production services started successfully!${NC}"
    echo ""
    echo -e "${BLUE}Services running:${NC}"
    docker-compose -f docker-compose.yml ps
    echo ""
    echo -e "${GREEN}🚀 Application is running in production mode${NC}"
    echo -e "${GREEN}📊 Database is available at: localhost:5555${NC}"
    echo ""
    echo -e "${YELLOW}Production commands:${NC}"
    echo "  View logs:     docker-compose logs -f"
    echo "  Stop services: docker-compose down"
    echo "  Restart:       docker-compose restart"
    echo ""
    echo -e "${RED}⚠️  Production Environment Notes:${NC}"
    echo "  - Make sure all environment variables are properly configured"
    echo "  - Ensure AWS credentials are valid"
    echo "  - Database will persist data between restarts"
    echo "  - Use a reverse proxy (nginx) for HTTPS in production"
else
    echo -e "${RED}✗ Failed to start production services${NC}"
    exit 1
fi