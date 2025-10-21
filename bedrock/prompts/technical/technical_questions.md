# Bedrock Agent Prompts - Technical & Architecture

**Category:** Technical Architecture & Implementation  
**Total Prompts:** 30 questions  
**Last Updated:** October 21, 2025

---

## Section 1: System Architecture (10 questions)

### 1.1 What is the overall system architecture?
**Expected Answer:** Describe complete architecture: Data layer (S3, Glue, Athena), ML layer (Fargate training/inference), AI layer (Bedrock KB + Agent), Orchestration (Step Functions, Lambda), API (API Gateway, DynamoDB), Infrastructure (Terraform, VPC). Include data flow diagram description.

### 1.2 How does the ML training pipeline work?
**Expected Answer:** 10-step pipeline:
1. Raw data upload (S3)
2. Pre-cleanup (Lambda)
3. Data preparation (Lambda + Athena)
4. Data validation (Lambda + Great Expectations)
5. Parallel: Training (Fargate 64GB RAM) + Feature engineering (Athena)
6. Inference (Fargate)
7. Results processing (Lambda)
8. Final tables (Lambda + Athena - QA + Results)
9. Bedrock KB sync
10. Agent ready for queries
Weekly batch, 30-minute total runtime.

### 1.3 What AWS services are used and why?
**Expected Answer:** Service catalog with justifications:
- S3: Scalable data storage (56.6 MB → TB scale)
- Glue: Data catalog, schema discovery
- Athena: Serverless SQL queries (cost-effective)
- Fargate: ML containers (64GB RAM, no server management)
- Lambda: Event-driven compute (8 functions)
- Step Functions: Workflow orchestration
- Bedrock: Conversational AI (KB + Agent)
- DynamoDB: Real-time prediction cache
- API Gateway: RESTful API layer
- VPC: Network isolation, security

### 1.4 How are models deployed to production?
**Expected Answer:** Two deployment paths:
1. Batch (weekly): Fargate container, S3 model storage, predictions to Athena + DynamoDB
2. Real-time (API): Lambda function, DynamoDB cache (updated weekly), <100ms latency, fallback to direct model inference
Model versioning in S3, automated rollback on performance degradation.

### 1.5 What is the data pipeline flow?
**Expected Answer:** CSV/Parquet → S3 → Glue crawler → Athena tables → Data prep Lambda → Training Fargate → Model S3 → Inference Fargate → Results Athena/DynamoDB → API Gateway → Applications. Include partitioning strategy (by date), compression (Parquet), and optimization (VPC endpoints).

### 1.6 How is the system secured?
**Expected Answer:** Multi-layer security:
- Encryption: AES-256 at rest, TLS 1.3 in transit
- Network: VPC isolation, private subnets, VPC endpoints (no internet)
- IAM: Least privilege, no root access, service roles
- Monitoring: CloudTrail, GuardDuty, Security Hub
- Container: ECR scanning, SBOM generation
- Secrets: AWS Secrets Manager
Compliance: SOC 2, HIPAA, GDPR, ISO 27001.

### 1.7 What is the cost breakdown?
**Expected Answer:** Monthly costs for 100K customers, weekly batch:
- S3: $5 (100 GB storage)
- Athena: $6 (50 GB scanned/week)
- Fargate: $48 (4 hrs/week, 64GB RAM)
- Lambda: $1 (1M invocations)
- Bedrock KB: $15 (100K embeddings)
- Bedrock Agent: $25 (10K queries)
- DynamoDB: $8 (1M reads, 100K writes)
- API Gateway: $0.35 (100K requests)
- CloudWatch: $10
Total: ~$118/month, $18/run

### 1.8 How does the Bedrock Knowledge Base work?
**Expected Answer:** S3-based vector store with Titan v2 embeddings:
- Documents: 5 knowledge base files (project, data, models, analytics, strategy)
- Vector store: S3 (no OpenSearch/pgvector)
- Embeddings: Amazon Titan Embeddings v2
- Retrieval: Semantic search with relevance scoring
- Agent integration: RAG (Retrieve and Generate)
- Model: Claude 3.5 Sonnet for responses

### 1.9 What monitoring and observability is in place?
**Expected Answer:** Comprehensive observability:
- SRE Golden Signals: Latency, traffic, errors, saturation
- CloudWatch: Dashboards, alarms, logs
- X-Ray: Distributed tracing
- Prometheus/Grafana: Custom metrics (optional)
- Alerts: PagerDuty integration
- Runbooks: Automated remediation
- SLOs/SLIs: 99.9% uptime, <100ms latency

