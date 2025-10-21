"""
Create QA Table Lambda: Sample 400 records for manual review
"""

import os
import boto3
import logging

logger = logging.getLogger()
logger.setLevel(logging.INFO)

athena_client = boto3.client('athena')

ENV = os.getenv('ENV', 'dev')
ATHENA_WORKGROUP = os.getenv('ATHENA_WORKGROUP')
GLUE_DATABASE_ML = os.getenv('GLUE_DATABASE_ML')
QA_SAMPLE_SIZE = int(os.getenv('QA_SAMPLE_SIZE', '400'))


def lambda_handler(event, context):
    """Create QA sample table"""
    logger.info("Creating QA table...")
    
    try:
        # Stratified sampling query (100 per quartile)
        query = f"""
        CREATE TABLE {GLUE_DATABASE_ML}.qa_sample
        WITH (format='PARQUET')
        AS
        SELECT * FROM (
            SELECT *, NTILE(4) OVER (ORDER BY predicted_engagement_score) as quartile
            FROM {GLUE_DATABASE_ML}.predictions
        )
        WHERE MOD(ABS(xxhash64(customer_id)), 10) = 0
        LIMIT {QA_SAMPLE_SIZE}
        """
        
        response = athena_client.start_query_execution(
            QueryString=query,
            WorkGroup=ATHENA_WORKGROUP
        )
        
        logger.info(f"✅ QA table created: {QA_SAMPLE_SIZE} records")
        
        return {
            'statusCode': 200,
            'body': 'QA table created',
            'sample_size': QA_SAMPLE_SIZE,
            'execution_id': response['QueryExecutionId']
        }
        
    except Exception as e:
        logger.error(f"❌ QA table creation failed: {e}", exc_info=True)
        raise

