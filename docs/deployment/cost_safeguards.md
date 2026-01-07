# Cost Safeguards and Budget Controls

**Customer Engagement Prediction Platform**  
**Version:** 1.0  
**Last Updated:** 2025-10-21  
**Classification:** Public

---

## Overview

This document describes cost drivers, safeguards, and optimization strategies for the Customer Engagement Prediction Platform. **Always run in a sandbox AWS account with budget alerts enabled.**

---

## ⚠️ Cost Warning

**Before deploying to AWS:**

1. **Use a sandbox account** - Never deploy to production accounts without proper cost controls
2. **Set AWS Budgets** - Configure budget alerts at 50%, 80%, and 100% of expected spend
3. **Enable MFA** - Require MFA for all IAM users to prevent unauthorized deployments
4. **Review this document** - Understand cost drivers before deployment

---

## Cost Drivers

### Primary Cost Drivers

| Service | Cost Driver | 100K Users | 60M Users |
|---------|-------------|------------|-----------|
| **ECS Fargate** | Runtime (64GB RAM, 4 vCPU) | $8.50/month | $5,100/month |
| **Athena** | Data scanned per query | $1.20/month | $720/month |
| **CloudWatch Logs** | Log ingestion + storage | $1.50/month | $900/month |
| **Step Functions** | State transitions | $0.50/month | $300/month |
| **S3 Storage** | Data stored | $0.30/month | $180/month |
| **Bedrock** | Model invocations | $0.50/month | $300/month |
| **Total** | | **~$12/month** | **~$7,700/month** |

*See [Cost Analysis](../executive/COSTS_BUDGET.md) for detailed breakdowns*

### Cost Breakdown by Component

#### 1. ECS Fargate (Largest Cost Driver)

**Training Task:**
- 4 vCPU, 64GB RAM
- Runtime: ~30 minutes per week
- Cost: $0.04048 per vCPU-hour × 4 vCPU × 0.5 hours × 4.33 weeks = **$0.35/month**
- **At scale (60M users):** ~210 hours/month = **$2,100/month**

**Inference Task:**
- 4 vCPU, 64GB RAM
- Runtime: ~20 minutes per week
- Cost: $0.04048 per vCPU-hour × 4 vCPU × 0.33 hours × 4.33 weeks = **$0.23/month**
- **At scale (60M users):** ~140 hours/month = **$1,400/month**

**Safeguards:**
- Set Fargate task timeout (max 1 hour)
- Use Spot capacity for non-critical workloads (70% savings)
- Right-size memory allocation (monitor actual usage)
- Schedule training during off-peak hours

#### 2. Athena Queries

**Cost:** $5 per TB scanned

**Weekly Queries:**
- Data prep: ~50GB scanned = $0.25
- Training data load: ~50GB scanned = $0.25
- Inference data load: ~50GB scanned = $0.25
- Analytics queries: ~50GB scanned = $0.25
- **Monthly:** ~$4.33

**Safeguards:**
- **Partition data** by date (reduces scan size by 90%+)
- **Compress data** (Parquet with Snappy: 10x compression)
- **Use columnar formats** (Parquet instead of CSV)
- **Cache query results** (S3 result caching)
- **Set query result size limits** (prevent runaway queries)
- **Monitor data scanned** via CloudWatch metrics

**Optimization Example:**
```sql
-- ❌ BAD: Scans entire table (100GB)
SELECT * FROM customers;

-- ✅ GOOD: Scans only recent partition (10GB)
SELECT * FROM customers
WHERE year = 2025 AND month = 10;
```

#### 3. CloudWatch Logs

**Cost:** $0.50 per GB ingested, $0.03 per GB stored

**Monthly Usage (100K users):**
- Lambda logs: ~2GB ingested = $1.00
- Fargate logs: ~0.5GB ingested = $0.25
- Storage: ~2.5GB × $0.03 = $0.08
- **Total:** ~$1.33/month

**Safeguards:**
- **Set log retention** (90 days default, archive older logs to S3)
- **Use log filtering** (reduce ingestion volume)
- **Compress logs** (enable compression)
- **Archive to S3** (cheaper storage: $0.023/GB)
- **Disable verbose logging** in production

**Terraform Example:**
```hcl
resource "aws_cloudwatch_log_group" "lambda_logs" {
  name              = "/aws/lambda/${var.function_name}"
  retention_in_days = 90  # Auto-delete after 90 days
  
  tags = var.tags
}
```

#### 4. Step Functions

**Cost:** $0.025 per 1,000 state transitions

**Monthly Usage:**
- Weekly pipeline: ~50 transitions × 4.33 weeks = 217 transitions
- Cost: 217 / 1,000 × $0.025 = **$0.005/month**

**Safeguards:**
- Set execution timeout (prevent runaway executions)
- Monitor execution history for failures
- Use Express Workflows for high-volume, short-duration workflows (cheaper)