### 1.10 How does the system scale?
**Expected Answer:** Horizontal scaling strategy:
- S3: Petabyte scale (no limits)
- Athena: Serverless (auto-scales)
- Fargate: Task count scaling (1 → N containers)
- Lambda: 1000 concurrent by default (configurable)
- DynamoDB: On-demand billing (auto-scales)
- API Gateway: 10K RPS default (higher available)
Current: 100K customers. Tested: 10M customers. Capacity: Unlimited with cost scaling.

---

## Section 2: ML/AI Technical (10 questions)

### 2.1 What ML frameworks and libraries are used?
**Expected Answer:** 
- Core: XGBoost (regression/classification), PyTorch (neural networks), Scikit-learn (preprocessing)
- Specialized: TensorFlow Federated, Optuna (hyperparameter tuning)
- Fairness: Fairlearn, AIF360
- Explainability: SHAP, LIME
- Monitoring: deepchecks, Great Expectations
- Orchestration: MLflow (experiment tracking)

### 2.2 How are features engineered?
**Expected Answer:** Multi-step process:
1. Raw features: 42 attributes from customer dataset
2. Derived features: engagement_velocity, social_influence_score, transaction_momentum, profile_quality_score, activity_recency_score
3. Encoding: StandardScaler (numeric), OneHotEncoder (categorical)
4. Selection: Recursive Feature Elimination (top 25 features)
5. Storage: Feature store in S3, Athena feature tables

### 2.3 What is the model training process?
**Expected Answer:** 
1. Data extraction: Athena queries
2. Train/test split: 80/20 stratified by churn
3. Preprocessing: Scaling, encoding, imputation
4. Training: XGBoost/PyTorch with cross-validation
5. Hyperparameter tuning: Optuna (100 trials)
6. Evaluation: RMSE, AUC-ROC, R², fairness metrics
7. Model artifacts: JSON/PT files to S3
8. Metadata: Metrics to JSON, model cards
Duration: 20-25 minutes for 8 models on Fargate 64GB.

### 2.4 How is model performance evaluated?
**Expected Answer:** Multi-metric evaluation:
- Regression: RMSE, MAE, R², MAPE
- Classification: AUC-ROC, Accuracy, Precision, Recall, F1
- Ranking: Precision@K, NDCG, Hit Rate
- Fairness: Demographic parity, equalized odds, calibration
- Business: ROI, lift, conversion rate
Automated testing: Unit tests, integration tests, ML model tests (pytest).

### 2.5 What prevents model overfitting?
**Expected Answer:** Multiple techniques:
- Cross-validation: 5-fold stratified
- Regularization: L1/L2 penalties, dropout
- Early stopping: Validation loss monitoring
- Max depth limits: XGBoost max_depth=7
- Ensemble methods: Multiple models, voting
- Feature selection: RFE to prevent feature explosion
- Monitoring: Train vs test performance tracking

### 2.6 How does the recommendation engine work?
**Expected Answer:** Neural Collaborative Filtering:
- Architecture: User/item embeddings → 2-layer neural network → match score
- Input: Customer ID, gig/connection ID, context features
- Training: 2M historical interactions
- Loss: Binary cross-entropy
- Optimization: Adam optimizer
- Inference: Top-K retrieval for each user
- Performance: Precision@10 82%, NDCG 0.89

### 2.7 What is the anomaly detection approach?
**Expected Answer:** Ensemble method:
1. Isolation Forest: Tree-based outlier detection
2. Autoencoders: Neural network reconstruction error
3. Ensemble: Weighted average of both scores
4. Threshold: >0.7 = investigate, >0.9 = auto-block
5. Feedback loop: Human review → model retraining
Detection types: Transaction fraud, fake profiles, bots, abuse, account takeover.

### 2.8 How is model bias detected and mitigated?
**Expected Answer:** Comprehensive fairness framework:
- Detection: 
  - 80% rule (demographic parity ratio >0.8)
  - Equalized odds (similar TPR/FPR across groups)
  - Calibration analysis
- Mitigation:
  - Pre-processing: Balanced sampling, synthetic data
  - In-processing: Adversarial debiasing, fairness constraints
  - Post-processing: Threshold optimization by group
- Monitoring: Weekly automated checks, quarterly human review
All models pass fairness audits ✅.

### 2.9 What explainability methods are used?
**Expected Answer:** Multiple techniques:
- Global: Feature importance (XGBoost), SHAP summary plots
- Local: SHAP values per prediction, LIME
- Counterfactual: "What-if" analysis
- Model cards: Performance, fairness, limitations documentation
- Business rules: Threshold explanations
Use case: Customer support can explain why customer flagged as at-risk.

### 2.10 How is the Next Best Action model trained?
**Expected Answer:** Thompson Sampling (Bayesian Bandits):
- Online learning: Continuous updates
- Action space: 8 intervention types
- Reward signal: Engagement lift (0-1)
- Exploration vs exploitation: Thompson Sampling balances automatically
- Context: User segment, time, device, history
- Update frequency: Real-time (per action outcome)
- Performance tracking: Regret minimization, conversion rate
Result: 18% uplift vs random actions.

