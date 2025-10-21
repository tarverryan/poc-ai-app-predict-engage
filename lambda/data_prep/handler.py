"""
Data Prep Lambda: Create train/test splits via Athena queries
"""

import os
import boto3
import logging
import time

logger = logging.getLogger()
logger.setLevel(logging.INFO)

athena_client = boto3.client('athena')

ENV = os.getenv('ENV', 'dev')
ATHENA_WORKGROUP = os.getenv('ATHENA_WORKGROUP')
ATHENA_RESULTS_BUCKET = os.getenv('ATHENA_RESULTS_BUCKET')
GLUE_DATABASE_RAW = os.getenv('GLUE_DATABASE_RAW')
GLUE_DATABASE_PROCESSED = os.getenv('GLUE_DATABASE_PROCESSED')


def lambda_handler(event, context):
    """Prepare data splits for ML training"""
    logger.info("Starting data preparation...")
    
    try:
        # Create train/test split (80/20) using MOD hash
        query_train = f"""
        CREATE TABLE {GLUE_DATABASE_PROCESSED}.customers_train
        WITH (format='PARQUET', external_location='s3://{os.getenv('PROCESSED_BUCKET')}/train/')
        AS SELECT * FROM {GLUE_DATABASE_RAW}.customers
        WHERE MOD(ABS(xxhash64(customer_id)), 10) < 8
        """
        
        query_test = f"""
        CREATE TABLE {GLUE_DATABASE_PROCESSED}.customers_test
        WITH (format='PARQUET', external_location='s3://{os.getenv('PROCESSED_BUCKET')}/test/')
        AS SELECT * FROM {GLUE_DATABASE_RAW}.customers
        WHERE MOD(ABS(xxhash64(customer_id)), 10) >= 8
        """
        
        # Execute queries
        train_execution_id = execute_athena_query(query_train)
        test_execution_id = execute_athena_query(query_test)
        
        # Wait for completion
        wait_for_query(train_execution_id)
        wait_for_query(test_execution_id)
        
        logger.info("✅ Data preparation completed successfully")
        
        return {
            'statusCode': 200,
            'body': 'Data split created',
            'train_execution_id': train_execution_id,
            'test_execution_id': test_execution_id
        }
        
    except Exception as e:
        logger.error(f"❌ Data prep failed: {e}", exc_info=True)
        raise


def execute_athena_query(query: str) -> str:
    """Execute Athena query and return execution ID"""
    response = athena_client.start_query_execution(
        QueryString=query,
        WorkGroup=ATHENA_WORKGROUP,
        ResultConfiguration={'OutputLocation': f's3://{ATHENA_RESULTS_BUCKET}/query-results/'}
    )
    return response['QueryExecutionId']


def wait_for_query(execution_id: str, max_wait: int = 300):
    """Wait for Athena query to complete"""
    start = time.time()
    while time.time() - start < max_wait:
        response = athena_client.get_query_execution(QueryExecutionId=execution_id)
        state = response['QueryExecution']['Status']['State']
        
        if state in ['SUCCEEDED']:
            return
        elif state in ['FAILED', 'CANCELLED']:
            raise Exception(f"Query {execution_id} failed: {state}")
        
        time.sleep(5)
    
    raise TimeoutError(f"Query {execution_id} timed out after {max_wait}s")

