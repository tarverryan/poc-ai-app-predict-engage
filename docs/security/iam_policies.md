# IAM Policies Documentation

**Customer Engagement Prediction Platform**  
**Version:** 1.0  
**Last Updated:** 2025-10-21  
**Classification:** Public

---

## Overview

This document catalogs all IAM policies used in this platform, with special attention to policies that use wildcard (`Resource = "*"`) permissions. These wildcard policies are used for simplicity in this POC but **must be tightened for production deployments**.

---

## ⚠️ Important Warning

**This is a Proof-of-Concept (POC) / Learning Project**

- IAM policies in this repository use wildcards (`Resource = "*"`) for simplicity
- **These policies are NOT suitable for production use without modification**
- For production, replace wildcards with specific ARNs following the principle of least privilege
- See [Required Permissions](required_permissions.md) for high-level permission requirements

---

## IAM Policies with Wildcard Resources

### 1. Lambda Execution Role (`terraform/modules/compute/iam.tf`)

**Role:** `lambda_execution`

#### Wildcard Policies:

**a) Athena Permissions (`Resource = "*"`)**
```hcl
Action = [
  "athena:StartQueryExecution",
  "athena:GetQueryExecution",
  "athena:GetQueryResults",
  "athena:StopQueryExecution",
  "athena:GetWorkGroup"
]
Resource = "*"
```

**Why wildcard:** Athena workgroups don't support resource-level permissions in IAM. Workgroup-level access control must be configured in Athena itself.

**Production tightening:**
- Configure Athena workgroup-level access control
- Use workgroup-specific IAM policies if supported
- Limit to specific workgroup ARNs: `arn:aws:athena:${region}:${account}:workgroup/${workgroup-name}`

**b) Glue Permissions (`Resource = "*"`)**
```hcl
Action = [
  "glue:GetDatabase",
  "glue:GetTable",
  "glue:GetPartitions",
  "glue:CreateTable",
  "glue:UpdateTable",
  "glue:DeleteTable",
  "glue:BatchCreatePartition"
]
Resource = "*"
```

**Why wildcard:** Glue catalog permissions are often granted at database/table level, but IAM resource ARNs for Glue can be complex.

**Production tightening:**
- Limit to specific database ARNs: `arn:aws:glue:${region}:${account}:database/${database-name}`
- Limit to specific table ARNs: `arn:aws:glue:${region}:${account}:table/${database-name}/${table-name}`
- Use resource tags for additional access control

**c) CloudWatch Metrics (`Resource = "*"`)**
```hcl
Action = [
  "cloudwatch:PutMetricData"
]
Resource = "*"
```

**Why wildcard:** CloudWatch `PutMetricData` doesn't support resource-level permissions. Access is controlled via the metric namespace.

**Production tightening:**
- Use metric namespaces to scope access (e.g., `MLPipeline/*`)
- Consider using CloudWatch metric filters and alarms instead
- Monitor metric publishing via CloudTrail

**d) Bedrock Permissions (`Resource = "*"`)**
```hcl
Action = [
  "bedrock:InvokeModel",
  "bedrock:InvokeAgent",
  "bedrock:Retrieve"
]
Resource = "*"
```

**Why wildcard:** Bedrock model invocation permissions are typically granted at the account level for simplicity.

**Production tightening:**
- Limit to specific model ARNs: `arn:aws:bedrock:${region}::foundation-model/${model-id}`
- Limit to specific knowledge base ARNs: `arn:aws:bedrock:${region}:${account}:knowledge-base/${kb-id}`
- Use resource-based policies on knowledge bases

---

### 2. Step Functions Execution Role (`terraform/modules/compute/iam.tf`)

**Role:** `step_functions`

#### Wildcard Policies:

**a) ECS Task Management (`Resource = "*"`)**
```hcl
Action = [
  "ecs:RunTask",
  "ecs:StopTask",
  "ecs:DescribeTasks"
]
Resource = "*"
```

**Why wildcard:** Step Functions needs to run ECS tasks dynamically. Resource-level permissions can be complex.

**Production tightening:**
- Limit to specific cluster ARNs: `arn:aws:ecs:${region}:${account}:cluster/${cluster-name}`
- Limit to specific task definition ARNs: `arn:aws:ecs:${region}:${account}:task-definition/${family}:${revision}`
- Use task execution role for runtime permissions (already scoped)

**b) IAM PassRole (`Resource = "*"`)**
```hcl
Action = [
  "iam:PassRole"
]
Resource = "*"
Condition = {
  StringEquals = {
    "iam:PassedToService" = "ecs-tasks.amazonaws.com"
  }
}
```

**Why wildcard:** Step Functions needs to pass the ECS task execution role to ECS tasks.

**Production tightening:**
- Limit to specific role ARNs: `arn:aws:iam::${account}:role/${ecs-task-execution-role-name}`
- Use the condition to restrict to ECS service (already present)
- Consider using a dedicated role for each task type

**c) EventBridge Permissions (`Resource = "*"`)**
```hcl
Action = [
  "events:PutTargets",
  "events:PutRule",
  "events:DescribeRule"
]
Resource = "*"
```

**Why wildcard:** Step Functions may create EventBridge rules for scheduling.

**Production tightening:**
- Limit to specific rule ARNs: `arn:aws:events:${region}:${account}:rule/${rule-name}`
- Use resource tags for access control
- Consider using Step Functions native scheduling instead

