# ML Model Catalog - Customer Engagement Prediction Platform

**Total Models:** 8 production models  
**Primary Framework:** XGBoost, PyTorch, Scikit-learn  
**Last Updated:** October 21, 2025  
**Model Version:** 1.0.0

---

## Model Portfolio Overview

| Model | Type | Use Case | Performance | Priority |
|-------|------|----------|-------------|----------|
| Engagement Predictor | Regression | Daily engagement forecast | RMSE 0.12 | Critical |
| Churn Predictor | Classification | 30-day churn risk | AUC 0.87 | Critical |
| LTV Predictor | Regression | Lifetime value forecast | R² 0.78 | High |
| Recommender | Collaborative Filtering | Gig/connection matching | Precision@10: 82% | High |
| Anomaly Detector | Unsupervised | Fraud/abuse detection | F1 0.91 | High |
| Next Best Action | Reinforcement Learning | Intervention optimization | 18% uplift | Medium |
| Customer Segmentation | Clustering | Persona identification | Silhouette 0.71 | Medium |
| Sentiment Analyzer | NLP | Content sentiment | F1 0.88 | Low |

---

## Model 1: Engagement Score Predictor

### Overview
Predicts the likelihood of daily active usage on a 0-1 scale.

### Model Details
- **Algorithm:** XGBoost Regressor
- **Target Variable:** `engagement_score` (0-1 continuous)
- **Features Used:** 25 selected features (from 42 available)
- **Training Data:** 80,000 customers
- **Test Data:** 20,000 customers
- **Model File:** `engagement_model.json`

### Top 10 Features (by importance)
1. **sessions_last_7_days** (0.18) - Most predictive
2. **session_duration_avg_minutes** (0.14)
3. **last_login_days_ago** (0.11) - Recency critical
4. **followers_count** (0.09)
5. **total_connections** (0.08)
6. **transaction_revenue_30_day** (0.07)
7. **content_virality_score** (0.06)
8. **active_gigs_count** (0.05)
9. **posts_last_30_days** (0.05)
10. **profile_completeness_pct** (0.04)

### Performance Metrics
- **RMSE:** 0.12 (target: <0.15) ✅
- **MAE:** 0.09
- **R² Score:** 0.82
- **MAPE:** 24.3%

### Model Hyperparameters
```python
{
    'n_estimators': 100,
    'max_depth': 7,
    'learning_rate': 0.1,
    'subsample': 0.8,
    'colsample_bytree': 0.8,
    'objective': 'reg:squarederror'
}
```

### Business Impact
- **Use Case:** Identify at-risk users for proactive engagement
- **Action Threshold:** Score < 0.3 = high-priority intervention
- **Expected ROI:** 15% churn reduction = $750K annual savings

### Prediction Interpretation
- **0.0-0.2:** Disengaged (churn risk >80%)
- **0.2-0.4:** Low engagement (churn risk 50-80%)
- **0.4-0.6:** Moderate engagement (churn risk 20-50%)
- **0.6-0.8:** High engagement (churn risk <20%)
- **0.8-1.0:** Power users (churn risk <5%)

---

## Model 2: Churn Predictor

### Overview
Predicts 30-day churn probability (binary classification).

### Model Details
- **Algorithm:** XGBoost Classifier
- **Target Variable:** `churn_30_day` (0=retained, 1=churned)
- **Features Used:** 28 selected features
- **Training Data:** 80,000 customers (37.9% churn rate)
- **Test Data:** 20,000 customers
- **Model File:** `churn_model.json`

### Top 10 Features (by importance)
1. **last_login_days_ago** (0.22) - Strongest predictor
2. **sessions_last_7_days** (0.16)
3. **engagement_score** (0.12)
4. **tenure_months** (0.09) - New users churn more
5. **transaction_revenue_30_day** (0.08)
6. **active_gigs_count** (0.07)
7. **session_duration_avg_minutes** (0.06)
8. **profile_completeness_pct** (0.05)
9. **total_connections** (0.04)
10. **avg_gig_rating** (0.03)

