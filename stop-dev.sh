#!/bin/bash

# Colors for output
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

echo -e "${BLUE}===============================================${NC}"
echo -e "${BLUE}    Stopping Development Services             ${NC}"
echo -e "${BLUE}===============================================${NC}"

echo -e "${YELLOW}Stopping development services...${NC}"

# Stop services
docker-compose -f docker-compose.dev.yml down

if [ $? -eq 0 ]; then
    echo -e "${GREEN}✓ Services stopped successfully!${NC}"
else
    echo -e "${RED}✗ Error stopping services${NC}"
    exit 1
fi

# Ask if user wants to remove volumes
read -p "Do you want to remove database volumes? (This will delete all data) (y/N): " -n 1 -r
echo
if [[ $REPLY =~ ^[Yy]$ ]]; then
    echo -e "${YELLOW}Removing volumes...${NC}"
    docker-compose -f docker-compose.dev.yml down -v
    echo -e "${GREEN}✓ Volumes removed${NC}"
fi

echo -e "${BLUE}Development environment stopped.${NC}"