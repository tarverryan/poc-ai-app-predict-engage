-- ========================================
-- CREATE ALL TABLES FOR ML PIPELINE
-- ========================================
-- Database: engagement_prediction_raw_dev
-- Purpose: Complete schema for customer engagement platform
-- ========================================

-- ========================================
-- 1. RAW CUSTOMERS TABLE (Source Data)
-- ========================================

CREATE EXTERNAL TABLE IF NOT EXISTS customers (
    -- Primary Key
    customer_id STRING COMMENT 'Unique customer identifier (UUID)',
    
    -- Demographics
    age INT COMMENT 'Customer age (18-80)',
    gender STRING COMMENT 'Gender: M/F/O/N',
    location STRING COMMENT 'Location code (e.g., US-CA, UK-LON)',
    
    -- Tenure & Engagement
    tenure_months INT COMMENT 'Months since account creation',
    sessions_last_7_days INT COMMENT 'Sessions in past week',
    session_duration_avg_minutes INT COMMENT 'Average session duration',
    engagement_score DOUBLE COMMENT 'Overall engagement (0-1)',
    
    -- Dating/Matching Features (Tinder-like)
    swipes_right_last_30_days INT COMMENT 'Right swipes in past month',
    matches_last_30_days INT COMMENT 'Successful matches',
    match_success_rate DOUBLE COMMENT 'Matches / Swipes ratio (%)',
    connections_sent INT COMMENT 'Connection requests sent',
    connections_received INT COMMENT 'Connection requests received',
    total_connections INT COMMENT 'Total active connections',
    
    -- Social Features (Instagram-like)
    posts_last_30_days INT COMMENT 'Posts published in past month',
    stories_last_30_days INT COMMENT 'Stories published in past month',
    followers_count INT COMMENT 'Number of followers',
    following_count INT COMMENT 'Number following',
    profile_views_received INT COMMENT 'Profile views received',
    content_virality_score DOUBLE COMMENT 'Content reach metric (0-1)',
    
    -- Gig Economy Features (Fiverr-like)
    gig_applications_sent INT COMMENT 'Gig applications sent',
    gig_applications_received INT COMMENT 'Gig applications received',
    active_gigs_count INT COMMENT 'Currently active gigs',
    transaction_revenue_last_90_days DOUBLE COMMENT 'Revenue in USD',
    avg_job_completion_rating DOUBLE COMMENT 'Average rating (1-5)',
    
    -- Influence & Risk
    influence_score DOUBLE COMMENT 'Influence metric (0-1)',
    risk_score DOUBLE COMMENT 'Risk metric (0-1)',
    
    -- Advanced Behavioral Features
    avg_sentiment_score DOUBLE COMMENT 'Average sentiment (-1 to 1)',
    network_centrality DOUBLE COMMENT 'Network position metric (0-1)',
    content_diversity_score DOUBLE COMMENT 'Content variety metric (0-1)',
    session_consistency_score DOUBLE COMMENT 'Usage consistency (0-1)',
    last_7_day_engagement_trend DOUBLE COMMENT 'Engagement trend (-1 to 1)',
    trust_score DOUBLE COMMENT 'Trust metric (0-1)',
    response_time_avg_hours DOUBLE COMMENT 'Avg response time (hours)',
    peak_activity_hour INT COMMENT 'Most active hour (0-23)',
    referral_count INT COMMENT 'Referrals made',
    time_since_first_transaction_days INT COMMENT 'Days since first transaction',
    premium_features_used_count INT COMMENT 'Premium features used',
    social_influence_tier STRING COMMENT 'Tier: Nano/Micro/Mid/Macro/Mega',
    
    -- Prediction Targets
    churn_30_day INT COMMENT 'Churn indicator (0/1)',
    lifetime_value_usd DOUBLE COMMENT 'Customer lifetime value (USD)',
    content_category_primary STRING COMMENT 'Primary content category'
)
STORED AS PARQUET
LOCATION 's3://engagement-prediction-raw-dev/customers/'
TBLPROPERTIES (
    'parquet.compression'='SNAPPY',
    'classification'='parquet'
);

-- ========================================
-- 2. PROCESSED TABLES (Train/Test Splits)
-- ========================================

-- Training Dataset (80% of data)
CREATE TABLE IF NOT EXISTS customers_train
WITH (
    format='PARQUET',
    parquet_compression='SNAPPY',
    external_location='s3://engagement-prediction-processed-dev/train/'
) AS
SELECT *
FROM customers
WHERE MOD(ABS(xxhash64(customer_id)), 10) < 8;

-- Test Dataset (20% of data)
CREATE TABLE IF NOT EXISTS customers_test
WITH (
    format='PARQUET',
    parquet_compression='SNAPPY',
    external_location='s3://engagement-prediction-processed-dev/test/'
) AS
SELECT *
FROM customers
WHERE MOD(ABS(xxhash64(customer_id)), 10) >= 8;

-- ========================================
-- 3. FEATURES TABLE (Engineered Features)
-- ========================================

