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

variable "vpc_id" {
  description = "VPC ID for Fargate tasks"
  type        = string
  default     = ""
}

variable "private_subnet_ids" {
  description = "Private subnet IDs for Fargate tasks"
  type        = list(string)
  default     = []
}

variable "fargate_security_group_id" {
  description = "Security group ID for Fargate tasks"
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

