# API Gateway REST API for Real-Time Predictions

# REST API
resource "aws_api_gateway_rest_api" "predictions" {
  name        = "${var.project_name}-predictions-api-${var.environment}"
  description = "Real-time customer engagement prediction API"

  endpoint_configuration {
    types = ["REGIONAL"]
  }

  tags = merge(var.tags, {
    Name = "${var.project_name}-predictions-api"
  })
}

# /predict Resource
resource "aws_api_gateway_resource" "predict" {
  rest_api_id = aws_api_gateway_rest_api.predictions.id
  parent_id   = aws_api_gateway_rest_api.predictions.root_resource_id
  path_part   = "predict"
}

# POST /predict Method
resource "aws_api_gateway_method" "predict_post" {
  rest_api_id   = aws_api_gateway_rest_api.predictions.id
  resource_id   = aws_api_gateway_resource.predict.id
  http_method   = "POST"
  authorization = "API_KEY"
  api_key_required = true

  request_validator_id = aws_api_gateway_request_validator.predict.id

  request_models = {
    "application/json" = aws_api_gateway_model.predict_request.name
  }
}

# Request Validator
resource "aws_api_gateway_request_validator" "predict" {
  name                        = "${var.project_name}-predict-validator-${var.environment}"
  rest_api_id                 = aws_api_gateway_rest_api.predictions.id
  validate_request_body       = true
  validate_request_parameters = false
}

# Request Model (JSON Schema)
resource "aws_api_gateway_model" "predict_request" {
  rest_api_id  = aws_api_gateway_rest_api.predictions.id
  name         = "PredictRequest"
  description  = "Schema for prediction request"
  content_type = "application/json"

  schema = jsonencode({
    "$schema" = "http://json-schema.org/draft-04/schema#"
    title     = "PredictRequest"
    type      = "object"
    properties = {
      customer_features = {
        type = "object"
        description = "Customer features for prediction"
        properties = {
          age                                 = { type = "integer", minimum = 18, maximum = 100 }
          gender                              = { type = "string", enum = ["M", "F", "O", "N"] }
          tenure_months                       = { type = "integer", minimum = 0 }
          sessions_last_7_days                = { type = "integer", minimum = 0 }
          session_duration_avg_minutes        = { type = "integer", minimum = 0 }
          followers_count                     = { type = "integer", minimum = 0 }
          following_count                     = { type = "integer", minimum = 0 }
          total_connections                   = { type = "integer", minimum = 0 }
          swipes_right_last_30_days           = { type = "integer", minimum = 0 }
          matches_last_30_days                = { type = "integer", minimum = 0 }
          posts_last_30_days                  = { type = "integer", minimum = 0 }
          stories_last_30_days                = { type = "integer", minimum = 0 }
          gig_applications_sent               = { type = "integer", minimum = 0 }
          active_gigs_count                   = { type = "integer", minimum = 0 }
        }
      }
      model_name = {
        type = "string"
        description = "Model to use for prediction"
        enum = ["engagement", "churn", "ltv", "recommendations", "anomaly"]
        default = "engagement"
      }
    }
    required = ["customer_features"]
  })
}

# Lambda Integration
resource "aws_api_gateway_integration" "predict_lambda" {
  rest_api_id             = aws_api_gateway_rest_api.predictions.id
  resource_id             = aws_api_gateway_resource.predict.id
  http_method             = aws_api_gateway_method.predict_post.http_method
  integration_http_method = "POST"
  type                    = "AWS_PROXY"
  uri                     = "arn:aws:apigateway:${var.aws_region}:lambda:path/2015-03-31/functions/${var.predict_lambda_arn}/invocations"
}

# Lambda Permission for API Gateway
resource "aws_lambda_permission" "api_gateway" {
  statement_id  = "AllowAPIGatewayInvoke"
  action        = "lambda:InvokeFunction"
  function_name = var.predict_lambda_name
  principal     = "apigateway.amazonaws.com"
  source_arn    = "${aws_api_gateway_rest_api.predictions.execution_arn}/*/*/*"
}

# Method Response
resource "aws_api_gateway_method_response" "predict_200" {
  rest_api_id = aws_api_gateway_rest_api.predictions.id
  resource_id = aws_api_gateway_resource.predict.id
  http_method = aws_api_gateway_method.predict_post.http_method
  status_code = "200"

  response_parameters = {
    "method.response.header.Access-Control-Allow-Origin" = true
  }

  response_models = {
    "application/json" = "Empty"
  }
}

# Deployment
resource "aws_api_gateway_deployment" "predictions" {
  rest_api_id = aws_api_gateway_rest_api.predictions.id

  triggers = {
    redeployment = sha1(jsonencode([
      aws_api_gateway_resource.predict.id,
      aws_api_gateway_method.predict_post.id,
      aws_api_gateway_integration.predict_lambda.id,
    ]))
  }

  lifecycle {
    create_before_destroy = true
  }

  depends_on = [
    aws_api_gateway_integration.predict_lambda
  ]
}

# Stage
resource "aws_api_gateway_stage" "predictions" {
  deployment_id = aws_api_gateway_deployment.predictions.id
  rest_api_id   = aws_api_gateway_rest_api.predictions.id
  stage_name    = var.environment

  xray_tracing_enabled = true

  access_log_settings {
    destination_arn = aws_cloudwatch_log_group.api_gateway.arn
    format = jsonencode({
      requestId      = "$context.requestId"
      ip             = "$context.identity.sourceIp"
      caller         = "$context.identity.caller"
      user           = "$context.identity.user"
      requestTime    = "$context.requestTime"
      httpMethod     = "$context.httpMethod"
      resourcePath   = "$context.resourcePath"
      status         = "$context.status"
      protocol       = "$context.protocol"
      responseLength = "$context.responseLength"
      latency        = "$context.integrationLatency"
    })
  }

  tags = var.tags
}

# CloudWatch Log Group for API Gateway
resource "aws_cloudwatch_log_group" "api_gateway" {
  name              = "/aws/apigateway/${var.project_name}-predictions-${var.environment}"
  retention_in_days = 30

  tags = var.tags
}

# Usage Plan
resource "aws_api_gateway_usage_plan" "predictions" {
  name        = "${var.project_name}-usage-plan-${var.environment}"
  description = "Usage plan for predictions API"

  api_stages {
    api_id = aws_api_gateway_rest_api.predictions.id
    stage  = aws_api_gateway_stage.predictions.stage_name
  }

  quota_settings {
    limit  = 10000
    period = "DAY"
  }

  throttle_settings {
    burst_limit = 100
    rate_limit  = 50
  }

  tags = var.tags
}

# API Key
resource "aws_api_gateway_api_key" "predictions" {
  name        = "${var.project_name}-api-key-${var.environment}"
  description = "API key for predictions API"
  enabled     = true

  tags = var.tags
}

# Usage Plan - API Key Association
resource "aws_api_gateway_usage_plan_key" "predictions" {
  key_id        = aws_api_gateway_api_key.predictions.id
  key_type      = "API_KEY"
  usage_plan_id = aws_api_gateway_usage_plan.predictions.id
}

