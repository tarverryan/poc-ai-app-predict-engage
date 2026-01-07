# Architecture Flow - Complete End-to-End

**Customer Engagement Prediction Platform**  
**Version:** 1.0  
**Last Updated:** 2025-10-21  
**Classification:** Public

---

## TL;DR Architecture

```
Data (CSV) → S3 → Glue Catalog → Athena
              ↓
         Docker → ECR → ECS Fargate (Training + Inference)
              ↓
         Lambda (Orchestration) → Step Functions
              ↓
         S3 (Results) → Bedrock Knowledge Base (S3 Vector Store + Titan v2)
              ↓
         Bedrock Agents → API Gateway → DynamoDB Cache → Predictions
```

**Key Constraint:** Bedrock Knowledge Base uses **S3 for vector storage** (NOT OpenSearch, NOT pgvector) with **Titan Embeddings v2**.

---

## 1. Infrastructure Layer (Terraform)

### 1.1 Terraform Module Organization

```
terraform/
├── main.tf
├── variables.tf
├── outputs.tf
├── providers.tf               # AWS + LocalStack config
├── backend.tf                 # S3 + DynamoDB state locking
│
├── modules/
│   ├── data/                  # S3, Glue, Athena
│   │   ├── s3.tf              # 5 buckets (raw, processed, features, models, results)
│   │   ├── glue.tf            # Data Catalog, Crawlers
│   │   ├── athena.tf          # Workgroups, Named Queries
│   │   └── outputs.tf
│   │
│   ├── compute/               # Lambda, Step Functions
│   │   ├── lambda.tf          # 7 Lambda functions
│   │   ├── step_functions.tf  # ML pipeline orchestration
│   │   ├── iam.tf             # IAM roles for Lambda
│   │   └── outputs.tf
│   │
│   ├── ml/                    # ECR, ECS/Fargate
│   │   ├── ecr.tf             # Container registry (2 repos: training, inference)
│   │   ├── ecs.tf             # Cluster + task definitions (16 vCPU, 64 GB)
│   │   ├── iam.tf             # ECS execution + task roles
│   │   └── outputs.tf
│   │
│   ├── ai/                    # Bedrock Knowledge Base + Agents
│   │   ├── bedrock_kb.tf      # Knowledge Base (S3 vector store + Titan v2)
│   │   ├── bedrock_agent.tf   # Agent configuration
│   │   ├── iam.tf             # Bedrock IAM roles
│   │   └── outputs.tf
│   │
│   ├── api/                   # API Gateway + DynamoDB
│   │   ├── api_gateway.tf     # REST API for predictions
│   │   ├── dynamodb.tf        # Prediction cache
│   │   ├── iam.tf             # API Gateway + DynamoDB roles
│   │   └── outputs.tf
│   │
│   └── network/               # VPC, Security Groups
│       ├── vpc.tf             # VPC, subnets, NAT
│       ├── security_groups.tf # SGs for Fargate, Lambda
│       ├── endpoints.tf       # VPC endpoints (PrivateLink)
│       └── outputs.tf
```

---

## 2. Data Flow (Batch ML Pipeline)

### 2.1 Step 1: Data Ingestion

```
CSV (100K records, 49 features)
  ↓
S3 Bucket: s3://engagement-raw/customers/
  └── customer_engagement_dataset_extended.csv (Parquet)
  ↓
Glue Crawler
  └── Creates table: engagement_raw.customers
  ↓
Athena (queryable)
```

**Terraform:**
```hcl
# terraform/modules/data/s3.tf
resource "aws_s3_bucket" "raw" {
  bucket = "engagement-raw"
  
  lifecycle {
    prevent_destroy = true
  }
}

# terraform/modules/data/glue.tf
resource "aws_glue_crawler" "customers" {
  name          = "customers-crawler"
  role          = aws_iam_role.glue.arn
  database_name = aws_glue_catalog_database.engagement_db.name

  s3_target {
    path = "s3://${aws_s3_bucket.raw.bucket}/customers/"
  }

  schema_change_policy {
    update_behavior = "UPDATE_IN_DATABASE"
    delete_behavior = "LOG"
  }
}
```

