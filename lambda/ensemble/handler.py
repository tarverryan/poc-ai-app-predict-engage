"""
Ensemble Lambda: Combine predictions from multiple models
"""

import os
import json
import boto3
import logging

logger = logging.getLogger()
logger.setLevel(logging.INFO)

s3_client = boto3.client('s3')

ENV = os.getenv('ENV', 'dev')
MODELS_BUCKET = os.getenv('MODELS_BUCKET')
MODEL_VERSION = os.getenv('MODEL_VERSION', 'v1.0')


def lambda_handler(event, context):
    """Ensemble multiple model predictions"""
    logger.info("Running ensemble prediction...")
    
    try:
        # Parse input predictions from event
        predictions = event.get('predictions', {})
        
        # Weighted average (simplified ensemble)
        weights = {
            'engagement': 0.4,
            'churn': 0.3,
            'ltv': 0.3
        }
        
        ensemble_score = sum(
            predictions.get(model, 0) * weight
            for model, weight in weights.items()
        )
        
        logger.info(f"Ensemble score: {ensemble_score:.4f}")
        
        return {
            'statusCode': 200,
            'ensemble_score': ensemble_score,
            'individual_predictions': predictions,
            'weights': weights
        }
        
    except Exception as e:
        logger.error(f"❌ Ensemble failed: {e}", exc_info=True)
        raise

