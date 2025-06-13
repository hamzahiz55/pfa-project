#!/bin/bash

# Colors for output
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

echo -e "${BLUE}===============================================${NC}"
echo -e "${BLUE}    TLS Certificate Status Check             ${NC}"
echo -e "${BLUE}===============================================${NC}"

# Check if kubectl is available
if ! command -v kubectl &> /dev/null; then
    echo -e "${RED}✗ kubectl is not installed.${NC}"
    exit 1
fi

# Check if cert-manager is installed
echo -e "\n${YELLOW}Checking cert-manager status...${NC}"
if kubectl get namespace cert-manager &> /dev/null 2>&1; then
    if kubectl get pods -n cert-manager | grep -q "Running"; then
        echo -e "${GREEN}✓ cert-manager is running${NC}"
    else
        echo -e "${RED}✗ cert-manager is not running properly${NC}"
        echo "Run: ./setup-cert-manager.sh"
        exit 1
    fi
else
    echo -e "${RED}✗ cert-manager is not installed${NC}"
    echo "Run: ./setup-cert-manager.sh"
    exit 1
fi

# Check ClusterIssuers
echo -e "\n${YELLOW}Checking ClusterIssuers...${NC}"
kubectl get clusterissuer

# Check certificates in aws-s3-manager namespace
echo -e "\n${YELLOW}Checking certificates in aws-s3-manager namespace...${NC}"
if kubectl get namespace aws-s3-manager &> /dev/null 2>&1; then
    CERTS=$(kubectl get certificates -n aws-s3-manager --no-headers 2>/dev/null | wc -l)
    if [ "$CERTS" -gt 0 ]; then
        echo -e "${GREEN}Found $CERTS certificate(s):${NC}"
        kubectl get certificates -n aws-s3-manager
        
        echo -e "\n${YELLOW}Certificate details:${NC}"
        kubectl get certificates -n aws-s3-manager -o wide
        
        # Check each certificate status
        for cert in $(kubectl get certificates -n aws-s3-manager -o name); do
            cert_name=$(echo $cert | cut -d'/' -f2)
            echo -e "\n${BLUE}Certificate: $cert_name${NC}"
            
            # Get status
            ready=$(kubectl get certificate $cert_name -n aws-s3-manager -o jsonpath='{.status.conditions[?(@.type=="Ready")].status}')
            if [ "$ready" == "True" ]; then
                echo -e "${GREEN}✓ Certificate is ready${NC}"
                
                # Show expiry
                not_after=$(kubectl get certificate $cert_name -n aws-s3-manager -o jsonpath='{.status.notAfter}')
                if [ -n "$not_after" ]; then
                    echo -e "  Expires: $not_after"
                fi
            else
                echo -e "${RED}✗ Certificate is not ready${NC}"
                
                # Show reason
                reason=$(kubectl get certificate $cert_name -n aws-s3-manager -o jsonpath='{.status.conditions[?(@.type=="Ready")].reason}')
                message=$(kubectl get certificate $cert_name -n aws-s3-manager -o jsonpath='{.status.conditions[?(@.type=="Ready")].message}')
                echo -e "  Reason: $reason"
                echo -e "  Message: $message"
            fi
        done
    else
        echo -e "${YELLOW}No certificates found in aws-s3-manager namespace${NC}"
    fi
else
    echo -e "${YELLOW}aws-s3-manager namespace not found${NC}"
fi

# Check certificate requests
echo -e "\n${YELLOW}Checking CertificateRequests...${NC}"
kubectl get certificaterequests -A | grep -E "(NAMESPACE|aws-s3-manager)" || echo "No certificate requests found"

# Check certificate orders (ACME)
echo -e "\n${YELLOW}Checking ACME Orders...${NC}"
kubectl get orders -A | grep -E "(NAMESPACE|aws-s3-manager)" || echo "No ACME orders found"

# Check challenges
echo -e "\n${YELLOW}Checking ACME Challenges...${NC}"
kubectl get challenges -A | grep -E "(NAMESPACE|aws-s3-manager)" || echo "No ACME challenges found"

# Check TLS secrets
echo -e "\n${YELLOW}Checking TLS secrets...${NC}"
if kubectl get namespace aws-s3-manager &> /dev/null 2>&1; then
    TLS_SECRETS=$(kubectl get secrets -n aws-s3-manager --field-selector type=kubernetes.io/tls --no-headers 2>/dev/null | wc -l)
    if [ "$TLS_SECRETS" -gt 0 ]; then
        echo -e "${GREEN}Found $TLS_SECRETS TLS secret(s):${NC}"
        kubectl get secrets -n aws-s3-manager --field-selector type=kubernetes.io/tls
    else
        echo -e "${YELLOW}No TLS secrets found${NC}"
    fi
fi

# Function to test TLS endpoint
test_tls_endpoint() {
    local hostname=$1
    echo -e "\n${YELLOW}Testing TLS endpoint: $hostname${NC}"
    
    if command -v openssl &> /dev/null; then
        # Test TLS connection
        if timeout 10 openssl s_client -connect $hostname:443 -servername $hostname < /dev/null &> /dev/null; then
            echo -e "${GREEN}✓ TLS connection successful${NC}"
            
            # Get certificate info
            cert_info=$(timeout 10 openssl s_client -connect $hostname:443 -servername $hostname < /dev/null 2>/dev/null | openssl x509 -noout -dates 2>/dev/null)
            if [ $? -eq 0 ]; then
                echo "$cert_info"
            fi
        else
            echo -e "${RED}✗ TLS connection failed${NC}"
        fi
    else
        echo -e "${YELLOW}openssl not available for TLS testing${NC}"
    fi
}

# Ask if user wants to test specific domains
read -p "Do you want to test TLS for specific domains? (y/N): " -n 1 -r
echo
if [[ $REPLY =~ ^[Yy]$ ]]; then
    read -p "Enter domain name (e.g., aws-s3-manager.example.com): " domain
    if [ -n "$domain" ]; then
        test_tls_endpoint "$domain"
    fi
fi

echo -e "\n${BLUE}Troubleshooting Tips:${NC}"
echo "1. Check cert-manager logs:"
echo "   kubectl logs -n cert-manager deployment/cert-manager"
echo ""
echo "2. Check specific certificate:"
echo "   kubectl describe certificate <cert-name> -n aws-s3-manager"
echo ""
echo "3. Check ACME challenge (if using Let's Encrypt):"
echo "   kubectl describe challenge <challenge-name> -n aws-s3-manager"
echo ""
echo "4. Common issues:"
echo "   - DNS not pointing to ingress controller"
echo "   - Ingress controller not accessible from internet"
echo "   - Rate limits (use staging issuer for testing)"
echo "   - Wrong email in ClusterIssuer"