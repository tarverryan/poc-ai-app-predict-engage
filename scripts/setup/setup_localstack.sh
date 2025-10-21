#!/bin/bash
set -e

echo "🚀 Setting up LocalStack environment..."

# Colors
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

# Check Docker
if ! command -v docker &> /dev/null; then
    echo -e "${RED}❌ Docker not found. Please install Docker first.${NC}"
    exit 1
fi

echo -e "${GREEN}✓ Docker found${NC}"

# Install LocalStack CLI
echo -e "${YELLOW}Installing LocalStack CLI...${NC}"
pip3 install --break-system-packages localstack localstack-ext || pip3 install localstack localstack-ext

# Install tflocal wrapper
echo -e "${YELLOW}Installing terraform-local (tflocal)...${NC}"
pip3 install --break-system-packages terraform-local || pip3 install terraform-local

# Install awslocal wrapper
echo -e "${YELLOW}Installing awscli-local (awslocal)...${NC}"
pip3 install --break-system-packages awscli-local || pip3 install awscli-local

echo -e "${GREEN}✓ LocalStack tools installed${NC}"

# Create LocalStack config
cat > .localstack/config.yml <<EOF
# LocalStack Configuration
version: "1.0"

services:
  - s3
  - lambda
  - dynamodb
  - ecs
  - ecr
  - stepfunctions
  - athena
  - glue
  - apigateway
  - cloudwatch
  - logs
  - iam
  - ec2
  - secretsmanager

# Resource limits
resource_limits:
  max_containers: 10
  max_memory_mb: 4096
EOF

echo -e "${GREEN}✓ LocalStack configuration created${NC}"

# Start LocalStack
echo -e "${YELLOW}Starting LocalStack...${NC}"
localstack start -d

# Wait for LocalStack to be ready
echo -e "${YELLOW}Waiting for LocalStack to be ready...${NC}"
sleep 10

# Health check
echo -e "${YELLOW}Checking LocalStack health...${NC}"
curl -s http://localhost:4566/_localstack/health | jq . || echo "LocalStack started (jq not available for pretty output)"

echo -e "${GREEN}✅ LocalStack is ready!${NC}"
echo ""
echo "LocalStack endpoints:"
echo "  - Main: http://localhost:4566"
echo "  - Health: http://localhost:4566/_localstack/health"
echo ""
echo "To stop: localstack stop"
echo "To view logs: localstack logs"

