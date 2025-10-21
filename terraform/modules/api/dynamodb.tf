# DynamoDB Table for Prediction Caching

resource "aws_dynamodb_table" "predictions_cache" {
  name         = "${var.project_name}-predictions-cache-${var.environment}"
  billing_mode = "PAY_PER_REQUEST"
  hash_key     = "customer_id"
  range_key    = "feature_hash"

  attribute {
    name = "customer_id"
    type = "S"
  }

  attribute {
    name = "feature_hash"
    type = "S"
  }

  attribute {
    name = "model_version"
    type = "S"
  }

  attribute {
    name = "timestamp"
    type = "N"
  }

  # TTL for automatic expiration (1 hour)
  ttl {
    attribute_name = "ttl"
    enabled        = true
  }

  # Global Secondary Index for querying by model version and timestamp
  global_secondary_index {
    name            = "model_version-timestamp-index"
    hash_key        = "model_version"
    range_key       = "timestamp"
    projection_type = "ALL"
  }

  # Point-in-time recovery
  point_in_time_recovery {
    enabled = true
  }

  # Server-side encryption
  server_side_encryption {
    enabled = true
  }

  tags = merge(var.tags, {
    Name = "${var.project_name}-predictions-cache"
  })
}

# DynamoDB Auto Scaling (optional, for on-demand we don't need this)
# But keeping configuration ready if switching to provisioned capacity

# CloudWatch Alarms for DynamoDB
resource "aws_cloudwatch_metric_alarm" "dynamodb_read_throttle" {
  alarm_name          = "${var.project_name}-dynamodb-read-throttle-${var.environment}"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = "2"
  metric_name         = "UserErrors"
  namespace           = "AWS/DynamoDB"
  period              = "300"
  statistic           = "Sum"
  threshold           = "10"
  alarm_description   = "Alert when DynamoDB read throttling occurs"
  alarm_actions       = []

  dimensions = {
    TableName = aws_dynamodb_table.predictions_cache.name
  }

  tags = var.tags
}

resource "aws_cloudwatch_metric_alarm" "dynamodb_write_throttle" {
  alarm_name          = "${var.project_name}-dynamodb-write-throttle-${var.environment}"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = "2"
  metric_name         = "UserErrors"
  namespace           = "AWS/DynamoDB"
  period              = "300"
  statistic           = "Sum"
  threshold           = "10"
  alarm_description   = "Alert when DynamoDB write throttling occurs"
  alarm_actions       = []

  dimensions = {
    TableName = aws_dynamodb_table.predictions_cache.name
  }

  tags = var.tags
}

