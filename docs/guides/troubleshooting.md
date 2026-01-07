# Troubleshooting Guide

**Customer Engagement Prediction Platform**  
**Version:** 1.0  
**Last Updated:** 2025-10-21  
**Classification:** Public

---

## Overview

This guide helps you diagnose and fix common issues in the Customer Engagement Prediction Platform. For detailed architecture information, see [Architecture Flow](../architecture/architecture_flow.md).

---

## Quick Reference

### Where to Look for Errors

| Component | Log Location | Console |
|-----------|-------------|---------|
| **Lambda Functions** | CloudWatch Logs: `/aws/lambda/{function-name}` | AWS Console → Lambda → Monitor |
| **Step Functions** | Execution History | AWS Console → Step Functions → Executions |
| **ECS Fargate Tasks** | CloudWatch Logs: `/ecs/{task-family}` | AWS Console → ECS → Tasks → Logs |
| **API Gateway** | CloudWatch Logs: `/aws/apigateway/{api-name}` | AWS Console → API Gateway → Logs |
| **Athena Queries** | Query History | AWS Console → Athena → History |
| **Bedrock** | CloudWatch Logs: `/aws/bedrock/{agent-name}` | AWS Console → Bedrock → Logs |

---

## Common Issues and Solutions

### 1. Step Functions Execution Fails

#### Symptoms
- Step Functions execution shows "Failed" status
- Error message in execution history

#### Diagnosis

**Step 1: Check Execution History**
```bash
aws stepfunctions describe-execution \
  --execution-arn <execution-arn> \
  --query 'error' \
  --output text
```

**Step 2: Check Lambda Logs**
```bash
# Find the failed step
aws stepfunctions get-execution-history \
  --execution-arn <execution-arn> \
  --query 'events[?type==`LambdaFunctionFailed`]'
```

**Step 3: View CloudWatch Logs**
- Navigate to CloudWatch → Log Groups
- Find `/aws/lambda/{function-name}`
- Check recent log streams for errors

#### Common Causes and Fixes

**a) Lambda Timeout**
```
Error: Task timed out after 900.00 seconds
```

**Fix:**
- Increase Lambda timeout (max 15 minutes)
- Optimize Lambda code (reduce processing time)
- Consider moving to Fargate for long-running tasks

**b) Lambda Memory Error**
```
Error: Runtime.OutOfMemoryError
```

**Fix:**
- Increase Lambda memory allocation
- Optimize data processing (process in batches)
- Use streaming for large datasets

**c) S3 Access Denied**
```
Error: AccessDenied: Access Denied
```

**Fix:**
- Check IAM role has S3 permissions
- Verify bucket name is correct
- Check bucket policy allows Lambda role

**d) Athena Query Failed**
```
Error: SYNTAX_ERROR: line 1:1: Column 'x' cannot be resolved
```

**Fix:**
- Verify Glue table schema matches data
- Check column names (case-sensitive)
- Run `MSCK REPAIR TABLE` to update partitions

---

### 2. ECS Fargate Task Fails

#### Symptoms
- Task shows "STOPPED" status
- Exit code is non-zero
- No predictions generated

#### Diagnosis

**Step 1: Check Task Status**
```bash
aws ecs describe-tasks \
  --cluster <cluster-name> \
  --tasks <task-id> \
  --query 'tasks[0].{status:lastStatus,exitCode:containers[0].exitCode,reason:stoppedReason}'
```

**Step 2: Check CloudWatch Logs**
```bash
# View recent logs
aws logs tail /ecs/training-task --follow
```

**Step 3: Check Task Definition**
```bash
aws ecs describe-task-definition \
  --task-definition <task-definition> \
  --query 'taskDefinition.containerDefinitions[0].environment'
```

#### Common Causes and Fixes

**a) Out of Memory**
```
Error: Container killed due to memory limit
```

**Fix:**
- Increase Fargate memory (current: 64GB, max: 120GB)
- Optimize model loading (load only needed models)
- Process data in smaller batches

**b) Model Not Found**
```
Error: FileNotFoundError: models/engagement_latest.pkl
```

**Fix:**
- Verify model exists in S3: `aws s3 ls s3://{models-bucket}/models/`
- Check MODEL_VERSION environment variable
- Verify training task completed successfully

**c) Athena Connection Error**
```
Error: Unable to connect to Athena
```

**Fix:**
- Check VPC endpoint configuration (if in VPC)
- Verify IAM role has Athena permissions
- Check Athena workgroup exists

**d) S3 Access Denied**
```
Error: AccessDenied when accessing S3
```

**Fix:**
- Verify ECS task role has S3 permissions
- Check bucket policy
- Verify bucket names in environment variables

