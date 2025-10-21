# Project Prompt: Customer Engagement Prediction Platform

**For:** New Cursor AI Instance  
**Purpose:** Quick context loading to continue development or spin up from scratch  
**Version:** 1.0

---

## QUICK START PROMPT

Copy this entire section into a new Cursor AI chat to get started:

```
I need you to build/continue development on a Customer Engagement Prediction Platform PoC.

PROJECT CONTEXT:
- This is a proof-of-concept for predicting customer engagement in a hybrid social/gig app (Tinder + Instagram + Fiverr)
- Tech stack: AWS services (mocked locally with LocalStack), Terraform, Docker, XGBoost ML
- Target: 100K dummy customer records, predict daily engagement scores (0-1 scale)
- Budget: $0 local cost, <$20/run AWS production cost
- Compliance: SOC2, HIPAA, PII-aware

KEY ARCHITECTURE:
- LocalStack for 100% local AWS service mocking (S3, Glue, Athena, ECR, ECS Fargate, Lambda, Step Functions, Bedrock)
- Terraform for Infrastructure as Code (organized by layer: data, compute, ml, ai, network)
- 7-stage ML pipeline orchestrated by Step Functions:
  1. Pre-cleanup Lambda (drop tables, clear S3)
  2. Data-prep Lambda (create Athena tables, split train/test)
  3. Fargate training task (XGBoost on 80K records)
  4. Fargate inference task (predictions on 100K records)
  5. QA table Lambda (400 edge cases for human review)
  6. Final results Lambda (join original + predictions + metadata)
  7. Success notification

DATA SCHEMA:
- 33 features total (24 existing + 9 new for hybrid app)
- New columns: match_success_rate, profile_views_received_week, gig_applications_sent_month, 
  gig_listings_active, transaction_revenue_month, content_virality_score, swipe_like_ratio, 
  avg_job_completion_rating, total_connections
- Target variable: engagement_score (0-1, daily active usage metric)

ML PIPELINE:
- Model: XGBoost regressor (regression for engagement score)
- Training: 80K records, test: 20K records
- Fargate Tasks: 16 vCPU, 64 GB RAM (compute-optimized for in-memory processing)
- Parallel execution: Training + validation run simultaneously; QA + results tables run simultaneously
- Runtime: ~8.5 minutes total (30% faster with parallel execution)
- Features: One-hot encoded categoricals, interaction features, StandardScaler
- Artifacts saved to S3: model.pkl, scaler.pkl, feature_importance.json, metrics.json

BEDROCK AGENT:
- Should answer 40 comprehensive questions about engagement (see project_requirements.md Section 7.2)
- Tools: query_athena(sql), get_feature_stats(feature), explain_prediction(customer_id)
- Mock locally with LangChain if LocalStack Bedrock is limited

DELIVERABLES:
1. Terraform modules (data, compute, ml, ai, network)
2. Docker container for ML (train.py, predict.py)
3. 4 Lambda functions (pre-cleanup, data-prep, create-qa-table, create-results-table)
4. Step Functions state machine JSON
5. 100K dummy data generator (Faker + correlations)
6. GitHub Actions CI/CD (lint, test, cost estimation, compliance)
7. Cost dashboard, architecture docs, compliance checklist

CURRENT STATE:
- Repository initialized with project_requirements.md (full spec)
- Original CSV with 10 sample records exists: customer_engagement_dataset_extended.csv
- Need to implement: [list what's missing based on current repo state]

NEXT ACTIONS:
Read project_requirements.md for complete specifications, then proceed with implementation starting with:
1. Repository structure setup
2. LocalStack docker-compose.yml
3. 100K dummy data generation
4. Terraform foundation (S3, Glue, Athena)

Ask me any questions about the requirements before proceeding.
```

---

## DETAILED CONTEXT SECTIONS

Use these sections to provide additional context as needed:

### 1. ARCHITECTURE OVERVIEW