CREATE TABLE IF NOT EXISTS customer_features
WITH (
    format='PARQUET',
    parquet_compression='SNAPPY',
    external_location='s3://engagement-prediction-features-dev/features/'
) AS
SELECT 
    customer_id,
    age,
    gender,
    location,
    tenure_months,
    sessions_last_7_days,
    session_duration_avg_minutes,
    engagement_score,
    
    -- Engineered Features
    CAST(engagement_score AS DOUBLE) / NULLIF(sessions_last_7_days, 0) AS engagement_per_session,
    CAST(session_duration_avg_minutes AS DOUBLE) * engagement_score AS avg_session_value,
    CAST(followers_count AS DOUBLE) / NULLIF(following_count, 0) AS follower_following_ratio,
    CAST(posts_last_30_days + stories_last_30_days AS DOUBLE) / 30.0 AS content_activity_rate,
    CAST(matches_last_30_days AS DOUBLE) / NULLIF(swipes_right_last_30_days, 0) AS match_efficiency,
    CAST(total_connections AS DOUBLE) / NULLIF(tenure_months, 0) AS connection_rate,
    CAST(active_gigs_count AS DOUBLE) / NULLIF(gig_applications_sent, 0) AS gig_success_rate,
    CAST(transaction_revenue_last_90_days AS DOUBLE) / NULLIF(active_gigs_count, 0) AS revenue_per_gig,
    
    -- Original features
    swipes_right_last_30_days,
    matches_last_30_days,
    total_connections,
    followers_count,
    following_count,
    posts_last_30_days,
    gig_applications_sent,
    active_gigs_count,
    transaction_revenue_last_90_days,
    avg_job_completion_rating,
    influence_score,
    risk_score,
    avg_sentiment_score,
    network_centrality,
    trust_score,
    
    -- Targets
    churn_30_day,
    lifetime_value_usd,
    content_category_primary
FROM customers;

-- ========================================
-- 4. PREDICTIONS TABLE (Model Outputs)
-- ========================================

CREATE EXTERNAL TABLE IF NOT EXISTS predictions (
    -- Primary Key
    customer_id STRING,
    
    -- Predictions
    predicted_engagement_score DOUBLE COMMENT 'Predicted engagement (0-1)',
    predicted_churn INT COMMENT 'Predicted churn (0/1)',
    predicted_churn_probability DOUBLE COMMENT 'Churn probability (0-1)',
    predicted_ltv_usd DOUBLE COMMENT 'Predicted LTV (USD)',
    anomaly_score DOUBLE COMMENT 'Anomaly score (lower = more anomalous)',
    is_anomaly INT COMMENT 'Anomaly flag (0/1)',
    
    -- Metadata
    model_version STRING COMMENT 'Model version',
    prediction_timestamp STRING COMMENT 'Prediction timestamp (ISO 8601)'
)
STORED AS PARQUET
LOCATION 's3://engagement-prediction-results-dev/predictions/'
TBLPROPERTIES (
    'parquet.compression'='SNAPPY'
);

-- ========================================
-- 5. QA SAMPLE TABLE (Manual Review)
-- ========================================

CREATE TABLE IF NOT EXISTS qa_sample
WITH (
    format='PARQUET',
    parquet_compression='SNAPPY',
    external_location='s3://engagement-prediction-results-dev/qa_sample/'
) AS
SELECT *
FROM (
    SELECT 
        *,
        NTILE(4) OVER (ORDER BY predicted_engagement_score) AS quartile
    FROM predictions
)
WHERE MOD(ABS(xxhash64(customer_id)), 10) = 0
LIMIT 400;

-- ========================================
-- 6. FINAL RESULTS TABLE (Original + Predictions)
-- ========================================

CREATE TABLE IF NOT EXISTS predictions_final
WITH (
    format='PARQUET',
    parquet_compression='SNAPPY',
    external_location='s3://engagement-prediction-results-dev/final/'
) AS
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
FROM customers c
LEFT JOIN predictions p
    ON c.customer_id = p.customer_id;

-- ========================================
-- 7. MODEL METRICS TABLE (Performance Tracking)
-- ========================================

CREATE EXTERNAL TABLE IF NOT EXISTS model_metrics (
    model_name STRING,
    model_version STRING,
    metric_name STRING,
    metric_value DOUBLE,
    dataset STRING COMMENT 'train/test/validation',
    timestamp STRING,
    metadata STRING COMMENT 'JSON metadata'
)
STORED AS PARQUET
LOCATION 's3://engagement-prediction-models-dev/metrics/'
TBLPROPERTIES (
    'parquet.compression'='SNAPPY'
);

-- ========================================
-- VERIFICATION QUERIES
-- ========================================

-- Count records in each table
SELECT 'customers' AS table_name, COUNT(*) AS row_count FROM customers
UNION ALL
SELECT 'customers_train', COUNT(*) FROM customers_train
UNION ALL
SELECT 'customers_test', COUNT(*) FROM customers_test
UNION ALL
SELECT 'customer_features', COUNT(*) FROM customer_features
UNION ALL
SELECT 'predictions', COUNT(*) FROM predictions
UNION ALL
SELECT 'predictions_final', COUNT(*) FROM predictions_final;