**d) CloudWatch Logs (`Resource = "*"`)**
```hcl
Action = [
  "logs:CreateLogDelivery",
  "logs:GetLogDelivery",
  "logs:UpdateLogDelivery",
  "logs:DeleteLogDelivery",
  "logs:ListLogDeliveries",
  "logs:PutResourcePolicy",
  "logs:DescribeResourcePolicies",
  "logs:DescribeLogGroups"
]
Resource = "*"
```

**Why wildcard:** Step Functions needs to create log deliveries and manage log groups.

**Production tightening:**
- Limit to specific log group ARNs: `arn:aws:logs:${region}:${account}:log-group:/aws/stepfunctions/${state-machine-name}`
- Use resource-based policies on log groups
- Pre-create log groups with specific permissions

**e) CloudWatch Metrics (`Resource = "*"`)**
- Same as Lambda (see above)

**f) X-Ray Tracing (`Resource = "*"`)**
```hcl
Action = [
  "xray:PutTraceSegments",
  "xray:PutTelemetryRecords"
]
Resource = "*"
```

**Why wildcard:** X-Ray doesn't support resource-level permissions for trace segments.

**Production tightening:**
- Use sampling rules to control trace collection
- Monitor via CloudTrail
- Consider disabling X-Ray if not needed

---

### 3. ECS Execution Role (`terraform/modules/ml/iam.tf`)

**Role:** `ecs_execution`

#### Wildcard Policies:

**a) ECR Permissions (`Resource = "*"`)**
```hcl
Action = [
  "ecr:GetAuthorizationToken",
  "ecr:BatchCheckLayerAvailability",
  "ecr:GetDownloadUrlForLayer",
  "ecr:BatchGetImage"
]
Resource = "*"
```

**Why wildcard:** ECR `GetAuthorizationToken` must be `*`. Other actions can be scoped.

**Production tightening:**
- Keep `GetAuthorizationToken` as `*` (required by AWS)
- Limit `BatchGetImage` to specific repository ARNs: `arn:aws:ecr:${region}:${account}:repository/${repo-name}`
- Use repository resource policies

**b) CloudWatch Logs (`Resource = "*"`)**
```hcl
Action = [
  "logs:CreateLogStream",
  "logs:PutLogEvents"
]
Resource = "*"
```

**Why wildcard:** ECS tasks need to write to log streams dynamically.

**Production tightening:**
- Limit to specific log group ARNs: `arn:aws:logs:${region}:${account}:log-group:/ecs/${task-family}`
- Pre-create log groups with specific permissions
- Use log group resource policies

---

### 4. ECS Task Role (`terraform/modules/ml/iam.tf`)

**Role:** `ecs_task`

#### Wildcard Policies:

**a) Athena Permissions (`Resource = "*"`)**
- Same as Lambda (see above)

**b) Glue Permissions (`Resource = "*"`)**
- Same as Lambda (see above)

**c) CloudWatch Metrics (`Resource = "*"`)**
- Same as Lambda (see above)

**d) X-Ray Tracing (`Resource = "*"`)**
- Same as Step Functions (see above)

**e) CloudWatch Logs (`Resource = "*"`)**
- Same as ECS Execution Role (see above)

---

## Policies with Scoped Resources (Good Examples)

These policies demonstrate proper resource scoping:

### S3 Bucket Access
```hcl
Resource = [
  "arn:aws:s3:::${var.data_buckets.raw}",
  "arn:aws:s3:::${var.data_buckets.raw}/*",
  # ... specific buckets only
]
```
✅ **Good:** Specific bucket ARNs, not wildcards

### DynamoDB Table Access
```hcl
Resource = "arn:aws:dynamodb:${var.aws_region}:*:table/${var.project_name}-*"
```
⚠️ **Acceptable:** Scoped to project-specific tables via naming convention

### Secrets Manager Access
```hcl
Resource = "arn:aws:secretsmanager:${var.aws_region}:*:secret:${var.project_name}-*"
```
⚠️ **Acceptable:** Scoped to project-specific secrets via naming convention

---

## Production Hardening Checklist

Before deploying to production:

- [ ] Replace all `Resource = "*"` with specific ARNs
- [ ] Use resource tags for additional access control
- [ ] Enable CloudTrail for all IAM actions
- [ ] Set up IAM Access Analyzer to detect over-permissive policies
- [ ] Review and test each policy with least privilege principle
- [ ] Document any remaining wildcards with justification
- [ ] Set up budget alerts to detect unauthorized resource creation
- [ ] Use AWS Organizations SCPs to prevent wildcard policies at account level

---

## References

- [AWS IAM Best Practices](https://docs.aws.amazon.com/IAM/latest/UserGuide/best-practices.html)
- [Principle of Least Privilege](https://docs.aws.amazon.com/IAM/latest/UserGuide/best-practices.html#grant-least-privilege)
- [Required Permissions](required_permissions.md) - High-level permission requirements
- [AWS Security Best Practices](https://aws.amazon.com/architecture/security-identity-compliance/)

---

## Questions?

For questions about IAM policies:
- See [Required Permissions](required_permissions.md) for high-level requirements
- Review AWS IAM documentation for service-specific permission requirements
- Use AWS IAM Policy Simulator to test policies before deployment