```
┌─────────────────────────────────────────────────────────────────┐
│                   CUSTOMER ENGAGEMENT ML PLATFORM                │
└─────────────────────────────────────────────────────────────────┘

LOCAL DEVELOPMENT (LocalStack)
├── S3 Buckets:
│   ├── engagement-data (raw CSV, processed Parquet)
│   ├── engagement-models (XGBoost artifacts)
│   ├── engagement-predictions (inference outputs)
│   ├── engagement-qa (human review queue)
│   └── engagement-results (final joined tables)
│
├── Glue Data Catalog:
│   ├── engagement_raw (customers, training_data, test_data, inference_input)
│   ├── engagement_predictions (predictions table)
│   ├── engagement_qa (human_review table)
│   └── engagement_analytics (final_results + 3 views)
│
├── Athena:
│   └── SQL queries on all databases
│
├── ECR:
│   └── engagement-ml:latest (Python 3.11 + XGBoost)
│
├── ECS Fargate:
│   ├── training-task (16 vCPU, 64 GB, ~3 min) [Parallel with validation Lambda]
│   └── inference-task (16 vCPU, 64 GB, ~1 min)
│
├── Lambda Functions:
│   ├── pre-cleanup-lambda (512 MB, 5 min timeout)
│   ├── data-prep-lambda (1024 MB, 10 min timeout)
│   ├── data-validation-lambda (512 MB, 3 min timeout) [Parallel with training]
│   ├── create-qa-table-lambda (512 MB, 5 min timeout) [Parallel with results]
│   └── create-results-table-lambda (1024 MB, 5 min timeout) [Parallel with QA]
│
├── Step Functions:
│   └── engagement-ml-pipeline (7 stages with 2 parallel blocks, ~8.5 min total)
│
└── Bedrock Agent:
    └── Claude 3.5 Sonnet (40 Q&A capabilities)

NETWORK:
└── VPC with private subnets (Fargate + Lambda isolated)
```

### 2. DATA FLOW

```
Raw CSV (10 records) 
  → Dummy Generator (100K records with correlations)
    → S3: engagement-data/raw/customers.csv
      → Data Prep Lambda: Athena CREATE TABLE
        → Split 80/20 → Parquet (compressed)
          → Training (80K) → Fargate train.py → XGBoost model → S3
          → Test (20K) → Model evaluation → Metrics JSON → S3
          → Inference (100K) → Fargate predict.py → Predictions → S3
            → QA Lambda: Edge cases (400 records) → Athena table
            → Results Lambda: JOIN original + predictions → Final table (partitioned)
              → Athena Views (high_value, at_risk, model_performance)
                → Bedrock Agent queries → Answers to 40 questions
```

### 3. KEY FILES TO CREATE

**Priority 1 (Foundation & Setup):**
```
.gitignore                             # Git ignore patterns
README.md                              # Project overview & quick start
CHANGELOG.md                           # Version history
LICENSE                                # MIT License
Makefile                               # Common tasks automation
docker-compose.yml                     # LocalStack services
terraform/providers.tf                 # AWS/LocalStack provider config
terraform/data/s3.tf                   # 5 S3 buckets
terraform/data/glue.tf                 # 4 databases
terraform/data/athena.tf               # Workgroup, output bucket
terraform/network/vpc.tf               # VPC, subnets, security groups
data/generate_dummy_data.py            # 100K records with Faker
sql/schema/01_create_databases.sql     # Database creation
sql/schema/02_create_raw_tables.sql    # Raw tables
```

**Priority 2 (ML Pipeline - Fargate):**
```
fargate/Dockerfile                     # Python 3.11 + XGBoost + boto3
fargate/requirements.txt               # xgboost, scikit-learn, pandas, boto3, pyarrow
fargate/train.py                       # XGBoost training logic
fargate/predict.py                     # Inference logic
fargate/utils/data_loader.py           # Data loading utilities
fargate/utils/feature_engineering.py   # Feature transformations
terraform/ml/ecr.tf                    # ECR repository
terraform/ml/ecs.tf                    # Cluster, task definitions (16 vCPU, 64 GB)
```

**Priority 3 (Lambda Functions):**
```
lambda/pre_cleanup/lambda_function.py
lambda/data_prep/lambda_function.py
lambda/data_validation/lambda_function.py    # NEW: runs parallel with training
lambda/create_qa_table/lambda_function.py
lambda/create_results_table/lambda_function.py
lambda/shared/athena_client.py         # Shared Athena utilities
lambda/shared/s3_client.py             # Shared S3 utilities
terraform/compute/lambda.tf            # All 5 Lambda functions
terraform/compute/iam.tf               # Lambda execution roles
```

