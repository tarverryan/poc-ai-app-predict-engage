# Outputs for Data Module

# S3 Bucket Names
output "raw_bucket_name" {
  description = "Name of the raw data S3 bucket"
  value       = aws_s3_bucket.raw.id
}

output "raw_bucket_arn" {
  description = "ARN of the raw data S3 bucket"
  value       = aws_s3_bucket.raw.arn
}

output "processed_bucket_name" {
  description = "Name of the processed data S3 bucket"
  value       = aws_s3_bucket.processed.id
}

output "processed_bucket_arn" {
  description = "ARN of the processed data S3 bucket"
  value       = aws_s3_bucket.processed.arn
}

output "features_bucket_name" {
  description = "Name of the features S3 bucket"
  value       = aws_s3_bucket.features.id
}

output "features_bucket_arn" {
  description = "ARN of the features S3 bucket"
  value       = aws_s3_bucket.features.arn
}

output "models_bucket_name" {
  description = "Name of the models S3 bucket"
  value       = aws_s3_bucket.models.id
}

output "models_bucket_arn" {
  description = "ARN of the models S3 bucket"
  value       = aws_s3_bucket.models.arn
}

output "results_bucket_name" {
  description = "Name of the results S3 bucket"
  value       = aws_s3_bucket.results.id
}

output "results_bucket_arn" {
  description = "ARN of the results S3 bucket"
  value       = aws_s3_bucket.results.arn
}

output "knowledge_base_bucket_name" {
  description = "Name of the Bedrock Knowledge Base S3 bucket"
  value       = aws_s3_bucket.knowledge_base.id
}

output "knowledge_base_bucket_arn" {
  description = "ARN of the Bedrock Knowledge Base S3 bucket"
  value       = aws_s3_bucket.knowledge_base.arn
}

output "knowledge_base_vectors_bucket_name" {
  description = "Name of the Bedrock KB vectors S3 bucket"
  value       = aws_s3_bucket.knowledge_base_vectors.id
}

output "knowledge_base_vectors_bucket_arn" {
  description = "ARN of the Bedrock KB vectors S3 bucket"
  value       = aws_s3_bucket.knowledge_base_vectors.arn
}

output "athena_results_bucket_name" {
  description = "Name of the Athena query results S3 bucket"
  value       = aws_s3_bucket.athena_results.id
}

output "athena_results_bucket_arn" {
  description = "ARN of the Athena query results S3 bucket"
  value       = aws_s3_bucket.athena_results.arn
}

# Glue Database Names
output "glue_database_raw" {
  description = "Name of the raw Glue database"
  value       = aws_glue_catalog_database.raw.name
}

output "glue_database_processed" {
  description = "Name of the processed Glue database"
  value       = aws_glue_catalog_database.processed.name
}

output "glue_database_analytics" {
  description = "Name of the analytics Glue database"
  value       = aws_glue_catalog_database.analytics.name
}

output "glue_database_ml" {
  description = "Name of the ML Glue database"
  value       = aws_glue_catalog_database.ml.name
}

# Athena Workgroup
output "athena_workgroup_name" {
  description = "Name of the Athena workgroup"
  value       = aws_athena_workgroup.main.name
}

output "athena_workgroup_id" {
  description = "ID of the Athena workgroup"
  value       = aws_athena_workgroup.main.id
}

# IAM Roles
output "glue_crawler_role_arn" {
  description = "ARN of the Glue Crawler IAM role"
  value       = aws_iam_role.glue_crawler.arn
}

output "athena_query_role_arn" {
  description = "ARN of the Athena query execution IAM role"
  value       = aws_iam_role.athena_query.arn
}

# All bucket names as a map (for convenience)
output "all_buckets" {
  description = "Map of all S3 bucket names"
  value = {
    raw                       = aws_s3_bucket.raw.id
    processed                 = aws_s3_bucket.processed.id
    features                  = aws_s3_bucket.features.id
    models                    = aws_s3_bucket.models.id
    results                   = aws_s3_bucket.results.id
    knowledge_base            = aws_s3_bucket.knowledge_base.id
    knowledge_base_vectors    = aws_s3_bucket.knowledge_base_vectors.id
    athena_results            = aws_s3_bucket.athena_results.id
  }
}