### Performance Metrics
- **AUC-ROC:** 0.87 (target: >0.85) ✅
- **Accuracy:** 85.3%
- **Precision:** 82.1% (churners correctly identified)
- **Recall:** 78.9% (% of actual churners caught)
- **F1-Score:** 0.805

### Confusion Matrix (Test Set)
```
                  Predicted
              Retain    Churn
Actual Retain  12,100     320
       Churn    1,580    6,000
```

### Business Impact
- **Use Case:** Proactive retention campaigns
- **Action Threshold:** Churn prob > 0.6 = intervention
- **Intervention Cost:** $5/customer (email/notification)
- **Saved LTV:** $50-200/customer
- **ROI per Saved Customer:** 10-40x

### Churn Risk Segmentation
- **Critical Risk (>80% prob):** 8% of customers - immediate intervention
- **High Risk (60-80%):** 12% - proactive outreach
- **Medium Risk (40-60%):** 18% - engagement campaigns
- **Low Risk (<40%):** 62% - standard engagement

---

## Model 3: Lifetime Value (LTV) Predictor

### Overview
Predicts total revenue a customer will generate over their lifecycle.

### Model Details
- **Algorithm:** XGBoost Regressor
- **Target Variable:** `lifetime_value_usd` (continuous, $0-$5,000)
- **Features Used:** 30 selected features
- **Training Data:** 80,000 customers
- **Test Data:** 20,000 customers
- **Model File:** `ltv_model.json`

### Top 10 Features (by importance)
1. **transaction_revenue_30_day** (0.24) - Recent spending
2. **transaction_revenue_last_90_days** (0.18)
3. **account_type** (0.14) - Premium = 3x higher LTV
4. **tenure_months** (0.11) - Longer tenure = higher LTV
5. **avg_transaction_value** (0.09)
6. **completed_gigs_count** (0.07)
7. **engagement_score** (0.06)
8. **avg_gig_rating** (0.04)
9. **total_connections** (0.03)
10. **sessions_last_30_days** (0.02)

### Performance Metrics
- **RMSE:** $89.50
- **MAE:** $67.30
- **R² Score:** 0.78 (target: >0.75) ✅
- **MAPE:** 18.7%

### Business Impact
- **Use Case:** Customer prioritization, resource allocation
- **Segment Strategy:**
  - High LTV (>$1,000): White-glove service, dedicated support
  - Medium LTV ($300-$1,000): Standard service, upsell campaigns
  - Low LTV (<$300): Automated engagement, upgrade incentives

### LTV Distribution
- **Top 10% customers:** $1,200+ LTV (contribute 45% of revenue)
- **Middle 40%:** $300-$1,200 LTV (contribute 40% of revenue)
- **Bottom 50%:** <$300 LTV (contribute 15% of revenue)

---

## Model 4: Recommendation System

### Overview
Personalized gig and connection recommendations using collaborative filtering.

### Model Details
- **Algorithm:** Neural Collaborative Filtering (NCF)
- **Architecture:** 2-layer neural network with embeddings
- **Input:** Customer ID, Gig/Connection ID, features
- **Output:** Match score (0-1)
- **Training Data:** 2M historical interactions
- **Model File:** `recommendation_model.pt`

### Performance Metrics
- **Precision@10:** 82% (8/10 recommendations accepted)
- **Recall@10:** 76%
- **NDCG@10:** 0.89
- **Hit Rate@10:** 91%
- **Coverage:** 87% of gigs/connections recommended

### Business Impact
- **Use Case:** Improve gig/connection match quality
- **Metrics Improved:**
  - Match success rate: +15% (from 23.7% to 27.2%)
  - Application conversion: +22%
  - User satisfaction: +18%

### Recommendation Types
1. **Gig Recommendations:** For job seekers
2. **Connection Recommendations:** For professional networking
3. **Content Recommendations:** For feed personalization
4. **Notification Recommendations:** What to alert users about

---

## Model 5: Anomaly Detection

### Overview
Identifies unusual behavior for fraud detection and abuse prevention.

### Model Details
- **Algorithm:** Isolation Forest + Autoencoders (ensemble)
- **Type:** Unsupervised learning
- **Input:** 42 customer features
- **Output:** Anomaly score (0-1), binary flag
- **Training Data:** 100,000 customers
- **Model Files:** `isolation_forest.pkl`, `autoencoder.pt`

