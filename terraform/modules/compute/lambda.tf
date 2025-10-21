# Lambda Functions for ML Pipeline

# Lambda Layer for common dependencies
resource "aws_lambda_layer_version" "common" {
  filename   = "${path.module}/../../../lambda/common_layer.zip"
  layer_name = "${var.project_name}-common-layer-${var.environment}"

  compatible_runtimes = ["python3.11"]

  lifecycle {
    create_before_destroy = true
  }
}

# Pre-Cleanup Lambda
resource "aws_lambda_function" "pre_cleanup" {
  filename      = "${path.module}/../../../lambda/pre_cleanup/function.zip"
  function_name = "${var.project_name}-pre-cleanup-${var.environment}"
  role          = aws_iam_role.lambda_execution.arn
  handler       = "handler.lambda_handler"
  runtime       = "python3.11"
  timeout       = 300
  memory_size   = 512

  environment {
    variables = {
      ENV                     = var.environment
      RAW_BUCKET              = var.data_buckets.raw
      PROCESSED_BUCKET        = var.data_buckets.processed
      FEATURES_BUCKET         = var.data_buckets.features
      RESULTS_BUCKET          = var.data_buckets.results
      ATHENA_RESULTS_BUCKET   = var.data_buckets.athena_results
      ATHENA_WORKGROUP        = var.athena_workgroup_name
      GLUE_DATABASE_ML        = var.glue_databases.ml
    }
  }

  tags = merge(var.tags, {
    Name = "${var.project_name}-pre-cleanup"
  })
}

# Data Prep Lambda
resource "aws_lambda_function" "data_prep" {
  filename      = "${path.module}/../../../lambda/data_prep/function.zip"
  function_name = "${var.project_name}-data-prep-${var.environment}"
  role          = aws_iam_role.lambda_execution.arn
  handler       = "handler.lambda_handler"
  runtime       = "python3.11"
  timeout       = 600
  memory_size   = 1024

  environment {
    variables = {
      ENV                     = var.environment
      RAW_BUCKET              = var.data_buckets.raw
      PROCESSED_BUCKET        = var.data_buckets.processed
      FEATURES_BUCKET         = var.data_buckets.features
      ATHENA_RESULTS_BUCKET   = var.data_buckets.athena_results
      ATHENA_WORKGROUP        = var.athena_workgroup_name
      GLUE_DATABASE_RAW       = var.glue_databases.raw
      GLUE_DATABASE_PROCESSED = var.glue_databases.processed
    }
  }

  tags = merge(var.tags, {
    Name = "${var.project_name}-data-prep"
  })
}

# Data Validation Lambda
resource "aws_lambda_function" "data_validation" {
  filename      = "${path.module}/../../../lambda/data_validation/function.zip"
  function_name = "${var.project_name}-data-validation-${var.environment}"
  role          = aws_iam_role.lambda_execution.arn
  handler       = "handler.lambda_handler"
  runtime       = "python3.11"
  timeout       = 600
  memory_size   = 2048

  environment {
    variables = {
      ENV                   = var.environment
      PROCESSED_BUCKET      = var.data_buckets.processed
      FEATURES_BUCKET       = var.data_buckets.features
      GLUE_DATABASE_PROCESSED = var.glue_databases.processed
    }
  }

  tags = merge(var.tags, {
    Name = "${var.project_name}-data-validation"
  })
}

# Create QA Table Lambda
resource "aws_lambda_function" "create_qa_table" {
  filename      = "${path.module}/../../../lambda/create_qa_table/function.zip"
  function_name = "${var.project_name}-create-qa-table-${var.environment}"
  role          = aws_iam_role.lambda_execution.arn
  handler       = "handler.lambda_handler"
  runtime       = "python3.11"
  timeout       = 600
  memory_size   = 1024

  environment {
    variables = {
      ENV                     = var.environment
      RESULTS_BUCKET          = var.data_buckets.results
      MODELS_BUCKET           = var.data_buckets.models
      ATHENA_RESULTS_BUCKET   = var.data_buckets.athena_results
      ATHENA_WORKGROUP        = var.athena_workgroup_name
      GLUE_DATABASE_ML        = var.glue_databases.ml
      QA_SAMPLE_SIZE          = "400"
    }
  }

  tags = merge(var.tags, {
    Name = "${var.project_name}-create-qa-table"
  })
}

# Create Results Table Lambda
resource "aws_lambda_function" "create_results_table" {
  filename      = "${path.module}/../../../lambda/create_results_table/function.zip"
  function_name = "${var.project_name}-create-results-table-${var.environment}"
  role          = aws_iam_role.lambda_execution.arn
  handler       = "handler.lambda_handler"
  runtime       = "python3.11"
  timeout       = 600
  memory_size   = 1024

  environment {
    variables = {
      ENV                     = var.environment
      RAW_BUCKET              = var.data_buckets.raw
      RESULTS_BUCKET          = var.data_buckets.results
      ATHENA_RESULTS_BUCKET   = var.data_buckets.athena_results
      ATHENA_WORKGROUP        = var.athena_workgroup_name
      GLUE_DATABASE_RAW       = var.glue_databases.raw
      GLUE_DATABASE_ML        = var.glue_databases.ml
    }
  }

  tags = merge(var.tags, {
    Name = "${var.project_name}-create-results-table"
  })
}

