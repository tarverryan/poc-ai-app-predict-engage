# Developer Guide - Customer Engagement Prediction Platform

**Audience:** Developers, Interns, Contributors  
**Purpose:** Understand the codebase and contribute effectively  
**Difficulty:** Beginner to Intermediate

---

## 🎯 Quick Start for Developers

### What This Platform Does (In Simple Terms)

This platform predicts which customers are likely to stop using a social media/dating app, and suggests ways to keep them engaged.

**Input:** Customer behavior data (clicks, messages, time spent, etc.)  
**Output:** Predictions + recommendations for each customer  
**Method:** Machine Learning (XGBoost model)  
**Deployment:** AWS serverless infrastructure

### 3-Minute Understanding

1. **Data Generation** (`data/`) - Creates 100,000 fake customers with realistic behavior
2. **ML Training** (`fargate/training/`) - Teaches computer to predict engagement
3. **ML Inference** (`fargate/inference/`) - Makes predictions on new data
4. **Reporting** (`reports/`) - Creates PDF reports for executives
5. **Infrastructure** (`terraform/`) - AWS setup code

---

## 📁 Project Structure Explained

```
poc-ai-app-predict-engage/
│
├── data/                          # Data generation scripts
│   ├── generate_platform_data.py  # Creates 100K fake customer records
│   └── requirements.txt           # Python packages needed
│
├── reports/                       # Executive PDF report generation
│   ├── generate_ceo_*.py          # 3 report generators (run these!)
│   ├── report_styles.py           # PDF formatting/colors
│   └── output/                    # Generated PDFs go here
│
├── lambda/                        # AWS Lambda functions (serverless)
│   ├── pre_cleanup/               # Deletes old data before new run
│   ├── data_prep/                 # Prepares data for ML
│   ├── create_qa_table/           # Creates quality assurance table
│   ├── create_results_table/      # Creates final results table
│   └── ensemble/                  # Combines multiple model predictions
│
├── fargate/                       # ML training & inference (containers)
│   ├── training/                  # Trains the ML model
│   │   ├── train.py               # Main training script
│   │   ├── preprocess.py          # Cleans/prepares data
│   │   └── fairness.py            # Checks for bias
│   └── inference/                 # Makes predictions
│       └── predict.py             # Main prediction script
│
├── sql/                           # Database queries
│   ├── schema/                    # Table definitions
│   ├── analytics/                 # Analysis queries
│   └── fairness/                  # Bias detection queries
│
├── terraform/                     # Infrastructure as Code (AWS setup)
│   └── modules/                   # Reusable infrastructure components
│       ├── data/                  # S3, Glue, Athena
│       ├── compute/               # Lambda, Step Functions
│       ├── ml/                    # ECS Fargate, ECR
│       └── ai/                    # Bedrock (AI assistant)
│
├── tests/                         # Automated tests
│   └── unit/                      # Small, fast tests
│
├── scripts/                       # Helper scripts
│   ├── setup/                     # Installation scripts
│   └── testing/                   # Test runners
│
└── docs/                          # Documentation
    ├── architecture/              # How it's built
    ├── security/                  # Security details
    └── guides/                    # How-to guides
```

---

## 🔑 Key Concepts for Interns

### 1. What is "Serverless"?

**Traditional:** You rent a server 24/7, pay whether it's used or not  
**Serverless:** AWS only charges when code runs (like per-second billing)

**Example:** If ML training runs 30 minutes/week:
- Traditional server: $50/month (always on)
- Serverless (Fargate): $1.48/month (only when running)

**Services we use:**
- **Lambda:** Runs small tasks (<15 min, <10 GB memory)
- **Fargate:** Runs big tasks (ML training, 64 GB memory, 30+ min)
- **S3:** Stores files (like Dropbox but for code)
- **Athena:** SQL queries on S3 files (no database needed!)

### 2. What is Machine Learning (ML)?

