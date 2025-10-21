# Bedrock Agent Configuration

# Bedrock Agent
resource "aws_bedrockagent_agent" "engagement" {
  agent_name              = "${var.project_name}-agent-${var.environment}"
  agent_resource_role_arn = aws_iam_role.bedrock_agent.arn
  foundation_model        = "anthropic.claude-3-5-sonnet-20240620-v1:0"
  description             = "AI agent for customer engagement analysis and predictions"
  idle_session_ttl_in_seconds = 600

  instruction = <<EOF
You are an AI assistant specialized in customer engagement analysis and machine learning model interpretation. 

Your role is to help users understand:
1. Customer engagement patterns and trends
2. Model predictions and feature importance
3. Strategies to improve customer engagement
4. Fairness and bias analysis across demographic groups
5. Performance metrics and model quality

You have access to:
- A knowledge base containing model metrics, feature importance, and data dictionaries
- Action groups to query customer data, retrieve predictions, and explain model decisions

When answering questions:
- Be concise and data-driven
- Cite specific metrics and sources from the knowledge base
- Provide actionable recommendations
- Highlight any fairness concerns or demographic disparities
- Explain technical concepts in business-friendly language

Always acknowledge uncertainty and recommend human review for critical decisions.
EOF

  tags = merge(var.tags, {
    Name = "${var.project_name}-bedrock-agent"
  })
}

# Bedrock Agent Knowledge Base Association
resource "aws_bedrockagent_agent_knowledge_base_association" "engagement" {
  agent_id             = aws_bedrockagent_agent.engagement.agent_id
  description          = "Knowledge base for engagement model metrics and feature importance"
  knowledge_base_id    = aws_bedrockagent_knowledge_base.engagement.id
  knowledge_base_state = "ENABLED"
}

# Bedrock Agent Action Group
resource "aws_bedrockagent_agent_action_group" "engagement_actions" {
  agent_id      = aws_bedrockagent_agent.engagement.agent_id
  agent_version = "DRAFT"
  action_group_name = "engagement-actions"
  description   = "Actions for querying customer data and predictions"

  action_group_executor {
    lambda = var.bedrock_action_handler_lambda_arn
  }

  api_schema {
    payload = jsonencode({
      openapi = "3.0.0"
      info = {
        title   = "Customer Engagement Actions"
        version = "1.0.0"
        description = "API for querying customer engagement data and predictions"
      }
      paths = {
        "/query_athena" = {
          post = {
            summary     = "Execute Athena SQL query"
            description = "Run a SQL query against the customer engagement database"
            operationId = "query_athena"
            requestBody = {
              required = true
              content = {
                "application/json" = {
                  schema = {
                    type = "object"
                    properties = {
                      query = {
                        type        = "string"
                        description = "SQL query to execute"
                      }
                      database = {
                        type        = "string"
                        description = "Glue database name"
                        default     = "raw"
                      }
                    }
                    required = ["query"]
                  }
                }
              }
            }
            responses = {
              "200" = {
                description = "Query results"
                content = {
                  "application/json" = {
                    schema = {
                      type = "object"
                      properties = {
                        rows = {
                          type = "array"
                          items = {
                            type = "object"
                          }
                        }
                        row_count = {
                          type = "integer"
                        }
                      }
                    }
                  }
                }
              }
            }
          }
        }
        "/get_customer_details" = {
          get = {
            summary     = "Get customer details by ID"
            description = "Retrieve full customer profile and engagement metrics"
            operationId = "get_customer_details"
            parameters = [
              {
                name        = "customer_id"
                in          = "query"
                description = "Customer UUID"
                required    = true
                schema = {
                  type = "string"
                }
              }
            ]
            responses = {
              "200" = {
                description = "Customer details"
                content = {
                  "application/json" = {
                    schema = {
                      type = "object"
                      properties = {
                        customer_id        = { type = "string" }
                        age                = { type = "integer" }
                        gender             = { type = "string" }
                        location           = { type = "string" }
                        engagement_score   = { type = "number" }
                        tenure_months      = { type = "integer" }
                        churn_30_day       = { type = "integer" }
                        lifetime_value_usd = { type = "number" }
                      }
                    }
                  }
                }
              }
            }
          }
        }
        "/explain_prediction" = {
          get = {
            summary     = "Explain model prediction for a customer"
            description = "Get SHAP values and feature importance for a customer's prediction"
            operationId = "explain_prediction"
            parameters = [
              {
                name        = "customer_id"
                in          = "query"
                description = "Customer UUID"
                required    = true
                schema = {
                  type = "string"
                }
              },
              {
                name        = "model_name"
                in          = "query"
                description = "Model name (engagement, churn, ltv, etc.)"
                required    = false
                schema = {
                  type    = "string"
                  default = "engagement"
                }
              }
            ]
            responses = {
              "200" = {
                description = "Prediction explanation"
                content = {
                  "application/json" = {
                    schema = {
                      type = "object"
                      properties = {
                        customer_id       = { type = "string" }
                        model_name        = { type = "string" }
                        prediction        = { type = "number" }
                        shap_values       = { type = "object" }
                        top_features      = { type = "array" }
                      }
                    }
                  }
                }
              }
            }
          }
        }
      }
    })
  }
}

# Bedrock Agent Alias
resource "aws_bedrockagent_agent_alias" "engagement" {
  agent_alias_name = "production"
  agent_id         = aws_bedrockagent_agent.engagement.agent_id
  description      = "Production alias for the engagement agent"

  tags = merge(var.tags, {
    Name = "${var.project_name}-agent-alias"
  })
}

