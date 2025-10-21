#!/bin/bash
# Test DynamoDB with LocalStack

set -e

GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

export AWS_ENDPOINT_URL=http://localhost:4566
export AWS_DEFAULT_REGION=us-east-1
export AWS_ACCESS_KEY_ID=test
export AWS_SECRET_ACCESS_KEY=test

echo -e "${GREEN}========================================${NC}"
echo -e "${GREEN}Testing DynamoDB${NC}"
echo -e "${GREEN}========================================${NC}"

# Create predictions table
echo -e "\n${YELLOW}1. Creating predictions table...${NC}"
awslocal dynamodb create-table \
    --table-name predictions \
    --attribute-definitions AttributeName=customer_id,AttributeType=S \
    --key-schema AttributeName=customer_id,KeyType=HASH \
    --billing-mode PAY_PER_REQUEST 2>/dev/null || echo "Table may already exist"

# Create cache table
echo -e "\n${YELLOW}2. Creating prediction_cache table...${NC}"
awslocal dynamodb create-table \
    --table-name prediction_cache \
    --attribute-definitions AttributeName=cache_key,AttributeType=S \
    --key-schema AttributeName=cache_key,KeyType=HASH \
    --billing-mode PAY_PER_REQUEST \
    --time-to-live-specification Enabled=true,AttributeName=ttl 2>/dev/null || echo "Table may already exist"

# List tables
echo -e "\n${YELLOW}3. Listing DynamoDB tables...${NC}"
awslocal dynamodb list-tables

# Insert test item
echo -e "\n${YELLOW}4. Inserting test prediction...${NC}"
awslocal dynamodb put-item \
    --table-name predictions \
    --item '{
        "customer_id": {"S": "test-123"},
        "predicted_engagement_score": {"N": "0.75"},
        "predicted_churn": {"N": "0"},
        "predicted_churn_probability": {"N": "0.25"},
        "predicted_ltv_usd": {"N": "500.50"},
        "model_version": {"S": "v1.0.0"},
        "prediction_timestamp": {"S": "2025-10-21T14:30:00Z"}
    }'

echo -e "${GREEN}✓ Test item inserted${NC}"

# Query item
echo -e "\n${YELLOW}5. Querying test prediction...${NC}"
awslocal dynamodb get-item \
    --table-name predictions \
    --key '{"customer_id": {"S": "test-123"}}' \
    --output json | python3 -m json.tool

# Scan table
echo -e "\n${YELLOW}6. Scanning predictions table...${NC}"
awslocal dynamodb scan --table-name predictions --max-items 5

echo -e "\n${GREEN}========================================${NC}"
echo -e "${GREEN}✅ DynamoDB tests complete!${NC}"
echo -e "${GREEN}========================================${NC}"

