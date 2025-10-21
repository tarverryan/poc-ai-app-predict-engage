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

variable "knowledge_base_bucket_name" {
  description = "S3 bucket name for Bedrock Knowledge Base documents"
  type        = string
}

variable "knowledge_base_bucket_arn" {
  description = "S3 bucket ARN for Bedrock Knowledge Base documents"
  type        = string
}

variable "knowledge_base_vectors_bucket_name" {
  description = "S3 bucket name for Bedrock Knowledge Base vectors (S3 vector store)"
  type        = string
}

variable "knowledge_base_vectors_bucket_arn" {
  description = "S3 bucket ARN for Bedrock Knowledge Base vectors"
  type        = string
}

variable "bedrock_action_handler_lambda_arn" {
  description = "ARN of the Bedrock action handler Lambda function"
  type        = string
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

