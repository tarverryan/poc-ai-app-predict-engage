# 🚀 LocalStack Quick Start Guide

**Get the entire platform running locally in 10 minutes - $0 cost**

---

## Prerequisites

- ✅ Docker installed and running
- ✅ Python 3.11+ installed
- ✅ ~10 GB disk space
- ✅ 8 GB RAM available

---

## Step 1: Install LocalStack Tools (2 minutes)

```bash
# Install LocalStack CLI
pip3 install localstack localstack-ext

# Install wrapper tools
pip3 install terraform-local awscli-local

# Verify installation
localstack --version
tflocal --version
awslocal --version
```

---

## Step 2: Start LocalStack (1 minute)

```bash
# Start LocalStack (runs in background)
localstack start -d

# Wait for it to be ready (~30 seconds)
sleep 30

# Check health
curl http://localhost:4566/_localstack/health
```

**Expected output:** All services show `"available": true`

---

## Step 3: Run Component Tests (2 minutes)

```bash
# Make scripts executable
chmod +x scripts/*.sh

# Run comprehensive component tests
./scripts/test_components.sh
```

**Expected output:** All 7 tests pass ✅

Tests verify:
1. ✅ S3 buckets creation
2. ✅ DynamoDB table creation
3. ✅ ECR repositories
4. ✅ Lambda function deployment & invocation
5. ✅ API Gateway creation
6. ✅ Docker builds
7. ✅ Data quality validation

---

## Step 4: Deploy Infrastructure with Terraform (Optional)

Since we don't have a root Terraform configuration yet, let's create a simplified test:

```bash
# Create test Terraform
mkdir -p terraform/test
cd terraform/test

cat > main.tf <<'EOF'
terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

provider "aws" {
  region                      = "us-east-1"
  access_key                  = "test"
  secret_key                  = "test"
  skip_credentials_validation = true
  skip_metadata_api_check     = true
  skip_requesting_account_id  = true

  endpoints {
    s3             = "http://localhost:4566"
    dynamodb       = "http://localhost:4566"
    lambda         = "http://localhost:4566"
    apigateway     = "http://localhost:4566"
    iam            = "http://localhost:4566"
  }
}

resource "aws_s3_bucket" "test" {
  bucket = "terraform-test-bucket"
}
EOF

# Initialize and apply
terraform init
terraform apply -auto-approve

# Verify
awslocal s3 ls | grep terraform-test-bucket
```

---

## Step 5: Build Docker Images (5 minutes)

```bash
cd /Users/rb/github/poc-ai-app-predict-engage

# Build training image
docker build -t engagement-training:latest fargate/training/

# Build inference image  
docker build -t engagement-inference:latest fargate/inference/

# Verify images
docker images | grep engagement
```

**Expected:** 2 images (~2 GB total)

---

## Step 6: Run Python Tests Locally (Without Deployment)

Since full deployment requires all Terraform modules, let's test the Python code directly:

```bash
# Test data generation (already done)
python3 data/generate_dummy_data.py

# Test Lambda functions locally
cd lambda/pre_cleanup
python3 -m pytest test_handler.py  # (if tests exist)

# Test training script with mock data
cd ../../fargate/training
python3 -c "
import train
print('Training imports successful')
"
```

---

## Troubleshooting

### LocalStack won't start
```bash
# Check Docker
docker ps

# Check LocalStack logs
localstack logs

# Restart LocalStack
localstack stop
localstack start -d
```

### Port 4566 already in use
```bash
# Find process using port
lsof -i :4566

# Kill LocalStack
localstack stop

# Or use different port
export LOCALSTACK_HOST=localhost:4567
```

### Out of disk space
```bash
# Clean Docker
docker system prune -a

# Remove old LocalStack data
rm -rf ~/.localstack
```

---

## Verification Checklist

After running the quick start:

- [ ] LocalStack running (`docker ps | grep localstack`)
- [ ] S3 buckets created (`awslocal s3 ls`)
- [ ] DynamoDB table exists (`awslocal dynamodb list-tables`)
- [ ] ECR repos created (`awslocal ecr describe-repositories`)
- [ ] Lambda test passed (`awslocal lambda list-functions`)
- [ ] Docker images built (`docker images | grep engagement`)
- [ ] Data file exists (`ls -lh customer_engagement_dataset_extended.csv`)

---

## What's NOT Included (Would Require More Setup)

The following would require full Terraform deployment (not included in quick test):

- ❌ Bedrock Knowledge Base (mocking Bedrock requires additional setup)
- ❌ ECS/Fargate cluster (requires VPC configuration)
- ❌ Step Functions state machine (requires all Lambda functions deployed)
- ❌ Complete API Gateway with Lambda integration
- ❌ Glue Data Catalog (limited LocalStack support)
- ❌ Athena queries (limited LocalStack support)

---

## Alternative: Test Individual Components

Since full deployment is complex, test components individually:

### Test 1: Data Generation ✅
```bash
python3 data/generate_dummy_data.py
# ✅ Generates 100K records in 2 seconds
```

### Test 2: S3 Operations ✅
```bash
awslocal s3 mb s3://test-bucket
awslocal s3 cp customer_engagement_dataset_extended.csv s3://test-bucket/
awslocal s3 ls s3://test-bucket/
# ✅ File uploaded successfully
```

### Test 3: DynamoDB Operations ✅
```bash
awslocal dynamodb put-item \
  --table-name engagement-prediction-predictions-cache-dev \
  --item '{"customer_id": {"S": "test123"}, "feature_hash": {"S": "hash123"}, "prediction": {"N": "0.75"}}'

awslocal dynamodb get-item \
  --table-name engagement-prediction-predictions-cache-dev \
  --key '{"customer_id": {"S": "test123"}, "feature_hash": {"S": "hash123"}}'
# ✅ Item stored and retrieved
```

### Test 4: Lambda Execution ✅
```bash
awslocal lambda invoke \
  --function-name engagement-prediction-test-dev \
  --payload '{"test": "data"}' \
  output.json

cat output.json
# ✅ Lambda executes successfully
```

### Test 5: Docker Container ✅
```bash
# Run training container locally
docker run --rm \
  -e ENV=dev \
  -e AWS_REGION=us-east-1 \
  engagement-training:latest \
  python --version

# ✅ Container runs successfully
```

---

## Summary

**What Works in LocalStack:**
- ✅ S3 bucket operations
- ✅ DynamoDB CRUD operations
- ✅ Lambda function deployment & invocation
- ✅ ECR repositories
- ✅ API Gateway basic setup
- ✅ Docker image builds
- ✅ Data generation

**What's Limited:**
- ⚠️ Bedrock (requires mock/stub)
- ⚠️ Glue Catalog (basic support)
- ⚠️ Athena (basic support)
- ⚠️ ECS/Fargate (requires networking setup)

**Recommendation:**
- Use this quick start to verify **individual components** work
- For **full integration testing**, deploy to AWS dev account
- Estimated AWS dev cost: **$1-5** for complete pipeline test

---

## Next Steps

1. ✅ Run `./scripts/test_components.sh` - Verify all components
2. ⚠️ For full deployment, see `docs/production_deployment.md`
3. 💡 For AWS deployment, use `terraform/` with real AWS credentials

---

**Total Time:** ~10 minutes  
**Total Cost:** $0 (LocalStack)  
**What You Get:** Validated components ready for integration