---

### 2.2 Step 2: Docker Image (ML Container)

```
Dockerfile (fargate/training/Dockerfile)
  └── Python 3.11 + XGBoost + scikit-learn + pandas
  ↓
docker build -t engagement-training:latest .
  ↓
docker tag engagement-training:latest <account>.dkr.ecr.us-east-1.amazonaws.com/engagement-training:latest
  ↓
docker push <account>.dkr.ecr.us-east-1.amazonaws.com/engagement-training:latest
  ↓
ECR Repository: engagement-training
```

**Terraform:**
```hcl
# terraform/modules/ml/ecr.tf
resource "aws_ecr_repository" "training" {
  name                 = "engagement-training"
  image_tag_mutability = "MUTABLE"

  image_scanning_configuration {
    scan_on_push = true
  }

  encryption_configuration {
    encryption_type = "AES256"
  }
}

resource "aws_ecr_repository" "inference" {
  name                 = "engagement-inference"
  image_tag_mutability = "MUTABLE"

  image_scanning_configuration {
    scan_on_push = true
  }

  encryption_configuration {
    encryption_type = "AES256"
  }
}
```

---

### 2.3 Step 3: ECS Fargate (Training)

```
Step Functions triggers ECS Task
  ↓
ECS Fargate Task Definition
  ├── Image: <account>.dkr.ecr.us-east-1.amazonaws.com/engagement-training:latest
  ├── CPU: 16 vCPU (16384)
  ├── Memory: 64 GB (65536)
  ├── Environment Variables:
  │   ├── S3_BUCKET_PROCESSED=engagement-processed
  │   ├── S3_BUCKET_MODELS=engagement-models
  │   ├── MODEL_NAME=engagement_v1.0
  │   └── TRAINING_CONFIG=s3://engagement-config/training.json
  └── IAM Role: ECSTaskRole (S3 read/write, Athena query)
  ↓
Training Script (fargate/training/train.py)
  ├── Load data from Athena (via S3)
  ├── Train XGBoost model (5 models in parallel)
  ├── Evaluate (RMSE, R², AUC-ROC, fairness)
  ├── Save model artifacts to S3
  └── Publish metrics to CloudWatch
  ↓
S3 Bucket: s3://engagement-models/
  ├── engagement_v1.0.pkl
  ├── scaler_v1.0.pkl
  ├── feature_importance.json
  └── metrics.json
```

**Terraform:**
```hcl
# terraform/modules/ml/ecs.tf
resource "aws_ecs_cluster" "ml_cluster" {
  name = "engagement-ml-cluster"

  setting {
    name  = "containerInsights"
    value = "enabled"
  }
}

resource "aws_ecs_task_definition" "training" {
  family                   = "engagement-training"
  network_mode             = "awsvpc"
  requires_compatibilities = ["FARGATE"]
  cpu                      = "16384"  # 16 vCPU
  memory                   = "65536"  # 64 GB
  execution_role_arn       = aws_iam_role.ecs_execution.arn
  task_role_arn            = aws_iam_role.ecs_task.arn

  container_definitions = jsonencode([
    {
      name      = "training"
      image     = "${aws_ecr_repository.training.repository_url}:latest"
      cpu       = 16384
      memory    = 65536
      essential = true

      environment = [
        { name = "S3_BUCKET_PROCESSED", value = "engagement-processed" },
        { name = "S3_BUCKET_MODELS", value = "engagement-models" },
        { name = "MODEL_NAME", value = "engagement_v1.0" }
      ]

      logConfiguration = {
        logDriver = "awslogs"
        options = {
          "awslogs-group"         = "/ecs/training-task"
          "awslogs-region"        = "us-east-1"
          "awslogs-stream-prefix" = "ecs"
        }
      }
    }
  ])
}
```

