"""
Predict Lambda: Real-time prediction API with DynamoDB caching
"""

import os
import json
import hashlib
import time
import boto3
import logging
import joblib
import numpy as np

logger = logging.getLogger()
logger.setLevel(logging.INFO)

s3_client = boto3.client('s3')
dynamodb = boto3.resource('dynamodb')

ENV = os.getenv('ENV', 'dev')
MODELS_BUCKET = os.getenv('MODELS_BUCKET')
DYNAMODB_TABLE = os.getenv('DYNAMODB_TABLE')
MODEL_VERSION = os.getenv('MODEL_VERSION', 'v1.0')
CACHE_TTL_SECONDS = int(os.getenv('CACHE_TTL_SECONDS', '3600'))

table = dynamodb.Table(DYNAMODB_TABLE)

# Global model cache (Lambda warm start optimization)
_model_cache = {}


def lambda_handler(event, context):
    """Handle real-time prediction requests"""
    start_time = time.time()
    
    try:
        # Parse request
        body = json.loads(event.get('body', '{}'))
        features = body.get('customer_features', {})
        model_name = body.get('model_name', 'engagement')
        
        # Generate feature hash for caching
        feature_hash = hashlib.sha256(json.dumps(features, sort_keys=True).encode()).hexdigest()[:16]
        
        # Check cache
        cached_prediction = get_cached_prediction(feature_hash, model_name)
        if cached_prediction:
            logger.info("Cache hit")
            return format_response(200, {
                'prediction': cached_prediction,
                'cached': True,
                'latency_ms': (time.time() - start_time) * 1000
            })
        
        # Load model and predict
        model = load_model(model_name)
        feature_vector = prepare_features(features)
        prediction = float(model.predict([feature_vector])[0])
        
        # Cache result
        cache_prediction(feature_hash, model_name, prediction)
        
        latency = (time.time() - start_time) * 1000
        logger.info(f"Prediction completed in {latency:.2f}ms")
        
        return format_response(200, {
            'prediction': prediction,
            'model_name': model_name,
            'model_version': MODEL_VERSION,
            'cached': False,
            'latency_ms': latency
        })
        
    except Exception as e:
        logger.error(f"❌ Prediction failed: {e}", exc_info=True)
        return format_response(500, {'error': str(e)})


def load_model(model_name: str):
    """Load model from S3 with caching"""
    if model_name in _model_cache:
        return _model_cache[model_name]
    
    # Download from S3 to /tmp
    model_key = f"models/{MODEL_VERSION}/{model_name}_latest.pkl"
    model_path = f"/tmp/{model_name}.pkl"
    
    s3_client.download_file(MODELS_BUCKET, model_key, model_path)
    model = joblib.load(model_path)
    
    _model_cache[model_name] = model
    return model


def prepare_features(features: dict) -> list:
    """Convert feature dict to vector (simplified)"""
    # In production, apply proper feature engineering and scaling
    return list(features.values())


def get_cached_prediction(feature_hash: str, model_name: str):
    """Get cached prediction from DynamoDB"""
    try:
        response = table.get_item(
            Key={'customer_id': feature_hash, 'feature_hash': model_name}
        )
        if 'Item' in response:
            return response['Item'].get('prediction')
    except:
        pass
    return None


def cache_prediction(feature_hash: str, model_name: str, prediction: float):
    """Cache prediction in DynamoDB"""
    try:
        table.put_item(
            Item={
                'customer_id': feature_hash,
                'feature_hash': model_name,
                'prediction': prediction,
                'model_version': MODEL_VERSION,
                'timestamp': int(time.time()),
                'ttl': int(time.time()) + CACHE_TTL_SECONDS
            }
        )
    except Exception as e:
        logger.warning(f"Failed to cache prediction: {e}")


def format_response(status_code: int, body: dict) -> dict:
    """Format API Gateway response"""
    return {
        'statusCode': status_code,
        'headers': {
            'Content-Type': 'application/json',
            'Access-Control-Allow-Origin': '*'
        },
        'body': json.dumps(body)
    }