#### 5. S3 Storage

**Cost:** $0.023 per GB/month (Standard)

**Monthly Usage:**
- Raw data: ~10GB = $0.23
- Processed data: ~5GB = $0.12
- Models: ~1GB = $0.02
- **Total:** ~$0.37/month

**Safeguards:**
- **Lifecycle policies** - Move old data to cheaper storage classes
- **Delete old data** - Auto-delete after retention period
- **Compress data** - Use Parquet instead of CSV (10x smaller)
- **Enable S3 Intelligent-Tiering** - Automatic cost optimization

**Terraform Example:**
```hcl
resource "aws_s3_bucket_lifecycle_configuration" "data_retention" {
  bucket = aws_s3_bucket.data.id

  rule {
    id     = "delete-old-data"
    status = "Enabled"

    expiration {
      days = 90  # Delete data older than 90 days
    }
  }

  rule {
    id     = "move-to-glacier"
    status = "Enabled"

    transition {
      days          = 30
      storage_class = "GLACIER"  # Cheaper storage
    }
  }
}
```

#### 6. Bedrock (AI Assistant)

**Cost:** Pay per token (varies by model)

**Monthly Usage:**
- Claude 3.5 Sonnet: ~$0.003 per 1K input tokens, $0.015 per 1K output tokens
- Estimated: 100 queries/month × 1K tokens = **~$0.50/month**

**Safeguards:**
- **Cache responses** - Use DynamoDB to cache common queries
- **Limit query complexity** - Set max tokens per query
- **Monitor usage** - Set CloudWatch alarms for high usage
- **Use cheaper models** - Claude Haiku for simple queries

---

## AWS Budgets Configuration

### Setting Up Budgets

**Via AWS Console:**
1. Navigate to AWS Budgets
2. Click "Create budget"
3. Choose "Cost budget"
4. Set amount (e.g., $50 for sandbox, $1,000 for production)
5. Configure alerts at 50%, 80%, and 100%
6. Add email/SNS notifications

**Via Terraform:**
```hcl
resource "aws_budgets_budget" "platform_budget" {
  name              = "${var.project_name}-monthly-budget"
  budget_type       = "COST"
  limit_amount      = "50"  # $50/month
  limit_unit        = "USD"
  time_period_start = "2025-01-01_00:00"
  time_unit         = "MONTHLY"

  notification {
    comparison_operator        = "GREATER_THAN"
    threshold                  = 50  # Alert at 50% of budget
    threshold_type             = "PERCENTAGE"
    notification_type          = "ACTUAL"
    subscriber_email_addresses = [var.budget_alert_email]
  }

  notification {
    comparison_operator        = "GREATER_THAN"
    threshold                  = 80  # Alert at 80% of budget
    threshold_type             = "PERCENTAGE"
    notification_type          = "ACTUAL"
    subscriber_email_addresses = [var.budget_alert_email]
  }

  notification {
    comparison_operator        = "GREATER_THAN"
    threshold                  = 100  # Alert at 100% of budget
    threshold_type             = "PERCENTAGE"
    notification_type          = "ACTUAL"
    subscriber_email_addresses = [var.budget_alert_email]
  }
}
```

### Budget Recommendations

| Environment | Monthly Budget | Alert Thresholds |
|-------------|---------------|------------------|
| **Sandbox** | $50 | 50%, 80%, 100% |
| **Development** | $200 | 50%, 80%, 100% |
| **Staging** | $500 | 50%, 80%, 100% |
| **Production** | Based on usage | 50%, 80%, 100% |

---

## CloudWatch Cost Alarms

### Setting Up Cost Alarms

**Via AWS Console:**
1. Navigate to CloudWatch → Alarms
2. Create alarm for "EstimatedCharges" metric
3. Set threshold (e.g., $10 for sandbox)
4. Configure SNS notification

**Via Terraform:**
```hcl
resource "aws_cloudwatch_metric_alarm" "cost_alarm" {
  alarm_name          = "${var.project_name}-cost-alarm"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 1
  metric_name         = "EstimatedCharges"
  namespace           = "AWS/Billing"
  period              = 86400  # 24 hours
  statistic           = "Maximum"
  threshold           = 10  # $10
  alarm_description   = "Alert when estimated charges exceed $10"
  alarm_actions       = [aws_sns_topic.cost_alerts.arn]

  dimensions = {
    Currency = "USD"
  }
}
```

---

## Cost Optimization Strategies

### 1. Data Partitioning (Athena)

**Before (scans 100GB):**
```sql
SELECT * FROM customers WHERE signup_date > '2025-01-01';
-- Cost: 100GB × $5/TB = $0.50 per query
```