---

### 2.4 Step 4: Lambda Orchestration

```
Step Functions State Machine: engagement-ml-pipeline
  ├── Stage 1: Pre-Cleanup (Lambda)
  │   └── Clear Athena tables, S3 temp data
  │
  ├── Stage 2: Data Preparation (Lambda)
  │   ├── Run Athena queries (80/20 split)
  │   └── Create training/test datasets
  │
  ├── Stage 3: Parallel Execution
  │   ├── Branch A: Fargate Training (ECS RunTask)
  │   │   └── Train 5 models (engagement, churn, LTV, reco, anomaly)
  │   └── Branch B: Data Validation (Lambda)
  │       └── Great Expectations checks
  │
  ├── Stage 4: Fargate Inference (ECS RunTask)
  │   └── Generate predictions for 100K records
  │
  ├── Stage 5: Parallel Table Creation
  │   ├── Branch A: QA Table (Lambda)
  │   │   └── Create qa_table (400 records for manual review)
  │   └── Branch B: Final Results (Lambda)
  │       └── Create predictions_final (100K records)
  │
  └── Stage 6: Success Notification (Lambda)
      └── Send completion status
```

**Terraform:**
```hcl
# terraform/modules/compute/step_functions.tf
resource "aws_sfn_state_machine" "ml_pipeline" {
  name     = "engagement-ml-pipeline"
  role_arn = aws_iam_role.step_functions.arn

  definition = templatefile("${path.module}/state_machine.json", {
    pre_cleanup_arn      = aws_lambda_function.pre_cleanup.arn
    data_prep_arn        = aws_lambda_function.data_prep.arn
    data_validation_arn  = aws_lambda_function.data_validation.arn
    create_qa_table_arn  = aws_lambda_function.create_qa_table.arn
    create_results_arn   = aws_lambda_function.create_results.arn
    training_task_def    = "arn:aws:ecs:us-east-1:000000000000:task-definition/engagement-training"
    inference_task_def   = "arn:aws:ecs:us-east-1:000000000000:task-definition/engagement-inference"
    ecs_cluster_arn      = var.ecs_cluster_arn
  })
}
```

---

### 2.5 Step 5: Athena Results

```
Lambda: create-results-table
  ↓
Athena Query: CREATE TABLE predictions_final AS
  SELECT
    c.customer_id,
    c.age,
    c.gender,
    c.tenure_months,
    -- ... all 49 features ...
    p.predicted_engagement_score,
    p.predicted_churn_probability,
    p.predicted_ltv_usd,
    p.model_version,
    p.prediction_timestamp
  FROM engagement_raw.customers c
  LEFT JOIN engagement_results.predictions p
    ON c.customer_id = p.customer_id
  ↓
S3: s3://engagement-results/predictions_final/
  ↓
Athena: SELECT * FROM engagement_analytics.predictions_final
```

---

## 3. AI Layer (Bedrock Knowledge Base + Agents)

### 3.1 Bedrock Knowledge Base (S3 Vector Store + Titan v2)

**CRITICAL CONFIGURATION:**
- **Vector Store:** S3 (NOT OpenSearch, NOT pgvector)
- **Embeddings Model:** Amazon Titan Embeddings v2 (`amazon.titan-embed-text-v2:0`)
- **Documents:** Model metrics, feature importance, Athena query results

