# Outputs for API Module

# API Gateway
output "api_gateway_id" {
  description = "ID of the API Gateway REST API"
  value       = aws_api_gateway_rest_api.predictions.id
}

output "api_gateway_arn" {
  description = "ARN of the API Gateway REST API"
  value       = aws_api_gateway_rest_api.predictions.arn
}

output "api_gateway_endpoint" {
  description = "Invoke URL for the API Gateway"
  value       = aws_api_gateway_stage.predictions.invoke_url
}

output "api_gateway_stage_name" {
  description = "Name of the API Gateway stage"
  value       = aws_api_gateway_stage.predictions.stage_name
}

output "api_gateway_execution_arn" {
  description = "Execution ARN of the API Gateway"
  value       = aws_api_gateway_rest_api.predictions.execution_arn
}

# API Key
output "api_key_id" {
  description = "ID of the API Gateway API key"
  value       = aws_api_gateway_api_key.predictions.id
}

output "api_key_value" {
  description = "Value of the API Gateway API key"
  value       = aws_api_gateway_api_key.predictions.value
  sensitive   = true
}

# Usage Plan
output "usage_plan_id" {
  description = "ID of the API Gateway usage plan"
  value       = aws_api_gateway_usage_plan.predictions.id
}

# DynamoDB
output "dynamodb_table_name" {
  description = "Name of the DynamoDB predictions cache table"
  value       = aws_dynamodb_table.predictions_cache.name
}

output "dynamodb_table_arn" {
  description = "ARN of the DynamoDB predictions cache table"
  value       = aws_dynamodb_table.predictions_cache.arn
}

output "dynamodb_table_id" {
  description = "ID of the DynamoDB predictions cache table"
  value       = aws_dynamodb_table.predictions_cache.id
}

output "dynamodb_gsi_name" {
  description = "Name of the DynamoDB GSI"
  value       = "model_version-timestamp-index"
}

# Combined outputs
output "api_endpoint_full" {
  description = "Full API endpoint URL for predictions"
  value       = "${aws_api_gateway_stage.predictions.invoke_url}/predict"
}

output "api_curl_example" {
  description = "Example curl command to test the API"
  value       = <<EOF
curl -X POST ${aws_api_gateway_stage.predictions.invoke_url}/predict \
  -H "Content-Type: application/json" \
  -H "x-api-key: ${aws_api_gateway_api_key.predictions.value}" \
  -d '{
    "customer_features": {
      "age": 35,
      "gender": "M",
      "tenure_months": 12,
      "sessions_last_7_days": 5,
      "session_duration_avg_minutes": 20,
      "followers_count": 500,
      "following_count": 300,
      "total_connections": 150
    },
    "model_name": "engagement"
  }'
EOF
  sensitive   = true
}