---

## Section 3: Infrastructure & DevOps (10 questions)

### 3.1 How is infrastructure managed?
**Expected Answer:** Infrastructure as Code (Terraform):
- Modules: 6 modules (data, compute, ml, ai, api, network)
- Environments: Dev, staging, prod (planned)
- State: S3 backend with locking (DynamoDB)
- CI/CD: GitHub Actions (plan, apply, destroy)
- Validation: tfsec, Checkov, infracost
- Versioning: Git tags for releases

### 3.2 What is the CI/CD pipeline?
**Expected Answer:** GitHub Actions workflow:
1. Code push → Trigger
2. Lint: Black, isort, Flake8, mypy, Bandit
3. Test: pytest (unit, integration, ML model tests)
4. Security: Trivy, Safety, pip-audit, Prowler
5. Build: Docker images → ECR
6. Deploy: Terraform apply (auto-approve on main)
7. Smoke tests: Health checks
8. Notifications: Slack/email
DORA metrics: Deployment frequency daily, lead time <1 hour, MTTR <30 min, change failure rate <5%.

### 3.3 How is the system tested locally?
**Expected Answer:** LocalStack for local development:
- Supported: S3, Lambda, DynamoDB
- Unsupported: Athena, Glue, Fargate (native), Bedrock (native)
- Workarounds: Docker containers locally, Bedrock mocks (unittest.mock)
- Data: 100K rows generated locally ($0 cost)
- Validation: Python syntax, data quality, integration tests
- Scripts: test_localstack_s3.sh, test_lambda_functions.sh, test_dynamodb.sh, test_docker_training.sh

### 3.4 What deployment strategies are supported?
**Expected Answer:** 
- Local: LocalStack Community Edition (partial)
- AWS Free Tier: $20-30/month (12 months)
- Production AWS: $118/month (full features)
- Blue/Green: Supported via Terraform workspaces
- Canary: API Gateway stages (10% → 100%)
- Rollback: Terraform state versioning, automated on errors

### 3.5 How are secrets managed?
**Expected Answer:** AWS Secrets Manager:
- API keys: Bedrock, external services
- Database credentials: DynamoDB (if RDS added)
- Encryption keys: KMS-managed
- Rotation: Automated 90-day rotation
- Access: IAM policies (least privilege)
- Local dev: .secrets.example template, env vars

### 3.6 What disaster recovery plan exists?
**Expected Answer:** Multi-layer DR:
- Data: S3 versioning, cross-region replication (optional)
- Models: S3 versioning, multiple copies
- Infrastructure: Terraform state in S3 (versioned)
- Recovery Time Objective (RTO): 4 hours
- Recovery Point Objective (RPO): 24 hours (daily backups)
- Runbooks: Automated recovery procedures
- Testing: Quarterly DR drills

### 3.7 How is performance optimized?
**Expected Answer:** Multiple optimizations:
- Data: Parquet compression (50% smaller), partitioning (date-based)
- Compute: Fargate Spot instances (70% cost savings)
- Network: VPC endpoints (avoid NAT, faster, cheaper)
- Caching: DynamoDB for predictions (avoid recomputation)
- Queries: Athena partitioning, columnar reads
- API: CloudFront CDN (optional), API Gateway caching

### 3.8 What logging and debugging tools are available?
**Expected Answer:** Comprehensive logging:
- CloudWatch Logs: All Lambda, Fargate logs
- X-Ray: Distributed tracing, bottleneck identification
- S3 access logs: Data access auditing
- CloudTrail: API call history
- Log levels: DEBUG (dev), INFO (prod)
- Retention: 30 days (adjustable)
- Search: CloudWatch Insights queries

### 3.9 How are dependencies managed?
**Expected Answer:** 
- Python: requirements.txt (pinned versions)
- Docker: Multi-stage builds, layer caching
- Terraform: Provider versions locked
- Security scanning: Dependabot, Safety, pip-audit
- Update cadence: Monthly for non-security, immediate for CVEs
- Testing: After each dependency update

### 3.10 What is the database strategy?
**Expected Answer:** Hybrid approach:
- Analytical: Athena (S3-based, serverless SQL)
- Operational: DynamoDB (real-time predictions)
- Feature store: S3 + Athena (historical features)
- Model artifacts: S3 (versioned)
- Rationale: Cost-effective, scalable, serverless
- Future: Consider Aurora for OLTP if needed

---

**Total Technical Prompts:** 30 questions  
**Coverage:** Architecture, ML/AI, Infrastructure, DevOps  
**Complexity:** Senior engineer level  
**Expected Agent Performance:** >90% technical accuracy

