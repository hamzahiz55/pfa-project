#!/bin/bash

# Colors for output
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

echo -e "${BLUE}===============================================${NC}"
echo -e "${BLUE}    User Photo Upload Debug                   ${NC}"
echo -e "${BLUE}===============================================${NC}"

# Check if application is running
echo -e "\n${YELLOW}Checking application status...${NC}"
if curl -s http://localhost:3001/api/health > /dev/null 2>&1; then
    echo -e "${GREEN}✓ Application is running${NC}"
else
    echo -e "${RED}✗ Application is not responding${NC}"
    echo "Start with: ./run-dev.sh"
    exit 1
fi

# Check environment variables
echo -e "\n${YELLOW}Checking environment configuration...${NC}"
if [ -f ".env.local" ]; then
    echo -e "${GREEN}✓ .env.local file exists${NC}"
    
    # Check AWS configuration
    if grep -q "your-access-key" .env.local; then
        echo -e "${YELLOW}⚠ AWS credentials are placeholder values${NC}"
        echo "  Update AWS_ACCESS_KEY_ID and AWS_SECRET_ACCESS_KEY in .env.local"
    else
        echo -e "${GREEN}✓ AWS credentials appear to be configured${NC}"
    fi
    
    if grep -q "your-bucket-name" .env.local; then
        echo -e "${YELLOW}⚠ S3 bucket name is placeholder value${NC}"
        echo "  Update NEXT_PUBLIC_S3_BUCKET_NAME in .env.local"
    else
        echo -e "${GREEN}✓ S3 bucket name appears to be configured${NC}"
    fi
else
    echo -e "${RED}✗ .env.local file not found${NC}"
    echo "Create it by copying: cp .env.development .env.local"
fi

# Check placeholder image
echo -e "\n${YELLOW}Checking placeholder image...${NC}"
if [ -f "public/placeholder-avatar.svg" ]; then
    echo -e "${GREEN}✓ Placeholder avatar exists${NC}"
else
    echo -e "${RED}✗ Placeholder avatar missing${NC}"
    echo "Creating placeholder avatar..."
    cat > public/placeholder-avatar.svg << 'EOF'
<svg width="100" height="100" viewBox="0 0 100 100" fill="none" xmlns="http://www.w3.org/2000/svg">
  <circle cx="50" cy="50" r="50" fill="#E5E7EB"/>
  <circle cx="50" cy="35" r="15" fill="#9CA3AF"/>
  <path d="M20 80 C20 65, 35 55, 50 55 C65 55, 80 65, 80 80" fill="#9CA3AF"/>
</svg>
EOF
    echo -e "${GREEN}✓ Placeholder avatar created${NC}"
fi

# Test placeholder image accessibility
echo -e "\n${YELLOW}Testing placeholder image accessibility...${NC}"
if curl -s http://localhost:3001/placeholder-avatar.svg > /dev/null 2>&1; then
    echo -e "${GREEN}✓ Placeholder image accessible${NC}"
else
    echo -e "${RED}✗ Placeholder image not accessible${NC}"
fi

# Check database connection
echo -e "\n${YELLOW}Checking database connection...${NC}"
if docker-compose -f docker-compose.dev.yml exec -T db psql -U postgres -d aws_s3_manager -c "SELECT version();" > /dev/null 2>&1; then
    echo -e "${GREEN}✓ Database is accessible${NC}"
    
    # Check users table
    echo -e "${YELLOW}Checking users table...${NC}"
    USER_COUNT=$(docker-compose -f docker-compose.dev.yml exec -T db psql -U postgres -d aws_s3_manager -t -c "SELECT COUNT(*) FROM users;" 2>/dev/null | tr -d ' \n')
    if [ "$USER_COUNT" ]; then
        echo -e "${GREEN}✓ Users table exists with $USER_COUNT users${NC}"
        
        # Show sample user data
        echo -e "${YELLOW}Sample user data:${NC}"
        docker-compose -f docker-compose.dev.yml exec -T db psql -U postgres -d aws_s3_manager -c "SELECT id, name, email, photo_url FROM users LIMIT 3;" 2>/dev/null || echo "No users found"
    else
        echo -e "${YELLOW}⚠ Users table might not exist or be empty${NC}"
    fi
else
    echo -e "${RED}✗ Cannot connect to database${NC}"
fi

# Test API endpoints
echo -e "\n${YELLOW}Testing API endpoints...${NC}"

# Test users GET endpoint
if curl -s http://localhost:3001/api/users | grep -q "users"; then
    echo -e "${GREEN}✓ Users API GET endpoint working${NC}"
else
    echo -e "${RED}✗ Users API GET endpoint not working${NC}"
fi

# Show recent logs
echo -e "\n${YELLOW}Recent application logs:${NC}"
docker-compose -f docker-compose.dev.yml logs app --tail=5

echo -e "\n${BLUE}=== Troubleshooting Steps ===${NC}"
echo -e "${YELLOW}If photos still don't appear:${NC}"
echo ""
echo "1. ${BLUE}Check browser developer tools console for errors${NC}"
echo ""
echo "2. ${BLUE}Test user creation:${NC}"
echo "   - Go to http://localhost:3001/user-management"
echo "   - Add a user with name, email, and photo"
echo "   - Check browser network tab for API calls"
echo ""
echo "3. ${BLUE}Configure AWS credentials (optional):${NC}"
echo "   - Edit .env.local"
echo "   - Replace 'your-access-key' with real AWS access key"
echo "   - Replace 'your-secret-key' with real AWS secret key"
echo "   - Replace 'your-bucket-name' with real S3 bucket name"
echo "   - Restart: docker-compose -f docker-compose.dev.yml restart app"
echo ""
echo "4. ${BLUE}If AWS is not configured:${NC}"
echo "   - Photos will use placeholder avatar"
echo "   - This is normal for development without AWS setup"
echo ""
echo "5. ${BLUE}View detailed logs:${NC}"
echo "   docker-compose -f docker-compose.dev.yml logs -f app"