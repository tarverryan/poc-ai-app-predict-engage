"""
Mock Bedrock Runtime for Local Testing

This mock simulates AWS Bedrock responses for:
- InvokeModel (text generation)
- InvokeModelWithResponseStream (streaming)
- Retrieve (Knowledge Base retrieval)
- RetrieveAndGenerate (KB + generation)

Usage:
    from tests.mocks.bedrock_mock import mock_bedrock_runtime
    
    @mock_bedrock_runtime
    def test_my_function():
        # Your test code here
        pass
"""

import json
import random
from unittest.mock import MagicMock, patch
from typing import Dict, Any, List


class MockBedrockRuntime:
    """Mock AWS Bedrock Runtime client"""
    
    def __init__(self, **kwargs):
        self.region = kwargs.get('region_name', 'us-east-1')
    
    def invoke_model(self, modelId: str, body: str, **kwargs) -> Dict[str, Any]:
        """Mock invoke_model for text generation"""
        
        # Parse request
        request_body = json.loads(body)
        prompt = request_body.get('prompt', '')
        max_tokens = request_body.get('max_tokens_to_sample', 1000)
        
        # Generate mock response based on model
        if 'claude' in modelId.lower():
            response_text = self._generate_claude_response(prompt, max_tokens)
            response_body = {
                'completion': response_text,
                'stop_reason': 'end_turn',
                'model': modelId
            }
        elif 'titan' in modelId.lower():
            response_text = self._generate_titan_response(prompt, max_tokens)
            response_body = {
                'results': [{'outputText': response_text}],
                'inputTextTokenCount': len(prompt.split()),
                'model': modelId
            }
        else:
            response_text = "This is a mock response from Bedrock."
            response_body = {'text': response_text}
        
        return {
            'body': json.dumps(response_body).encode('utf-8'),
            'contentType': 'application/json',
            'ResponseMetadata': {
                'RequestId': f'mock-request-{random.randint(1000, 9999)}',
                'HTTPStatusCode': 200
            }
        }
    
    def _generate_claude_response(self, prompt: str, max_tokens: int) -> str:
        """Generate mock Claude response"""
        
        # Context-aware mock responses
        if 'engagement' in prompt.lower():
            return """Based on the customer engagement data, here are key insights:

1. **High Engagement Indicators:**
   - Sessions > 5 per week
   - Session duration > 15 minutes
   - Follower growth rate > 10%
   - Active content creation (posts/stories)

2. **Improvement Strategies for Low Engagement:**
   - Personalized push notifications
   - Gamification features
   - Community engagement initiatives
   - Premium feature trials

3. **Churn Risk Factors:**
   - Declining session frequency
   - Low social interaction
   - Limited content consumption

These insights are derived from analyzing customer behavior patterns."""

        elif 'churn' in prompt.lower():
            return """Customer churn analysis reveals:

**High-Risk Indicators:**
- No sessions in last 7 days
- Engagement score < 0.3
- Declining trend in past month
- Low social connections

**Retention Strategies:**
- Re-engagement campaigns
- Personalized offers
- Win-back emails
- Feature education

**Model Performance:**
- AUC-ROC: 0.85
- Precision: 0.78
- Recall: 0.82"""

        elif 'feature' in prompt.lower() and 'importance' in prompt.lower():
            return """Top predictive features for engagement:

1. **sessions_last_7_days** (importance: 0.23)
2. **tenure_months** (importance: 0.18)
3. **followers_count** (importance: 0.15)
4. **content_virality_score** (importance: 0.12)
5. **total_connections** (importance: 0.10)

These features show strong correlation with customer engagement patterns."""

        else:
            return f"""I understand you're asking about: {prompt[:100]}...

Based on the customer engagement prediction platform data, I can help you with:
- Understanding engagement patterns
- Identifying churn risks
- Analyzing feature importance
- Recommending improvement strategies

Please ask a specific question about customer engagement, churn, or model performance."""
    
    def _generate_titan_response(self, prompt: str, max_tokens: int) -> str:
        """Generate mock Titan response"""
        return f"Mock Titan response for: {prompt[:100]}..."


