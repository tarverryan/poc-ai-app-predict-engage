# Outputs for AI Module

# Bedrock Knowledge Base
output "knowledge_base_id" {
  description = "ID of the Bedrock Knowledge Base"
  value       = aws_bedrockagent_knowledge_base.engagement.id
}

output "knowledge_base_arn" {
  description = "ARN of the Bedrock Knowledge Base"
  value       = aws_bedrockagent_knowledge_base.engagement.arn
}

output "knowledge_base_name" {
  description = "Name of the Bedrock Knowledge Base"
  value       = aws_bedrockagent_knowledge_base.engagement.name
}

# Bedrock Knowledge Base Data Source
output "knowledge_base_data_source_id" {
  description = "ID of the Bedrock Knowledge Base data source"
  value       = aws_bedrockagent_data_source.engagement_docs.data_source_id
}

# Bedrock Agent
output "agent_id" {
  description = "ID of the Bedrock Agent"
  value       = aws_bedrockagent_agent.engagement.agent_id
}

output "agent_arn" {
  description = "ARN of the Bedrock Agent"
  value       = aws_bedrockagent_agent.engagement.agent_arn
}

output "agent_name" {
  description = "Name of the Bedrock Agent"
  value       = aws_bedrockagent_agent.engagement.agent_name
}

# Bedrock Agent Alias
output "agent_alias_id" {
  description = "ID of the Bedrock Agent alias"
  value       = aws_bedrockagent_agent_alias.engagement.agent_alias_id
}

output "agent_alias_arn" {
  description = "ARN of the Bedrock Agent alias"
  value       = aws_bedrockagent_agent_alias.engagement.agent_alias_arn
}

output "agent_alias_name" {
  description = "Name of the Bedrock Agent alias"
  value       = aws_bedrockagent_agent_alias.engagement.agent_alias_name
}

# IAM Roles
output "bedrock_kb_role_arn" {
  description = "ARN of the Bedrock Knowledge Base IAM role"
  value       = aws_iam_role.bedrock_kb.arn
}

output "bedrock_agent_role_arn" {
  description = "ARN of the Bedrock Agent IAM role"
  value       = aws_iam_role.bedrock_agent.arn
}

# Combined outputs for convenience
output "bedrock_endpoints" {
  description = "Map of Bedrock service endpoints"
  value = {
    knowledge_base_id = aws_bedrockagent_knowledge_base.engagement.id
    agent_id          = aws_bedrockagent_agent.engagement.agent_id
    agent_alias_id    = aws_bedrockagent_agent_alias.engagement.agent_alias_id
  }
}

