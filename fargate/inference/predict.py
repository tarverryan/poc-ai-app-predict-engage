#!/usr/bin/env python3
"""
Batch Inference Script for Customer Engagement Platform

Generates predictions for all 100K customers using trained models.
"""

import os
import json
import time
import logging
from datetime import datetime

import boto3
import pandas as pd
import numpy as np
import joblib
import awswrangler as wr

# Configure logging
logging.basicConfig(level=logging.INFO, format='%(asctime)s - %(levelname)s - %(message)s')
logger = logging.getLogger(__name__)

# Environment variables
ENV = os.getenv('ENV', 'dev')
AWS_REGION = os.getenv('AWS_REGION', 'us-east-1')
GLUE_DATABASE_RAW = os.getenv('GLUE_DATABASE_RAW')
GLUE_DATABASE_ML = os.getenv('GLUE_DATABASE_ML')
MODELS_BUCKET = os.getenv('MODELS_BUCKET')
RESULTS_BUCKET = os.getenv('RESULTS_BUCKET')
MODEL_VERSION = os.getenv('MODEL_VERSION', 'v1.0')

# Initialize AWS clients
s3_client = boto3.client('s3', region_name=AWS_REGION)
cloudwatch = boto3.client('cloudwatch', region_name=AWS_REGION)


def publish_metric(metric_name: str, value: float, unit: str = 'None'):
    """Publish custom metric to CloudWatch"""
    try:
        cloudwatch.put_metric_data(
            Namespace='MLPipeline/Inference',
            MetricData=[
                {'MetricName': metric_name, 'Value': value, 'Unit': unit, 'Timestamp': datetime.utcnow()}
            ]
        )
    except Exception as e:
        logger.warning(f"Failed to publish metric {metric_name}: {e}")


def load_models_from_s3() -> dict:
    """Load all trained models from S3"""
    logger.info("Loading models from S3...")
    
    models = {}
    model_names = ['engagement', 'churn', 'ltv', 'anomaly']
    
    for model_name in model_names:
        # Find latest model file
        prefix = f"models/{MODEL_VERSION}/{model_name}_"
        response = s3_client.list_objects_v2(Bucket=MODELS_BUCKET, Prefix=prefix)
        
        if 'Contents' not in response:
            raise FileNotFoundError(f"No models found for {model_name} in {prefix}")
        
        # Get latest model
        latest = sorted(response['Contents'], key=lambda x: x['LastModified'], reverse=True)[0]
        model_key = latest['Key']
        
        # Download and load model
        model_path = f"/tmp/{model_name}.pkl"
        s3_client.download_file(MODELS_BUCKET, model_key, model_path)
        models[model_name] = joblib.load(model_path)
        
        logger.info(f"Loaded {model_name} model from s3://{MODELS_BUCKET}/{model_key}")
    
    # Load scaler
    scaler_key = f"preprocessing/scaler_{MODEL_VERSION}.pkl"
    scaler_path = "/tmp/scaler.pkl"
    s3_client.download_file(MODELS_BUCKET, scaler_key, scaler_path)
    models['scaler'] = joblib.load(scaler_path)
    
    return models


def load_customer_data() -> pd.DataFrame:
    """Load customer data from Athena"""
    logger.info("Loading customer data from Athena...")
    query = f"SELECT * FROM {GLUE_DATABASE_RAW}.customers"
    df = wr.athena.read_sql_query(query, database=GLUE_DATABASE_RAW)
    logger.info(f"Loaded {len(df)} customer records")
    return df


