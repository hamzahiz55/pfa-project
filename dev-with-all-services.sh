#!/bin/bash

# Colors for output
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

echo -e "${BLUE}===============================================${NC}"
echo -e "${BLUE}    Development with All Services            ${NC}"
echo -e "${BLUE}===============================================${NC}"

# Start all services
./start-all-services.sh

if [ $? -eq 0 ]; then
    echo -e "\n${GREEN}All services started successfully!${NC}"
    echo -e "${YELLOW}Starting Next.js development server...${NC}"
    
    # Start the development server
    npm run dev:only
else
    echo -e "${RED}Failed to start services. Please check the logs above.${NC}"
    exit 1
fi