# System Architecture Overview

**Audience:** CEO, CTO, Solution Architects  
**Purpose:** High-level view of AWS serverless architecture for customer engagement prediction

---

## Architecture Diagram

```mermaid
graph TB
    subgraph "Data Ingestion Layer"
        CSV[Customer Data CSV<br/>100K Records]
        S3_RAW[(S3 Raw Bucket<br/>Parquet Storage)]
        GLUE[AWS Glue Crawler<br/>Auto-Discovery]
    end
    
    subgraph "Analytics Layer"
        ATHENA[Amazon Athena<br/>SQL Queries<br/>Pay-per-Query]
        GLUE_CAT[(Glue Data Catalog<br/>Metadata)]
    end
    
    subgraph "Orchestration Layer"
        SF[AWS Step Functions<br/>Workflow Engine]
        CW_EVENTS[EventBridge<br/>Weekly Trigger]
    end
    
    subgraph "Compute Layer - Lambda"
        L1[Lambda: Pre-Cleanup<br/>30 sec]
        L2[Lambda: Data Prep<br/>2 min]
        L3[Lambda: Create QA Table<br/>30 sec]
        L4[Lambda: Create Results<br/>1 min]
    end
    
    subgraph "Compute Layer - ML"
        FARGATE_TRAIN[ECS Fargate: Training<br/>64GB RAM, 30 min<br/>XGBoost ML]
        FARGATE_INFER[ECS Fargate: Inference<br/>64GB RAM, 20 min<br/>Batch Predictions]
        ECR[(ECR<br/>Container Images)]
    end
    
    subgraph "AI Layer"
        BEDROCK[Amazon Bedrock<br/>Claude 3.5 Sonnet]
        BEDROCK_KB[(Bedrock Knowledge Base<br/>S3 Vector Store<br/>Titan Embeddings v2)]
        API_GW[API Gateway<br/>RESTful API]
    end
    
    subgraph "Storage & Results"
        S3_MODELS[(S3 Models Bucket<br/>Trained Models)]
        S3_RESULTS[(S3 Results Bucket<br/>Predictions)]
        ATHENA_RESULTS[(Athena Results Table<br/>Queryable)]
        DYNAMO[(DynamoDB<br/>Prediction Cache)]
    end
    
    subgraph "Monitoring & Security"
        CW[CloudWatch Logs<br/>Metrics<br/>Alarms]
        XRAY[X-Ray Tracing<br/>Performance]
        VPC[VPC Isolation<br/>Private Subnets]
        IAM[IAM Roles<br/>Least Privilege]
    end
    
    %% Data Flow
    CSV --> S3_RAW
    S3_RAW --> GLUE
    GLUE --> GLUE_CAT
    GLUE_CAT --> ATHENA
    
    %% Orchestration
    CW_EVENTS -.Weekly Trigger.-> SF
    SF --> L1
    L1 --> L2
    L2 --> FARGATE_TRAIN
    FARGATE_TRAIN --> FARGATE_INFER
    FARGATE_INFER --> L3
    L3 --> L4
    
    %% ML Process
    L2 --> ATHENA
    ATHENA --> S3_RAW
    FARGATE_TRAIN --> S3_MODELS
    S3_MODELS --> FARGATE_INFER
    FARGATE_INFER --> S3_RESULTS
    S3_RESULTS --> ATHENA_RESULTS
    
    %% Container Management
    ECR --> FARGATE_TRAIN
    ECR --> FARGATE_INFER
    
    %% AI Layer
    ATHENA_RESULTS --> BEDROCK_KB
    S3_RESULTS --> BEDROCK_KB
    BEDROCK_KB --> BEDROCK
    API_GW --> BEDROCK
    BEDROCK --> DYNAMO
    
    %% Monitoring
    SF -.logs.-> CW
    L1 -.logs.-> CW
    L2 -.logs.-> CW
    L3 -.logs.-> CW
    L4 -.logs.-> CW
    FARGATE_TRAIN -.logs.-> CW
    FARGATE_INFER -.logs.-> CW
    FARGATE_TRAIN -.traces.-> XRAY
    FARGATE_INFER -.traces.-> XRAY
    
    %% Security
    VPC -.isolates.-> FARGATE_TRAIN
    VPC -.isolates.-> FARGATE_INFER
    IAM -.controls.-> SF
    IAM -.controls.-> L1
    IAM -.controls.-> FARGATE_TRAIN
    
    classDef storage fill:#3498db,stroke:#2980b9,color:#fff
    classDef compute fill:#e74c3c,stroke:#c0392b,color:#fff
    classDef ai fill:#9b59b6,stroke:#8e44ad,color:#fff
    classDef orchestration fill:#f39c12,stroke:#e67e22,color:#fff
    classDef monitoring fill:#2ecc71,stroke:#27ae60,color:#fff
    
    class S3_RAW,S3_MODELS,S3_RESULTS,ATHENA_RESULTS,DYNAMO,GLUE_CAT,ECR storage
    class L1,L2,L3,L4,FARGATE_TRAIN,FARGATE_INFER compute
    class BEDROCK,BEDROCK_KB,API_GW ai
    class SF,CW_EVENTS orchestration
    class CW,XRAY,VPC,IAM monitoring
```

