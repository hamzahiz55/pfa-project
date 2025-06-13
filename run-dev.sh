#!/bin/bash

# Colors for output
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

echo -e "${BLUE}===============================================${NC}"
echo -e "${BLUE}    AWS S3 Manager - Development Mode         ${NC}"
echo -e "${BLUE}===============================================${NC}"

# Check if Docker is running
if ! docker info &> /dev/null 2>&1; then
    echo -e "${RED}✗ Docker is not running. Please start Docker first.${NC}"
    exit 1
fi

# Check if .env.local exists
if [ ! -f ".env.local" ]; then
    echo -e "${YELLOW}Creating .env.local from .env.development...${NC}"
    cp .env.development .env.local
fi

echo -e "${YELLOW}Starting development services...${NC}"

# Start services
docker-compose -f docker-compose.dev.yml up --build -d

if [ $? -eq 0 ]; then
    echo -e "${GREEN}✓ Services started successfully!${NC}"
    echo ""
    echo -e "${BLUE}Services running:${NC}"
    docker-compose -f docker-compose.dev.yml ps
    echo ""
    echo -e "${GREEN}🚀 Application is available at: http://localhost:3000${NC}"
    echo -e "${GREEN}📊 Database is available at: localhost:5555${NC}"
    echo ""
    echo -e "${YELLOW}Useful commands:${NC}"
    echo "  View logs:     docker-compose -f docker-compose.dev.yml logs -f"
    echo "  Stop services: docker-compose -f docker-compose.dev.yml down"
    echo "  Restart:       docker-compose -f docker-compose.dev.yml restart"
    echo ""
    echo -e "${BLUE}Press Ctrl+C to view logs or run './stop-dev.sh' to stop services${NC}"
    
    # Ask if user wants to see logs
    read -p "Do you want to view live logs? (y/N): " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        docker-compose -f docker-compose.dev.yml logs -f
    fi
else
    echo -e "${RED}✗ Failed to start services${NC}"
    exit 1
fi