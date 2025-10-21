# SQL Scripts for Customer Engagement Platform

**Purpose:** Complete SQL scripts for data loading, schema creation, analytics, and fairness analysis

---

## 📁 Directory Structure

```
sql/
├── schema/
│   ├── create_customers_table.sql    # Original customers table DDL
│   ├── create_all_tables.sql         # All table definitions (7 tables)
│   └── load_data.sql                 # Data loading and verification scripts
├── analytics/
│   ├── engagement_analysis.sql       # 10 engagement analysis queries
│   └── model_performance.sql         # 10 model evaluation queries
├── fairness/
│   └── bias_detection.sql            # 10 fairness/bias detection queries
└── README.md                         # This file
```

---

## 📊 SQL Files Summary

### 1. Schema Files (3 files)

#### `schema/create_customers_table.sql`
- **Purpose:** Create external customers table
- **Tables:** 1 (customers)
- **Size:** 50 lines

#### `schema/create_all_tables.sql` ✨ **NEW**
- **Purpose:** Complete schema for entire ML pipeline
- **Tables:** 7 tables
  1. `customers` - Raw source data (42 columns)
  2. `customers_train` - Training dataset (80%)
  3. `customers_test` - Test dataset (20%)
  4. `customer_features` - Engineered features
  5. `predictions` - Model outputs
  6. `qa_sample` - Manual review sample (400 rows)
  7. `predictions_final` - Original + predictions joined
  8. `model_metrics` - Performance tracking
- **Size:** 300+ lines
- **Features:** Partition support, compression, verification queries

#### `schema/load_data.sql` ✨ **NEW**
- **Purpose:** Load and verify data from S3
- **Operations:**
  - Database creation
  - CSV → Parquet conversion
  - Data quality checks
  - Partition management
  - Permission grants
  - View creation
- **Size:** 250+ lines

---

### 2. Analytics Files (2 files)

#### `analytics/engagement_analysis.sql` ✨ **NEW**
- **Purpose:** Understand customer engagement patterns
- **Queries:** 10 comprehensive analyses
  1. High engagement customers (top 1000)
  2. At-risk customers (churn indicators)
  3. Customer segmentation (tenure × engagement)
  4. Feature correlations with engagement
  5. LTV analysis by segment
  6. Engagement trends by location
  7. Content creation vs engagement
  8. Session consistency analysis
  9. Gig economy metrics
  10. Top 100 customers by LTV
- **Size:** 400+ lines
- **Use Cases:** Business insights, campaign targeting, strategy

#### `analytics/model_performance.sql` ✨ **NEW**
- **Purpose:** Evaluate ML model performance
- **Queries:** 10 evaluation metrics
  1. Engagement model (RMSE, MAE, R²)
  2. Churn model (Accuracy, Precision, Recall, F1)
  3. LTV model (RMSE, MAE, R²)
  4. Anomaly detection performance
  5. Performance by segment
  6. Prediction confidence analysis
  7. Time-based model drift
  8. Model version comparison
  9. Error analysis (worst predictions)
  10. Overall model scorecard
- **Size:** 450+ lines
- **Use Cases:** Model monitoring, A/B testing, debugging

---

### 3. Fairness Files (1 file)

#### `fairness/bias_detection.sql` ✨ **NEW**
- **Purpose:** Detect and measure bias across protected classes
- **Queries:** 10 fairness analyses
  1. Demographic parity by gender (80% rule)
  2. Equalized odds (accuracy by gender)
  3. Calibration by gender
  4. Age group analysis
  5. Location-based fairness
  6. Intersectional analysis (gender × age)
  7. Feature importance fairness
  8. False positive/negative rates by gender
  9. Fairness scorecard (overall summary)
  10. Prohibited feature check
- **Size:** 500+ lines
- **Standards:** IEEE 7010, NIST AI RMF, 80% Rule
- **Use Cases:** Bias auditing, regulatory compliance

---

## 🚀 Usage Guide

### Step 1: Create Databases

```sql
-- Run in Athena
CREATE DATABASE IF NOT EXISTS engagement_prediction_raw_dev;
CREATE DATABASE IF NOT EXISTS engagement_prediction_processed_dev;
CREATE DATABASE IF NOT EXISTS engagement_prediction_analytics_dev;
CREATE DATABASE IF NOT EXISTS engagement_prediction_ml_dev;
```

### Step 2: Upload Data to S3

```bash
# Upload CSV file
aws s3 cp customer_engagement_dataset_extended.csv \
  s3://engagement-prediction-raw-dev/customers_csv/data.csv

# Or upload Parquet (faster)
aws s3 cp customer_engagement_dataset_extended.parquet \
  s3://engagement-prediction-raw-dev/customers/data.parquet
```

### Step 3: Create Schema

```sql
-- Option A: Run all tables at once
-- Execute: sql/schema/create_all_tables.sql in Athena

-- Option B: Step by step
-- 1. Create customers table
--    Execute: sql/schema/create_customers_table.sql
-- 2. Load data
--    Execute: sql/schema/load_data.sql
-- 3. Create remaining tables
--    Execute: sql/schema/create_all_tables.sql
```

### Step 4: Run Analytics

