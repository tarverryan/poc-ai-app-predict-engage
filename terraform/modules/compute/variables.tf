variable "environment" {
  description = "Environment name (dev, staging, prod)"
  type        = string
  default     = "dev"
}

variable "project_name" {
  description = "Project name for resource naming"
  type        = string
  default     = "engagement-prediction"
}

variable "aws_region" {
  description = "AWS region"
  type        = string
  default     = "us-east-1"
}

variable "data_buckets" {
  description = "Map of data layer S3 bucket names"
  type = object({
    raw                    = string
    processed              = string
    features               = string
    models                 = string
    results                = string
    knowledge_base         = string
    knowledge_base_vectors = string
    athena_results         = string
  })
}

variable "glue_databases" {
  description = "Map of Glue database names"
  type = object({
    raw       = string
    processed = string
    analytics = string
    ml        = string
  })
}

variable "athena_workgroup_name" {
  description = "Name of the Athena workgroup"
  type        = string
}

variable "ecs_cluster_name" {
  description = "Name of the ECS cluster for Fargate tasks"
  type        = string
  default     = ""
}

variable "training_task_definition_arn" {
  description = "ARN of the training Fargate task definition"
  type        = string
  default     = ""
}

variable "inference_task_definition_arn" {
  description = "ARN of the inference Fargate task definition"
  type        = string
  default     = ""
}

variable "vpc_id" {
  description = "VPC ID for Lambda functions"
  type        = string
  default     = ""
}

variable "private_subnet_ids" {
  description = "Private subnet IDs for Lambda functions in VPC"
  type        = list(string)
  default     = []
}

variable "lambda_security_group_id" {
  description = "Security group ID for Lambda functions"
  type        = string
  default     = ""
}

variable "tags" {
  description = "Common tags for all resources"
  type        = map(string)
  default = {
    Project     = "engagement-prediction"
    ManagedBy   = "terraform"
    Environment = "dev"
  }
}