**Simple explanation:** Teaching a computer to find patterns in data

**Our use case:**
- **Input:** Customer behavior (clicks, messages, time spent)
- **Pattern:** "Customers who do X are likely to churn"
- **Output:** Churn probability (0-100%)

**Example:**
```
Customer A: 
  - Last login: 20 days ago
  - Messages sent: 0 in 30 days
  - Premium: No
  → Churn probability: 85% (HIGH RISK)
  → Action: Send re-engagement email

Customer B:
  - Last login: Today
  - Messages sent: 50 in 30 days
  - Premium: Yes
  → Churn probability: 5% (LOW RISK)
  → Action: None needed
```

### 3. The Data Pipeline (Step-by-Step)

```
Week 1:                           [Weekly Batch Process]
├─ Monday 3 AM: Cleanup old data (Lambda: 30 seconds)
├─ Monday 3:01 AM: Prepare data (Lambda: 2 minutes)
├─ Monday 3:03 AM: Train ML model (Fargate: 30 minutes)
├─ Monday 3:33 AM: Make predictions (Fargate: 20 minutes)
├─ Monday 3:53 AM: Create QA table (Lambda: 30 seconds)
└─ Monday 3:54 AM: Create results table (Lambda: 1 minute)

Total time: ~55 minutes
Total cost: $0.22 (yes, 22 cents!)
```

**What happens:**
1. **Cleanup:** Delete old temporary files
2. **Prepare:** Run SQL queries to get customer data
3. **Train:** Teach ML model to predict engagement
4. **Predict:** Score all 100K customers
5. **QA:** Create table for data quality checks
6. **Results:** Combine everything into final table

### 4. How Data Flows

```
CSV File (100K customers)
    ↓
S3 Bucket (raw data storage)
    ↓
Glue Crawler (finds tables automatically)
    ↓
Athena (SQL queries on S3)
    ↓
Lambda (data prep)
    ↓
Fargate (ML training)
    ↓
S3 (model storage)
    ↓
Fargate (inference/predictions)
    ↓
Athena Table (results)
    ↓
Bedrock AI (answers business questions)
```

---

## 💻 Common Developer Tasks

### Task 1: Generate Dummy Data

```bash
# Navigate to data folder
cd data/

# Install dependencies
pip install -r requirements.txt

# Generate 100,000 fake customers (takes ~30 seconds)
python3 generate_platform_data.py

# Output:
# - data/raw/platform_engagement_dataset.csv (30.6 MB)
# - data/raw/platform_engagement_dataset.parquet (9.4 MB)
```

**What it creates:**
- 100,000 customer IDs (fake, UUID format)
- 72 behavioral features per customer
- Realistic distributions (using Faker library)
- No real PII (all synthetic)

### Task 2: Generate CEO Reports

```bash
# Navigate to reports folder
cd reports/

# Install dependencies
pip install -r requirements.txt

# Generate all 3 reports (takes ~2 minutes)
python3 generate_ceo_engagement_report.py
python3 generate_ceo_costs_report.py
python3 generate_ceo_architecture_report.py

# Output: reports/output/*.pdf (3 PDF files)
```

**What it creates:**
- Engagement Report: Business case for improving engagement
- Cost Report: AWS infrastructure cost analysis
- Architecture Report: Technical justification for service choices

### Task 3: Test Locally with LocalStack

```bash
# Install LocalStack (free local AWS simulator)
pip install localstack

# Start LocalStack
docker-compose up -d

# Run setup script
./scripts/setup/setup_localstack.sh

# Test S3
./scripts/testing/test_localstack_s3.sh

# Stop LocalStack
docker-compose down
```

**What LocalStack does:**
- Simulates AWS services on your computer (free!)
- S3, Lambda, DynamoDB, API Gateway
- Perfect for testing without AWS charges

### Task 4: Run Tests