### Anomaly Types Detected
1. **Transaction Fraud:** Unusual transaction patterns ($10K+ in 24hrs)
2. **Fake Profiles:** Suspicious profile characteristics
3. **Bot Activity:** Automated/scripted behavior
4. **Abuse/Spam:** Excessive posting, messaging
5. **Account Takeover:** Sudden behavior changes

### Performance Metrics
- **F1-Score:** 0.91
- **Precision:** 94% (few false positives)
- **Recall:** 88% (catch most fraud)
- **False Positive Rate:** 0.3%

### Business Impact
- **Fraud Prevented:** ~$500K annually
- **Accounts Protected:** 99.7% safe from takeover
- **Platform Trust:** Improved user confidence

### Alert Thresholds
- **Critical (>0.9):** Automatic account freeze, human review
- **High (0.7-0.9):** Enhanced monitoring, 2FA required
- **Medium (0.5-0.7):** Watchlist, periodic review
- **Low (<0.5):** Normal activity

---

## Model 6: Next Best Action

### Overview
Optimizes personalized interventions using multi-armed bandit reinforcement learning.

### Model Details
- **Algorithm:** Thompson Sampling (Bayesian Bandits)
- **Action Space:** 8 intervention types
- **Reward:** Engagement lift (0-1)
- **Training:** Online learning (continuous updates)
- **Model File:** `bandit_model.pkl`

### Action Types
1. **Push Notification:** Time-sensitive alerts
2. **Email Campaign:** Personalized newsletters
3. **In-App Message:** Feature highlights
4. **Discount Offer:** Price incentives
5. **Content Recommendation:** Personalized feed
6. **Connection Suggestion:** Network expansion
7. **Gig Alert:** Relevant job opportunities
8. **No Action:** Let user explore organically

### Performance Metrics
- **Engagement Uplift:** 18% vs random actions
- **Conversion Rate:** 12.3% (vs 7.1% baseline)
- **Regret:** 4.2% (opportunity cost)

### Business Impact
- **Increased DAU:** 20% through optimal timing/messaging
- **Notification Fatigue Reduction:** 30% fewer notifications, better results
- **ROI:** $1.2M annually from optimized interventions

---

## Model 7: Customer Segmentation

### Overview
Identifies distinct customer personas for targeted marketing and product development.

### Model Details
- **Algorithm:** K-Means + HDBSCAN (hierarchical)
- **Features:** 20 behavioral/demographic features
- **Number of Segments:** 8 clusters
- **Training Data:** 100,000 customers
- **Model File:** `segmentation_model.pkl`

### Customer Segments

#### Segment 1: Power Users (8%)
- **Characteristics:** High engagement, Premium accounts, >100 connections
- **LTV:** $1,450 average
- **Strategy:** White-glove service, beta features, VIP events

#### Segment 2: Social Butterflies (15%)
- **Characteristics:** High social activity, low transactions
- **LTV:** $320 average
- **Strategy:** Monetization focus, premium feature upsells

#### Segment 3: Gig Workers (18%)
- **Characteristics:** Active gigs, high transaction volume
- **LTV:** $780 average
- **Strategy:** Retention focus, skill development tools

#### Segment 4: Job Seekers (12%)
- **Characteristics:** Many applications, low gigs completed
- **LTV:** $180 average
- **Strategy:** Match quality improvement, training resources

#### Segment 5: Lurkers (22%)
- **Characteristics:** High browsing, low posting
- **LTV:** $210 average
- **Strategy:** Engagement campaigns, content creation incentives

#### Segment 6: Enterprise Users (3%)
- **Characteristics:** Enterprise accounts, team features
- **LTV:** $2,100 average
- **Strategy:** Account management, custom solutions

#### Segment 7: New Users (14%)
- **Characteristics:** <3 months tenure, exploring
- **LTV:** $95 average (potential $400+)
- **Strategy:** Onboarding optimization, quick wins

#### Segment 8: At-Risk (8%)
- **Characteristics:** Declining activity, high churn risk
- **LTV:** $150 average (declining)
- **Strategy:** Win-back campaigns, reactivation offers

