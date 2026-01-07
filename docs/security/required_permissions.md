# Required Permissions - High-Level Summary

**Customer Engagement Prediction Platform**  
**Version:** 1.0  
**Last Updated:** 2025-10-21  
**Classification:** Public

---

## Overview

This document provides a high-level summary of AWS permissions required by each service in the platform. For detailed IAM policies with wildcard warnings, see [IAM Policies](iam_policies.md).

---

## Permission Summary by Service

### Lambda Functions

**Services:** `pre_cleanup`, `data_prep`, `data_validation`, `create_qa_table`, `create_results_table`, `ensemble`, `predict`, `bedrock_action_handler`

**Required Permissions:**

1. **S3 Access**
   - Read/write to raw data bucket
   - Read/write to processed data bucket
   - Read/write to features bucket
   - Read/write to models bucket
   - Read/write to results bucket
   - Read/write to Athena results bucket
   - Read from knowledge base bucket

2. **Athena Access**
   - Start query execution
   - Get query execution status
   - Get query results
   - Stop query execution
   - Access workgroup

3. **Glue Data Catalog**
   - Get database metadata
   - Get table metadata
   - Get partition metadata
   - Create/update/delete tables
   - Create partitions

4. **DynamoDB Access** (predict Lambda only)
   - GetItem, PutItem, UpdateItem, DeleteItem
   - Query, Scan
   - Scoped to project-specific tables

5. **CloudWatch**
   - Put custom metrics
   - Create log groups/streams
   - Put log events

6. **Bedrock** (bedrock_action_handler only)
   - Invoke model
   - Invoke agent
   - Retrieve from knowledge base

---

### Step Functions

**Service:** ML Pipeline Orchestration

**Required Permissions:**

1. **Lambda Invocation**
   - Invoke: `pre_cleanup`, `data_prep`, `data_validation`, `create_qa_table`, `create_results_table`

2. **ECS Task Management**
   - Run ECS tasks (training and inference)
   - Stop ECS tasks
   - Describe task status

3. **IAM PassRole**
   - Pass ECS task execution role to ECS tasks
   - Scoped to ECS service only

4. **EventBridge** (if using scheduled execution)
   - Put targets
   - Put rules
   - Describe rules

5. **CloudWatch**
   - Create log deliveries
   - Put metrics
   - Manage log groups

6. **X-Ray** (if tracing enabled)
   - Put trace segments
   - Put telemetry records

---

### ECS Fargate (Training Task)

**Service:** ML Model Training

**Required Permissions:**

1. **S3 Access**
   - Read from raw data bucket
   - Read from processed data bucket
   - Write to models bucket
   - Write to features bucket

2. **Athena Access**
   - Start query execution
   - Get query execution status
   - Get query results
   - Access workgroup

3. **Glue Data Catalog**
   - Get database/table/partition metadata
   - Create/update tables

4. **CloudWatch**
   - Put custom metrics (model accuracy, training duration)
   - Create log streams
   - Put log events

5. **X-Ray** (if tracing enabled)
   - Put trace segments
   - Put telemetry records

6. **ECR** (via execution role)
   - Get authorization token
   - Pull container images

7. **Secrets Manager** (if using secrets)
   - Get secret values
   - Scoped to project-specific secrets

---

### ECS Fargate (Inference Task)

**Service:** Batch Prediction

**Required Permissions:**

1. **S3 Access**
   - Read from models bucket
   - Read from raw/processed data (via Athena)
   - Write to results bucket

2. **Athena Access**
   - Start query execution
   - Get query execution status
   - Get query results
   - Access workgroup

3. **Glue Data Catalog**
   - Get database/table/partition metadata

4. **CloudWatch**
   - Put custom metrics (prediction latency, accuracy)
   - Create log streams
   - Put log events

5. **X-Ray** (if tracing enabled)
   - Put trace segments
   - Put telemetry records

6. **ECR** (via execution role)
   - Get authorization token
   - Pull container images

---

### Bedrock Knowledge Base

**Service:** AI Assistant Data Source

**Required Permissions:**

1. **S3 Access**
   - Read from knowledge base bucket
   - Read/write to vector store bucket

2. **Bedrock**
   - Invoke Titan Embeddings v2 model
   - Scoped to specific model ARN

---

### Bedrock Agent

**Service:** AI Assistant

**Required Permissions:**

1. **Bedrock**
   - Invoke Claude 3.5 Sonnet model
   - Retrieve from knowledge base
   - Scoped to specific model/knowledge base ARNs

2. **Lambda Invocation**
   - Invoke `bedrock_action_handler` Lambda
   - Scoped to specific Lambda ARN

---

### API Gateway

**Service:** Public API Endpoint

**Required Permissions:**

1. **Lambda Invocation**
   - Invoke `predict` Lambda
   - Scoped to specific Lambda ARN

2. **CloudWatch**
   - Put metrics (API request count, latency)
   - Create log streams
   - Put log events

---

## Permission Scoping Best Practices

### ✅ Good: Specific Resource ARNs

```hcl
Resource = [
  "arn:aws:s3:::engagement-raw-data-dev",
  "arn:aws:s3:::engagement-raw-data-dev/*"
]
```

### ⚠️ Acceptable: Scoped via Naming Convention

```hcl
Resource = "arn:aws:dynamodb:${region}:*:table/${project_name}-*"
```

### ❌ Avoid: Wildcard Resources (POC only)

```hcl
Resource = "*"  # Only for POC - tighten for production
```

---

## Production Hardening

For production deployments:

1. **Replace Wildcards**
   - Replace all `Resource = "*"` with specific ARNs
   - See [IAM Policies](iam_policies.md) for detailed guidance

2. **Use Resource Tags**
   - Tag all resources with project/environment tags
   - Use tag-based access control where possible

3. **Enable CloudTrail**
   - Log all IAM API calls
   - Monitor for unauthorized access attempts

4. **Use IAM Access Analyzer**
   - Detect over-permissive policies
   - Review findings regularly

5. **Principle of Least Privilege**
   - Grant minimum permissions required
   - Review and audit permissions quarterly

---

## Permission Dependencies

```
Step Functions
  ├── Lambda (invoke)
  └── ECS (run task)
      └── ECS Task Role (runtime permissions)
          ├── S3 (read/write)
          ├── Athena (query)
          ├── Glue (catalog)
          └── CloudWatch (metrics/logs)

Lambda Functions
  ├── S3 (read/write)
  ├── Athena (query)
  ├── Glue (catalog)
  ├── DynamoDB (cache)
  └── Bedrock (AI)

Bedrock Agent
  ├── Bedrock (models)
  └── Lambda (action handler)
```

---

## References

- [IAM Policies](iam_policies.md) - Detailed IAM policies with wildcard warnings
- [Secrets Management](secrets_management.md) - How to manage secrets securely
- [AWS IAM Best Practices](https://docs.aws.amazon.com/IAM/latest/UserGuide/best-practices.html)

---

## Questions?

For questions about required permissions:
- Review [IAM Policies](iam_policies.md) for detailed policy examples
- Check AWS service documentation for service-specific permission requirements
- Use AWS IAM Policy Simulator to test policies

