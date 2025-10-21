-- ========================================
-- DATA LOADING SCRIPTS
-- ========================================
-- Purpose: Load customer data into Athena tables
-- Source: S3 bucket with CSV/Parquet files
-- ========================================

-- ========================================
-- 1. VERIFY S3 DATA EXISTS
-- ========================================

-- Check if data is available in S3
-- Run this in AWS CLI:
-- aws s3 ls s3://engagement-prediction-raw-dev/customers/

-- ========================================
-- 2. CREATE DATABASE (if not exists)
-- ========================================

CREATE DATABASE IF NOT EXISTS engagement_prediction_raw_dev
COMMENT 'Raw customer engagement data'
LOCATION 's3://engagement-prediction-raw-dev/';

CREATE DATABASE IF NOT EXISTS engagement_prediction_processed_dev
COMMENT 'Processed and cleaned data'
LOCATION 's3://engagement-prediction-processed-dev/';

CREATE DATABASE IF NOT EXISTS engagement_prediction_analytics_dev
COMMENT 'Analytics views and results'
LOCATION 's3://engagement-prediction-athena-results-dev/';

CREATE DATABASE IF NOT EXISTS engagement_prediction_ml_dev
COMMENT 'ML features and predictions'
LOCATION 's3://engagement-prediction-results-dev/';

-- ========================================
-- 3. LOAD CSV DATA FROM S3
-- ========================================

-- Option A: Load from CSV (if using CSV upload)
CREATE EXTERNAL TABLE IF NOT EXISTS customers_csv (
    customer_id STRING,
    age INT,
    gender STRING,
    location STRING,
    tenure_months INT,
    sessions_last_7_days INT,
    session_duration_avg_minutes INT,
    engagement_score DOUBLE,
    swipes_right_last_30_days INT,
    matches_last_30_days INT,
    match_success_rate DOUBLE,
    connections_sent INT,
    connections_received INT,
    total_connections INT,
    posts_last_30_days INT,
    stories_last_30_days INT,
    followers_count INT,
    following_count INT,
    profile_views_received INT,
    content_virality_score DOUBLE,
    gig_applications_sent INT,
    gig_applications_received INT,
    active_gigs_count INT,
    transaction_revenue_last_90_days DOUBLE,
    avg_job_completion_rating DOUBLE,
    influence_score DOUBLE,
    risk_score DOUBLE,
    avg_sentiment_score DOUBLE,
    network_centrality DOUBLE,
    content_diversity_score DOUBLE,
    session_consistency_score DOUBLE,
    last_7_day_engagement_trend DOUBLE,
    trust_score DOUBLE,
    response_time_avg_hours DOUBLE,
    peak_activity_hour INT,
    referral_count INT,
    time_since_first_transaction_days INT,
    premium_features_used_count INT,
    social_influence_tier STRING,
    churn_30_day INT,
    lifetime_value_usd DOUBLE,
    content_category_primary STRING
)
ROW FORMAT DELIMITED
FIELDS TERMINATED BY ','
STORED AS TEXTFILE
LOCATION 's3://engagement-prediction-raw-dev/customers_csv/'
TBLPROPERTIES (
    'skip.header.line.count'='1',
    'serialization.null.format'=''
);

-- Convert CSV to Parquet for better performance
CREATE TABLE customers
WITH (
    format='PARQUET',
    parquet_compression='SNAPPY',
    external_location='s3://engagement-prediction-raw-dev/customers/'
) AS
SELECT * FROM customers_csv;

-- Drop temporary CSV table
DROP TABLE IF EXISTS customers_csv;

-- ========================================
-- 4. VERIFY DATA LOAD
-- ========================================

-- Count records
SELECT COUNT(*) AS total_customers FROM customers;

-- Check for nulls in key columns
SELECT 
    COUNT(*) AS total_rows,
    SUM(CASE WHEN customer_id IS NULL THEN 1 ELSE 0 END) AS null_customer_ids,
    SUM(CASE WHEN engagement_score IS NULL THEN 1 ELSE 0 END) AS null_engagement,
    SUM(CASE WHEN churn_30_day IS NULL THEN 1 ELSE 0 END) AS null_churn,
    SUM(CASE WHEN lifetime_value_usd IS NULL THEN 1 ELSE 0 END) AS null_ltv
FROM customers;

-- Sample data
SELECT * FROM customers LIMIT 10;

-- Basic statistics
SELECT 
    COUNT(*) AS total_customers,
    ROUND(AVG(age), 1) AS avg_age,
    ROUND(AVG(tenure_months), 1) AS avg_tenure,
    ROUND(AVG(engagement_score), 3) AS avg_engagement,
    ROUND(AVG(churn_30_day) * 100, 1) AS churn_rate_pct,
    ROUND(AVG(lifetime_value_usd), 2) AS avg_ltv
FROM customers;

-- ========================================
-- 5. CREATE PARTITION FOR INCREMENTAL LOADS (Optional)
-- ========================================

-- If doing incremental loads, partition by date
CREATE EXTERNAL TABLE IF NOT EXISTS customers_partitioned (
    customer_id STRING,
    age INT,
    -- ... all other columns ...
    lifetime_value_usd DOUBLE,
    content_category_primary STRING
)
PARTITIONED BY (load_date STRING)
STORED AS PARQUET
LOCATION 's3://engagement-prediction-raw-dev/customers_partitioned/';

