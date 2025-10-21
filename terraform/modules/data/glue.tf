# Glue Data Catalog

# Glue databases
resource "aws_glue_catalog_database" "raw" {
  name        = "${var.project_name}_raw_${var.environment}"
  description = "Raw customer engagement data"
  
  create_table_default_permission {
    permissions = ["SELECT"]
    principal {
      data_lake_principal_identifier = "IAM_ALLOWED_PRINCIPALS"
    }
  }
}

resource "aws_glue_catalog_database" "processed" {
  name        = "${var.project_name}_processed_${var.environment}"
  description = "Processed and cleaned data"
  
  create_table_default_permission {
    permissions = ["SELECT"]
    principal {
      data_lake_principal_identifier = "IAM_ALLOWED_PRINCIPALS"
    }
  }
}

resource "aws_glue_catalog_database" "analytics" {
  name        = "${var.project_name}_analytics_${var.environment}"
  description = "Analytics views and results"
  
  create_table_default_permission {
    permissions = ["SELECT"]
    principal {
      data_lake_principal_identifier = "IAM_ALLOWED_PRINCIPALS"
    }
  }
}

resource "aws_glue_catalog_database" "ml" {
  name        = "${var.project_name}_ml_${var.environment}"
  description = "ML features and predictions"
  
  create_table_default_permission {
    permissions = ["SELECT"]
    principal {
      data_lake_principal_identifier = "IAM_ALLOWED_PRINCIPALS"
    }
  }
}

# Glue crawler for raw customers data
resource "aws_glue_crawler" "customers_raw" {
  name          = "${var.project_name}-customers-raw-${var.environment}"
  role          = aws_iam_role.glue_crawler.arn
  database_name = aws_glue_catalog_database.raw.name

  s3_target {
    path = "s3://${aws_s3_bucket.raw.bucket}/customers/"
  }

  schema_change_policy {
    update_behavior = "UPDATE_IN_DATABASE"
    delete_behavior = "LOG"
  }

  configuration = jsonencode({
    Version = 1.0
    CrawlerOutput = {
      Partitions = {
        AddOrUpdateBehavior = "InheritFromTable"
      }
    }
  })

  tags = merge(var.tags, {
    Name = "${var.project_name}-customers-raw-crawler"
  })
}

# Glue crawler for processed data
resource "aws_glue_crawler" "customers_processed" {
  name          = "${var.project_name}-customers-processed-${var.environment}"
  role          = aws_iam_role.glue_crawler.arn
  database_name = aws_glue_catalog_database.processed.name

  s3_target {
    path = "s3://${aws_s3_bucket.processed.bucket}/customers/"
  }

  schema_change_policy {
    update_behavior = "UPDATE_IN_DATABASE"
    delete_behavior = "LOG"
  }

  tags = merge(var.tags, {
    Name = "${var.project_name}-customers-processed-crawler"
  })
}

# Glue crawler for predictions
resource "aws_glue_crawler" "predictions" {
  name          = "${var.project_name}-predictions-${var.environment}"
  role          = aws_iam_role.glue_crawler.arn
  database_name = aws_glue_catalog_database.ml.name

  s3_target {
    path = "s3://${aws_s3_bucket.results.bucket}/predictions/"
  }

  schema_change_policy {
    update_behavior = "UPDATE_IN_DATABASE"
    delete_behavior = "LOG"
  }

  tags = merge(var.tags, {
    Name = "${var.project_name}-predictions-crawler"
  })
}

