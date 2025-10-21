# Observability & Monitoring Strategy

**Customer Engagement Prediction Platform**  
**Version:** 1.0  
**Last Updated:** 2025-10-21  
**Classification:** Internal

---

## Table of Contents

1. [Overview](#overview)
2. [The Three Pillars](#the-three-pillars)
3. [Metrics & KPIs](#metrics--kpis)
4. [Logging Strategy](#logging-strategy)
5. [Tracing & Performance](#tracing--performance)
6. [Alerting & On-Call](#alerting--on-call)
7. [Dashboards](#dashboards)
8. [MLOps Monitoring](#mlops-monitoring)
9. [Cost Monitoring](#cost-monitoring)

---

## 1. Overview

**Observability = Metrics + Logs + Traces**

This framework ensures we can:
- Detect issues **before** users are impacted
- Debug problems in **minutes, not hours**
- Understand **why** systems behave as they do
- Track **business metrics** alongside technical metrics

**Tools:**
- **Metrics:** CloudWatch Metrics, Prometheus
- **Logs:** CloudWatch Logs, Structured JSON
- **Traces:** AWS X-Ray
- **Dashboards:** CloudWatch Dashboards, Grafana
- **Alerts:** CloudWatch Alarms, PagerDuty, Slack

---

## 2. The Three Pillars

### 2.1 Metrics (What is happening?)

**Infrastructure Metrics:**
- Lambda: Invocations, Duration, Errors, Throttles, Concurrent Executions
- Fargate: CPU Utilization, Memory Utilization, Task Count
- DynamoDB: Read/Write Capacity, Throttled Requests, Latency
- S3: Bucket Size, Request Count, 4xx/5xx Errors
- Athena: Query Execution Time, Data Scanned, Failed Queries

**Application Metrics (Custom):**
- API: Request Rate, Response Time (p50, p95, p99), Error Rate
- ML Pipeline: Training Duration, Inference Latency, Model Accuracy
- Data Quality: Null Rate, Schema Violations, Outlier Count
- Business: Daily Active Users, Churn Rate, Engagement Score

### 2.2 Logs (What happened in detail?)

**Structured JSON Logging:**
```json
{
  "timestamp": "2025-10-21T10:30:00Z",
  "level": "INFO",
  "service": "engagement-predictor",
  "function": "predict",
  "customer_id": "hashed_12345",
  "model_version": "v1.0",
  "prediction": 0.73,
  "latency_ms": 45,
  "request_id": "abc-123",
  "trace_id": "xyz-789"
}
```

**Log Levels:**
- DEBUG: Detailed diagnostic info
- INFO: General informational messages
- WARN: Warning messages (handled errors)
- ERROR: Error messages (exceptions)
- CRITICAL: System failures

### 2.3 Traces (How did requests flow?)

**AWS X-Ray Tracing:**
- End-to-end request flow visualization
- Identify bottlenecks (which service is slow?)
- Detect anomalies (unusual patterns)
- Service map (dependencies)

**Trace Spans:**
```
API Gateway (10ms)
  └─ Lambda: predict (50ms)
      ├─ DynamoDB: get_cached_prediction (15ms) [CACHE MISS]
      ├─ Lambda: load_model (20ms)
      └─ XGBoost: inference (15ms)
```

---

## 3. Metrics & KPIs

### 3.1 Golden Signals (SRE)

| Signal | Metric | Target | Alert Threshold |
|--------|--------|--------|-----------------|
| **Latency** | API p95 response time | < 200ms | > 300ms |
| **Traffic** | Requests per second | Varies | N/A (informational) |
| **Errors** | Error rate (%) | < 0.1% | > 1% |
| **Saturation** | Lambda concurrent executions | < 80% | > 90% |

### 3.2 ML Model Metrics

**Training Metrics:**
- Training duration (target: < 5 min per model)
- Model accuracy (RMSE, R², AUC-ROC)
- Fairness metrics (demographic parity)

**Inference Metrics:**
- Prediction latency (p95 < 100ms)
- Throughput (predictions/sec)
- Cache hit rate (target: > 95%)

**Model Health:**
- Data drift (KS statistic < 0.1)
- Prediction drift (distribution shift)
- Feature drift (individual feature distributions)

### 3.3 Data Quality Metrics

| Metric | Target | Alert Threshold |
|--------|--------|-----------------|
| **Null Rate** | < 1% | > 5% |
| **Schema Violations** | 0 | > 10 records |
| **Outliers** | < 2% | > 5% |
| **Duplicate Records** | 0 | > 100 |
| **Freshness** | < 24 hours | > 48 hours |

### 3.4 Business Metrics

**User Engagement:**
- Daily Active Users (DAU)
- Weekly Active Users (WAU)
- DAU/WAU ratio (stickiness)

**Model Impact:**
- Churn rate (target: < 5%)
- Retention rate (target: > 85%)
- Average LTV (target: > $500)
- Engagement score (target: > 0.6)

**Financial:**
- Revenue per user (RPU)
- Customer Acquisition Cost (CAC)
- LTV/CAC ratio (target: > 3)

---

## 4. Logging Strategy

### 4.1 Log Aggregation

**CloudWatch Log Groups:**
```
/aws/lambda/pre-cleanup-lambda
/aws/lambda/data-prep-lambda
/aws/lambda/data-validation-lambda
/aws/lambda/create-qa-table-lambda
/aws/lambda/create-results-table-lambda
/ecs/training-task
/ecs/inference-task
/aws/apigateway/engagement-api
/aws/stepfunctions/ml-pipeline
```

**Log Retention:**
- Hot: 90 days (CloudWatch)
- Warm: 1 year (S3 Standard)
- Cold: 7 years (S3 Glacier)

### 4.2 Log Queries (CloudWatch Insights)

**Find errors:**
```
fields @timestamp, @message
| filter level = "ERROR"
| sort @timestamp desc
| limit 100
```

**Slow predictions:**
```
fields @timestamp, customer_id, latency_ms
| filter latency_ms > 200
| stats count() by bin(5m)
```

**Model accuracy by version:**
```
fields @timestamp, model_version, prediction, actual
| filter actual != ""
| stats avg(abs(prediction - actual)) by model_version
```

### 4.3 Sensitive Data Redaction

**PII Masking:**
```python
import hashlib

def mask_pii(value):
    """Hash PII for logging"""
    return hashlib.sha256(value.encode()).hexdigest()[:12]

# Usage
logger.info({
    "customer_id": mask_pii(customer_id),
    "prediction": score
})
```

---

## 5. Tracing & Performance

### 5.1 AWS X-Ray Configuration

**Lambda Function:**
```python
import aws_xray_sdk.core
from aws_xray_sdk.core import xray_recorder

@xray_recorder.capture('predict_engagement')
def lambda_handler(event, context):
    customer_id = event['customer_id']
    
    # Segment: Load model
    with xray_recorder.capture('load_model'):
        model = load_model_from_s3()
    
    # Segment: Inference
    with xray_recorder.capture('inference'):
        prediction = model.predict(features)
    
    return prediction
```

**Fargate Task:**
```python
# train.py
from aws_xray_sdk.core import xray_recorder

xray_recorder.configure(service='training-task')

@xray_recorder.capture('train_model')
def train():
    with xray_recorder.capture('load_data'):
        X_train, y_train = load_data()
    
    with xray_recorder.capture('xgboost_fit'):
        model.fit(X_train, y_train)
    
    with xray_recorder.capture('save_model'):
        save_to_s3(model)
```

### 5.2 Performance Targets

| Component | p50 | p95 | p99 |
|-----------|-----|-----|-----|
| **API Gateway** | 10ms | 20ms | 50ms |
| **Lambda (predict)** | 50ms | 150ms | 250ms |
| **DynamoDB read** | 5ms | 15ms | 30ms |
| **S3 read (model)** | 100ms | 200ms | 500ms |
| **XGBoost inference** | 10ms | 30ms | 50ms |

---

## 6. Alerting & On-Call

### 6.1 Alert Severities

| Severity | Response Time | Examples |
|----------|---------------|----------|
| **P0 - Critical** | 15 min | API down, data breach, model returning NaN |
| **P1 - High** | 1 hour | High error rate, slow API, training failure |
| **P2 - Medium** | 4 hours | Data drift, fairness violation, cost spike |
| **P3 - Low** | 1 business day | Minor performance degradation |
| **P4 - Info** | 1 week | Capacity planning, optimization opportunities |

### 6.2 CloudWatch Alarms

**API Error Rate:**
```hcl
resource "aws_cloudwatch_metric_alarm" "api_error_rate" {
  alarm_name          = "api-error-rate-high"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 2
  metric_name         = "4XXError"
  namespace           = "AWS/ApiGateway"
  period              = 300
  statistic           = "Sum"
  threshold           = 10
  alarm_description   = "API error rate > 1%"
  alarm_actions       = [aws_sns_topic.pagerduty.arn]
}
```

**Model Accuracy Degradation:**
```hcl
resource "aws_cloudwatch_metric_alarm" "model_accuracy" {
  alarm_name          = "model-accuracy-degraded"
  comparison_operator = "LessThanThreshold"
  evaluation_periods  = 3
  metric_name         = "ModelR2"
  namespace           = "CustomMetrics/ML"
  period              = 86400  # 1 day
  statistic           = "Average"
  threshold           = 0.75  # Alert if R² < 0.75
  alarm_description   = "Model accuracy below acceptable threshold"
  alarm_actions       = [aws_sns_topic.ml_team.arn]
}
```

**Data Drift:**
```hcl
resource "aws_cloudwatch_metric_alarm" "data_drift" {
  alarm_name          = "data-drift-detected"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 1
  metric_name         = "KSStatistic"
  namespace           = "CustomMetrics/DataQuality"
  period              = 86400
  statistic           = "Maximum"
  threshold           = 0.1
  alarm_description   = "Data distribution drift detected"
  alarm_actions       = [aws_sns_topic.data_team.arn]
}
```

### 6.3 Notification Channels

**Routing:**
```
P0 → PagerDuty (phone call) + Slack #incidents
P1 → PagerDuty (SMS) + Slack #alerts
P2 → Slack #alerts + Email
P3 → Email only
P4 → Weekly digest
```

---

## 7. Dashboards

### 7.1 Operational Dashboard (Real-Time)

**CloudWatch Dashboard:** `engagement-platform-ops`

**Widgets:**
1. **API Health**
   - Request rate (last 1 hour)
   - Error rate (%)
   - Latency (p50, p95, p99)

2. **Lambda Performance**
   - Invocations per function
   - Duration (avg, max)
   - Errors & Throttles

3. **Fargate Tasks**
   - CPU utilization
   - Memory utilization
   - Running task count

4. **Data Pipeline**
   - Step Functions execution status
   - Athena query duration
   - S3 storage size

### 7.2 ML Model Dashboard

**Custom Dashboard:** `ml-models-health`

**Widgets:**
1. **Model Accuracy** (line chart, 30 days)
   - Engagement: R²
   - Churn: AUC-ROC
   - LTV: RMSE

2. **Fairness Metrics** (bar chart)
   - Gender parity
   - Age parity
   - Location parity

3. **Prediction Distribution** (histogram)
   - Engagement scores (0-1)
   - Churn probabilities (0-1)
   - LTV estimates ($)

4. **Feature Drift** (heatmap)
   - KS statistic per feature
   - Alert if > 0.1

### 7.3 Business Dashboard

**Dashboard:** `business-metrics`

**Widgets:**
1. **User Engagement**
   - DAU, WAU, MAU
   - Session duration
   - Feature adoption

2. **Revenue Impact**
   - LTV by segment
   - CAC by channel
   - LTV/CAC ratio

3. **Model ROI**
   - Churn reduction (%)
   - Retention rate
   - Cost savings

---

## 8. MLOps Monitoring

### 8.1 Model Lifecycle Tracking

**Model Registry Metadata:**
```json
{
  "model_id": "engagement_v1.0",
  "training_date": "2025-10-21",
  "deployment_date": "2025-10-22",
  "status": "production",
  "metrics": {
    "rmse": 0.087,
    "r2": 0.823,
    "fairness": {
      "gender_parity": 0.96,
      "age_parity": 0.89
    }
  },
  "data_version": "100k_v1",
  "training_duration_min": 5,
  "last_evaluated": "2025-10-21T10:00:00Z"
}
```

### 8.2 Model Monitoring Lambda

**Function:** `model-health-check` (runs daily)

```python
def check_model_health():
    """Daily model health check"""
    results = {
        'accuracy_check': check_accuracy_degradation(),
        'fairness_check': check_fairness_metrics(),
        'drift_check': check_data_drift(),
        'performance_check': check_inference_latency()
    }
    
    # Alert if any check fails
    if any(not r['passed'] for r in results.values()):
        send_alert(results)
    
    # Log to CloudWatch
    put_metric('ModelHealth', 1 if all_passed else 0)
```

### 8.3 Automated Retraining Triggers

**Conditions for retraining:**
1. Model accuracy < 0.75 (R² drops below threshold)
2. Data drift KS statistic > 0.1
3. Fairness violation (parity < 0.80)
4. Scheduled: Every 90 days

**EventBridge Rule:**
```hcl
resource "aws_cloudwatch_event_rule" "model_retrain" {
  name                = "trigger-model-retraining"
  schedule_expression = "cron(0 2 * * ? *)"  # Daily at 2am
}

resource "aws_cloudwatch_event_target" "retrain_lambda" {
  rule = aws_cloudwatch_event_rule.model_retrain.name
  arn  = aws_lambda_function.retrain_evaluator.arn
}
```

---

## 9. Cost Monitoring

### 9.1 Cost Allocation Tags

**Tagging Strategy:**
```hcl
tags = {
  Project     = "engagement-prediction"
  Environment = "production"
  Team        = "ml-platform"
  CostCenter  = "engineering"
  Model       = "engagement|churn|ltv|recommendation|anomaly"
}
```

### 9.2 Cost Anomaly Detection

**AWS Cost Anomaly Detection:**
- Alert if daily cost > 20% above baseline
- Send to Slack #finops + email

**Budget Alerts:**
```hcl
resource "aws_budgets_budget" "monthly" {
  name         = "engagement-platform-monthly"
  budget_type  = "COST"
  limit_amount = "500"
  limit_unit   = "USD"
  time_unit    = "MONTHLY"

  notification {
    comparison_operator = "GREATER_THAN"
    threshold          = 80
    threshold_type     = "PERCENTAGE"
    notification_type  = "ACTUAL"
    subscriber_email_addresses = ["finops@company.com"]
  }
}
```

### 9.3 Cost Dashboard

**Widgets:**
1. **Daily Cost by Service** (line chart)
2. **Cost by Model** (pie chart)
3. **Cost per Prediction** (metric)
4. **Forecast vs Actual** (comparison)

**Target:** $4.42/run, $530/month (4 runs/week × 4 weeks)

---

## 10. Runbooks

### 10.1 Common Issues

#### **Issue: API Latency > 300ms**

**Diagnosis:**
1. Check X-Ray traces for bottleneck
2. Check DynamoDB throttling
3. Check Lambda cold starts

**Resolution:**
- If DynamoDB: Increase capacity
- If cold starts: Enable provisioned concurrency
- If model loading: Increase Lambda memory

#### **Issue: Model Accuracy Degraded**

**Diagnosis:**
1. Check data drift metrics
2. Compare feature distributions (train vs production)
3. Review recent data quality issues

**Resolution:**
- If data drift: Trigger retraining
- If data quality: Fix upstream pipeline
- If fairness violation: Apply bias mitigation

#### **Issue: Training Job Failed**

**Diagnosis:**
1. Check Fargate task logs (CloudWatch)
2. Check S3 data availability
3. Check memory/CPU utilization

**Resolution:**
- If OOM: Increase task memory to 128 GB
- If data missing: Check Athena queries
- If code error: Rollback to last known good version

---

## 11. SLOs & SLIs

### 11.1 Service Level Objectives

| Service | SLO | Measurement Period |
|---------|-----|-------------------|
| **API Availability** | 99.9% | 30 days |
| **API Latency** | p95 < 200ms | 24 hours |
| **Model Accuracy** | R² > 0.75 | 7 days |
| **Fairness** | Parity > 0.80 | 7 days |
| **Data Freshness** | < 24 hours | Real-time |

### 11.2 Error Budget

**Calculation:**
- SLO: 99.9% availability
- Error budget: 0.1% = 43 minutes/month

**Error Budget Policy:**
- If budget > 50% → Ship fast, take risks
- If budget < 50% → Freeze features, focus on reliability
- If budget = 0% → Incident response mode

---

## 12. References

- **SRE Book (Google):** https://sre.google/books/
- **AWS X-Ray:** https://aws.amazon.com/xray/
- **CloudWatch Best Practices:** https://docs.aws.amazon.com/AmazonCloudWatch/
- **MLOps Principles:** https://ml-ops.org/

---

**Document Owner:** SRE Team Lead  
**Review Frequency:** Quarterly  
**Next Review:** 2026-01-21  
**Classification:** Internal

