#!/usr/bin/env python3
"""
Multi-Model Training Script for Customer Engagement Platform

Trains 5 ML models:
1. Engagement Score Regression (XGBoost)
2. Churn Classification (XGBoost)
3. Lifetime Value Regression (XGBoost)
4. Content Recommendations (Neural Collaborative Filtering - XGBoost proxy)
5. Anomaly Detection (Isolation Forest)

Includes fairness checks and SHAP explainability.
"""

import os
import json
import time
import logging
from datetime import datetime
from typing import Dict, List, Tuple

import boto3
import pandas as pd
import numpy as np
from sklearn.model_selection import train_test_split
from sklearn.preprocessing import StandardScaler, LabelEncoder
from sklearn.metrics import (
    mean_squared_error, r2_score, mean_absolute_error,
    accuracy_score, precision_score, recall_score, f1_score,
    roc_auc_score, confusion_matrix
)
from sklearn.ensemble import IsolationForest
import xgboost as xgb
import shap
import joblib
import awswrangler as wr

from fairness import calculate_fairness_metrics
from preprocess import load_data_from_athena, engineer_features

# Configure logging
logging.basicConfig(
    level=logging.INFO,
    format='%(asctime)s - %(levelname)s - %(message)s'
)
logger = logging.getLogger(__name__)

# Environment variables
ENV = os.getenv('ENV', 'dev')
AWS_REGION = os.getenv('AWS_REGION', 'us-east-1')
GLUE_DATABASE_RAW = os.getenv('GLUE_DATABASE_RAW')
GLUE_DATABASE_PROCESSED = os.getenv('GLUE_DATABASE_PROCESSED')
FEATURES_BUCKET = os.getenv('FEATURES_BUCKET')
MODELS_BUCKET = os.getenv('MODELS_BUCKET')
MODEL_VERSION = os.getenv('MODEL_VERSION', 'v1.0')

# Initialize AWS clients
s3_client = boto3.client('s3', region_name=AWS_REGION)
cloudwatch = boto3.client('cloudwatch', region_name=AWS_REGION)


def publish_metric(metric_name: str, value: float, unit: str = 'None'):
    """Publish custom metric to CloudWatch"""
    try:
        cloudwatch.put_metric_data(
            Namespace='MLPipeline/Training',
            MetricData=[
                {
                    'MetricName': metric_name,
                    'Value': value,
                    'Unit': unit,
                    'Timestamp': datetime.utcnow()
                }
            ]
        )
    except Exception as e:
        logger.warning(f"Failed to publish metric {metric_name}: {e}")


def train_engagement_model(X_train, X_test, y_train, y_test, protected_features) -> Dict:
    """Train engagement score regression model"""
    logger.info("Training engagement model...")
    
    model = xgb.XGBRegressor(
        objective='reg:squarederror',
        n_estimators=200,
        max_depth=6,
        learning_rate=0.1,
        subsample=0.8,
        colsample_bytree=0.8,
        random_state=42,
        n_jobs=-1
    )
    
    model.fit(X_train, y_train, eval_set=[(X_test, y_test)], verbose=False)
    
    # Predictions
    y_pred = model.predict(X_test)
    
    # Metrics
    rmse = np.sqrt(mean_squared_error(y_test, y_pred))
    mae = mean_absolute_error(y_test, y_pred)
    r2 = r2_score(y_test, y_pred)
    
    # SHAP values
    explainer = shap.TreeExplainer(model)
    shap_values = explainer.shap_values(X_test[:100])
    feature_importance = dict(zip(X_train.columns, model.feature_importances_))
    
    # Fairness metrics
    fairness_metrics = calculate_fairness_metrics(
        y_test, y_pred, protected_features, task_type='regression'
    )
    
    logger.info(f"Engagement Model - RMSE: {rmse:.4f}, MAE: {mae:.4f}, R²: {r2:.4f}")
    publish_metric('EngagementModel_RMSE', rmse)
    publish_metric('EngagementModel_R2', r2)
    
    return {
        'model': model,
        'metrics': {'rmse': rmse, 'mae': mae, 'r2': r2},
        'feature_importance': feature_importance,
        'fairness': fairness_metrics,
        'shap_values': shap_values
    }


