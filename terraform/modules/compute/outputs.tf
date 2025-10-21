# Outputs for Compute Module

# Lambda Function ARNs
output "pre_cleanup_lambda_arn" {
  description = "ARN of the pre-cleanup Lambda function"
  value       = aws_lambda_function.pre_cleanup.arn
}

output "pre_cleanup_lambda_name" {
  description = "Name of the pre-cleanup Lambda function"
  value       = aws_lambda_function.pre_cleanup.function_name
}

output "data_prep_lambda_arn" {
  description = "ARN of the data prep Lambda function"
  value       = aws_lambda_function.data_prep.arn
}

output "data_prep_lambda_name" {
  description = "Name of the data prep Lambda function"
  value       = aws_lambda_function.data_prep.function_name
}

output "data_validation_lambda_arn" {
  description = "ARN of the data validation Lambda function"
  value       = aws_lambda_function.data_validation.arn
}

output "data_validation_lambda_name" {
  description = "Name of the data validation Lambda function"
  value       = aws_lambda_function.data_validation.function_name
}

output "create_qa_table_lambda_arn" {
  description = "ARN of the create QA table Lambda function"
  value       = aws_lambda_function.create_qa_table.arn
}

output "create_qa_table_lambda_name" {
  description = "Name of the create QA table Lambda function"
  value       = aws_lambda_function.create_qa_table.function_name
}

output "create_results_table_lambda_arn" {
  description = "ARN of the create results table Lambda function"
  value       = aws_lambda_function.create_results_table.arn
}

output "create_results_table_lambda_name" {
  description = "Name of the create results table Lambda function"
  value       = aws_lambda_function.create_results_table.function_name
}

output "bedrock_action_handler_lambda_arn" {
  description = "ARN of the Bedrock action handler Lambda function"
  value       = aws_lambda_function.bedrock_action_handler.arn
}

output "bedrock_action_handler_lambda_name" {
  description = "Name of the Bedrock action handler Lambda function"
  value       = aws_lambda_function.bedrock_action_handler.function_name
}

output "predict_lambda_arn" {
  description = "ARN of the predict Lambda function"
  value       = aws_lambda_function.predict.arn
}

output "predict_lambda_name" {
  description = "Name of the predict Lambda function"
  value       = aws_lambda_function.predict.function_name
}

output "ensemble_lambda_arn" {
  description = "ARN of the ensemble Lambda function"
  value       = aws_lambda_function.ensemble.arn
}

output "ensemble_lambda_name" {
  description = "Name of the ensemble Lambda function"
  value       = aws_lambda_function.ensemble.function_name
}

# Step Functions
output "step_functions_state_machine_arn" {
  description = "ARN of the Step Functions state machine"
  value       = aws_sfn_state_machine.ml_pipeline.arn
}

output "step_functions_state_machine_name" {
  description = "Name of the Step Functions state machine"
  value       = aws_sfn_state_machine.ml_pipeline.name
}

# IAM Roles
output "lambda_execution_role_arn" {
  description = "ARN of the Lambda execution IAM role"
  value       = aws_iam_role.lambda_execution.arn
}

output "step_functions_role_arn" {
  description = "ARN of the Step Functions execution IAM role"
  value       = aws_iam_role.step_functions.arn
}

# All Lambda ARNs as a map (for convenience)
output "all_lambda_arns" {
  description = "Map of all Lambda function ARNs"
  value = {
    pre_cleanup            = aws_lambda_function.pre_cleanup.arn
    data_prep              = aws_lambda_function.data_prep.arn
    data_validation        = aws_lambda_function.data_validation.arn
    create_qa_table        = aws_lambda_function.create_qa_table.arn
    create_results_table   = aws_lambda_function.create_results_table.arn
    bedrock_action_handler = aws_lambda_function.bedrock_action_handler.arn
    predict                = aws_lambda_function.predict.arn
    ensemble               = aws_lambda_function.ensemble.arn
  }
}

