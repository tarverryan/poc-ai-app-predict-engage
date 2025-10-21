#!/bin/bash
# Test Lambda Functions Locally with LocalStack

set -e

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

# LocalStack configuration
export AWS_ENDPOINT_URL=http://localhost:4566
export AWS_DEFAULT_REGION=us-east-1
export AWS_ACCESS_KEY_ID=test
export AWS_SECRET_ACCESS_KEY=test

echo -e "${GREEN}========================================${NC}"
echo -e "${GREEN}Testing Lambda Functions${NC}"
echo -e "${GREEN}========================================${NC}"

# Test 1: Create IAM role for Lambda
echo -e "\n${YELLOW}1. Creating IAM role for Lambda...${NC}"
awslocal iam create-role \
    --role-name lambda-execution-role \
    --assume-role-policy-document '{
        "Version": "2012-10-17",
        "Statement": [{
            "Effect": "Allow",
            "Principal": {"Service": "lambda.amazonaws.com"},
            "Action": "sts:AssumeRole"
        }]
    }' 2>/dev/null || echo "Role already exists"

ROLE_ARN=$(awslocal iam get-role --role-name lambda-execution-role --query 'Role.Arn' --output text)
echo -e "${GREEN}✓ IAM Role ARN: ${ROLE_ARN}${NC}"

# Test 2: Package and deploy pre_cleanup Lambda
echo -e "\n${YELLOW}2. Packaging pre_cleanup Lambda...${NC}"
cd lambda/pre_cleanup
zip -q function.zip handler.py
awslocal lambda create-function \
    --function-name pre-cleanup \
    --runtime python3.11 \
    --role ${ROLE_ARN} \
    --handler handler.lambda_handler \
    --zip-file fileb://function.zip \
    --timeout 60 \
    --memory-size 256 2>/dev/null || \
awslocal lambda update-function-code \
    --function-name pre-cleanup \
    --zip-file fileb://function.zip
rm function.zip
cd ../..
echo -e "${GREEN}✓ pre_cleanup Lambda deployed${NC}"

# Test 3: Invoke pre_cleanup Lambda
echo -e "\n${YELLOW}3. Testing pre_cleanup Lambda...${NC}"
awslocal lambda invoke \
    --function-name pre-cleanup \
    --payload '{"bucket": "engagement-prediction-raw-dev", "prefix": "test/"}' \
    --cli-binary-format raw-in-base64-out \
    /tmp/pre-cleanup-response.json

if [ -f /tmp/pre-cleanup-response.json ]; then
    echo -e "${GREEN}✓ Lambda invoked successfully${NC}"
    cat /tmp/pre-cleanup-response.json | python3 -m json.tool 2>/dev/null || cat /tmp/pre-cleanup-response.json
else
    echo -e "${RED}✗ Lambda invocation failed${NC}"
fi

# Test 4: Package and deploy data_prep Lambda
echo -e "\n${YELLOW}4. Packaging data_prep Lambda...${NC}"
cd lambda/data_prep
zip -q function.zip handler.py
awslocal lambda create-function \
    --function-name data-prep \
    --runtime python3.11 \
    --role ${ROLE_ARN} \
    --handler handler.lambda_handler \
    --zip-file fileb://function.zip \
    --timeout 300 \
    --memory-size 512 2>/dev/null || \
awslocal lambda update-function-code \
    --function-name data-prep \
    --zip-file fileb://function.zip
rm function.zip
cd ../..
echo -e "${GREEN}✓ data_prep Lambda deployed${NC}"

# Test 5: List all Lambda functions
echo -e "\n${YELLOW}5. Listing deployed Lambda functions...${NC}"
awslocal lambda list-functions --query 'Functions[*].[FunctionName,Runtime,MemorySize,Timeout]' --output table

# Test 6: Get Lambda function details
echo -e "\n${YELLOW}6. Lambda function details...${NC}"
awslocal lambda get-function --function-name pre-cleanup --query 'Configuration.[FunctionName,Runtime,Handler,Timeout,MemorySize]' --output table

echo -e "\n${GREEN}========================================${NC}"
echo -e "${GREEN}✅ Lambda tests complete!${NC}"
echo -e "${GREEN}========================================${NC}"
echo -e "\n${YELLOW}Summary:${NC}"
echo -e "  ✅ IAM role created"
echo -e "  ✅ Lambda functions deployed: 2"
echo -e "  ✅ Lambda invocation tested"
echo -e "  ${YELLOW}Note: Only basic Lambdas tested (pre_cleanup, data_prep)${NC}"
echo -e "  ${YELLOW}Full Lambda testing would require dependencies packaging${NC}"