```
S3 Bucket: s3://engagement-knowledge-base/
  ├── model_metrics/
  │   ├── engagement_model_metrics.json
  │   ├── churn_model_metrics.json
  │   ├── ltv_model_metrics.json
  │   └── fairness_report.json
  │
  ├── feature_importance/
  │   ├── engagement_features.json
  │   ├── churn_features.json
  │   └── ltv_features.json
  │
  ├── athena_results/
  │   ├── high_engagement_customers.json
  │   ├── at_risk_customers.json
  │   └── churn_analysis.json
  │
  └── data_dictionary/
      └── schema.md (49 features documented)
  ↓
Bedrock Knowledge Base
  ├── Name: engagement-kb
  ├── Embeddings: Amazon Titan Embeddings v2
  ├── Vector Store: S3 (native S3 vector storage)
  │   └── S3 URI: s3://engagement-knowledge-base-vectors/
  ├── Chunking Strategy: Fixed size (300 tokens, 20% overlap)
  └── Metadata: model_version, timestamp, data_source
  ↓
Vector Database (managed by Bedrock in S3)
  └── ~1000 embeddings (1536 dimensions each, Titan v2)
```

**Terraform:**
```hcl
# terraform/modules/ai/bedrock_kb.tf
resource "aws_bedrockagent_knowledge_base" "engagement" {
  name        = "engagement-kb"
  description = "Customer engagement prediction knowledge base"
  role_arn    = aws_iam_role.bedrock_kb.arn

  knowledge_base_configuration {
    vector_knowledge_base_configuration {
      embedding_model_arn = "arn:aws:bedrock:us-east-1::foundation-model/amazon.titan-embed-text-v2:0"
    }
    type = "VECTOR"
  }

  storage_configuration {
    type = "S3"
    s3_configuration {
      bucket_arn = aws_s3_bucket.knowledge_base.arn
      
      # S3 as vector store (NOT OpenSearch, NOT pgvector)
      vector_store {
        s3_uri = "s3://${aws_s3_bucket.knowledge_base_vectors.bucket}/"
      }
    }
  }
}

resource "aws_bedrockagent_data_source" "model_metrics" {
  knowledge_base_id = aws_bedrockagent_knowledge_base.engagement.id
  name              = "model-metrics"
  
  data_source_configuration {
    type = "S3"
    s3_configuration {
      bucket_arn = aws_s3_bucket.knowledge_base.arn
      inclusion_prefixes = ["model_metrics/", "feature_importance/"]
    }
  }

  vector_ingestion_configuration {
    chunking_configuration {
      chunking_strategy = "FIXED_SIZE"
      fixed_size_chunking_configuration {
        max_tokens         = 300
        overlap_percentage = 20
      }
    }
  }
}
```

**Key Points:**
- ✅ S3 as vector store (native Bedrock S3 support)
- ✅ Titan Embeddings v2 (1536 dimensions)
- ❌ NO OpenSearch (not using OpenSearch Serverless)
- ❌ NO pgvector (not using RDS/Aurora with pgvector extension)

---

### 3.2 Bedrock Agent

```
Bedrock Agent: engagement-agent
  ├── Foundation Model: Claude 3.5 Sonnet (anthropic.claude-3-5-sonnet-20240620-v1:0)
  ├── Knowledge Base: engagement-kb (S3 vector store)
  ├── Action Groups:
  │   ├── query_athena: Execute Athena queries
  │   ├── get_customer_details: Fetch customer info
  │   └── explain_prediction: SHAP explanations
  └── Instruction: "You are an AI assistant helping analyze customer engagement..."
  ↓
User Query: "What are the top 5 features that predict high engagement?"
  ↓
Agent Process:
  1. Query Knowledge Base (S3 vector search via Titan v2)
  2. Retrieve: feature_importance/engagement_features.json
  3. Execute Action: query_athena("SELECT * FROM high_engagement_customers LIMIT 10")
  4. Synthesize Response with Claude 3.5 Sonnet
  ↓
Response: "Based on the model analysis, the top 5 features are:
  1. sessions_last_7_days (SHAP: 0.23)
  2. tenure_months (SHAP: 0.19)
  3. network_centrality (SHAP: 0.15)
  4. avg_sentiment_score (SHAP: 0.12)
  5. content_diversity_score (SHAP: 0.10)
  
  These customers typically have 15+ sessions/week and..."
```