**Priority 4 (SQL Queries):**
```
sql/queries/data_preparation.sql       # Training/test split queries
sql/queries/qa_table_creation.sql      # QA table creation
sql/queries/final_results_table.sql    # Final results JOIN
sql/queries/analytics_views.sql        # High-value, at-risk, performance views
```

**Priority 5 (Orchestration with Parallel Execution):**
```
terraform/compute/stepfunctions.tf     # State machine definition + IAM
terraform/compute/stepfunctions.json   # 7-stage workflow with 2 parallel blocks
  - ParallelTrainingAndValidation: Fargate training + Lambda validation
  - ParallelTableCreation: QA table + Final results table
```

**Priority 6 (AI & Analytics - Bedrock):**
```
bedrock/agent_handler.py               # Q&A logic (40 questions)
bedrock/athena_tools.py                # Query execution helpers
bedrock/knowledge_base.py              # KB management
bedrock/prompts/system_prompt.txt      # System prompt template
terraform/ai/bedrock.tf                # Agent configuration
```

**Priority 7 (Documentation):**
```
docs/architecture/overview.md          # Architecture overview
docs/architecture/data_flow.md         # Data pipeline flow
docs/architecture/diagrams/architecture.mmd  # Mermaid diagram
docs/deployment/local_setup.md         # LocalStack setup guide
docs/data_dictionary.md                # 33-column schema
docs/cost_analysis.md                  # Cost breakdown
docs/compliance_checklist.md           # SOC2, HIPAA controls
docs/contributing.md                   # Contribution guidelines
```

**Priority 8 (CI/CD & Scripts):**
```
.github/workflows/ci.yml               # CI/CD pipeline
.github/workflows/cost-estimate.yml    # Cost analysis on PRs
.github/workflows/security-scan.yml    # tfsec, Trivy scans
scripts/setup/install_dependencies.sh
scripts/deploy/build_docker.sh
scripts/deploy/push_ecr.sh
scripts/run/start_pipeline.sh
scripts/cleanup/destroy_infrastructure.sh
```

**Priority 9 (Testing):**
```
tests/unit/test_ml_training.py
tests/unit/test_lambda_functions.py
tests/integration/test_end_to_end.py
tests/conftest.py                      # Pytest fixtures
```

### 4. DEVELOPMENT WORKFLOW

```bash
# Step 1: Start LocalStack
docker-compose up -d

# Step 2: Generate 100K dummy data
python src/data_generation/generate_dummy_data.py

# Step 3: Build ML Docker image
cd src/ml_pipeline
docker build -t engagement-ml:latest .

# Step 4: Push to LocalStack ECR
aws --endpoint-url=http://localhost:4566 ecr create-repository --repository-name engagement-ml
docker tag engagement-ml:latest localhost:4566/engagement-ml:latest
docker push localhost:4566/engagement-ml:latest

# Step 5: Apply Terraform
cd terraform
tflocal init
tflocal plan
tflocal apply -auto-approve

# Step 6: Trigger Step Functions
aws --endpoint-url=http://localhost:4566 stepfunctions start-execution \
  --state-machine-arn arn:aws:states:us-east-1:000000000000:stateMachine:engagement-ml-pipeline

# Step 7: Monitor execution
aws --endpoint-url=http://localhost:4566 stepfunctions describe-execution \
  --execution-arn <execution-arn>

# Step 8: Query results in Athena
aws --endpoint-url=http://localhost:4566 athena start-query-execution \
  --query-string "SELECT * FROM engagement_analytics.final_results LIMIT 10" \
  --result-configuration OutputLocation=s3://athena-results/
```

### 5. COST CALCULATION FORMULAS (Updated for 64GB Fargate)

**Production AWS Cost (per weekly run):**
- S3: 500 MB × $0.023/GB = $0.01
- Glue: 5 min × 1 DPU × $0.44/DPU-hour = $0.05
- Athena: 10 queries × 100 MB each × $5/TB = $0.05
- **Fargate Training:** 16 vCPU × 64 GB × 3 min
  - CPU: 16 × $0.04048/vCPU-hr × 0.05 hr × 0.3 (Spot) = $0.97
  - Memory: 64 × $0.004445/GB-hr × 0.05 hr × 0.3 (Spot) = $0.43
  - **Subtotal: $1.40** (on-demand would be $21.60, Spot saves 93%)
