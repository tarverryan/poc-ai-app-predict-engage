#!/bin/bash
# Test LocalStack S3 functionality

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Configuration
export AWS_ENDPOINT_URL=http://localhost:4566
export AWS_DEFAULT_REGION=us-east-1
export AWS_ACCESS_KEY_ID=test
export AWS_SECRET_ACCESS_KEY=test

echo -e "${GREEN}========================================${NC}"
echo -e "${GREEN}Testing LocalStack S3${NC}"
echo -e "${GREEN}========================================${NC}"

# Test 1: Create S3 buckets
echo -e "\n${YELLOW}1. Creating S3 buckets...${NC}"
awslocal s3 mb s3://engagement-prediction-raw-dev || echo "Bucket may already exist"
awslocal s3 mb s3://engagement-prediction-processed-dev || echo "Bucket may already exist"
awslocal s3 mb s3://engagement-prediction-results-dev || echo "Bucket may already exist"
awslocal s3 mb s3://engagement-prediction-athena-results-dev || echo "Bucket may already exist"
awslocal s3 mb s3://engagement-prediction-models-dev || echo "Bucket may already exist"

echo -e "${GREEN}✓ Buckets created${NC}"

# Test 2: List buckets
echo -e "\n${YELLOW}2. Listing S3 buckets...${NC}"
awslocal s3 ls

# Test 3: Upload CSV data
echo -e "\n${YELLOW}3. Uploading CSV data...${NC}"
if [ -f "customer_engagement_dataset_extended.csv" ]; then
    awslocal s3 cp customer_engagement_dataset_extended.csv \
        s3://engagement-prediction-raw-dev/customers/data.csv
    echo -e "${GREEN}✓ CSV uploaded${NC}"
else
    echo -e "${RED}✗ CSV file not found${NC}"
    exit 1
fi

# Test 4: Upload Parquet data
echo -e "\n${YELLOW}4. Uploading Parquet data...${NC}"
if [ -f "customer_engagement_dataset_extended.parquet" ]; then
    awslocal s3 cp customer_engagement_dataset_extended.parquet \
        s3://engagement-prediction-raw-dev/customers/data.parquet
    echo -e "${GREEN}✓ Parquet uploaded${NC}"
else
    echo -e "${RED}✗ Parquet file not found${NC}"
    exit 1
fi

# Test 5: List uploaded files
echo -e "\n${YELLOW}5. Listing uploaded files...${NC}"
awslocal s3 ls s3://engagement-prediction-raw-dev/customers/ --recursive

# Test 6: Get file sizes
echo -e "\n${YELLOW}6. Checking file sizes...${NC}"
awslocal s3 ls s3://engagement-prediction-raw-dev/customers/ --recursive --human-readable

# Test 7: Download and verify
echo -e "\n${YELLOW}7. Verifying upload (download test)...${NC}"
awslocal s3 cp s3://engagement-prediction-raw-dev/customers/data.csv /tmp/test-download.csv
CSV_SIZE=$(wc -c < /tmp/test-download.csv)
echo -e "   Downloaded CSV size: ${CSV_SIZE} bytes"
rm -f /tmp/test-download.csv

echo -e "\n${GREEN}========================================${NC}"
echo -e "${GREEN}✅ S3 tests passed!${NC}"
echo -e "${GREEN}========================================${NC}"