---

### 3. Athena Query Errors

#### Symptoms
- Query fails with syntax error
- Query returns no results
- Query scans too much data (high cost)

#### Diagnosis

**Step 1: Check Query Syntax**
```sql
-- Test query
SELECT COUNT(*) FROM engagement_raw.customers LIMIT 1;
```

**Step 2: Check Table Schema**
```sql
-- View table schema
SHOW CREATE TABLE engagement_raw.customers;
```

**Step 3: Check Partitions**
```sql
-- List partitions
SHOW PARTITIONS engagement_raw.customers;
```

#### Common Causes and Fixes

**a) Table Not Found**
```
Error: Table 'engagement_raw.customers' not found
```

**Fix:**
- Verify Glue database exists: `aws glue get-database --name engagement_raw`
- Verify table exists: `aws glue get-table --database-name engagement_raw --name customers`
- Run Glue crawler to create table

**b) Partition Not Found**
```
Error: Partition not found
```

**Fix:**
- Run `MSCK REPAIR TABLE engagement_raw.customers` to register partitions
- Manually add partition:
  ```sql
  ALTER TABLE engagement_raw.customers
  ADD PARTITION (year=2025, month=10, day=21)
  LOCATION 's3://bucket/data/year=2025/month=10/day=21/';
  ```

**c) High Data Scan Cost**
```
Warning: Query scanned 100GB (cost: $0.50)
```

**Fix:**
- Add partition filters: `WHERE year=2025 AND month=10`
- Use columnar format (Parquet) instead of CSV
- Compress data (Snappy compression)
- Use LIMIT clause for testing

---

### 4. Lambda Function Errors

#### Symptoms
- Lambda invocation fails
- Timeout errors
- Memory errors

#### Diagnosis

**Step 1: Check Lambda Logs**
```bash
aws logs tail /aws/lambda/{function-name} --follow
```

**Step 2: Check Lambda Metrics**
```bash
aws cloudwatch get-metric-statistics \
  --namespace AWS/Lambda \
  --metric-name Duration \
  --dimensions Name=FunctionName,Value={function-name} \
  --start-time $(date -u -d '1 hour ago' +%Y-%m-%dT%H:%M:%S) \
  --end-time $(date -u +%Y-%m-%dT%H:%M:%S) \
  --period 300 \
  --statistics Average,Maximum
```

**Step 3: Test Lambda Locally**
```python
# Test handler
import json
from handler import lambda_handler

event = {
    'body': json.dumps({'customer_features': {...}})
}
context = None

result = lambda_handler(event, context)
print(result)
```

#### Common Causes and Fixes

**a) Import Error**
```
Error: No module named 'boto3'
```

**Fix:**
- Add `boto3` to `requirements.txt`
- Deploy Lambda with updated dependencies
- Use Lambda layers for large dependencies

**b) Environment Variable Missing**
```
Error: KeyError: 'MODELS_BUCKET'
```

**Fix:**
- Check Lambda environment variables in console
- Verify all required variables are set
- Use default values in code: `os.getenv('VAR', 'default')`

**c) DynamoDB Throttling**
```
Error: ProvisionedThroughputExceededException
```

**Fix:**
- Increase DynamoDB read/write capacity
- Enable auto-scaling
- Add exponential backoff retry logic

---

### 5. Bedrock Agent Errors

#### Symptoms
- Agent returns error
- No response from agent
- Action handler fails

#### Diagnosis

**Step 1: Check Agent Logs**
```bash
aws logs tail /aws/bedrock/{agent-name} --follow
```

**Step 2: Check Action Handler Lambda**
```bash
aws logs tail /aws/lambda/bedrock-action-handler --follow
```

**Step 3: Test Knowledge Base**
```bash
aws bedrock-runtime retrieve \
  --knowledge-base-id <kb-id> \
  --retrieval-query "test query"
```

#### Common Causes and Fixes

**a) Knowledge Base Not Synced**
```
Error: No results from knowledge base
```

**Fix:**
- Check knowledge base sync status in console
- Re-sync knowledge base: `aws bedrock-agent start-ingestion-job --knowledge-base-id <kb-id>`
- Verify S3 bucket has data

**b) Action Handler Timeout**
```
Error: Lambda function timed out
```

**Fix:**
- Increase Lambda timeout (max 15 minutes)
- Optimize action handler code
- Check Athena query performance

**c) Model Access Denied**
```
Error: AccessDenied when invoking model
```

**Fix:**
- Verify IAM role has `bedrock:InvokeModel` permission
- Check model ARN is correct
- Verify model is available in your region

---

