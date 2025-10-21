# Step Functions State Machine

resource "aws_sfn_state_machine" "ml_pipeline" {
  name     = "${var.project_name}-ml-pipeline-${var.environment}"
  role_arn = aws_iam_role.step_functions.arn

  definition = jsonencode({
    Comment = "Customer Engagement ML Pipeline with Parallel Execution"
    StartAt = "Pre-Cleanup"
    States = {
      Pre-Cleanup = {
        Type     = "Task"
        Resource = aws_lambda_function.pre_cleanup.arn
        Comment  = "Clean up old Athena tables and temp S3 data"
        Retry = [
          {
            ErrorEquals     = ["Lambda.ServiceException", "Lambda.TooManyRequestsException"]
            IntervalSeconds = 2
            MaxAttempts     = 3
            BackoffRate     = 2.0
          }
        ]
        Catch = [
          {
            ErrorEquals = ["States.ALL"]
            ResultPath  = "$.error"
            Next        = "Cleanup-Failed"
          }
        ]
        Next = "Data-Prep"
      }

      Data-Prep = {
        Type     = "Task"
        Resource = aws_lambda_function.data_prep.arn
        Comment  = "Prepare train/test splits via Athena queries"
        Retry = [
          {
            ErrorEquals     = ["Lambda.ServiceException"]
            IntervalSeconds = 2
            MaxAttempts     = 3
            BackoffRate     = 2.0
          }
        ]
        Catch = [
          {
            ErrorEquals = ["States.ALL"]
            ResultPath  = "$.error"
            Next        = "Data-Prep-Failed"
          }
        ]
        Next = "Training-And-Validation"
      }

      Training-And-Validation = {
        Type    = "Parallel"
        Comment = "Run training and validation in parallel"
        Branches = [
          {
            StartAt = "Train-Models"
            States = {
              Train-Models = {
                Type     = "Task"
                Resource = "arn:aws:states:::ecs:runTask.sync"
                Parameters = {
                  LaunchType     = "FARGATE"
                  Cluster        = var.ecs_cluster_name
                  TaskDefinition = var.training_task_definition_arn
                  NetworkConfiguration = {
                    AwsvpcConfiguration = {
                      Subnets        = var.private_subnet_ids
                      SecurityGroups = [var.lambda_security_group_id]
                      AssignPublicIp = "DISABLED"
                    }
                  }
                  Overrides = {
                    ContainerOverrides = [
                      {
                        Name = "training"
                        Environment = [
                          {
                            Name  = "GLUE_DATABASE_RAW"
                            Value = var.glue_databases.raw
                          },
                          {
                            Name  = "FEATURES_BUCKET"
                            Value = var.data_buckets.features
                          },
                          {
                            Name  = "MODELS_BUCKET"
                            Value = var.data_buckets.models
                          }
                        ]
                      }
                    ]
                  }
                }
                Retry = [
                  {
                    ErrorEquals     = ["States.TaskFailed"]
                    IntervalSeconds = 60
                    MaxAttempts     = 2
                    BackoffRate     = 2.0
                  }
                ]
                End = true
              }
            }
          },
          {
            StartAt = "Validate-Data"
            States = {
              Validate-Data = {
                Type     = "Task"
                Resource = aws_lambda_function.data_validation.arn
                Comment  = "Run Great Expectations data quality checks"
                Retry = [
                  {
                    ErrorEquals     = ["Lambda.ServiceException"]
                    IntervalSeconds = 2
                    MaxAttempts     = 3
                    BackoffRate     = 2.0
                  }
                ]
                End = true
              }
            }
          }
        ]
        Catch = [
          {
            ErrorEquals = ["States.ALL"]
            ResultPath  = "$.error"
            Next        = "Training-Failed"
          }
        ]
        Next = "Inference"
      }

      Inference = {
        Type     = "Task"
        Resource = "arn:aws:states:::ecs:runTask.sync"
        Comment  = "Run batch inference on all 100K customers"
        Parameters = {
          LaunchType     = "FARGATE"
          Cluster        = var.ecs_cluster_name
          TaskDefinition = var.inference_task_definition_arn
          NetworkConfiguration = {
            AwsvpcConfiguration = {
              Subnets        = var.private_subnet_ids
              SecurityGroups = [var.lambda_security_group_id]
              AssignPublicIp = "DISABLED"
            }
          }
          Overrides = {
            ContainerOverrides = [
              {
                Name = "inference"
                Environment = [
                  {
                    Name  = "GLUE_DATABASE_RAW"
                    Value = var.glue_databases.raw
                  },
                  {
                    Name  = "MODELS_BUCKET"
                    Value = var.data_buckets.models
                  },
                  {
                    Name  = "RESULTS_BUCKET"
                    Value = var.data_buckets.results
                  }
                ]
              }
            ]
          }
        }
        Retry = [
          {
            ErrorEquals     = ["States.TaskFailed"]
            IntervalSeconds = 60
            MaxAttempts     = 2
            BackoffRate     = 2.0
          }
        ]
        Catch = [
          {
            ErrorEquals = ["States.ALL"]
            ResultPath  = "$.error"
            Next        = "Inference-Failed"
          }
        ]
        Next = "Create-Output-Tables"
      }

      Create-Output-Tables = {
        Type    = "Parallel"
        Comment = "Create QA and final results tables in parallel"
        Branches = [
          {
            StartAt = "Create-QA-Table"
            States = {
              Create-QA-Table = {
                Type     = "Task"
                Resource = aws_lambda_function.create_qa_table.arn
                Comment  = "Create 400-row QA sample table"
                Retry = [
                  {
                    ErrorEquals     = ["Lambda.ServiceException"]
                    IntervalSeconds = 2
                    MaxAttempts     = 3
                    BackoffRate     = 2.0
                  }
                ]
                End = true
              }
            }
          },
          {
            StartAt = "Create-Results-Table"
            States = {
              Create-Results-Table = {
                Type     = "Task"
                Resource = aws_lambda_function.create_results_table.arn
                Comment  = "Create final 100K results table"
                Retry = [
                  {
                    ErrorEquals     = ["Lambda.ServiceException"]
                    IntervalSeconds = 2
                    MaxAttempts     = 3
                    BackoffRate     = 2.0
                  }
                ]
                End = true
              }
            }
          }
        ]
        Catch = [
          {
            ErrorEquals = ["States.ALL"]
            ResultPath  = "$.error"
            Next        = "Output-Tables-Failed"
          }
        ]
        End = true
      }

      Cleanup-Failed = {
        Type  = "Fail"
        Cause = "Pre-cleanup step failed"
        Error = "CleanupError"
      }

      Data-Prep-Failed = {
        Type  = "Fail"
        Cause = "Data preparation step failed"
        Error = "DataPrepError"
      }

      Training-Failed = {
        Type  = "Fail"
        Cause = "Training or validation step failed"
        Error = "TrainingError"
      }

      Inference-Failed = {
        Type  = "Fail"
        Cause = "Inference step failed"
        Error = "InferenceError"
      }

      Output-Tables-Failed = {
        Type  = "Fail"
        Cause = "Output table creation failed"
        Error = "OutputTablesError"
      }
    }
  })

  logging_configuration {
    log_destination        = "${aws_cloudwatch_log_group.step_functions.arn}:*"
    include_execution_data = true
    level                  = "ALL"
  }

  tags = merge(var.tags, {
    Name = "${var.project_name}-ml-pipeline"
  })
}

# CloudWatch Log Group for Step Functions
resource "aws_cloudwatch_log_group" "step_functions" {
  name              = "/aws/states/${var.project_name}-ml-pipeline-${var.environment}"
  retention_in_days = 30

  tags = var.tags
}