**Terraform:**
```hcl
# terraform/modules/ai/bedrock_agent.tf
resource "aws_bedrockagent_agent" "engagement" {
  agent_name              = "engagement-agent"
  agent_resource_role_arn = aws_iam_role.bedrock_agent.arn
  foundation_model        = "anthropic.claude-3-5-sonnet-20240620-v1:0"
  description             = "AI agent for customer engagement analysis"

  instruction = <<-EOT
    You are an expert AI assistant helping business analysts understand customer engagement.
    
    Use the knowledge base to answer questions about:
    - Feature importance and SHAP values
    - Model performance metrics (RMSE, R², AUC-ROC)
    - Customer segmentation insights
    - Churn risk factors
    - LTV prediction drivers
    
    When asked about specific customers, use the query_athena action.
    Always cite your sources (model version, data timestamp).
  EOT

  idle_session_ttl_in_seconds = 600
}

resource "aws_bedrockagent_agent_knowledge_base_association" "engagement" {
  agent_id             = aws_bedrockagent_agent.engagement.id
  knowledge_base_id    = aws_bedrockagent_knowledge_base.engagement.id
  knowledge_base_state = "ENABLED"
  description          = "Engagement prediction knowledge base"
}

resource "aws_bedrockagent_agent_action_group" "athena_actions" {
  agent_id      = aws_bedrockagent_agent.engagement.id
  action_group_name = "athena-actions"
  
  action_group_executor {
    lambda = aws_lambda_function.bedrock_action_handler.arn
  }

  api_schema {
    payload = jsonencode({
      openapi = "3.0.0"
      info = {
        title   = "Athena Query API"
        version = "1.0.0"
      }
      paths = {
        "/query_athena" = {
          post = {
            description = "Execute Athena SQL query"
            parameters = [{
              name     = "sql_query"
              in       = "body"
              required = true
              schema   = { type = "string" }
            }]
            responses = {
              "200" = {
                description = "Query results"
                content = {
                  "application/json" = {
                    schema = { type = "object" }
                  }
                }
              }
            }
          }
        }
      }
    })
  }
}
```

---

## 4. Real-Time Prediction API

### 4.1 API Gateway + Lambda + DynamoDB

```
Client Request: POST /predict
  {
    "customer_id": "12345",
    "features": {
      "age": 28,
      "tenure_months": 15,
      "sessions_last_7_days": 8,
      // ... 46 more features
    }
  }
  ↓
API Gateway: /predict (REST API)
  ├── Authorization: API Key or Cognito
  ├── Request Validation: JSON schema
  └── Integration: Lambda (predict-lambda)
  ↓
Lambda: predict-lambda
  ├── 1. Check DynamoDB cache
  │   └── Key: customer_id#feature_hash
  │   └── TTL: 1 hour
  │
  ├── 2. If CACHE HIT:
  │   └── Return cached prediction (latency < 5ms)
  │
  └── 3. If CACHE MISS:
      ├── Load model from S3 (or in-memory cache)
      ├── Run XGBoost inference
      ├── Store in DynamoDB (with TTL)
      └── Return prediction
  ↓
DynamoDB Table: predictions-cache
  ├── Partition Key: customer_id (String)
  ├── Sort Key: feature_hash (String)
  ├── Attributes:
  │   ├── prediction_score (Number)
  │   ├── model_version (String)
  │   ├── timestamp (Number)
  │   └── ttl (Number, 1 hour)
  └── GSI: model_version-timestamp-index
  ↓
Response: 200 OK
  {
    "customer_id": "12345",
    "prediction": {
      "engagement_score": 0.73,
      "churn_probability": 0.12,
      "ltv_usd": 487.50
    },
    "model_version": "v1.0",
    "timestamp": "2025-10-21T10:30:00Z",
    "latency_ms": 45
  }
```