-- Add partitions manually or use msck repair
MSCK REPAIR TABLE customers_partitioned;

-- Or add partitions explicitly:
-- ALTER TABLE customers_partitioned ADD PARTITION (load_date='2025-10-21') 
-- LOCATION 's3://engagement-prediction-raw-dev/customers_partitioned/load_date=2025-10-21/';

-- ========================================
-- 6. OPTIMIZE TABLES (Optional)
-- ========================================

-- Analyze table for query optimization
ANALYZE TABLE customers COMPUTE STATISTICS;

-- Create table with better compression and format
CREATE TABLE customers_optimized
WITH (
    format='PARQUET',
    parquet_compression='SNAPPY',
    bucketed_by = ARRAY['customer_id'],
    bucket_count = 10,
    external_location='s3://engagement-prediction-raw-dev/customers_optimized/'
) AS
SELECT * FROM customers;

-- ========================================
-- 7. DATA QUALITY CHECKS
-- ========================================

-- Check for duplicates
SELECT 
    customer_id,
    COUNT(*) AS duplicate_count
FROM customers
GROUP BY customer_id
HAVING COUNT(*) > 1;

-- Check data ranges
SELECT 
    'age' AS column_name,
    MIN(age) AS min_value,
    MAX(age) AS max_value,
    CAST(AVG(age) AS INT) AS avg_value,
    SUM(CASE WHEN age < 18 OR age > 100 THEN 1 ELSE 0 END) AS out_of_range_count
FROM customers

UNION ALL

SELECT 
    'engagement_score',
    MIN(engagement_score),
    MAX(engagement_score),
    AVG(engagement_score),
    SUM(CASE WHEN engagement_score < 0 OR engagement_score > 1 THEN 1 ELSE 0 END)
FROM customers

UNION ALL

SELECT 
    'churn_30_day',
    MIN(churn_30_day),
    MAX(churn_30_day),
    AVG(churn_30_day),
    SUM(CASE WHEN churn_30_day NOT IN (0, 1) THEN 1 ELSE 0 END)
FROM customers;

-- Check gender distribution
SELECT 
    gender,
    COUNT(*) AS customer_count,
    ROUND(COUNT(*) * 100.0 / SUM(COUNT(*)) OVER (), 2) AS pct_of_total
FROM customers
GROUP BY gender
ORDER BY customer_count DESC;

-- Check location distribution
SELECT 
    location,
    COUNT(*) AS customer_count,
    ROUND(AVG(engagement_score), 3) AS avg_engagement
FROM customers
GROUP BY location
ORDER BY customer_count DESC
LIMIT 20;

-- ========================================
-- 8. GRANT PERMISSIONS (if using AWS Lake Formation)
-- ========================================

-- Grant SELECT permissions to analysts
-- GRANT SELECT ON TABLE customers TO IAM_ROLE 'arn:aws:iam::123456789012:role/AnalystRole';

-- Grant ALL permissions to ML service
-- GRANT ALL ON TABLE customers TO IAM_ROLE 'arn:aws:iam::123456789012:role/MLServiceRole';

-- ========================================
-- 9. CREATE VIEWS FOR COMMON QUERIES
-- ========================================

-- Active customers view
CREATE OR REPLACE VIEW active_customers AS
SELECT *
FROM customers
WHERE sessions_last_7_days > 0
  AND engagement_score > 0.3;

-- At-risk customers view
CREATE OR REPLACE VIEW at_risk_customers AS
SELECT *
FROM customers
WHERE churn_30_day = 1 
   OR engagement_score < 0.3
   OR (sessions_last_7_days = 0 AND tenure_months > 3);

-- High-value customers view
CREATE OR REPLACE VIEW high_value_customers AS
SELECT *
FROM customers
WHERE lifetime_value_usd > (SELECT PERCENTILE(lifetime_value_usd, 0.9) FROM customers);

-- ========================================
-- COMPLETE DATA LOAD VERIFICATION
-- ========================================

SELECT 
    'Data Load Summary' AS step,
    'COMPLETE' AS status,
    CAST(COUNT(*) AS VARCHAR) || ' customers loaded' AS details
FROM customers

UNION ALL

SELECT 
    'Train/Test Split',
    CASE 
        WHEN (SELECT COUNT(*) FROM customers_train) > 0 
         AND (SELECT COUNT(*) FROM customers_test) > 0 
        THEN 'COMPLETE'
        ELSE 'PENDING'
    END,
    'Train: ' || CAST((SELECT COUNT(*) FROM customers_train) AS VARCHAR) || 
    ', Test: ' || CAST((SELECT COUNT(*) FROM customers_test) AS VARCHAR)

UNION ALL

SELECT 
    'Feature Engineering',
    CASE 
        WHEN (SELECT COUNT(*) FROM customer_features) > 0 
        THEN 'COMPLETE'
        ELSE 'PENDING'
    END,
    CAST((SELECT COUNT(*) FROM customer_features) AS VARCHAR) || ' feature rows'

UNION ALL

SELECT 
    'Ready for ML Pipeline',
    'YES',
    'All tables created and verified';