```bash
# Install test dependencies
pip install pytest pytest-cov

# Run all tests
pytest tests/ -v

# Run with coverage report
pytest tests/ --cov=. --cov-report=html

# Open coverage report
open htmlcov/index.html
```

---

## 🐛 Debugging Tips

### Problem: "Module not found"
```bash
# Solution: Install dependencies
pip install -r requirements.txt

# Or for specific module:
pip install pandas numpy scikit-learn
```

### Problem: "Permission denied" on scripts
```bash
# Solution: Make script executable
chmod +x scripts/testing/test_components.sh

# Then run:
./scripts/testing/test_components.sh
```

### Problem: "Data file not found"
```bash
# Solution: Generate data first
cd data/
python3 generate_platform_data.py
```

### Problem: "Docker not running"
```bash
# Solution: Start Docker Desktop
# Then:
docker-compose up -d
```

---

## 📖 Code Commenting Standards

### Python Functions
```python
def calculate_engagement_score(user_data: dict) -> float:
    """
    Calculate engagement score for a user (0.0 to 1.0).
    
    This score represents how engaged a user is with the platform based on
    their activity. Higher scores = more engaged users.
    
    Args:
        user_data (dict): Dictionary containing user activity metrics
            - 'sessions_last_7_days' (int): Number of app opens
            - 'feed_time_minutes_day' (float): Avg daily feed time
            - 'posts_last_30_days' (int): Number of posts created
    
    Returns:
        float: Engagement score between 0.0 (not engaged) and 1.0 (very engaged)
    
    Example:
        >>> user = {'sessions_last_7_days': 10, 'feed_time_minutes_day': 30, 'posts_last_30_days': 5}
        >>> calculate_engagement_score(user)
        0.65
    
    Calculation:
        score = (sessions * 0.3) + (feed_time * 0.5) + (posts * 0.2)
        Normalized to 0-1 range
    """
    # Your code here
```

### SQL Queries
```sql
-- Purpose: Calculate daily active users (DAU) by engagement tier
-- Used by: Executive dashboard, engagement reports
-- Run frequency: Daily
-- Expected runtime: 2-3 seconds
-- Output: 4 rows (one per tier)

SELECT 
    -- Group users into engagement tiers (Low, Medium, High, Very High)
    CASE 
        WHEN engagement_score < 0.3 THEN 'Low'
        WHEN engagement_score < 0.5 THEN 'Medium'
        WHEN engagement_score < 0.7 THEN 'High'
        ELSE 'Very High'
    END AS engagement_tier,
    
    -- Count users who opened app today
    COUNT(DISTINCT customer_id) AS daily_active_users,
    
    -- Calculate percentage of total users
    ROUND(COUNT(DISTINCT customer_id) * 100.0 / SUM(COUNT(DISTINCT customer_id)) OVER (), 2) AS pct_of_total
    
FROM customers
WHERE app_opens_today > 0  -- Only count active users today
GROUP BY 1                  -- Group by engagement tier
ORDER BY 1;                 -- Sort by tier name
```

### Shell Scripts
```bash
#!/bin/bash
################################################################################
# Script: test_localstack_s3.sh
# Purpose: Test S3 operations in LocalStack (local AWS simulator)
# Author: Platform Team
# Usage: ./test_localstack_s3.sh
# Requirements: Docker running, LocalStack installed
################################################################################

# Exit on any error (makes debugging easier)
set -e

# Print each command before executing (helps with debugging)
set -x

# Define variables (easier to change later)
BUCKET_NAME="test-engagement-bucket"
TEST_FILE="test-data.csv"

# Step 1: Create S3 bucket in LocalStack
# --endpoint-url tells AWS CLI to use LocalStack instead of real AWS
echo "Creating S3 bucket: $BUCKET_NAME"
awslocal s3 mb s3://$BUCKET_NAME

# Step 2: Upload test file
echo "Uploading test file: $TEST_FILE"
echo "test,data" > $TEST_FILE
awslocal s3 cp $TEST_FILE s3://$BUCKET_NAME/

# Step 3: List bucket contents (verify upload)
echo "Listing bucket contents:"
awslocal s3 ls s3://$BUCKET_NAME/

# Step 4: Download file (verify it works)
echo "Downloading file:"
awslocal s3 cp s3://$BUCKET_NAME/$TEST_FILE downloaded_$TEST_FILE

# Step 5: Cleanup
echo "Cleaning up..."
rm $TEST_FILE downloaded_$TEST_FILE
awslocal s3 rb s3://$BUCKET_NAME --force

echo "✅ S3 test completed successfully!"
```

