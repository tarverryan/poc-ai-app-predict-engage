"""
Pre-Cleanup Lambda: Clean up old Athena tables and temp S3 data
"""

import os
import boto3
import logging

logger = logging.getLogger()
logger.setLevel(logging.INFO)

s3_client = boto3.client('s3')
athena_client = boto3.client('athena')
glue_client = boto3.client('glue')

ENV = os.getenv('ENV', 'dev')
RESULTS_BUCKET = os.getenv('RESULTS_BUCKET')
FEATURES_BUCKET = os.getenv('FEATURES_BUCKET')
ATHENA_RESULTS_BUCKET = os.getenv('ATHENA_RESULTS_BUCKET')
GLUE_DATABASE_ML = os.getenv('GLUE_DATABASE_ML')


def lambda_handler(event, context):
    """Clean up old data before new pipeline run"""
    logger.info("Starting pre-cleanup...")
    
    try:
        # 1. Delete old temp files in features bucket
        delete_s3_prefix(FEATURES_BUCKET, 'temp/')
        
        # 2. Delete old Athena query results (keep last 100)
        cleanup_athena_results(ATHENA_RESULTS_BUCKET)
        
        # 3. Drop temporary Glue tables
        drop_temp_tables(GLUE_DATABASE_ML, ['temp_', 'staging_'])
        
        logger.info("✅ Pre-cleanup completed successfully")
        
        return {
            'statusCode': 200,
            'body': 'Cleanup completed',
            'cleaned_locations': [
                f's3://{FEATURES_BUCKET}/temp/',
                f's3://{ATHENA_RESULTS_BUCKET}/query-results/'
            ]
        }
        
    except Exception as e:
        logger.error(f"❌ Pre-cleanup failed: {e}", exc_info=True)
        raise


def delete_s3_prefix(bucket: str, prefix: str):
    """Delete all objects under a prefix"""
    paginator = s3_client.get_paginator('list_objects_v2')
    pages = paginator.paginate(Bucket=bucket, Prefix=prefix)
    
    count = 0
    for page in pages:
        if 'Contents' not in page:
            continue
        
        objects = [{'Key': obj['Key']} for obj in page['Contents']]
        if objects:
            s3_client.delete_objects(Bucket=bucket, Delete={'Objects': objects})
            count += len(objects)
    
    logger.info(f"Deleted {count} objects from s3://{bucket}/{prefix}")


def cleanup_athena_results(bucket: str):
    """Keep only last 100 query results"""
    response = s3_client.list_objects_v2(
        Bucket=bucket,
        Prefix='query-results/',
        MaxKeys=1000
    )
    
    if 'Contents' not in response or len(response['Contents']) <= 100:
        return
    
    # Sort by date and delete oldest
    objects = sorted(response['Contents'], key=lambda x: x['LastModified'], reverse=True)
    to_delete = [{'Key': obj['Key']} for obj in objects[100:]]
    
    if to_delete:
        s3_client.delete_objects(Bucket=bucket, Delete={'Objects': to_delete})
        logger.info(f"Deleted {len(to_delete)} old Athena query results")


def drop_temp_tables(database: str, prefixes: list):
    """Drop temporary Glue tables"""
    try:
        response = glue_client.get_tables(DatabaseName=database)
        tables = response.get('TableList', [])
        
        for table in tables:
            table_name = table['Name']
            if any(table_name.startswith(prefix) for prefix in prefixes):
                glue_client.delete_table(DatabaseName=database, Name=table_name)
                logger.info(f"Dropped table {database}.{table_name}")
    except Exception as e:
        logger.warning(f"Failed to drop temp tables: {e}")

