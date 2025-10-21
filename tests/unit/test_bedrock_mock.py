"""
Test suite for Bedrock mock functionality
"""

import json
import sys
sys.path.insert(0, '..')

from mocks.bedrock_mock import (
    MockBedrockRuntime,
    MockBedrockAgent,
    mock_bedrock_runtime,
    mock_bedrock_agent
)


def test_bedrock_runtime_claude():
    """Test mocking Bedrock Runtime with Claude"""
    
    print("\n=== Testing Bedrock Runtime (Claude) ===")
    
    client = MockBedrockRuntime(region_name='us-east-1')
    
    # Test invoke_model
    request_body = {
        'prompt': 'What are the key features for predicting customer engagement?',
        'max_tokens_to_sample': 500,
        'temperature': 0.7
    }
    
    response = client.invoke_model(
        modelId='anthropic.claude-3-5-sonnet-20240620-v1:0',
        body=json.dumps(request_body)
    )
    
    # Parse response
    response_body = json.loads(response['body'].decode('utf-8'))
    print(f"✓ Status Code: {response['ResponseMetadata']['HTTPStatusCode']}")
    print(f"✓ Response (first 200 chars): {response_body['completion'][:200]}...")
    print(f"✓ Stop Reason: {response_body.get('stop_reason')}")
    
    assert response['ResponseMetadata']['HTTPStatusCode'] == 200
    assert 'completion' in response_body
    assert len(response_body['completion']) > 0
    
    print("✅ Claude mock test PASSED")


def test_bedrock_agent_invoke():
    """Test mocking Bedrock Agent"""
    
    print("\n=== Testing Bedrock Agent ===")
    
    client = MockBedrockAgent(region_name='us-east-1')
    
    response = client.invoke_agent(
        agentId='TEST123',
        agentAliasId='ALIAS456',
        sessionId='session-789',
        inputText='What is the average customer LTV?'
    )
    
    print(f"✓ Status Code: {response['ResponseMetadata']['HTTPStatusCode']}")
    print(f"✓ Session ID: {response['sessionId']}")
    
    # Get response text from chunks
    response_text = response['completion'][0]['chunk']['bytes'].decode('utf-8')
    print(f"✓ Response (first 200 chars): {response_text[:200]}...")
    
    assert response['ResponseMetadata']['HTTPStatusCode'] == 200
    assert response['sessionId'] == 'session-789'
    assert len(response_text) > 0
    
    print("✅ Agent invoke test PASSED")


def test_bedrock_kb_retrieve():
    """Test mocking Knowledge Base retrieval"""
    
    print("\n=== Testing Knowledge Base Retrieval ===")
    
    client = MockBedrockAgent(region_name='us-east-1')
    
    response = client.retrieve(
        knowledgeBaseId='KB123',
        retrievalQuery={'text': 'engagement score definition'}
    )
    
    results = response['retrievalResults']
    
    print(f"✓ Retrieved {len(results)} results")
    for i, result in enumerate(results, 1):
        print(f"✓ Result {i} - Score: {result['score']:.2f}, Source: {result['metadata']['source']}")
        print(f"  Content: {result['content']['text'][:80]}...")
    
    assert len(results) > 0
    assert all('score' in r for r in results)
    assert all('content' in r for r in results)
    
    print("✅ KB retrieval test PASSED")


def test_bedrock_rag():
    """Test mocking Retrieve and Generate (RAG)"""
    
    print("\n=== Testing Retrieve and Generate (RAG) ===")
    
    client = MockBedrockAgent(region_name='us-east-1')
    
    response = client.retrieve_and_generate(
        input={'text': 'How do I improve customer engagement?'}
    )
    
    generated_text = response['output']['text']
    citations = response['citations']
    
    print(f"✓ Generated Response (first 200 chars): {generated_text[:200]}...")
    print(f"✓ Citations: {len(citations)}")
    
    assert len(generated_text) > 0
    assert len(citations) > 0
    
    print("✅ RAG test PASSED")


@mock_bedrock_runtime
def test_decorator_mock():
    """Test using decorator for mocking"""
    
    print("\n=== Testing Decorator Mock ===")
    
    import boto3
    
    # This will use the mock!
    client = boto3.client('bedrock-runtime', region_name='us-east-1')
    
    response = client.invoke_model(
        modelId='anthropic.claude-3-5-sonnet-20240620-v1:0',
        body=json.dumps({'prompt': 'Test prompt', 'max_tokens_to_sample': 100})
    )
    
    print(f"✓ Decorator mock working!")
    print(f"✓ Status: {response['ResponseMetadata']['HTTPStatusCode']}")
    
    assert response['ResponseMetadata']['HTTPStatusCode'] == 200
    
    print("✅ Decorator test PASSED")


def run_all_tests():
    """Run all Bedrock mock tests"""
    
    print("="*60)
    print("BEDROCK MOCK TEST SUITE")
    print("="*60)
    
    tests = [
        test_bedrock_runtime_claude,
        test_bedrock_agent_invoke,
        test_bedrock_kb_retrieve,
        test_bedrock_rag,
        test_decorator_mock
    ]
    
    passed = 0
    failed = 0
    
    for test in tests:
        try:
            test()
            passed += 1
        except Exception as e:
            print(f"\n❌ {test.__name__} FAILED: {e}")
            failed += 1
    
    print("\n" + "="*60)
    print(f"TEST RESULTS: {passed} passed, {failed} failed")
    print("="*60)
    
    if failed == 0:
        print("\n✅ ALL BEDROCK MOCK TESTS PASSED!")
        return True
    else:
        print(f"\n⚠️ {failed} test(s) failed")
        return False


if __name__ == '__main__':
    success = run_all_tests()
    sys.exit(0 if success else 1)