# Bedrock Action Handler Lambda
resource "aws_lambda_function" "bedrock_action_handler" {
  filename      = "${path.module}/../../../lambda/bedrock_action_handler/function.zip"
  function_name = "${var.project_name}-bedrock-action-${var.environment}"
  role          = aws_iam_role.lambda_execution.arn
  handler       = "handler.lambda_handler"
  runtime       = "python3.11"
  timeout       = 300
  memory_size   = 512

  environment {
    variables = {
      ENV                     = var.environment
      RAW_BUCKET              = var.data_buckets.raw
      RESULTS_BUCKET          = var.data_buckets.results
      MODELS_BUCKET           = var.data_buckets.models
      ATHENA_RESULTS_BUCKET   = var.data_buckets.athena_results
      ATHENA_WORKGROUP        = var.athena_workgroup_name
      GLUE_DATABASE_RAW       = var.glue_databases.raw
      GLUE_DATABASE_ML        = var.glue_databases.ml
    }
  }

  tags = merge(var.tags, {
    Name = "${var.project_name}-bedrock-action-handler"
  })
}

# Predict Lambda (Real-Time API)
resource "aws_lambda_function" "predict" {
  filename      = "${path.module}/../../../lambda/predict/function.zip"
  function_name = "${var.project_name}-predict-${var.environment}"
  role          = aws_iam_role.lambda_execution.arn
  handler       = "handler.lambda_handler"
  runtime       = "python3.11"
  timeout       = 30
  memory_size   = 3008  # 2 vCPU

  environment {
    variables = {
      ENV                = var.environment
      MODELS_BUCKET      = var.data_buckets.models
      DYNAMODB_TABLE     = "${var.project_name}-predictions-cache-${var.environment}"
      MODEL_VERSION      = "v1.0"
      CACHE_TTL_SECONDS  = "3600"
    }
  }

  tags = merge(var.tags, {
    Name = "${var.project_name}-predict"
  })
}

# Ensemble Lambda (Optional)
resource "aws_lambda_function" "ensemble" {
  filename      = "${path.module}/../../../lambda/ensemble/function.zip"
  function_name = "${var.project_name}-ensemble-${var.environment}"
  role          = aws_iam_role.lambda_execution.arn
  handler       = "handler.lambda_handler"
  runtime       = "python3.11"
  timeout       = 60
  memory_size   = 1024

  environment {
    variables = {
      ENV           = var.environment
      MODELS_BUCKET = var.data_buckets.models
      MODEL_VERSION = "v1.0"
    }
  }

  tags = merge(var.tags, {
    Name = "${var.project_name}-ensemble"
  })
}

# CloudWatch Log Groups
resource "aws_cloudwatch_log_group" "pre_cleanup" {
  name              = "/aws/lambda/${aws_lambda_function.pre_cleanup.function_name}"
  retention_in_days = 7

  tags = var.tags
}

resource "aws_cloudwatch_log_group" "data_prep" {
  name              = "/aws/lambda/${aws_lambda_function.data_prep.function_name}"
  retention_in_days = 7

  tags = var.tags
}

resource "aws_cloudwatch_log_group" "data_validation" {
  name              = "/aws/lambda/${aws_lambda_function.data_validation.function_name}"
  retention_in_days = 7

  tags = var.tags
}

resource "aws_cloudwatch_log_group" "create_qa_table" {
  name              = "/aws/lambda/${aws_lambda_function.create_qa_table.function_name}"
  retention_in_days = 7

  tags = var.tags
}

resource "aws_cloudwatch_log_group" "create_results_table" {
  name              = "/aws/lambda/${aws_lambda_function.create_results_table.function_name}"
  retention_in_days = 7

  tags = var.tags
}

resource "aws_cloudwatch_log_group" "bedrock_action_handler" {
  name              = "/aws/lambda/${aws_lambda_function.bedrock_action_handler.function_name}"
  retention_in_days = 7

  tags = var.tags
}

resource "aws_cloudwatch_log_group" "predict" {
  name              = "/aws/lambda/${aws_lambda_function.predict.function_name}"
  retention_in_days = 30  # Keep longer for API monitoring

  tags = var.tags
}

resource "aws_cloudwatch_log_group" "ensemble" {
  name              = "/aws/lambda/${aws_lambda_function.ensemble.function_name}"
  retention_in_days = 7

  tags = var.tags
}