---

## 🔐 Security Guidelines

### Never Commit:
- ❌ API keys (`sk-...`, `ghp_...`)
- ❌ Passwords or tokens
- ❌ Real customer data (PII)
- ❌ AWS credentials
- ❌ `.env` files with secrets

### Always:
- ✅ Use environment variables for secrets
- ✅ Check `.gitignore` before committing
- ✅ Use synthetic data only (Faker library)
- ✅ Run `git status` before `git push`

### Checking for Secrets:
```bash
# Search for potential secrets
grep -r "sk-" --include="*.py" .
grep -r "password" --include="*.py" .
grep -r "api_key" --include="*.py" .

# If found: DO NOT COMMIT. Remove and use env vars instead.
```

---

## 📚 Additional Resources

### Learning Materials:
- **AWS Basics:** [AWS Free Tier](https://aws.amazon.com/free/)
- **Python:** [Real Python Tutorials](https://realpython.com/)
- **ML Basics:** [Google ML Crash Course](https://developers.google.com/machine-learning/crash-course)
- **SQL:** [Mode Analytics SQL Tutorial](https://mode.com/sql-tutorial/)

### Our Documentation:
- **README.md** - Project overview
- **QUICK_START_CEO.md** - 30-second exec summary
- **EXECUTIVE_BRIEFING.md** - Business case
- **COSTS_BUDGET.md** - AWS cost details
- **ARCHITECTURE_REASONING.md** - Technical decisions

### Getting Help:
1. Check relevant README in folder
2. Search codebase for examples
3. Run tests to understand behavior
4. Ask senior developer
5. Check AWS documentation

---

## 🎓 Internship Learning Path

### Week 1: Understanding
- [ ] Read this guide
- [ ] Clone repository
- [ ] Generate dummy data
- [ ] Generate CEO reports
- [ ] Understand folder structure

### Week 2: Local Development
- [ ] Install LocalStack
- [ ] Run local tests
- [ ] Understand data pipeline
- [ ] Read Lambda functions
- [ ] Read SQL queries

### Week 3: Code Contributions
- [ ] Fix a bug
- [ ] Add code comments
- [ ] Write a test
- [ ] Update documentation
- [ ] Submit first pull request

### Week 4: Feature Work
- [ ] Add new metric to reports
- [ ] Create new analysis query
- [ ] Enhance visualization
- [ ] Optimize performance
- [ ] Present your work

---

## ✅ Checklist Before Committing Code

```bash
# 1. Run tests
pytest tests/ -v

# 2. Check for secrets
grep -r "sk-" --include="*.py" .

# 3. Format code (optional but nice)
black *.py

# 4. Check what you're committing
git status
git diff

# 5. Commit with good message
git commit -m "feat: Add user segmentation analysis

- Added K-means clustering for 8 user segments
- Created segment visualization in report
- Updated tests for new functionality"

# 6. Push
git push
```

---

## 🤝 Contributing

See [CONTRIBUTING.md](CONTRIBUTING.md) for:
- Code style guide
- Pull request process
- Review checklist
- Branch naming conventions

---

**Remember:** Every expert was once a beginner. Don't hesitate to ask questions!

**Questions?** Check README.md or ask a senior developer.