### 6. API Gateway Errors

#### Symptoms
- API returns 500 error
- Request times out
- CORS errors

#### Diagnosis

**Step 1: Check API Gateway Logs**
```bash
aws logs tail /aws/apigateway/{api-name} --follow
```

**Step 2: Check Lambda Logs**
```bash
aws logs tail /aws/lambda/predict --follow
```

**Step 3: Test API Endpoint**
```bash
curl -X POST https://{api-id}.execute-api.{region}.amazonaws.com/v1/predict \
  -H "Content-Type: application/json" \
  -H "x-api-key: {api-key}" \
  -d '{"customer_features": {...}}'
```

#### Common Causes and Fixes

**a) API Key Missing**
```
Error: Forbidden: Missing Authentication Token
```

**Fix:**
- Include `x-api-key` header in request
- Verify API key is valid: `aws apigateway get-api-key --api-key {key-id}`
- Check API key is associated with usage plan

**b) Lambda Integration Error**
```
Error: Internal server error
```

**Fix:**
- Check Lambda function logs
- Verify Lambda function exists and is deployed
- Check IAM role has `lambda:InvokeFunction` permission

**c) CORS Error**
```
Error: CORS policy: No 'Access-Control-Allow-Origin' header
```

**Fix:**
- Enable CORS in API Gateway
- Add CORS headers in Lambda response
- Configure allowed origins

---

## Debugging Commands

### View Recent Errors

```bash
# Lambda errors
aws logs filter-log-events \
  --log-group-name /aws/lambda/{function-name} \
  --filter-pattern "ERROR" \
  --start-time $(date -u -d '1 hour ago' +%s)000

# Step Functions errors
aws stepfunctions list-executions \
  --state-machine-arn <arn> \
  --status-filter FAILED \
  --max-results 10

# ECS task errors
aws ecs list-tasks \
  --cluster <cluster> \
  --desired-status STOPPED \
  --max-results 10
```

### Check Resource Status

```bash
# S3 buckets
aws s3 ls

# Lambda functions
aws lambda list-functions --query 'Functions[?contains(FunctionName, `engagement`)].FunctionName'

# ECS clusters
aws ecs list-clusters

# Step Functions state machines
aws stepfunctions list-state-machines
```

### Test Connectivity

```bash
# Test S3 access
aws s3 ls s3://{bucket-name}/

# Test Athena query
aws athena start-query-execution \
  --query-string "SELECT 1" \
  --work-group {workgroup}

# Test Lambda invocation
aws lambda invoke \
  --function-name {function-name} \
  --payload '{}' \
  response.json
```

---

## Performance Optimization

### Slow Lambda Functions

**Symptoms:** Lambda duration > 5 seconds

**Fixes:**
- Increase memory allocation (more CPU)
- Optimize code (reduce processing)
- Use Lambda layers for dependencies
- Enable Lambda provisioned concurrency

### Slow Athena Queries

**Symptoms:** Query duration > 30 seconds

**Fixes:**
- Partition data by date
- Use Parquet format (not CSV)
- Compress data (Snappy)
- Add LIMIT clause for testing
- Use query result caching

### High Fargate Costs

**Symptoms:** Fargate costs > $100/month

**Fixes:**
- Right-size memory (monitor actual usage)
- Use Spot capacity for training (70% savings)
- Schedule training during off-peak hours
- Optimize model size (quantization)

---

## Getting Help

### Documentation
- [Architecture Flow](../architecture/architecture_flow.md) - System architecture
- [Developer Guide](DEVELOPER_GUIDE.md) - Setup and development
- [Cost Safeguards](../deployment/cost_safeguards.md) - Cost optimization

### AWS Support
- **Basic Support:** AWS Support Center
- **Developer Support:** AWS Support (paid)
- **Enterprise Support:** 24/7 support (paid)

### Community
- GitHub Issues: Report bugs and request features
- GitHub Discussions: Ask questions and share solutions

---

## Prevention Best Practices

1. **Monitor Proactively**
   - Set up CloudWatch alarms for errors
   - Monitor cost daily
   - Review logs weekly

2. **Test Before Deploy**
   - Test locally with LocalStack
   - Run integration tests
   - Verify all environment variables

3. **Use Infrastructure as Code**
   - Deploy with Terraform
   - Version control all changes
   - Review changes before applying

4. **Document Changes**
   - Update documentation
   - Document environment variables
   - Record troubleshooting steps

---

## Questions?

For questions about troubleshooting:
- Check CloudWatch Logs first
- Review this guide for common issues
- See [Developer Guide](DEVELOPER_GUIDE.md) for setup help
- Open a GitHub Issue for bugs