**After (scans 10GB with partitioning):**
```sql
SELECT * FROM customers 
WHERE year = 2025 AND month >= 1 
  AND signup_date > '2025-01-01';
-- Cost: 10GB × $5/TB = $0.05 per query (90% savings)
```

**Implementation:**
- Partition by `year`, `month`, `day` in Glue table definition
- Use `MSCK REPAIR TABLE` to register partitions
- Query only required partitions

### 2. Data Compression (S3 + Athena)

**Before (CSV, 100GB):**
- Storage: 100GB × $0.023 = $2.30/month
- Athena scan: 100GB × $5/TB = $0.50 per query

**After (Parquet + Snappy, 10GB):**
- Storage: 10GB × $0.023 = $0.23/month (90% savings)
- Athena scan: 10GB × $5/TB = $0.05 per query (90% savings)

### 3. Lifecycle Policies (S3)

**Strategy:**
- **Hot tier (0-30 days):** S3 Standard
- **Warm tier (30-90 days):** S3 Standard-IA ($0.0125/GB)
- **Cold tier (90-365 days):** S3 Glacier ($0.004/GB)
- **Archive tier (365+ days):** Delete or Glacier Deep Archive ($0.00099/GB)

**Monthly Savings:** ~70% on old data storage

### 4. Log Retention (CloudWatch)

**Strategy:**
- **Hot logs (0-7 days):** CloudWatch Logs
- **Warm logs (7-90 days):** CloudWatch Logs
- **Cold logs (90+ days):** Archive to S3, delete after 1 year

**Monthly Savings:** ~50% on log storage

### 5. Fargate Spot Capacity

**Strategy:**
- Use Spot capacity for training tasks (non-critical)
- 70% cost savings vs On-Demand
- Accept interruptions (retry on failure)

**Monthly Savings:** ~70% on Fargate costs

---

## Cost Monitoring Dashboard

### CloudWatch Dashboard Metrics

Create a dashboard with:
- **Estimated charges** (AWS/Billing)
- **Fargate CPU/Memory utilization** (ECS/ContainerInsights)
- **Athena data scanned** (custom metric)
- **S3 bucket size** (S3/StorageMetrics)
- **CloudWatch log ingestion** (Logs/MetricFilter)

### Cost Allocation Tags

Tag all resources for cost tracking:

```hcl
tags = {
  Project     = "engagement-platform"
  Environment = "dev"
  Component   = "ml-pipeline"
  CostCenter  = "engineering"
}
```

**Benefits:**
- Track costs by project/environment
- Identify cost drivers
- Allocate costs to teams

---

## Emergency Cost Controls

### 1. Stop All Resources

**Lambda:**
```bash
aws lambda list-functions --query 'Functions[?contains(FunctionName, `engagement`)].FunctionName' | \
  xargs -I {} aws lambda delete-function --function-name {}
```

**ECS Tasks:**
```bash
aws ecs list-tasks --cluster engagement-cluster | \
  xargs -I {} aws ecs stop-task --cluster engagement-cluster --task {}
```

**Step Functions:**
```bash
aws stepfunctions list-executions --state-machine-arn <arn> | \
  jq -r '.executions[].executionArn' | \
  xargs -I {} aws stepfunctions stop-execution --execution-arn {}
```

### 2. Delete Test Data

```bash
# Delete S3 buckets (careful - irreversible!)
aws s3 rm s3://engagement-raw-data-dev --recursive
aws s3 rm s3://engagement-processed-data-dev --recursive
```

### 3. Disable Scheduled Executions

```bash
# Disable EventBridge rule
aws events disable-rule --name engagement-weekly-pipeline
```

---

## Cost Estimation Tools

### AWS Pricing Calculator

1. Navigate to [AWS Pricing Calculator](https://calculator.aws/)
2. Add services: ECS Fargate, Athena, CloudWatch, S3, Step Functions, Bedrock
3. Configure usage (see [Cost Analysis](../executive/COSTS_BUDGET.md))
4. Review estimate

### Terraform Cost Estimation

Use [infracost](https://www.infracost.io/) to estimate Terraform costs:

```bash
infracost breakdown --path terraform/
```

---

## References

- [Cost Analysis](../executive/COSTS_BUDGET.md) - Detailed cost breakdowns
- [AWS Pricing](https://aws.amazon.com/pricing/) - Official pricing documentation
- [AWS Cost Optimization](https://aws.amazon.com/pricing/cost-optimization/) - Best practices
- [AWS Budgets Documentation](https://docs.aws.amazon.com/cost-management/latest/userguide/budgets-managing-costs.html)

---

## Questions?

For questions about costs:
- Review [Cost Analysis](../executive/COSTS_BUDGET.md) for detailed breakdowns
- Use AWS Cost Explorer to analyze actual spend
- Set up budget alerts before deployment
- Contact AWS Support for cost optimization recommendations