---

## Key Architecture Principles

### 1. **100% Serverless**
- **No servers to manage:** AWS handles all infrastructure
- **Auto-scaling:** Scales from 0 to millions automatically
- **Pay-per-use:** Only charged when code runs

### 2. **Event-Driven**
- **Weekly automation:** EventBridge triggers Step Functions
- **Parallel execution:** Lambda and Fargate run concurrently
- **Fault tolerance:** Automatic retries and error handling

### 3. **Cost-Optimized**
- **Fargate for ML:** 70-200× cheaper than alternatives
- **Athena:** Pay-per-query, no database management
- **S3 Intelligent-Tiering:** Automatic cost optimization

### 4. **Security-First**
- **VPC isolation:** Fargate and Lambda in private subnets
- **IAM least privilege:** Minimal permissions per service
- **Encryption:** At-rest (S3, DynamoDB) and in-transit (TLS 1.3)

---

## Architecture Decisions

| Service | Why Chosen | Alternative Rejected | Cost Savings |
|---------|-----------|---------------------|--------------|
| **ECS Fargate** | 64GB RAM, 30+ min runtime | Lambda (10GB limit, 15 min max) | 70× cheaper than SageMaker |
| **Athena** | Serverless SQL, pay-per-query | RDS ($200/month fixed) | $197/month saved |
| **S3 + Titan v2** | Built-in vector store | OpenSearch ($150/month) | $148/month saved |
| **Step Functions** | Visual workflow, fault tolerance | Custom orchestration | Faster development |
| **EventBridge** | Native AWS cron | Custom scheduler | Free tier eligible |

**Total Monthly Savings:** $345+ per month vs. traditional architecture

---

## Data Flow Summary

1. **Ingest:** CSV → S3 → Glue Crawler (auto-discovery)
2. **Prepare:** Lambda queries Athena for feature engineering
3. **Train:** Fargate trains XGBoost model on 100K records (30 min)
4. **Predict:** Fargate scores all customers (20 min)
5. **Store:** Results in Athena table (queryable SQL)
6. **AI:** Bedrock agent answers business questions

**Total Pipeline Time:** ~55 minutes  
**Total Pipeline Cost:** $0.22 per run

---

## Scalability Path

| Users | Monthly Cost | Changes Required |
|-------|-------------|------------------|
| **100K** | $12 | None (current architecture) |
| **1M** | $18 | None (auto-scales) |
| **10M** | $48 | None (auto-scales) |
| **60M** | $170 | None (auto-scales) |

**600× growth with no architecture changes** — serverless handles it automatically.

---

## Security & Compliance

- **SOC 2 Ready:** Audit logging with CloudTrail
- **HIPAA Eligible:** VPC isolation, encryption at-rest/in-transit
- **ISO 27001:** IAM least privilege, MFA enforcement
- **GDPR/CCPA:** PII pseudonymization, right-to-delete support

---

## Next Steps

1. Review [Data Flow Pipeline](02-data-flow-pipeline.md)
2. Review [ML Pipeline](03-ml-pipeline.md)
3. Review [Step Functions Orchestration](04-step-functions-workflow.md)
4. Review [Cost Optimization](07-cost-optimization.md)