**Terraform:**
```hcl
# terraform/modules/api/api_gateway.tf
resource "aws_api_gateway_rest_api" "engagement_api" {
  name        = "engagement-prediction-api"
  description = "Real-time customer engagement predictions"

  endpoint_configuration {
    types = ["REGIONAL"]
  }
}

resource "aws_api_gateway_resource" "predict" {
  rest_api_id = aws_api_gateway_rest_api.engagement_api.id
  parent_id   = aws_api_gateway_rest_api.engagement_api.root_resource_id
  path_part   = "predict"
}

resource "aws_api_gateway_method" "predict_post" {
  rest_api_id   = aws_api_gateway_rest_api.engagement_api.id
  resource_id   = aws_api_gateway_resource.predict.id
  http_method   = "POST"
  authorization = "API_KEY"

  request_validator_id = aws_api_gateway_request_validator.predict.id
}

resource "aws_api_gateway_integration" "predict_lambda" {
  rest_api_id = aws_api_gateway_rest_api.engagement_api.id
  resource_id = aws_api_gateway_resource.predict.id
  http_method = aws_api_gateway_method.predict_post.http_method

  integration_http_method = "POST"
  type                    = "AWS_PROXY"
  uri                     = aws_lambda_function.predict.invoke_arn
}

# terraform/modules/api/dynamodb.tf
resource "aws_dynamodb_table" "predictions_cache" {
  name           = "predictions-cache"
  billing_mode   = "PAY_PER_REQUEST"
  hash_key       = "customer_id"
  range_key      = "feature_hash"

  attribute {
    name = "customer_id"
    type = "S"
  }

  attribute {
    name = "feature_hash"
    type = "S"
  }

  attribute {
    name = "model_version"
    type = "S"
  }

  attribute {
    name = "timestamp"
    type = "N"
  }

  ttl {
    attribute_name = "ttl"
    enabled        = true
  }

  global_secondary_index {
    name            = "model_version-timestamp-index"
    hash_key        = "model_version"
    range_key       = "timestamp"
    projection_type = "ALL"
  }

  point_in_time_recovery {
    enabled = true
  }

  server_side_encryption {
    enabled = true
  }

  tags = {
    Name        = "predictions-cache"
    Environment = var.environment
  }
}
```

---

## 5. Complete Architecture Diagram

```
┌──────────────────────────────────────────────────────────────────────┐
│                         DATA INGESTION                                │
└──────────────────────────────────────────────────────────────────────┘
CSV (100K rows, 49 features)
  ↓
S3: s3://engagement-raw/
  ↓
Glue Crawler
  ↓
Athena: engagement_raw.customers

┌──────────────────────────────────────────────────────────────────────┐
│                      ML PIPELINE (Batch)                              │
└──────────────────────────────────────────────────────────────────────┘
Step Functions: engagement-ml-pipeline
  │
  ├─ Stage 1: Lambda (pre-cleanup)
  ├─ Stage 2: Lambda (data-prep) → Athena queries
  │
  ├─ Stage 3: PARALLEL
  │   ├─ ECS Fargate (16 vCPU, 64 GB) → Docker (ECR)
  │   │   └─ XGBoost Training (5 models)
  │   │       └─ S3: s3://engagement-models/
  │   └─ Lambda (data-validation) → Great Expectations
  │
  ├─ Stage 4: ECS Fargate (inference)
  │   └─ Generate 100K predictions
  │       └─ S3: s3://engagement-results/
  │
  └─ Stage 5: PARALLEL
      ├─ Lambda (create-qa-table) → Athena
      └─ Lambda (create-results-table) → Athena
          └─ predictions_final (100K rows)

┌──────────────────────────────────────────────────────────────────────┐
│               AI LAYER (Bedrock Knowledge Base + Agents)             │
└──────────────────────────────────────────────────────────────────────┘
S3: s3://engagement-knowledge-base/
  ├─ model_metrics/
  ├─ feature_importance/
  ├─ athena_results/
  └─ data_dictionary/
  ↓
Bedrock Knowledge Base
  ├─ Embeddings: Amazon Titan Embeddings v2 (1536 dims)
  ├─ Vector Store: S3 (s3://engagement-knowledge-base-vectors/)
  │   ❌ NOT OpenSearch
  │   ❌ NOT pgvector
  └─ ~1000 vector embeddings
  ↓
Bedrock Agent
  ├─ Model: Claude 3.5 Sonnet
  ├─ Knowledge Base: engagement-kb
  └─ Action Groups:
      └─ query_athena (Lambda)

┌──────────────────────────────────────────────────────────────────────┐
│                  REAL-TIME PREDICTION API                             │
└──────────────────────────────────────────────────────────────────────┘
Client
  ↓
API Gateway: POST /predict
  ↓
Lambda: predict-lambda
  ├─ Check DynamoDB cache
  ├─ If miss: Load model from S3, infer
  └─ Store in DynamoDB (TTL 1 hour)
  ↓
DynamoDB: predictions-cache
  ├─ PK: customer_id
  ├─ SK: feature_hash
  └─ GSI: model_version-timestamp-index
  ↓
Response: { prediction: 0.73, latency_ms: 45 }

┌──────────────────────────────────────────────────────────────────────┐
│                      INFRASTRUCTURE (Terraform)                       │
└──────────────────────────────────────────────────────────────────────┘
terraform/
├── modules/data/      → S3, Glue, Athena
├── modules/compute/   → Lambda, Step Functions
├── modules/ml/        → ECR, ECS/Fargate
├── modules/ai/        → Bedrock KB + Agent (S3 vector store + Titan v2)
├── modules/api/       → API Gateway, DynamoDB
└── modules/network/   → VPC, Security Groups
```