```sql
-- Engagement analysis
-- Execute queries from: sql/analytics/engagement_analysis.sql

-- Model performance (after predictions are generated)
-- Execute queries from: sql/analytics/model_performance.sql

-- Fairness analysis (after predictions are generated)
-- Execute queries from: sql/fairness/bias_detection.sql
```

---

## 📊 Query Execution Order

### For Initial Setup:
1. ✅ `schema/create_all_tables.sql` - Create all tables
2. ✅ `schema/load_data.sql` - Load and verify data
3. ✅ `analytics/engagement_analysis.sql` - Run initial analysis

### After ML Pipeline Runs:
4. ⏳ `analytics/model_performance.sql` - Evaluate models
5. ⏳ `fairness/bias_detection.sql` - Check for bias

---

## 🎯 Key Features

### Schema DDL
- ✅ 7 tables (raw, train/test, features, predictions, QA, final, metrics)
- ✅ 42 customer features
- ✅ Parquet format with Snappy compression
- ✅ Partition support for incremental loads
- ✅ View definitions for common queries

### Analytics Queries
- ✅ 10 engagement analysis queries
- ✅ Customer segmentation (tenure × engagement)
- ✅ Geographic analysis
- ✅ Content creation impact
- ✅ Gig economy metrics
- ✅ Feature correlations

### Model Performance
- ✅ 10 evaluation queries
- ✅ Regression metrics (RMSE, MAE, R²)
- ✅ Classification metrics (Accuracy, Precision, Recall, F1)
- ✅ Confusion matrices
- ✅ Calibration analysis
- ✅ Model drift detection

### Fairness Analysis
- ✅ 10 bias detection queries
- ✅ 80% rule compliance
- ✅ Demographic parity
- ✅ Equalized odds
- ✅ Calibration by protected class
- ✅ Intersectional analysis
- ✅ False positive/negative rates
- ✅ Fairness scorecard

---

## 📈 Expected Query Performance

| Query Type | Records | Execution Time | Cost |
|------------|---------|----------------|------|
| Simple SELECT | 100K | 1-2 seconds | $0.001 |
| Aggregations | 100K | 2-5 seconds | $0.005 |
| Joins | 100K × 100K | 5-15 seconds | $0.01 |
| Complex Analytics | 100K | 10-30 seconds | $0.02 |

**Total Athena cost for all queries:** ~$0.10

---

## 🔧 Optimization Tips

### 1. Use Parquet Format
```sql
-- Convert CSV to Parquet for 10x faster queries
CREATE TABLE customers_parquet
WITH (format='PARQUET', parquet_compression='SNAPPY')
AS SELECT * FROM customers_csv;
```

### 2. Partition Large Tables
```sql
-- Partition by load date for incremental queries
PARTITIONED BY (load_date STRING)
```

### 3. Use Views for Common Queries
```sql
-- Create materialized views for frequent analyses
CREATE OR REPLACE VIEW high_engagement_customers AS
SELECT * FROM customers WHERE engagement_score > 0.7;
```

### 4. Limit Scanned Data
```sql
-- Use WHERE clauses to reduce data scanned
WHERE load_date >= '2025-10-01'
```

---

## 🎯 Query Examples

### High-Value At-Risk Customers
```sql
SELECT customer_id, lifetime_value_usd, engagement_score, churn_30_day
FROM customers
WHERE lifetime_value_usd > 1000
  AND (churn_30_day = 1 OR engagement_score < 0.3)
ORDER BY lifetime_value_usd DESC
LIMIT 100;
```

### Model Performance Summary
```sql
SELECT 
    ROUND(SQRT(AVG(POWER(engagement_score - predicted_engagement_score, 2))), 4) AS rmse,
    ROUND(AVG(CASE WHEN churn_30_day = predicted_churn THEN 1.0 ELSE 0.0 END), 4) AS churn_accuracy
FROM predictions_final;
```

### Fairness Check
```sql
SELECT 
    gender,
    AVG(predicted_engagement_score) AS avg_pred,
    MIN(AVG(predicted_engagement_score)) OVER () / MAX(AVG(predicted_engagement_score)) OVER () AS parity_ratio
FROM predictions_final
GROUP BY gender;
```

---

## 📚 Additional Resources

- **AWS Athena Documentation:** https://docs.aws.amazon.com/athena/
- **Parquet Format:** https://parquet.apache.org/
- **SQL Best Practices:** See `docs/data_quality_framework.md`
- **Fairness Standards:** See `docs/ai_ethics_framework.md`

---

## ✅ Verification Checklist

After running all SQL scripts:

- [ ] All 7 tables created in Glue Data Catalog
- [ ] 100,000 customers loaded into `customers` table
- [ ] Train/test split completed (80/20)
- [ ] Feature engineering table populated
- [ ] No null values in key columns
- [ ] No duplicate customer_ids
- [ ] Age range: 18-80
- [ ] Engagement score range: 0-1
- [ ] All analytics queries execute successfully
- [ ] Model performance metrics calculated (after ML run)
- [ ] Fairness checks passed (80% rule compliant)

---

**Status:** ✅ All SQL scripts complete and ready for use  
**Total Queries:** 30+ (schema, analytics, performance, fairness)  
**Total Lines:** ~1,500 SQL lines  
**Cost to Run:** < $0.10 (Athena queries)