class MockBedrockAgent:
    """Mock AWS Bedrock Agent client"""
    
    def __init__(self, **kwargs):
        self.region = kwargs.get('region_name', 'us-east-1')
    
    def invoke_agent(self, agentId: str, agentAliasId: str, sessionId: str, 
                     inputText: str, **kwargs) -> Dict[str, Any]:
        """Mock invoke_agent for agent interactions"""
        
        response_text = f"""Agent Response:

Question: {inputText}

Based on the knowledge base and customer engagement data:

1. Current engagement metrics show 37.9% churn rate
2. Average LTV is $455.10
3. Top features: sessions_last_7_days, tenure_months, followers_count

I can query specific data using action groups if you need detailed analysis."""
        
        return {
            'completion': [
                {
                    'chunk': {
                        'bytes': response_text.encode('utf-8')
                    }
                }
            ],
            'sessionId': sessionId,
            'ResponseMetadata': {
                'RequestId': f'mock-agent-{random.randint(1000, 9999)}',
                'HTTPStatusCode': 200
            }
        }
    
    def retrieve(self, knowledgeBaseId: str, retrievalQuery: Dict[str, str], 
                 **kwargs) -> Dict[str, Any]:
        """Mock retrieve from Knowledge Base"""
        
        query_text = retrievalQuery.get('text', '')
        
        # Mock retrieval results
        results = [
            {
                'content': {'text': 'Engagement score ranges from 0 to 1, with higher values indicating more active users.'},
                'score': 0.95,
                'location': {'s3Location': {'uri': 's3://kb-bucket/data_dictionary.md'}},
                'metadata': {'source': 'data_dictionary'}
            },
            {
                'content': {'text': 'Key features: sessions_last_7_days, tenure_months, followers_count, engagement_score.'},
                'score': 0.87,
                'location': {'s3Location': {'uri': 's3://kb-bucket/features.md'}},
                'metadata': {'source': 'feature_docs'}
            },
            {
                'content': {'text': 'Model performance: Engagement RMSE 0.12, Churn AUC-ROC 0.85, LTV R² 0.78.'},
                'score': 0.82,
                'location': {'s3Location': {'uri': 's3://kb-bucket/model_metrics.md'}},
                'metadata': {'source': 'metrics'}
            }
        ]
        
        return {
            'retrievalResults': results,
            'ResponseMetadata': {
                'RequestId': f'mock-retrieve-{random.randint(1000, 9999)}',
                'HTTPStatusCode': 200
            }
        }
    
    def retrieve_and_generate(self, input: Dict[str, Any], **kwargs) -> Dict[str, Any]:
        """Mock retrieve_and_generate (RAG)"""
        
        query_text = input.get('text', '')
        
        # Simulate RAG response
        generated_text = f"""Based on the knowledge base, here's what I found about: {query_text}

**Retrieved Information:**
- Engagement score definition and ranges
- Key predictive features and their importance
- Model performance metrics

**Analysis:**
The customer engagement platform uses 42 features to predict engagement, churn, and LTV. 
The models achieve strong performance with engagement RMSE of 0.12 and churn AUC-ROC of 0.85.

Top recommendations:
1. Focus on increasing session frequency
2. Improve content virality
3. Build stronger social connections"""
        
        return {
            'output': {'text': generated_text},
            'citations': [
                {
                    'generatedResponsePart': {'textResponsePart': {'text': 'engagement score'}},
                    'retrievedReferences': [
                        {'content': {'text': 'Engagement score ranges from 0 to 1...'}}
                    ]
                }
            ],
            'ResponseMetadata': {
                'RequestId': f'mock-rag-{random.randint(1000, 9999)}',
                'HTTPStatusCode': 200
            }
        }


# Decorator for easy mocking
def mock_bedrock_runtime(func):
    """Decorator to mock Bedrock Runtime client"""
    def wrapper(*args, **kwargs):
        with patch('boto3.client') as mock_client:
            # Return mock when 'bedrock-runtime' is requested
            def client_factory(service_name, **client_kwargs):
                if service_name == 'bedrock-runtime':
                    return MockBedrockRuntime(**client_kwargs)
                elif service_name == 'bedrock-agent-runtime':
                    return MockBedrockAgent(**client_kwargs)
                else:
                    # Return real client for other services
                    import boto3
                    return boto3.client(service_name, **client_kwargs)
            
            mock_client.side_effect = client_factory
            return func(*args, **kwargs)
    
    return wrapper


def mock_bedrock_agent(func):
    """Decorator to mock Bedrock Agent client"""
    def wrapper(*args, **kwargs):
        with patch('boto3.client') as mock_client:
            def client_factory(service_name, **client_kwargs):
                if service_name in ['bedrock-agent', 'bedrock-agent-runtime']:
                    return MockBedrockAgent(**client_kwargs)
                else:
                    import boto3
                    return boto3.client(service_name, **client_kwargs)
            
            mock_client.side_effect = client_factory
            return func(*args, **kwargs)
    
    return wrapper


# Standalone mock instances for manual use
def get_mock_bedrock_runtime(**kwargs):
    """Get a mock Bedrock Runtime client instance"""
    return MockBedrockRuntime(**kwargs)


def get_mock_bedrock_agent(**kwargs):
    """Get a mock Bedrock Agent client instance"""
    return MockBedrockAgent(**kwargs)