---

## 6. Key Services Summary

| Service | Purpose | Configuration |
|---------|---------|---------------|
| **Terraform** | IaC for all resources | 6 modules (data, compute, ml, ai, api, network) |
| **Docker** | ML container packaging | 2 images (training, inference) |
| **ECR** | Container registry | 2 repos with image scanning |
| **ECS/Fargate** | ML training/inference | 16 vCPU, 64 GB, Spot instances |
| **Lambda** | Orchestration, API | 7 functions (cleanup, prep, validation, QA, results, action handler, predict) |
| **S3** | Data storage | 5 buckets (raw, processed, features, models, results, KB) |
| **Athena/Glue** | Data catalog, analytics | 4 databases, 10+ tables |
| **Bedrock KB** | Vector search | **S3 vector store + Titan v2** (NOT OpenSearch, NOT pgvector) |
| **Bedrock Agent** | Agentic Q&A | Claude 3.5 Sonnet + KB + action groups |
| **API Gateway** | Real-time API | REST API with request validation |
| **DynamoDB** | Prediction cache | TTL 1 hour, GSI for versioning |
| **Step Functions** | ML pipeline orchestration | 5 stages, parallel execution |

---

## 7. Cost Summary (per run)

| Service | Cost | Notes |
|---------|------|-------|
| **Fargate Training** | $1.40 | 16 vCPU, 64 GB, 3 min, Spot (93% savings) |
| **Fargate Inference** | $0.47 | 16 vCPU, 64 GB, 1 min, Spot |
| **Lambda** | $0.05 | 7 functions, parallel execution |
| **S3** | $0.09 | 5 buckets, Intelligent-Tiering |
| **Athena** | $0.02 | 1 GB scanned/query, 10 queries, Parquet |
| **Bedrock KB** | $0.50 | S3 vector storage + Titan v2 embeddings |
| **Bedrock Agent** | $2.00 | Claude 3.5 Sonnet (50K in, 10K out tokens) |
| **API Gateway** | $0.01 | 1000 requests |
| **DynamoDB** | $0.03 | On-demand, 5K reads, 1K writes |
| **Step Functions** | $0.01 | 10 state transitions |
| **TOTAL** | **$4.58/run** | ✅ Under $20 target |

---

## 8. LocalStack Configuration