- **Fargate Inference:** 16 vCPU × 64 GB × 1 min
  - CPU: 16 × $0.04048/vCPU-hr × 0.017 hr × 0.3 (Spot) = $0.33
  - Memory: 64 × $0.004445/GB-hr × 0.017 hr × 0.3 (Spot) = $0.14
  - **Subtotal: $0.47**
- Lambda: 5 × 1 min × 1024 MB × $0.0000166667/GB-sec = $0.05
- Step Functions: 10 transitions × $0.000025 = $0.01
- Bedrock: (50K input × $0.003/1K + 10K output × $0.015/1K) tokens = $2.50
- ECR: 2 GB × $0.10/GB-month = $0.20
- CloudWatch Logs: 500 MB × $0.50/GB = $0.03

**Total:** $4.42/run ✅ (under $20 target, with 64GB Fargate + Spot pricing)

### 6. TESTING CHECKLIST

**Unit Tests:**
- [ ] Dummy data generator produces 100K records with correct schema
- [ ] XGBoost training completes without errors
- [ ] Inference generates predictions for all 100K records
- [ ] All Lambda functions execute successfully
- [ ] Athena queries return expected results

**Integration Tests:**
- [ ] End-to-end Step Functions execution succeeds
- [ ] S3 buckets contain expected artifacts
- [ ] Glue catalog tables are queryable
- [ ] Final results table has 100K records
- [ ] Model R² > 0.7 on test set

**Compliance Tests:**
- [ ] PII masked in Athena views
- [ ] S3 encryption enabled
- [ ] VPC isolation for compute resources
- [ ] No plaintext secrets in code

**CI/CD Tests:**
- [ ] GitHub Actions workflow completes in <15 min
- [ ] Terraform plan shows no drift
- [ ] Cost estimate under $20/run
- [ ] Security scan passes (tfsec)

### 7. COMMON ISSUES & SOLUTIONS

**Issue:** LocalStack Bedrock not fully supported  
**Solution:** Use LangChain with local Ollama model (llama3 or mistral) for Q&A

**Issue:** 100K records cause OOM in training  
**Solution:** Use batch processing with chunking (10K batches) or increase Fargate memory to 8 GB

**Issue:** Terraform state drift in LocalStack  
**Solution:** Run `docker-compose down -v` to clear volumes, then `tflocal apply` fresh

**Issue:** ECS task can't pull Docker image from ECR  
**Solution:** Verify network config allows LocalStack ECR access, check task execution role permissions

**Issue:** Athena queries timeout  
**Solution:** Use LIMIT clause for testing, ensure S3 data is Parquet format with partitioning

**Issue:** Step Functions execution fails silently  
**Solution:** Check CloudWatch logs (LocalStack), enable Step Functions logging, verify IAM roles

### 8. BEDROCK AGENT Q&A EXAMPLES

**Sample implementation for 3 questions:**

```python
# src/bedrock_agent/agent_handler.py

def answer_question(question: str) -> str:
    if "top 5 features" in question.lower():
        # Query feature importance from S3
        importance = load_feature_importance()
        top_5 = importance[:5]
        return f"Top 5 features: {', '.join([f'{f[0]} ({f[1]:.3f})' for f in top_5])}"
    
    elif "premium account" in question.lower():
        # Execute Athena query
        query = """
        SELECT 
            account_type,
            AVG(predicted_engagement_score) as avg_engagement
        FROM engagement_analytics.final_results
        GROUP BY account_type
        """
        results = execute_athena_query(query)
        return format_comparison(results)
    
    elif "model accurate" in question.lower():
        # Load evaluation metrics
        metrics = load_model_metrics()
        return f"Model R²: {metrics['r2']:.3f}, RMSE: {metrics['rmse']:.3f}"
```

### 9. DOCKER & ECR CONFIGURATION

**Dockerfile for ML Container:** `src/ml_pipeline/Dockerfile`

```dockerfile
FROM python:3.11-slim

RUN apt-get update && apt-get install -y gcc g++ libgomp1 && rm -rf /var/lib/apt/lists/*

WORKDIR /app

COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt

COPY train.py predict.py ./
COPY utils/ ./utils/

ENV PYTHONUNBUFFERED=1
ENV AWS_DEFAULT_REGION=us-east-1

CMD ["python", "train.py"]
```

**Build and Push to LocalStack ECR:**

