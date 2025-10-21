# ECS Cluster and Fargate Task Definitions

# ECS Cluster
resource "aws_ecs_cluster" "ml" {
  name = "${var.project_name}-ml-${var.environment}"

  setting {
    name  = "containerInsights"
    value = "enabled"
  }

  tags = merge(var.tags, {
    Name = "${var.project_name}-ml-cluster"
  })
}

# ECS Cluster Capacity Providers (Fargate + Fargate Spot)
resource "aws_ecs_cluster_capacity_providers" "ml" {
  cluster_name = aws_ecs_cluster.ml.name

  capacity_providers = ["FARGATE", "FARGATE_SPOT"]

  default_capacity_provider_strategy {
    capacity_provider = "FARGATE_SPOT"
    weight            = 1
    base              = 0
  }
}

# CloudWatch Log Groups for Fargate
resource "aws_cloudwatch_log_group" "training" {
  name              = "/ecs/${var.project_name}-training-${var.environment}"
  retention_in_days = 7

  tags = var.tags
}

resource "aws_cloudwatch_log_group" "inference" {
  name              = "/ecs/${var.project_name}-inference-${var.environment}"
  retention_in_days = 7

  tags = var.tags
}

# Training Task Definition
resource "aws_ecs_task_definition" "training" {
  family                   = "${var.project_name}-training-${var.environment}"
  network_mode             = "awsvpc"
  requires_compatibilities = ["FARGATE"]
  cpu                      = "16384"  # 16 vCPU
  memory                   = "65536"  # 64 GB
  execution_role_arn       = aws_iam_role.ecs_execution.arn
  task_role_arn            = aws_iam_role.ecs_task.arn

  container_definitions = jsonencode([
    {
      name      = "training"
      image     = "${aws_ecr_repository.training.repository_url}:latest"
      essential = true

      logConfiguration = {
        logDriver = "awslogs"
        options = {
          "awslogs-group"         = aws_cloudwatch_log_group.training.name
          "awslogs-region"        = var.aws_region
          "awslogs-stream-prefix" = "training"
        }
      }

      environment = [
        {
          name  = "ENV"
          value = var.environment
        },
        {
          name  = "AWS_REGION"
          value = var.aws_region
        },
        {
          name  = "RAW_BUCKET"
          value = var.data_buckets.raw
        },
        {
          name  = "PROCESSED_BUCKET"
          value = var.data_buckets.processed
        },
        {
          name  = "FEATURES_BUCKET"
          value = var.data_buckets.features
        },
        {
          name  = "MODELS_BUCKET"
          value = var.data_buckets.models
        },
        {
          name  = "GLUE_DATABASE_RAW"
          value = var.glue_databases.raw
        },
        {
          name  = "GLUE_DATABASE_PROCESSED"
          value = var.glue_databases.processed
        }
      ]

      healthCheck = {
        command     = ["CMD-SHELL", "python --version || exit 1"]
        interval    = 30
        timeout     = 5
        retries     = 3
        startPeriod = 60
      }
    }
  ])

  tags = merge(var.tags, {
    Name = "${var.project_name}-training-task"
  })
}

# Inference Task Definition
resource "aws_ecs_task_definition" "inference" {
  family                   = "${var.project_name}-inference-${var.environment}"
  network_mode             = "awsvpc"
  requires_compatibilities = ["FARGATE"]
  cpu                      = "16384"  # 16 vCPU
  memory                   = "65536"  # 64 GB
  execution_role_arn       = aws_iam_role.ecs_execution.arn
  task_role_arn            = aws_iam_role.ecs_task.arn

  container_definitions = jsonencode([
    {
      name      = "inference"
      image     = "${aws_ecr_repository.inference.repository_url}:latest"
      essential = true

      logConfiguration = {
        logDriver = "awslogs"
        options = {
          "awslogs-group"         = aws_cloudwatch_log_group.inference.name
          "awslogs-region"        = var.aws_region
          "awslogs-stream-prefix" = "inference"
        }
      }

      environment = [
        {
          name  = "ENV"
          value = var.environment
        },
        {
          name  = "AWS_REGION"
          value = var.aws_region
        },
        {
          name  = "RAW_BUCKET"
          value = var.data_buckets.raw
        },
        {
          name  = "MODELS_BUCKET"
          value = var.data_buckets.models
        },
        {
          name  = "RESULTS_BUCKET"
          value = var.data_buckets.results
        },
        {
          name  = "GLUE_DATABASE_RAW"
          value = var.glue_databases.raw
        },
        {
          name  = "GLUE_DATABASE_ML"
          value = var.glue_databases.ml
        }
      ]

      healthCheck = {
        command     = ["CMD-SHELL", "python --version || exit 1"]
        interval    = 30
        timeout     = 5
        retries     = 3
        startPeriod = 60
      }
    }
  ])

  tags = merge(var.tags, {
    Name = "${var.project_name}-inference-task"
  })
}