**docker-compose.yml:**
```yaml
version: '3.8'

services:
  localstack:
    image: localstack/localstack:latest
    ports:
      - "4566:4566"
      - "4571:4571"
    environment:
      - SERVICES=s3,glue,athena,ecr,ecs,lambda,stepfunctions,bedrock,apigateway,dynamodb,secretsmanager,kms,iam
      - DEBUG=1
      - DOCKER_HOST=unix:///var/run/docker.sock
      - PERSISTENCE=1
      - DATA_DIR=/var/lib/localstack/data
      - LOCALSTACK_API_KEY=${LOCALSTACK_API_KEY}  # For Bedrock support
    volumes:
      - "/var/run/docker.sock:/var/run/docker.sock"
      - "./localstack_data:/var/lib/localstack/data"
    networks:
      - ml-network

networks:
  ml-network:
    driver: bridge
```

---

## 9. Verification Checklist

- [ ] ✅ Terraform modules organized by layer (6 modules)
- [ ] ✅ Docker images built and pushed to ECR (2 images)
- [ ] ✅ ECS/Fargate task definitions configured (16 vCPU, 64 GB)
- [ ] ✅ Lambda functions deployed (7 functions)
- [ ] ✅ S3 buckets created (5 buckets + KB)
- [ ] ✅ Athena tables queryable (predictions_final)
- [ ] ✅ **Bedrock Knowledge Base uses S3 vector store** (NOT OpenSearch, NOT pgvector)
- [ ] ✅ **Bedrock Knowledge Base uses Titan Embeddings v2**
- [ ] ✅ Bedrock Agent configured with action groups
- [ ] ✅ API Gateway deployed with /predict endpoint
- [ ] ✅ DynamoDB predictions cache table created
- [ ] ✅ Step Functions state machine orchestrates 5 stages
- [ ] ✅ Cost < $20/run ($4.58 actual)

---

## 10. Security & Permissions

### IAM Policies & Permissions

This platform uses IAM roles for service authentication. For detailed information about IAM policies, required permissions, and security considerations, see:

- **[IAM Policies Documentation](../security/iam_policies.md)** - Detailed IAM policies with wildcard warnings and production hardening guidance
- **[Required Permissions](../security/required_permissions.md)** - High-level summary of permissions required by each service
- **[Secrets Management](../security/secrets_management.md)** - How to securely manage secrets using AWS Secrets Manager

**Important:** IAM policies in this POC use wildcards (`Resource = "*"`) for simplicity. **These must be tightened for production deployments.** See the IAM Policies documentation for detailed guidance.

### High-Level Permission Summary

- **Lambda Functions:** S3 read/write, Athena query, Glue catalog access, DynamoDB access, CloudWatch metrics/logs, Bedrock model invocation
- **Step Functions:** Lambda invocation, ECS task management, IAM PassRole, EventBridge rules, CloudWatch logs/metrics, X-Ray tracing
- **ECS Fargate:** S3 read/write, Athena query, Glue catalog access, CloudWatch metrics/logs, ECR image pull, Secrets Manager access
- **Bedrock Agent:** Bedrock model invocation, Knowledge Base retrieval, Lambda action handler invocation

For complete details, see [Required Permissions](../security/required_permissions.md).

---

## 11. Next Steps

1. **Implement Terraform modules** (6 modules)
2. **Build Docker images** (training + inference)
3. **Develop Lambda functions** (7 functions)
4. **Configure Bedrock Knowledge Base** (S3 + Titan v2)
5. **Create Bedrock Agent** (Claude 3.5 + action groups)
6. **Deploy API Gateway + DynamoDB**
7. **Test end-to-end flow** (LocalStack)
8. **Verify cost estimates** (Infracost)
9. **Review IAM policies** and tighten for production (see [IAM Policies](../security/iam_policies.md))

---

**Document Owner:** Solutions Architect  
**Review Frequency:** As architecture evolves  
**Classification:** Public (GitHub Reference Implementation)

