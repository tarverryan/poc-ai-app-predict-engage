"""
Create Results Table Lambda: Join original features + predictions
"""

import os
import boto3
import logging

logger = logging.getLogger()
logger.setLevel(logging.INFO)

athena_client = boto3.client('athena')

ENV = os.getenv('ENV', 'dev')
ATHENA_WORKGROUP = os.getenv('ATHENA_WORKGROUP')
GLUE_DATABASE_RAW = os.getenv('GLUE_DATABASE_RAW')
GLUE_DATABASE_ML = os.getenv('GLUE_DATABASE_ML')
RESULTS_BUCKET = os.getenv('RESULTS_BUCKET')


def lambda_handler(event, context):
    """Create final results table"""
    logger.info("Creating results table...")
    
    try:
        query = f"""
        CREATE TABLE {GLUE_DATABASE_ML}.predictions_final
        WITH (format='PARQUET', external_location='s3://{RESULTS_BUCKET}/final/')
        AS
        SELECT 
            c.*,
            p.predicted_engagement_score,
            p.predicted_churn,
            p.predicted_churn_probability,
            p.predicted_ltv_usd,
            p.anomaly_score,
            p.is_anomaly,
            p.model_version,
            p.prediction_timestamp
        FROM {GLUE_DATABASE_RAW}.customers c
        LEFT JOIN {GLUE_DATABASE_ML}.predictions p
        ON c.customer_id = p.customer_id
        """
        
        response = athena_client.start_query_execution(
            QueryString=query,
            WorkGroup=ATHENA_WORKGROUP
        )
        
        logger.info("✅ Results table created successfully")
        
        return {
            'statusCode': 200,
            'body': 'Results table created',
            'execution_id': response['QueryExecutionId'],
            'table': f'{GLUE_DATABASE_ML}.predictions_final'
        }
        
    except Exception as e:
        logger.error(f"❌ Results table creation failed: {e}", exc_info=True)
        raise

