# Bedrock Knowledge Base with S3 Vector Store

# Bedrock Knowledge Base
resource "aws_bedrockagent_knowledge_base" "engagement" {
  name        = "${var.project_name}-kb-${var.environment}"
  description = "Knowledge base for customer engagement predictions, model metrics, and feature importance"
  role_arn    = aws_iam_role.bedrock_kb.arn

  knowledge_base_configuration {
    type = "VECTOR"

    vector_knowledge_base_configuration {
      embedding_model_arn = "arn:aws:bedrock:${var.aws_region}::foundation-model/amazon.titan-embed-text-v2:0"
    }
  }

  storage_configuration {
    type = "S3"

    s3_storage_configuration {
      bucket_arn = var.knowledge_base_vectors_bucket_arn
    }
  }

  tags = merge(var.tags, {
    Name = "${var.project_name}-knowledge-base"
  })
}

# Bedrock Knowledge Base Data Source
resource "aws_bedrockagent_data_source" "engagement_docs" {
  name              = "${var.project_name}-kb-docs-${var.environment}"
  description       = "Model metrics, feature importance, and data dictionary documents"
  knowledge_base_id = aws_bedrockagent_knowledge_base.engagement.id

  data_source_configuration {
    type = "S3"

    s3_configuration {
      bucket_arn = var.knowledge_base_bucket_arn

      inclusion_prefixes = [
        "model_metrics/",
        "feature_importance/",
        "data_dictionary/",
        "analytics/"
      ]
    }
  }

  vector_ingestion_configuration {
    chunking_configuration {
      chunking_strategy = "FIXED_SIZE"

      fixed_size_chunking_configuration {
        max_tokens         = 300
        overlap_percentage = 20
      }
    }
  }
}