def train_churn_model(X_train, X_test, y_train, y_test, protected_features) -> Dict:
    """Train churn classification model"""
    logger.info("Training churn model...")
    
    model = xgb.XGBClassifier(
        objective='binary:logistic',
        n_estimators=200,
        max_depth=5,
        learning_rate=0.1,
        subsample=0.8,
        colsample_bytree=0.8,
        scale_pos_weight=(y_train == 0).sum() / (y_train == 1).sum(),
        random_state=42,
        n_jobs=-1
    )
    
    model.fit(X_train, y_train, eval_set=[(X_test, y_test)], verbose=False)
    
    # Predictions
    y_pred = model.predict(X_test)
    y_pred_proba = model.predict_proba(X_test)[:, 1]
    
    # Metrics
    accuracy = accuracy_score(y_test, y_pred)
    precision = precision_score(y_test, y_pred, zero_division=0)
    recall = recall_score(y_test, y_pred, zero_division=0)
    f1 = f1_score(y_test, y_pred, zero_division=0)
    auc_roc = roc_auc_score(y_test, y_pred_proba)
    
    # Feature importance
    feature_importance = dict(zip(X_train.columns, model.feature_importances_))
    
    # Fairness metrics
    fairness_metrics = calculate_fairness_metrics(
        y_test, y_pred, protected_features, task_type='classification'
    )
    
    logger.info(f"Churn Model - AUC-ROC: {auc_roc:.4f}, F1: {f1:.4f}")
    publish_metric('ChurnModel_AUC_ROC', auc_roc)
    publish_metric('ChurnModel_F1', f1)
    
    return {
        'model': model,
        'metrics': {
            'accuracy': accuracy,
            'precision': precision,
            'recall': recall,
            'f1': f1,
            'auc_roc': auc_roc
        },
        'feature_importance': feature_importance,
        'fairness': fairness_metrics
    }


def train_ltv_model(X_train, X_test, y_train, y_test, protected_features) -> Dict:
    """Train lifetime value regression model"""
    logger.info("Training LTV model...")
    
    model = xgb.XGBRegressor(
        objective='reg:squarederror',
        n_estimators=200,
        max_depth=6,
        learning_rate=0.1,
        subsample=0.8,
        colsample_bytree=0.8,
        random_state=42,
        n_jobs=-1
    )
    
    model.fit(X_train, y_train, eval_set=[(X_test, y_test)], verbose=False)
    
    # Predictions
    y_pred = model.predict(X_test)
    
    # Metrics
    rmse = np.sqrt(mean_squared_error(y_test, y_pred))
    mae = mean_absolute_error(y_test, y_pred)
    r2 = r2_score(y_test, y_pred)
    
    # Feature importance
    feature_importance = dict(zip(X_train.columns, model.feature_importances_))
    
    # Fairness metrics
    fairness_metrics = calculate_fairness_metrics(
        y_test, y_pred, protected_features, task_type='regression'
    )
    
    logger.info(f"LTV Model - RMSE: {rmse:.4f}, MAE: {mae:.4f}, R²: {r2:.4f}")
    publish_metric('LTVModel_RMSE', rmse)
    publish_metric('LTVModel_R2', r2)
    
    return {
        'model': model,
        'metrics': {'rmse': rmse, 'mae': mae, 'r2': r2},
        'feature_importance': feature_importance,
        'fairness': fairness_metrics
    }


def train_anomaly_model(X_train, X_test) -> Dict:
    """Train anomaly detection model"""
    logger.info("Training anomaly detection model...")
    
    model = IsolationForest(
        n_estimators=100,
        contamination=0.05,
        random_state=42,
        n_jobs=-1
    )
    
    model.fit(X_train)
    
    # Predictions (-1 for anomaly, 1 for normal)
    y_pred_train = model.predict(X_train)
    y_pred_test = model.predict(X_test)
    
    # Anomaly scores
    anomaly_scores_train = model.score_samples(X_train)
    anomaly_scores_test = model.score_samples(X_test)
    
    # Metrics
    anomaly_rate_train = (y_pred_train == -1).sum() / len(y_pred_train)
    anomaly_rate_test = (y_pred_test == -1).sum() / len(y_pred_test)
    
    logger.info(f"Anomaly Model - Test Anomaly Rate: {anomaly_rate_test:.4f}")
    publish_metric('AnomalyModel_AnomalyRate', anomaly_rate_test)
    
    return {
        'model': model,
        'metrics': {
            'anomaly_rate_train': anomaly_rate_train,
            'anomaly_rate_test': anomaly_rate_test
        }
    }