```bash
# Build Docker image
cd src/ml_pipeline
docker build -t engagement-ml:latest .

# Create ECR repository in LocalStack
aws --endpoint-url=http://localhost:4566 ecr create-repository --repository-name engagement-ml

# Tag for LocalStack
docker tag engagement-ml:latest localhost:4566/engagement-ml:latest

# Login to LocalStack ECR
aws --endpoint-url=http://localhost:4566 ecr get-login-password | \
  docker login --username AWS --password-stdin localhost:4566

# Push image
docker push localhost:4566/engagement-ml:latest
```

**ECS Task Definitions (16 vCPU, 64 GB):**

Training task:
- CPU: 16384 (16 vCPU)
- Memory: 65536 (64 GB)
- Runtime: ~3 minutes
- Command: `["python", "train.py"]`

Inference task:
- CPU: 16384 (16 vCPU)
- Memory: 65536 (64 GB)
- Runtime: ~1 minute
- Command: `["python", "predict.py"]`

### 10. TERRAFORM MODULE EXAMPLE

**Sample S3 bucket configuration:**

```hcl
# terraform/data/s3.tf

resource "aws_s3_bucket" "engagement_data" {
  bucket = "engagement-data"
  
  tags = {
    Project = "engagement-prediction"
    Environment = "local"
  }
}

resource "aws_s3_bucket_server_side_encryption_configuration" "engagement_data" {
  bucket = aws_s3_bucket.engagement_data.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

resource "aws_s3_bucket_versioning" "engagement_data" {
  bucket = aws_s3_bucket.engagement_data.id
  
  versioning_configuration {
    status = "Enabled"
  }
}
```

### 10. QUICK REFERENCE LINKS

- **Full Requirements:** `project_requirements.md` (in repo root)
- **Original Data:** `customer_engagement_dataset_extended.csv` (10 sample records)
- **LocalStack Docs:** https://docs.localstack.cloud/
- **Terraform LocalStack Provider:** https://registry.terraform.io/providers/localstack/localstack
- **XGBoost Docs:** https://xgboost.readthedocs.io/
- **Cursor Rules:** `.cursor/rules/master.mdc` (truth & integrity focus)

---

## PROMPT VARIATIONS

### For Initial Setup:
```
I'm starting the Customer Engagement Prediction Platform from scratch. 
Read project_requirements.md and project_prompt.md, then:
1. Create the repository structure
2. Set up docker-compose.yml for LocalStack
3. Generate 100K dummy customer records
4. Initialize Terraform modules
Ask me before proceeding with each major component.
```

### For Continuing Development:
```
I'm continuing work on the Customer Engagement Prediction Platform.
Current status: [describe what's done]
Next task: [describe what needs to be built]
Read project_requirements.md for context, then proceed with implementation.
```

### For Debugging:
```
I'm debugging the Customer Engagement Prediction Platform.
Issue: [describe the problem]
Context: [what component, what error messages]
Read project_requirements.md Section [X] for relevant architecture details.
```

### For Cost Analysis:
```
Review the Customer Engagement Prediction Platform architecture.
Calculate the actual AWS production cost per run based on:
- 100K records
- Weekly batch execution
- Current AWS pricing (verify latest rates)
Show detailed breakdown by service and compare to $20/run target.
```

### For Compliance Review:
```
Audit the Customer Engagement Prediction Platform for compliance.
Check: SOC2 Type II, HIPAA, PII handling
Review: Encryption, VPC isolation, data masking, audit logging
Reference project_requirements.md Section 2.3 for requirements.
Generate compliance checklist with gaps and recommendations.
```

---

## MEMORY TRIGGERS

**If you see these phrases, recall this project:**
- "engagement prediction"
- "Tinder + Instagram + Fiverr hybrid"
- "100K dummy customers"
- "LocalStack AWS mock"
- "XGBoost Fargate pipeline"
- "7-stage Step Functions"
- "40 Bedrock Q&A questions"

**Key identifiers:**
- Repository: `poc-ai-app-predict-engage`
- Primary file: `customer_engagement_dataset_extended.csv`
- Budget: $0 local, <$20 AWS production
- Timeline: 14 days / 2 sprints
- Target: Daily engagement score (0-1) prediction

---

## VERSION HISTORY

- **v1.0** (2025-10-21): Initial prompt document created alongside project_requirements.md
- Future versions: Update as implementation progresses

---

**Note:** Always read `project_requirements.md` first for complete specifications. This prompt document is a quick-start guide only.

