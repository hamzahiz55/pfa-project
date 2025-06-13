#!/bin/bash

# Colors for output
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

echo -e "${BLUE}===============================================${NC}"
echo -e "${BLUE}    Docker Services Status                    ${NC}"
echo -e "${BLUE}===============================================${NC}"

# Check if Docker is running
if ! docker info &> /dev/null 2>&1; then
    echo -e "${RED}✗ Docker is not running${NC}"
    exit 1
fi

echo -e "${GREEN}✓ Docker is running${NC}"
echo ""

# Check development services
echo -e "${YELLOW}Development Services:${NC}"
if docker-compose -f docker-compose.dev.yml ps | grep -q "Up"; then
    echo -e "${GREEN}✓ Development services are running${NC}"
    docker-compose -f docker-compose.dev.yml ps
    echo ""
    echo -e "${BLUE}Application URL: http://localhost:3000${NC}"
    echo -e "${BLUE}Database URL: localhost:5555${NC}"
else
    echo -e "${YELLOW}⚠ Development services are not running${NC}"
    echo "  Start with: ./run-dev.sh"
fi

echo ""

# Check production services
echo -e "${YELLOW}Production Services:${NC}"
if docker-compose -f docker-compose.yml ps | grep -q "Up"; then
    echo -e "${GREEN}✓ Production services are running${NC}"
    docker-compose -f docker-compose.yml ps
else
    echo -e "${YELLOW}⚠ Production services are not running${NC}"
    echo "  Start with: ./run-prod.sh"
fi

echo ""

# Show resource usage
echo -e "${YELLOW}Resource Usage:${NC}"
docker stats --no-stream --format "table {{.Container}}\t{{.CPUPerc}}\t{{.MemUsage}}\t{{.NetIO}}" | head -n 10

echo ""

# Show logs option
echo -e "${YELLOW}View logs:${NC}"
echo "  Development: docker-compose -f docker-compose.dev.yml logs -f"
echo "  Production:  docker-compose logs -f"

echo ""

# Health check
echo -e "${YELLOW}Quick Health Check:${NC}"
if curl -s http://localhost:3000/api/health > /dev/null 2>&1; then
    echo -e "${GREEN}✓ Application health endpoint is responding${NC}"
    
    # Show health details
    HEALTH_RESPONSE=$(curl -s http://localhost:3000/api/health)
    echo "Health Status: $HEALTH_RESPONSE"
else
    echo -e "${YELLOW}⚠ Application health endpoint not responding${NC}"
    echo "  Make sure the application is running on port 3000"
fi