# Outputs for ML Module

# ECR Repositories
output "training_ecr_repository_url" {
  description = "URL of the training ECR repository"
  value       = aws_ecr_repository.training.repository_url
}

output "training_ecr_repository_arn" {
  description = "ARN of the training ECR repository"
  value       = aws_ecr_repository.training.arn
}

output "training_ecr_repository_name" {
  description = "Name of the training ECR repository"
  value       = aws_ecr_repository.training.name
}

output "inference_ecr_repository_url" {
  description = "URL of the inference ECR repository"
  value       = aws_ecr_repository.inference.repository_url
}

output "inference_ecr_repository_arn" {
  description = "ARN of the inference ECR repository"
  value       = aws_ecr_repository.inference.arn
}

output "inference_ecr_repository_name" {
  description = "Name of the inference ECR repository"
  value       = aws_ecr_repository.inference.name
}

# ECS Cluster
output "ecs_cluster_id" {
  description = "ID of the ECS cluster"
  value       = aws_ecs_cluster.ml.id
}

output "ecs_cluster_name" {
  description = "Name of the ECS cluster"
  value       = aws_ecs_cluster.ml.name
}

output "ecs_cluster_arn" {
  description = "ARN of the ECS cluster"
  value       = aws_ecs_cluster.ml.arn
}

# Task Definitions
output "training_task_definition_arn" {
  description = "ARN of the training task definition"
  value       = aws_ecs_task_definition.training.arn
}

output "training_task_definition_family" {
  description = "Family of the training task definition"
  value       = aws_ecs_task_definition.training.family
}

output "training_task_definition_revision" {
  description = "Revision of the training task definition"
  value       = aws_ecs_task_definition.training.revision
}

output "inference_task_definition_arn" {
  description = "ARN of the inference task definition"
  value       = aws_ecs_task_definition.inference.arn
}

output "inference_task_definition_family" {
  description = "Family of the inference task definition"
  value       = aws_ecs_task_definition.inference.family
}

output "inference_task_definition_revision" {
  description = "Revision of the inference task definition"
  value       = aws_ecs_task_definition.inference.revision
}

# IAM Roles
output "ecs_execution_role_arn" {
  description = "ARN of the ECS execution IAM role"
  value       = aws_iam_role.ecs_execution.arn
}

output "ecs_task_role_arn" {
  description = "ARN of the ECS task IAM role"
  value       = aws_iam_role.ecs_task.arn
}

# CloudWatch Log Groups
output "training_log_group_name" {
  description = "Name of the training CloudWatch log group"
  value       = aws_cloudwatch_log_group.training.name
}

output "inference_log_group_name" {
  description = "Name of the inference CloudWatch log group"
  value       = aws_cloudwatch_log_group.inference.name
}

# Combined outputs for convenience
output "all_ecr_repositories" {
  description = "Map of all ECR repository URLs"
  value = {
    training  = aws_ecr_repository.training.repository_url
    inference = aws_ecr_repository.inference.repository_url
  }
}

