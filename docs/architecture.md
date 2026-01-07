# System Architecture

**Customer Engagement Prediction Platform**  
**Version:** 1.0  
**Last Updated:** 2025-10-21

---

## Purpose and Constraints

This is a **learning-focused proof-of-concept** that demonstrates serverless ML pipeline architecture on AWS. It is designed to explore trade-offs between managed services, not to serve as a production system.

**Key Constraints:**
- Built for learning and knowledge sharing, not production deployment
- Uses synthetic data only (100K records generated with Faker)
- Designed to run in LocalStack for zero-cost experimentation
- IAM policies use wildcards for simplicity (must be tightened for production)
- Cost-optimized for small-scale experimentation (~$12/month for 100K users)

---

## Component Responsibilities

### Data Layer

**Amazon S3**
- Stores raw customer data (Parquet format)
- Stores processed data, features, and trained models
- Stores prediction results and Athena query outputs
- Lifecycle policies manage data retention (90 days)

**AWS Glue Data Catalog**
- Discovers and catalogs data schemas automatically
- Enables SQL queries over S3 data via Athena
- Manages table metadata and partitions

**Amazon Athena**
- Executes SQL queries over S3 data
- Pay-per-query pricing (cost depends on data scanned)
- Query results stored in S3 for reuse

### Compute Layer

**AWS Lambda**
- Handles short-duration tasks (< 15 minutes)
- Data preparation, cleanup, and table creation
- Stateless functions with automatic scaling
- Cost: Pay per invocation and duration

**AWS Fargate (ECS)**
- Runs containerized ML workloads
- Training: 4 vCPU, 64GB RAM, ~30 minutes
- Inference: 4 vCPU, 64GB RAM, ~20 minutes
- Used when Lambda limits are exceeded
- Cost: Pay per vCPU-hour and GB-hour

**Amazon ECR**
- Stores Docker container images
- Training and inference containers
- Automatic vulnerability scanning

### Orchestration Layer

**AWS Step Functions**
- Coordinates the ML pipeline workflow
- Handles retries, error handling, and state management
- Provides execution visibility and debugging
- Weekly schedule via EventBridge

**Amazon EventBridge**
- Triggers weekly pipeline execution
- Cron-based scheduling (configurable)

### AI Layer

**Amazon Bedrock**
- Provides access to Claude 3.5 Sonnet for natural language Q&A
- Knowledge Base uses S3 as vector store (Titan Embeddings v2)
- Enables conversational queries over prediction results

**Amazon API Gateway**
- RESTful API endpoint for Bedrock agent
- API key authentication
- Request throttling and rate limiting

### Storage and Caching

**Amazon DynamoDB**
- Caches prediction results to avoid redundant computations
- TTL-based expiration (1 hour default)
- Reduces Fargate costs for repeated queries

### Monitoring and Security

**Amazon CloudWatch**
- Logs from all Lambda functions and Fargate tasks
- Custom metrics (model accuracy, prediction latency)
- Alarms for errors and cost thresholds

**AWS X-Ray**
- Distributed tracing across services
- Performance bottleneck identification
- Optional (can be disabled to reduce costs)

**VPC and IAM**
- VPC isolation for compute resources (optional)
- IAM roles with least-privilege principles
- Secrets stored in AWS Secrets Manager (not hardcoded)

---

## Data Flow

### Training Pipeline (Weekly)

1. **Data Ingestion**: CSV uploaded to S3 → Glue crawler discovers schema
2. **Data Preparation**: Lambda queries Athena to create train/test splits
3. **Feature Engineering**: Lambda creates feature tables via Athena
4. **Model Training**: Fargate loads data, trains XGBoost models, saves to S3
5. **Model Evaluation**: Training metrics published to CloudWatch
6. **Results Storage**: Predictions written to S3 and cataloged in Glue

### Inference Pipeline (On-Demand)

1. **Request**: API Gateway receives query
2. **Cache Check**: DynamoDB checked for cached prediction
3. **Model Loading**: If cache miss, Fargate loads model from S3
4. **Prediction**: Model generates prediction for customer features
5. **Caching**: Result stored in DynamoDB with TTL
6. **Response**: Prediction returned via API Gateway

### Failure Handling

- **Step Functions**: Automatic retries with exponential backoff
- **Lambda**: Retries handled by Step Functions, errors logged to CloudWatch
- **Fargate**: Task failures logged, manual retry required (or Step Functions can restart)
- **Athena**: Query failures logged, can be retried manually or via Lambda

---

## Cost Awareness

### Primary Cost Drivers

1. **Fargate Runtime**: Largest cost (~$8.50/month for 100K users)
   - Training: 4 vCPU × 0.5 hours × 4.33 weeks = ~$0.35/month
   - Inference: 4 vCPU × 0.33 hours × 4.33 weeks = ~$0.23/month
   - At scale (60M users): ~$3,500/month

2. **Athena Queries**: ~$1.20/month for 100K users
   - Cost = $5 per TB scanned
   - Optimized with partitioning and Parquet compression
   - At scale: ~$720/month

3. **CloudWatch Logs**: ~$1.50/month
   - Log ingestion: $0.50/GB
   - Log storage: $0.03/GB/month
   - Retention: 90 days (configurable)

4. **Step Functions**: ~$0.50/month
   - $0.025 per 1,000 state transitions
   - Weekly pipeline: ~217 transitions/month

### Scaling Considerations

- **Data Volume**: S3 storage scales linearly, but Athena costs depend on query patterns
- **Compute**: Fargate scales horizontally (multiple tasks), but costs scale linearly
- **Orchestration**: Step Functions costs scale with workflow complexity, not data volume
- **Optimization**: Partitioning, compression, and caching reduce costs at scale

---

## Security Boundaries and Assumptions

### Security Patterns

- **IAM Least Privilege**: Each service has minimal required permissions
- **No Hardcoded Secrets**: Use environment variables or Secrets Manager
- **VPC Isolation**: Optional, but recommended for production
- **Encryption**: At rest (S3, DynamoDB) and in transit (TLS)
- **Logging**: All actions logged to CloudWatch for auditability

### Assumptions

- **Sandbox Environment**: Designed for experimentation, not production
- **Synthetic Data**: No real customer data, no PII concerns
- **Single Tenant**: No multi-tenant isolation required
- **Public Repository**: Code is open source, no proprietary algorithms

### Known Limitations

- **IAM Wildcards**: Some policies use `Resource = "*"` for simplicity (documented in `docs/security/iam_policies.md`)
- **No Multi-Region**: Single region deployment (us-east-1)
- **No Disaster Recovery**: No backup/restore procedures defined
- **Limited Monitoring**: Basic CloudWatch metrics, no advanced observability

---

## References

- [Architecture Flow](architecture/architecture_flow.md) - Detailed end-to-end flow
- [Architecture Diagrams](diagrams/) - Visual documentation
- [IAM Policies](security/iam_policies.md) - Detailed IAM policy documentation
- [Cost Safeguards](deployment/cost_safeguards.md) - Cost optimization strategies
- [Troubleshooting Guide](guides/troubleshooting.md) - Common issues and solutions

---

## Questions?

For questions about the architecture:
- Review [Architecture Flow](architecture/architecture_flow.md) for detailed flows
- Check [Architecture Diagrams](diagrams/) for visual documentation
- See [Lessons Learned](lessons-learned.md) for practical insights

