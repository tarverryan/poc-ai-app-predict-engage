# Athena Configuration

# Athena workgroup
resource "aws_athena_workgroup" "main" {
  name = "${var.project_name}-workgroup-${var.environment}"

  configuration {
    enforce_workgroup_configuration    = true
    publish_cloudwatch_metrics_enabled = true

    result_configuration {
      output_location = "s3://${aws_s3_bucket.athena_results.bucket}/query-results/"

      encryption_configuration {
        encryption_option = "SSE_S3"
      }
    }

    engine_version {
      selected_engine_version = "Athena engine version 3"
    }
  }

  tags = merge(var.tags, {
    Name = "${var.project_name}-athena-workgroup"
  })
}

# Named query: High engagement customers
resource "aws_athena_named_query" "high_engagement" {
  name        = "high_engagement_customers"
  description = "Customers with engagement score > 0.7"
  database    = aws_glue_catalog_database.analytics.name
  workgroup   = aws_athena_workgroup.main.name

  query = <<EOF
SELECT 
  customer_id,
  age,
  gender,
  location,
  tenure_months,
  sessions_last_7_days,
  engagement_score,
  followers_count,
  total_connections
FROM ${aws_glue_catalog_database.raw.name}.customers
WHERE engagement_score > 0.7
ORDER BY engagement_score DESC
LIMIT 1000;
EOF
}

# Named query: At-risk customers (high churn probability)
resource "aws_athena_named_query" "at_risk" {
  name        = "at_risk_customers"
  description = "Customers with high churn probability"
  database    = aws_glue_catalog_database.analytics.name
  workgroup   = aws_athena_workgroup.main.name

  query = <<EOF
SELECT 
  customer_id,
  age,
  gender,
  tenure_months,
  engagement_score,
  churn_30_day,
  lifetime_value_usd
FROM ${aws_glue_catalog_database.raw.name}.customers
WHERE churn_30_day = 1
  OR engagement_score < 0.3
ORDER BY engagement_score ASC
LIMIT 1000;
EOF
}

# Named query: Model performance metrics
resource "aws_athena_named_query" "model_performance" {
  name        = "model_performance_metrics"
  description = "Calculate model performance metrics"
  database    = aws_glue_catalog_database.analytics.name
  workgroup   = aws_athena_workgroup.main.name

  query = <<EOF
SELECT 
  'engagement' as model_name,
  COUNT(*) as total_predictions,
  AVG(predicted_engagement_score) as avg_prediction,
  STDDEV(predicted_engagement_score) as std_prediction,
  MIN(predicted_engagement_score) as min_prediction,
  MAX(predicted_engagement_score) as max_prediction
FROM ${aws_glue_catalog_database.ml.name}.predictions
WHERE model_version = 'v1.0';
EOF
}

# Named query: Fairness analysis by gender
resource "aws_athena_named_query" "fairness_gender" {
  name        = "fairness_by_gender"
  description = "Analyze prediction fairness across gender groups"
  database    = aws_glue_catalog_database.analytics.name
  workgroup   = aws_athena_workgroup.main.name

  query = <<EOF
SELECT 
  gender,
  COUNT(*) as count,
  AVG(engagement_score) as avg_actual_engagement,
  AVG(predicted_engagement_score) as avg_predicted_engagement,
  AVG(predicted_engagement_score) / 
    (SELECT AVG(predicted_engagement_score) FROM ${aws_glue_catalog_database.ml.name}.predictions) as parity_ratio
FROM ${aws_glue_catalog_database.raw.name}.customers c
LEFT JOIN ${aws_glue_catalog_database.ml.name}.predictions p
  ON c.customer_id = p.customer_id
WHERE gender IN ('M', 'F')
GROUP BY gender;
EOF
}

# Named query: Customer segmentation
resource "aws_athena_named_query" "customer_segments" {
  name        = "customer_segmentation"
  description = "Segment customers by engagement and tenure"
  database    = aws_glue_catalog_database.analytics.name
  workgroup   = aws_athena_workgroup.main.name

  query = <<EOF
SELECT 
  CASE 
    WHEN tenure_months < 3 THEN 'New'
    WHEN tenure_months BETWEEN 3 AND 12 THEN 'Growing'
    WHEN tenure_months BETWEEN 13 AND 24 THEN 'Established'
    ELSE 'Veteran'
  END as tenure_segment,
  CASE 
    WHEN engagement_score < 0.3 THEN 'Low'
    WHEN engagement_score BETWEEN 0.3 AND 0.6 THEN 'Medium'
    ELSE 'High'
  END as engagement_segment,
  COUNT(*) as customer_count,
  AVG(lifetime_value_usd) as avg_ltv,
  AVG(sessions_last_7_days) as avg_sessions
FROM ${aws_glue_catalog_database.raw.name}.customers
GROUP BY 1, 2
ORDER BY 1, 2;
EOF
}

# Named query: Feature importance analysis
resource "aws_athena_named_query" "feature_correlations" {
  name        = "feature_correlations_with_engagement"
  description = "Analyze feature correlations with engagement score"
  database    = aws_glue_catalog_database.analytics.name
  workgroup   = aws_athena_workgroup.main.name

  query = <<EOF
SELECT 
  'sessions_last_7_days' as feature,
  CORR(sessions_last_7_days, engagement_score) as correlation
FROM ${aws_glue_catalog_database.raw.name}.customers
UNION ALL
SELECT 
  'tenure_months' as feature,
  CORR(tenure_months, engagement_score) as correlation
FROM ${aws_glue_catalog_database.raw.name}.customers
UNION ALL
SELECT 
  'followers_count' as feature,
  CORR(followers_count, engagement_score) as correlation
FROM ${aws_glue_catalog_database.raw.name}.customers
ORDER BY correlation DESC;
EOF
}