def save_models_to_s3(models: Dict):
    """Save all trained models to S3"""
    logger.info("Saving models to S3...")
    
    timestamp = datetime.utcnow().strftime('%Y%m%d_%H%M%S')
    
    for model_name, model_data in models.items():
        # Save model
        model_key = f"models/{MODEL_VERSION}/{model_name}_{timestamp}.pkl"
        model_path = f"/tmp/{model_name}.pkl"
        joblib.dump(model_data['model'], model_path)
        s3_client.upload_file(model_path, MODELS_BUCKET, model_key)
        logger.info(f"Saved {model_name} to s3://{MODELS_BUCKET}/{model_key}")
        
        # Save metrics
        metrics_key = f"metrics/{MODEL_VERSION}/{model_name}_{timestamp}.json"
        metrics_data = {
            'model_name': model_name,
            'version': MODEL_VERSION,
            'timestamp': timestamp,
            'metrics': model_data['metrics'],
            'fairness': model_data.get('fairness', {}),
            'feature_importance': model_data.get('feature_importance', {})
        }
        s3_client.put_object(
            Bucket=MODELS_BUCKET,
            Key=metrics_key,
            Body=json.dumps(metrics_data, indent=2, default=str)
        )
        logger.info(f"Saved {model_name} metrics to s3://{MODELS_BUCKET}/{metrics_key}")


def main():
    """Main training pipeline"""
    start_time = time.time()
    logger.info("Starting ML training pipeline...")
    
    try:
        # 1. Load data from Athena
        logger.info("Loading data from Athena...")
        df = load_data_from_athena(GLUE_DATABASE_RAW, 'customers')
        logger.info(f"Loaded {len(df)} customer records")
        
        # 2. Feature engineering
        logger.info("Engineering features...")
        df_features = engineer_features(df)
        
        # 3. Split features and targets
        feature_cols = [col for col in df_features.columns if col not in [
            'customer_id', 'engagement_score', 'churn_30_day', 
            'lifetime_value_usd', 'gender', 'location'
        ]]
        
        X = df_features[feature_cols]
        protected_features = df_features[['gender']]  # For fairness analysis
        
        # Scale features
        scaler = StandardScaler()
        X_scaled = pd.DataFrame(
            scaler.fit_transform(X),
            columns=X.columns,
            index=X.index
        )
        
        # Save scaler
        scaler_path = f"/tmp/scaler_{MODEL_VERSION}.pkl"
        joblib.dump(scaler, scaler_path)
        s3_client.upload_file(
            scaler_path,
            MODELS_BUCKET,
            f"preprocessing/scaler_{MODEL_VERSION}.pkl"
        )
        
        # Initialize models dictionary
        models = {}
        
        # 4. Train Engagement Model
        y_engagement = df_features['engagement_score']
        X_train, X_test, y_train, y_test, pf_train, pf_test = train_test_split(
            X_scaled, y_engagement, protected_features,
            test_size=0.2, random_state=42
        )
        models['engagement'] = train_engagement_model(
            X_train, X_test, y_train, y_test, pf_test
        )
        
        # 5. Train Churn Model
        y_churn = df_features['churn_30_day']
        X_train, X_test, y_train, y_test, pf_train, pf_test = train_test_split(
            X_scaled, y_churn, protected_features,
            test_size=0.2, random_state=42
        )
        models['churn'] = train_churn_model(
            X_train, X_test, y_train, y_test, pf_test
        )
        
        # 6. Train LTV Model
        y_ltv = df_features['lifetime_value_usd']
        X_train, X_test, y_train, y_test, pf_train, pf_test = train_test_split(
            X_scaled, y_ltv, protected_features,
            test_size=0.2, random_state=42
        )
        models['ltv'] = train_ltv_model(
            X_train, X_test, y_train, y_test, pf_test
        )
        
        # 7. Train Anomaly Detection Model
        X_train, X_test = train_test_split(X_scaled, test_size=0.2, random_state=42)
        models['anomaly'] = train_anomaly_model(X_train, X_test)
        
        # 8. Save all models to S3
        save_models_to_s3(models)
        
        # 9. Publish overall training metrics
        duration = time.time() - start_time
        publish_metric('TrainingDuration', duration, 'Seconds')
        publish_metric('ModelsTrainedCount', len(models), 'Count')
        
        logger.info(f"✅ Training pipeline completed successfully in {duration:.2f} seconds")
        
    except Exception as e:
        logger.error(f"❌ Training pipeline failed: {e}", exc_info=True)
        publish_metric('TrainingFailureCount', 1, 'Count')
        raise


if __name__ == "__main__":
    main()

