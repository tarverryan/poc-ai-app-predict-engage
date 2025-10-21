import pandas as pd
import numpy as np
from sklearn.model_selection import train_test_split
from sklearn.metrics import mean_squared_error, accuracy_score
import xgboost as xgb
import json
import os
from datetime import datetime

print("=" * 60)
print("CUSTOMER ENGAGEMENT ML TRAINING (LOCAL TEST)")
print("=" * 60)

# Load data
print("\n📊 Loading data...")
df = pd.read_parquet('/data/customer_engagement_dataset_extended.parquet')
print(f"✓ Loaded {len(df):,} rows, {len(df.columns)} columns")

# Basic data info
print(f"\n📈 Data Summary:")
print(f"  - Avg age: {df['age'].mean():.1f}")
print(f"  - Avg engagement: {df['engagement_score'].mean():.3f}")
print(f"  - Churn rate: {df['churn_30_day'].mean()*100:.1f}%")
print(f"  - Avg LTV: ${df['lifetime_value_usd'].mean():.2f}")

# Select features for quick training
feature_cols = [
    'age', 'tenure_months', 'sessions_last_7_days', 
    'session_duration_avg_minutes', 'followers_count',
    'total_connections', 'posts_last_30_days',
    'active_gigs_count', 'transaction_revenue_last_90_days'
]

print(f"\n🎯 Training models with {len(feature_cols)} features...")

# Train/test split
X = df[feature_cols].fillna(0)
y_engagement = df['engagement_score']
y_churn = df['churn_30_day']
y_ltv = df['lifetime_value_usd']

X_train, X_test, y_eng_train, y_eng_test = train_test_split(
    X, y_engagement, test_size=0.2, random_state=42
)
_, _, y_churn_train, y_churn_test = train_test_split(
    X, y_churn, test_size=0.2, random_state=42
)
_, _, y_ltv_train, y_ltv_test = train_test_split(
    X, y_ltv, test_size=0.2, random_state=42
)

print(f"  - Train: {len(X_train):,} samples")
print(f"  - Test: {len(X_test):,} samples")

# Model 1: Engagement Score (Regression)
print("\n🚀 Model 1: Engagement Prediction...")
model_eng = xgb.XGBRegressor(n_estimators=50, max_depth=5, random_state=42, verbosity=0)
model_eng.fit(X_train, y_eng_train)
pred_eng = model_eng.predict(X_test)
rmse_eng = np.sqrt(mean_squared_error(y_eng_test, pred_eng))
print(f"  ✅ RMSE: {rmse_eng:.4f}")

# Model 2: Churn Prediction (Classification)
print("\n🚀 Model 2: Churn Prediction...")
model_churn = xgb.XGBClassifier(n_estimators=50, max_depth=5, random_state=42, verbosity=0)
model_churn.fit(X_train, y_churn_train)
pred_churn = model_churn.predict(X_test)
acc_churn = accuracy_score(y_churn_test, pred_churn)
print(f"  ✅ Accuracy: {acc_churn:.4f}")

# Model 3: LTV Prediction (Regression)
print("\n🚀 Model 3: LTV Prediction...")
model_ltv = xgb.XGBRegressor(n_estimators=50, max_depth=5, random_state=42, verbosity=0)
model_ltv.fit(X_train, y_ltv_train)
pred_ltv = model_ltv.predict(X_test)
rmse_ltv = np.sqrt(mean_squared_error(y_ltv_test, pred_ltv))
print(f"  ✅ RMSE: ${rmse_ltv:.2f}")

# Save models
print("\n💾 Saving models...")
model_eng.save_model('/models/engagement_model.json')
model_churn.save_model('/models/churn_model.json')
model_ltv.save_model('/models/ltv_model.json')
print("  ✅ Models saved")

# Save metrics
metrics = {
    "timestamp": datetime.now().isoformat(),
    "data_size": len(df),
    "features": feature_cols,
    "models": {
        "engagement": {"rmse": float(rmse_eng), "metric": "RMSE"},
        "churn": {"accuracy": float(acc_churn), "metric": "Accuracy"},
        "ltv": {"rmse": float(rmse_ltv), "metric": "RMSE (USD)"}
    }
}

with open('/models/metrics.json', 'w') as f:
    json.dump(metrics, f, indent=2)
print("  ✅ Metrics saved")

print("\n" + "=" * 60)
print("✅ TRAINING COMPLETE!")
print("=" * 60)
print(f"\n📊 Summary:")
print(f"  Engagement RMSE:  {rmse_eng:.4f}")
print(f"  Churn Accuracy:   {acc_churn:.2%}")
print(f"  LTV RMSE:         ${rmse_ltv:.2f}")