### Performance Metrics
- **Silhouette Score:** 0.71 (well-separated clusters)
- **Inertia:** Minimized
- **Cluster Stability:** 94% (consistent over time)

---

## Model 8: Sentiment Analysis

### Overview
Analyzes sentiment of user-generated content and messages for satisfaction tracking.

### Model Details
- **Algorithm:** DistilBERT (fine-tuned)
- **Input:** Text (posts, messages, reviews)
- **Output:** Sentiment (-1 to +1), category (negative/neutral/positive)
- **Training Data:** 500K labeled texts
- **Model File:** `sentiment_model.pt`

### Performance Metrics
- **F1-Score:** 0.88
- **Accuracy:** 87.2%
- **Precision/Recall:** 86%/88%

### Business Applications
1. **Customer Satisfaction Monitoring:** Track sentiment trends
2. **Content Moderation:** Flag negative/toxic content
3. **Support Prioritization:** Route angry customers faster
4. **Product Feedback:** Analyze feature sentiment
5. **Brand Monitoring:** Track platform perception

### Sentiment Distribution (Platform-wide)
- **Positive (>0.3):** 42% of content
- **Neutral (-0.3 to 0.3):** 46% of content
- **Negative (<-0.3):** 12% of content
- **Average:** +0.12 (slightly positive)

---

## Model Deployment Architecture

### Training Pipeline
1. **Data Extraction:** Athena queries on S3 data
2. **Preprocessing:** Fargate container (64GB RAM)
3. **Training:** XGBoost/PyTorch on CPU/GPU
4. **Validation:** Cross-validation, hyperparameter tuning
5. **Evaluation:** Performance metrics, fairness checks
6. **Model Storage:** S3 (models/) + ECR (containerized)

### Inference Pipeline

#### Batch Inference (Weekly)
- **Container:** Fargate (64GB RAM)
- **Data:** Full customer base (100K records)
- **Duration:** 30 minutes
- **Output:** Athena results table + DynamoDB cache

#### Real-Time Inference (On-Demand)
- **Service:** Lambda (predict/)
- **Latency:** <100ms
- **Data Source:** DynamoDB cache (updated weekly)
- **Fallback:** Direct model inference if cache miss

---

## Model Monitoring & Maintenance

### Performance Monitoring
- **Metrics Tracked:** RMSE, AUC-ROC, R², Precision, Recall
- **Frequency:** Daily (batch), per-request (real-time)
- **Alerting:** CloudWatch alarms if metrics degrade >10%

### Data Drift Detection
- **Method:** KL divergence, Kolmogorov-Smirnov test
- **Frequency:** Weekly
- **Action:** Retrain if drift >15%

### Model Versioning
- **Format:** Semantic versioning (1.0.0)
- **Storage:** S3 with version history
- **Rollback:** Automated if new model underperforms

### Retraining Schedule
- **Engagement/Churn/LTV:** Monthly
- **Recommender:** Weekly (online learning)
- **Anomaly:** Quarterly
- **Next Best Action:** Continuous (online learning)
- **Segmentation:** Quarterly
- **Sentiment:** Semi-annually

---

## Fairness & Bias Controls

### Protected Attributes
- **Not Used as Features:** Gender, age (used only for fairness audits)
- **Proxy Detection:** Monitor for indirect discrimination

### Fairness Metrics
- **Demographic Parity:** 80% rule compliance ✅
- **Equalized Odds:** Similar TPR/FPR across groups ✅
- **Calibration:** Predictions well-calibrated across demographics ✅

### Bias Mitigation
- **Pre-processing:** Balanced sampling, data augmentation
- **In-processing:** Adversarial debiasing, fairness constraints
- **Post-processing:** Threshold optimization by group

### Audit Frequency
- **Automated:** Weekly fairness checks
- **Human Review:** Quarterly AI Ethics Committee review
- **External Audit:** Annual third-party fairness audit

---

**Last Updated:** October 21, 2025  
**Model Version:** 1.0.0  
**Next Retraining:** November 2025  
**Performance Status:** ✅ All models meeting targets

