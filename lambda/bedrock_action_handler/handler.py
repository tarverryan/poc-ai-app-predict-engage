"""
Bedrock Action Handler Lambda: Execute actions from Bedrock Agent
"""

import os
import json
import boto3
import logging

logger = logging.getLogger()
logger.setLevel(logging.INFO)

athena_client = boto3.client('athena')
s3_client = boto3.client('s3')

ENV = os.getenv('ENV', 'dev')
ATHENA_WORKGROUP = os.getenv('ATHENA_WORKGROUP')
GLUE_DATABASE_RAW = os.getenv('GLUE_DATABASE_RAW')
GLUE_DATABASE_ML = os.getenv('GLUE_DATABASE_ML')
MODELS_BUCKET = os.getenv('MODELS_BUCKET')


def lambda_handler(event, context):
    """Handle Bedrock Agent action requests"""
    logger.info(f"Bedrock action event: {json.dumps(event)}")
    
    try:
        # Parse Bedrock agent request
        agent_request = event.get('requestBody', {}).get('content', {}).get('application/json', {})
        action_group = event.get('actionGroup')
        api_path = event.get('apiPath')
        
        # Route to appropriate handler
        if api_path == '/query_athena':
            result = handle_query_athena(agent_request)
        elif api_path == '/get_customer_details':
            result = handle_get_customer(agent_request)
        elif api_path == '/explain_prediction':
            result = handle_explain_prediction(agent_request)
        else:
            result = {'error': f'Unknown action: {api_path}'}
        
        # Format response for Bedrock
        return {
            'messageVersion': '1.0',
            'response': {
                'actionGroup': action_group,
                'apiPath': api_path,
                'httpMethod': event.get('httpMethod', 'GET'),
                'httpStatusCode': 200,
                'responseBody': {
                    'application/json': {
                        'body': json.dumps(result)
                    }
                }
            }
        }
        
    except Exception as e:
        logger.error(f"❌ Bedrock action failed: {e}", exc_info=True)
        return {
            'messageVersion': '1.0',
            'response': {
                'httpStatusCode': 500,
                'responseBody': {'application/json': {'body': json.dumps({'error': str(e)})}}
            }
        }


def handle_query_athena(request: dict) -> dict:
    """Execute Athena SQL query"""
    query = request.get('query', '')
    database = request.get('database', GLUE_DATABASE_RAW)
    
    # Execute query (simplified - in prod, add result parsing)
    response = athena_client.start_query_execution(
        QueryString=query,
        QueryExecutionContext={'Database': database},
        WorkGroup=ATHENA_WORKGROUP
    )
    
    return {
        'execution_id': response['QueryExecutionId'],
        'status': 'Query submitted'
    }


def handle_get_customer(request: dict) -> dict:
    """Get customer details by ID"""
    customer_id = request.get('customer_id', '')
    
    # In production, query Athena or S3 for customer data
    return {
        'customer_id': customer_id,
        'status': 'Customer data retrieved (mock)'
    }


def handle_explain_prediction(request: dict) -> dict:
    """Explain prediction using SHAP values"""
    customer_id = request.get('customer_id', '')
    model_name = request.get('model_name', 'engagement')
    
    # In production, load SHAP values from S3
    return {
        'customer_id': customer_id,
        'model_name': model_name,
        'top_features': ['sessions_last_7_days', 'tenure_months', 'followers_count'],
        'status': 'Explanation retrieved (mock)'
    }