def prepare_features(df: pd.DataFrame, scaler) -> tuple:
    """Prepare features for inference"""
    logger.info("Preparing features...")
    
    # Feature engineering (same as training)
    df = df.copy()
    df['engagement_per_session'] = df['engagement_score'] / (df['sessions_last_7_days'] + 1)
    df['avg_session_value'] = df['session_duration_avg_minutes'] * df['engagement_score']
    df['follower_following_ratio'] = df['followers_count'] / (df['following_count'] + 1)
    df['content_activity_rate'] = (df['posts_last_30_days'] + df['stories_last_30_days']) / 30
    df['match_efficiency'] = df['matches_last_30_days'] / (df['swipes_right_last_30_days'] + 1)
    df['connection_rate'] = df['total_connections'] / (df['tenure_months'] + 1)
    df['gig_success_rate'] = df['active_gigs_count'] / (df['gig_applications_sent'] + 1)
    df['revenue_per_gig'] = df['transaction_revenue_last_90_days'] / (df['active_gigs_count'] + 1)
    
    df = df.replace([float('inf'), float('-inf')], 0).fillna(0)
    
    # Select feature columns
    feature_cols = [col for col in df.columns if col not in [
        'customer_id', 'engagement_score', 'churn_30_day', 
        'lifetime_value_usd', 'gender', 'location', 'content_category_primary'
    ]]
    
    X = df[feature_cols]
    X_scaled = pd.DataFrame(scaler.transform(X), columns=X.columns, index=X.index)
    
    return df[['customer_id']], X_scaled


def generate_predictions(customer_ids: pd.DataFrame, X: pd.DataFrame, models: dict) -> pd.DataFrame:
    """Generate predictions for all models"""
    logger.info("Generating predictions...")
    
    results = customer_ids.copy()
    
    # Engagement predictions
    results['predicted_engagement_score'] = models['engagement'].predict(X)
    
    # Churn predictions
    results['predicted_churn_probability'] = models['churn'].predict_proba(X)[:, 1]
    results['predicted_churn'] = (results['predicted_churn_probability'] > 0.5).astype(int)
    
    # LTV predictions
    results['predicted_ltv_usd'] = models['ltv'].predict(X)
    
    # Anomaly detection
    results['anomaly_score'] = models['anomaly'].score_samples(X)
    results['is_anomaly'] = (models['anomaly'].predict(X) == -1).astype(int)
    
    # Add metadata
    results['model_version'] = MODEL_VERSION
    results['prediction_timestamp'] = datetime.utcnow().isoformat()
    
    return results


def save_results_to_s3(results: pd.DataFrame):
    """Save prediction results to S3 as Parquet"""
    logger.info("Saving results to S3...")
    
    timestamp = datetime.utcnow().strftime('%Y%m%d_%H%M%S')
    results_key = f"predictions/{MODEL_VERSION}/predictions_{timestamp}.parquet"
    
    # Write to S3 via awswrangler
    wr.s3.to_parquet(
        df=results,
        path=f"s3://{RESULTS_BUCKET}/{results_key}",
        dataset=False,
        compression='snappy'
    )
    
    logger.info(f"Saved {len(results)} predictions to s3://{RESULTS_BUCKET}/{results_key}")
    
    # Publish summary statistics
    publish_metric('PredictionsGenerated', len(results), 'Count')
    publish_metric('AvgPredictedEngagement', results['predicted_engagement_score'].mean())
    publish_metric('ChurnRate', results['predicted_churn'].mean())
    publish_metric('AnomalyRate', results['is_anomaly'].mean())


def main():
    """Main inference pipeline"""
    start_time = time.time()
    logger.info("Starting inference pipeline...")
    
    try:
        # Load models
        models = load_models_from_s3()
        
        # Load data
        df = load_customer_data()
        
        # Prepare features
        customer_ids, X_scaled = prepare_features(df, models['scaler'])
        
        # Generate predictions
        results = generate_predictions(customer_ids, X_scaled, models)
        
        # Save results
        save_results_to_s3(results)
        
        # Publish metrics
        duration = time.time() - start_time
        publish_metric('InferenceDuration', duration, 'Seconds')
        
        logger.info(f"✅ Inference pipeline completed successfully in {duration:.2f} seconds")
        
    except Exception as e:
        logger.error(f"❌ Inference pipeline failed: {e}", exc_info=True)
        publish_metric('InferenceFailureCount', 1, 'Count')
        raise


if __name__ == "__main__":
    main()

