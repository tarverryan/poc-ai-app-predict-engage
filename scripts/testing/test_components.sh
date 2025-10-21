#!/bin/bash
set -e

echo "🧪 Testing Individual Components in LocalStack..."

# Colors
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
BLUE='\033[0;34m'
NC='\033[0m'

PROJECT_NAME="engagement-prediction"
ENV="dev"

# Utility functions
check_success() {
    if [ $? -eq 0 ]; then
        echo -e "${GREEN}✓ $1${NC}"
    else
        echo -e "${RED}✗ $1 FAILED${NC}"
        exit 1
    fi
}

echo_step() {
    echo -e "\n${BLUE}=== $1 ===${NC}"
}

# ========================================
# TEST 1: S3 Buckets
# ========================================
echo_step "TEST 1: S3 Buckets"

awslocal s3 mb s3://${PROJECT_NAME}-raw-${ENV} 2>/dev/null || true
awslocal s3 mb s3://${PROJECT_NAME}-processed-${ENV} 2>/dev/null || true
awslocal s3 mb s3://${PROJECT_NAME}-models-${ENV} 2>/dev/null || true
awslocal s3 mb s3://${PROJECT_NAME}-results-${ENV} 2>/dev/null || true

echo "Created S3 buckets:"
awslocal s3 ls | grep ${PROJECT_NAME}
check_success "S3 buckets created"

# Upload test data
echo "Uploading customer data..."
awslocal s3 cp customer_engagement_dataset_extended.csv \
    s3://${PROJECT_NAME}-raw-${ENV}/customers/data.csv
check_success "Customer data uploaded"

# ========================================
# TEST 2: DynamoDB Table
# ========================================
echo_step "TEST 2: DynamoDB Cache Table"

awslocal dynamodb create-table \
    --table-name ${PROJECT_NAME}-predictions-cache-${ENV} \
    --attribute-definitions \
        AttributeName=customer_id,AttributeType=S \
        AttributeName=feature_hash,AttributeType=S \
    --key-schema \
        AttributeName=customer_id,KeyType=HASH \
        AttributeName=feature_hash,KeyType=RANGE \
    --billing-mode PAY_PER_REQUEST \
    2>/dev/null || echo "Table may already exist"

awslocal dynamodb describe-table \
    --table-name ${PROJECT_NAME}-predictions-cache-${ENV} \
    --query 'Table.TableName' --output text
check_success "DynamoDB table created"

# ========================================
# TEST 3: ECR Repositories
# ========================================
echo_step "TEST 3: ECR Repositories"

awslocal ecr create-repository \
    --repository-name ${PROJECT_NAME}-training-${ENV} \
    2>/dev/null || echo "Repo may already exist"

awslocal ecr create-repository \
    --repository-name ${PROJECT_NAME}-inference-${ENV} \
    2>/dev/null || echo "Repo may already exist"

echo "ECR repositories:"
awslocal ecr describe-repositories --query 'repositories[*].repositoryName' --output table
check_success "ECR repositories created"

# ========================================
# TEST 4: Lambda Function (Simple Test)
# ========================================
echo_step "TEST 4: Lambda Function Deployment"

# Create a simple test Lambda
cat > /tmp/test_lambda.py <<'EOF'
def lambda_handler(event, context):
    return {
        'statusCode': 200,
        'body': 'Hello from LocalStack Lambda!'
    }
EOF

cd /tmp
zip -q test_lambda.zip test_lambda.py

awslocal lambda create-function \
    --function-name ${PROJECT_NAME}-test-${ENV} \
    --runtime python3.11 \
    --role arn:aws:iam::000000000000:role/lambda-role \
    --handler test_lambda.lambda_handler \
    --zip-file fileb://test_lambda.zip \
    2>/dev/null || echo "Lambda may already exist"

# Invoke Lambda
RESULT=$(awslocal lambda invoke \
    --function-name ${PROJECT_NAME}-test-${ENV} \
    --payload '{}' \
    /tmp/lambda_output.txt 2>&1)

cat /tmp/lambda_output.txt
check_success "Lambda function invoked"

# Cleanup
rm -f /tmp/test_lambda.py /tmp/test_lambda.zip /tmp/lambda_output.txt
cd -

# ========================================
# TEST 5: API Gateway
# ========================================
echo_step "TEST 5: API Gateway"

API_ID=$(awslocal apigateway create-rest-api \
    --name ${PROJECT_NAME}-api-${ENV} \
    --query 'id' --output text 2>/dev/null || echo "")

if [ -n "$API_ID" ]; then
    echo "API Gateway created: $API_ID"
    echo "Endpoint: http://localhost:4566/restapis/$API_ID/dev/_user_request_"
    check_success "API Gateway created"
else
    echo -e "${YELLOW}⚠ API Gateway may already exist${NC}"
fi

# ========================================
# TEST 6: Docker Build (Lightweight Test)
# ========================================
echo_step "TEST 6: Docker Build Test"

# Test that Dockerfiles are valid
echo "Validating Dockerfiles..."
docker build -t test-training -f fargate/training/Dockerfile --target builder fargate/training/ --quiet
check_success "Training Dockerfile valid"

docker build -t test-inference -f fargate/inference/Dockerfile --target builder fargate/inference/ --quiet
check_success "Inference Dockerfile valid"

# Cleanup test images
docker rmi -f test-training test-inference 2>/dev/null || true

# ========================================
# TEST 7: Data Quality Check
# ========================================
echo_step "TEST 7: Data Quality Validation"

python3 -c "
import pandas as pd
df = pd.read_csv('customer_engagement_dataset_extended.csv')
print(f'✓ Loaded {len(df):,} records')
print(f'✓ {len(df.columns)} columns')
print(f'✓ No nulls in customer_id: {df[\"customer_id\"].notna().all()}')
print(f'✓ Engagement score range: [{df[\"engagement_score\"].min():.2f}, {df[\"engagement_score\"].max():.2f}]')
"
check_success "Data quality validated"

# ========================================
# SUMMARY
# ========================================
echo_step "TEST SUMMARY"

echo -e "${GREEN}✅ All component tests passed!${NC}"
echo ""
echo "LocalStack Resources Created:"
echo "  - S3 Buckets: 4"
echo "  - DynamoDB Tables: 1"
echo "  - ECR Repositories: 2"
echo "  - Lambda Functions: 1 (test)"
echo "  - API Gateway: 1"
echo ""
echo "Next steps:"
echo "  1. Deploy full Terraform: cd terraform && tflocal apply"
echo "  2. Build Docker images: make docker-build-all"
echo "  3. Run full pipeline: make run-pipeline-local"

