# Data Quality Framework

**Customer Engagement Prediction Platform**  
**Version:** 1.0  
**Last Updated:** 2025-10-21  
**Classification:** Internal

---

## Table of Contents

1. [Overview](#overview)
2. [Data Quality Dimensions](#data-quality-dimensions)
3. [Validation Rules](#validation-rules)
4. [Monitoring & Alerts](#monitoring--alerts)
5. [Data Lineage](#data-lineage)
6. [Data Contracts](#data-contracts)
7. [Implementation](#implementation)

---

## 1. Overview

**Purpose:** Ensure the 100K dummy customer records (and future production data) meet quality standards for ML model training and inference.

**Framework:** Based on **Great Expectations** + **AWS Glue Data Quality**

**Quality Gates:**
- **Bronze Layer (Raw):** Basic completeness, schema validation
- **Silver Layer (Processed):** Business rules, statistical checks
- **Gold Layer (ML-Ready):** Feature engineering validation, distribution checks

---

## 2. Data Quality Dimensions

### 2.1 Accuracy
**Definition:** Data correctly represents real-world entities

**Checks:**
- Email format validation
- Phone number format validation
- Age within realistic bounds (18-100)
- Location exists in reference data

**Example:**
```python
expect_column_values_to_match_regex(
    'email', 
    regex=r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$'
)
```

### 2.2 Completeness
**Definition:** All required data is present

**Checks:**
- No nulls in primary key (`customer_id`)
- < 5% nulls in critical features (tenure, engagement_score)
- < 10% nulls in secondary features

**Example:**
```python
expect_column_values_to_not_be_null('customer_id')
expect_column_values_to_be_null('age', mostly=0.95)  # Allow 5% nulls
```

### 2.3 Consistency
**Definition:** Data is consistent across systems and time

**Checks:**
- `total_connections` = `connections_sent` + `connections_received`
- `engagement_score` correlates with `sessions_last_7_days`
- No contradictory values (e.g., churn = 1 but sessions_last_7_days = 20)

**Example:**
```python
df['total_connections_calc'] = df['connections_sent'] + df['connections_received']
expect_column_pair_values_to_be_equal('total_connections', 'total_connections_calc')
```

### 2.4 Timeliness
**Definition:** Data is up-to-date

**Checks:**
- Data freshness < 24 hours
- Last updated timestamp within expected range
- No future dates

**Example:**
```python
max_age_hours = (datetime.now() - df['created_at'].max()).total_seconds() / 3600
assert max_age_hours < 24, f"Data is {max_age_hours}h old (max: 24h)"
```

### 2.5 Uniqueness
**Definition:** No duplicate records

**Checks:**
- `customer_id` is unique (100% of records)
- No duplicate rows (across all columns)

**Example:**
```python
expect_column_values_to_be_unique('customer_id')
assert df.duplicated().sum() == 0, "Duplicate rows found"
```

### 2.6 Validity
**Definition:** Data conforms to business rules

**Checks:**
- `age` >= 18 (legal minimum)
- `engagement_score` between 0 and 1
- `gender` in ['M', 'F', 'O', 'N']
- `location` is valid country/region code

**Example:**
```python
expect_column_values_to_be_between('engagement_score', min_value=0, max_value=1)
expect_column_values_to_be_in_set('gender', ['M', 'F', 'O', 'N'])
```

### 2.7 Consistency (Statistical)
**Definition:** Data distributions are stable over time

**Checks:**
- Mean engagement score: 0.4 ± 0.1
- 95% of ages between 18-65
- Churn rate: 3-7%

**Example:**
```python
expect_column_mean_to_be_between('engagement_score', min_value=0.3, max_value=0.5)
expect_column_quantile_values_to_be_between(
    'age',
    quantile=0.95,
    min_value=18,
    max_value=65
)
```

---

## 3. Validation Rules

### 3.1 Schema Validation

**Athena Table Schema:**
```sql
CREATE EXTERNAL TABLE IF NOT EXISTS customers_raw (
  customer_id         STRING,
  age                 INT,
  gender              STRING,
  location            STRING,
  tenure_months       INT,
  sessions_last_7_days INT,
  engagement_score    DOUBLE,
  influence_score     DOUBLE,
  risk_score          DOUBLE,
  -- ... 40 more columns
)
STORED AS PARQUET
LOCATION 's3://engagement-processed/customers/'
```

**Validation:**
```python
expected_schema = {
    'customer_id': 'string',
    'age': 'int',
    'gender': 'string',
    'engagement_score': 'double',
    # ...
}

for col, dtype in expected_schema.items():
    assert col in df.columns, f"Missing column: {col}"
    assert df[col].dtype == dtype, f"Wrong type for {col}: {df[col].dtype} (expected {dtype})"
```

### 3.2 Business Rules

| Rule ID | Rule | Severity | Action |
|---------|------|----------|--------|
| **BR-001** | `customer_id` is not null | CRITICAL | Reject row |
| **BR-002** | `age` >= 18 | CRITICAL | Reject row |
| **BR-003** | `age` <= 100 | HIGH | Flag for review |
| **BR-004** | `engagement_score` in [0, 1] | CRITICAL | Reject row |
| **BR-005** | `tenure_months` >= 0 | CRITICAL | Reject row |
| **BR-006** | `sessions_last_7_days` >= 0 | HIGH | Replace with 0 |
| **BR-007** | `email` matches regex | MEDIUM | Flag for review |
| **BR-008** | `total_connections` = sum | HIGH | Recalculate |
| **BR-009** | < 5% nulls per feature | MEDIUM | Alert |
| **BR-010** | No duplicate `customer_id` | CRITICAL | Reject duplicates |

### 3.3 ML-Specific Rules

| Rule ID | Rule | Rationale |
|---------|------|-----------|
| **ML-001** | No infinite values | XGBoost doesn't handle inf |
| **ML-002** | No NaN after imputation | Breaks training |
| **ML-003** | Feature variance > 0.01 | Low-variance features are useless |
| **ML-004** | Correlation < 0.95 | Remove multicollinearity |
| **ML-005** | Class balance 20-80% | Prevent extreme imbalance |
| **ML-006** | No data leakage (target in features) | Invalidates model |

**Implementation:**
```python
def validate_ml_data(X, y):
    """Validate ML training data"""
    
    # ML-001: No infinite values
    assert not np.isinf(X).any().any(), "Infinite values found"
    
    # ML-002: No NaN
    assert not X.isna().any().any(), "NaN values found after imputation"
    
    # ML-003: Feature variance
    low_var_features = X.columns[X.var() < 0.01]
    assert len(low_var_features) == 0, f"Low-variance features: {low_var_features}"
    
    # ML-004: Multicollinearity
    corr_matrix = X.corr().abs()
    upper_triangle = corr_matrix.where(
        np.triu(np.ones(corr_matrix.shape), k=1).astype(bool)
    )
    high_corr = [col for col in upper_triangle.columns if any(upper_triangle[col] > 0.95)]
    assert len(high_corr) == 0, f"Highly correlated features: {high_corr}"
    
    # ML-005: Class balance
    positive_rate = (y > 0.5).mean()
    assert 0.2 <= positive_rate <= 0.8, f"Class imbalance: {positive_rate}"
    
    return True
```

---

## 4. Monitoring & Alerts

### 4.1 Data Quality Metrics

**CloudWatch Custom Metrics:**

| Metric | Namespace | Alert Threshold |
|--------|-----------|-----------------|
| `NullRate` | CustomMetrics/DataQuality | > 5% |
| `DuplicateCount` | CustomMetrics/DataQuality | > 0 |
| `SchemaViolations` | CustomMetrics/DataQuality | > 10 |
| `OutlierRate` | CustomMetrics/DataQuality | > 5% |
| `DataFreshnessHours` | CustomMetrics/DataQuality | > 24 |
| `RowCount` | CustomMetrics/DataQuality | < 90K (for 100K expected) |

**Lambda Function: `data-validation-lambda`**

```python
def lambda_handler(event, context):
    """Validate data quality and publish metrics"""
    
    # Load data from S3
    df = load_data_from_s3(event['s3_uri'])
    
    # Run validations
    results = {
        'null_rate': calculate_null_rate(df),
        'duplicate_count': df.duplicated().sum(),
        'schema_violations': validate_schema(df),
        'outlier_rate': detect_outliers(df),
        'freshness_hours': calculate_freshness(df),
        'row_count': len(df)
    }
    
    # Publish to CloudWatch
    for metric, value in results.items():
        put_metric(metric, value)
    
    # Alert if thresholds exceeded
    alerts = []
    if results['null_rate'] > 0.05:
        alerts.append(f"High null rate: {results['null_rate']}")
    if results['duplicate_count'] > 0:
        alerts.append(f"Duplicates found: {results['duplicate_count']}")
    
    if alerts:
        send_alert(alerts)
    
    return {'statusCode': 200, 'results': results}
```

### 4.2 Great Expectations Integration

**Checkpoint:** `data_quality_checkpoint.yml`

```yaml
name: customer_data_quality_checkpoint
config_version: 1.0

validations:
  - batch_request:
      datasource_name: s3_datasource
      data_connector_name: default_inferred_data_connector_name
      data_asset_name: customers
      data_connector_query:
        index: -1
    expectation_suite_name: customer_data_quality_suite

action_list:
  - name: store_validation_result
    action:
      class_name: StoreValidationResultAction

  - name: update_data_docs
    action:
      class_name: UpdateDataDocsAction

  - name: send_slack_notification_on_failure
    action:
      class_name: SlackNotificationAction
      slack_webhook: ${SLACK_WEBHOOK}
      notify_on: failure
```

**Expectation Suite:** `customer_data_quality_suite.json`

```json
{
  "expectation_suite_name": "customer_data_quality_suite",
  "expectations": [
    {
      "expectation_type": "expect_column_values_to_not_be_null",
      "kwargs": {"column": "customer_id"}
    },
    {
      "expectation_type": "expect_column_values_to_be_unique",
      "kwargs": {"column": "customer_id"}
    },
    {
      "expectation_type": "expect_column_values_to_be_between",
      "kwargs": {
        "column": "age",
        "min_value": 18,
        "max_value": 100
      }
    },
    {
      "expectation_type": "expect_column_values_to_be_in_set",
      "kwargs": {
        "column": "gender",
        "value_set": ["M", "F", "O", "N"]
      }
    },
    {
      "expectation_type": "expect_column_mean_to_be_between",
      "kwargs": {
        "column": "engagement_score",
        "min_value": 0.3,
        "max_value": 0.5
      }
    }
  ]
}
```

---

## 5. Data Lineage

### 5.1 Lineage Tracking

**Tool:** AWS Glue Data Catalog + custom tracking

**Lineage Metadata:**
```json
{
  "dataset_id": "customers_100k_v1",
  "source": "synthetic_generator",
  "created_at": "2025-10-21T10:00:00Z",
  "schema_version": "1.0",
  "row_count": 100000,
  "transformations": [
    {
      "step": "raw_ingestion",
      "s3_location": "s3://engagement-raw/customers.csv",
      "timestamp": "2025-10-21T10:00:00Z"
    },
    {
      "step": "data_cleaning",
      "sql_query": "sql/clean_customers.sql",
      "s3_location": "s3://engagement-processed/customers/",
      "timestamp": "2025-10-21T10:05:00Z",
      "rows_removed": 523
    },
    {
      "step": "feature_engineering",
      "script": "fargate/training/feature_engineering.py",
      "s3_location": "s3://engagement-features/training/",
      "timestamp": "2025-10-21T10:10:00Z"
    }
  ],
  "downstream_consumers": [
    "engagement_model_v1.0",
    "churn_model_v1.0",
    "ltv_model_v1.0"
  ]
}
```

### 5.2 Lineage Visualization

**Example Flow:**
```
CSV (Raw)
  ↓ [Lambda: data-prep-lambda]
Athena Table: customers_raw
  ↓ [Athena Query: clean_customers.sql]
Athena Table: customers_clean
  ↓ [Fargate: feature_engineering.py]
S3: engagement-features/training/
  ↓ [Fargate: train.py]
Model: engagement_model_v1.0
  ↓ [Fargate: inference.py]
Athena Table: predictions_final
```

---

## 6. Data Contracts

### 6.1 Contract Definition

**Contract:** `contracts/customers_contract.yml`

```yaml
dataset: customers
version: 1.0
owner: data-platform-team
sla:
  freshness: 24h
  availability: 99.9%
  completeness: 95%

schema:
  columns:
    - name: customer_id
      type: string
      nullable: false
      unique: true
      description: "Unique customer identifier (UUID)"
    
    - name: age
      type: int
      nullable: false
      min: 18
      max: 100
      description: "Customer age in years"
    
    - name: gender
      type: string
      nullable: true
      values: [M, F, O, N]
      description: "Customer gender (M=Male, F=Female, O=Other, N=Not specified)"
    
    - name: engagement_score
      type: double
      nullable: false
      min: 0.0
      max: 1.0
      description: "Engagement score (0=low, 1=high)"

quality_rules:
  - name: no_duplicates
    type: uniqueness
    column: customer_id
    threshold: 100%
  
  - name: age_distribution
    type: distribution
    column: age
    mean: [25, 45]
    std: [10, 20]
  
  - name: null_rate_limit
    type: completeness
    threshold: 95%

downstream_consumers:
  - ml_training_pipeline
  - analytics_dashboard
  - recommendation_service
```

### 6.2 Contract Validation

**Lambda Function: `validate-data-contract`**

```python
import yaml
from great_expectations.core import ExpectationSuite

def validate_contract(df, contract_path):
    """Validate data against contract"""
    
    # Load contract
    with open(contract_path, 'r') as f:
        contract = yaml.safe_load(f)
    
    violations = []
    
    # Schema validation
    for col_spec in contract['schema']['columns']:
        col_name = col_spec['name']
        
        # Check existence
        if col_name not in df.columns:
            violations.append(f"Missing column: {col_name}")
            continue
        
        # Check nullability
        if not col_spec.get('nullable', True):
            null_count = df[col_name].isna().sum()
            if null_count > 0:
                violations.append(f"{col_name}: {null_count} nulls (not allowed)")
        
        # Check uniqueness
        if col_spec.get('unique', False):
            dup_count = df[col_name].duplicated().sum()
            if dup_count > 0:
                violations.append(f"{col_name}: {dup_count} duplicates (must be unique)")
        
        # Check value range
        if 'min' in col_spec:
            below_min = (df[col_name] < col_spec['min']).sum()
            if below_min > 0:
                violations.append(f"{col_name}: {below_min} values below min ({col_spec['min']})")
        
        if 'max' in col_spec:
            above_max = (df[col_name] > col_spec['max']).sum()
            if above_max > 0:
                violations.append(f"{col_name}: {above_max} values above max ({col_spec['max']})")
    
    # Quality rules validation
    for rule in contract['quality_rules']:
        if rule['type'] == 'uniqueness':
            dup_count = df[rule['column']].duplicated().sum()
            if dup_count > 0:
                violations.append(f"Quality rule failed: {rule['name']} ({dup_count} duplicates)")
    
    return {
        'valid': len(violations) == 0,
        'violations': violations,
        'contract_version': contract['version']
    }
```

---

## 7. Implementation

### 7.1 Data Quality Pipeline

**Step 1: Ingest Raw Data**
```python
# Lambda: data-ingestion-lambda
df = pd.read_csv('s3://engagement-raw/customers.csv')
put_metric('RawRowCount', len(df))
```

**Step 2: Validate Raw Data**
```python
# Lambda: data-validation-lambda
validation_results = validate_contract(df, 'contracts/customers_contract.yml')

if not validation_results['valid']:
    send_alert(validation_results['violations'])
    raise ValueError("Data contract validation failed")
```

**Step 3: Clean & Transform**
```python
# Athena query: sql/clean_customers.sql
CREATE TABLE customers_clean AS
SELECT
  customer_id,
  age,
  gender,
  COALESCE(sessions_last_7_days, 0) AS sessions_last_7_days,
  engagement_score,
  ...
FROM customers_raw
WHERE customer_id IS NOT NULL
  AND age BETWEEN 18 AND 100
  AND engagement_score BETWEEN 0 AND 1;
```

**Step 4: Feature Engineering**
```python
# Fargate: feature_engineering.py
df['engagement_velocity'] = df['sessions_last_7_days'] / df['tenure_months']
df['influence_to_risk_ratio'] = df['influence_score'] / (df['risk_score'] + 1e-6)
```

**Step 5: Final Validation**
```python
# Validate ML-ready data
validate_ml_data(X_train, y_train)
```

**Step 6: Publish Metrics**
```python
put_metric('DataQualityScore', 0.98)  # 98% of rows passed all checks
put_metric('CleanedRowCount', len(df_clean))
```

### 7.2 Automated Remediation

**Auto-Fix Rules:**

| Issue | Auto-Fix Action |
|-------|----------------|
| Missing `sessions_last_7_days` | Replace with 0 |
| `age` < 18 | Replace with 18 |
| `engagement_score` > 1 | Cap at 1.0 |
| Minor outliers (< 2%) | Winsorize at 1st/99th percentile |
| Duplicate rows | Keep first occurrence, log others |

**Lambda Function: `auto-remediate-data`**

```python
def auto_remediate(df):
    """Apply auto-fix rules"""
    
    original_count = len(df)
    
    # Fix 1: Replace missing sessions with 0
    df['sessions_last_7_days'].fillna(0, inplace=True)
    
    # Fix 2: Cap age at 18
    df.loc[df['age'] < 18, 'age'] = 18
    
    # Fix 3: Cap engagement_score at 1.0
    df.loc[df['engagement_score'] > 1, 'engagement_score'] = 1.0
    
    # Fix 4: Winsorize outliers
    for col in df.select_dtypes(include=[np.number]).columns:
        lower = df[col].quantile(0.01)
        upper = df[col].quantile(0.99)
        df[col] = df[col].clip(lower, upper)
    
    # Fix 5: Remove duplicates
    df.drop_duplicates(subset='customer_id', keep='first', inplace=True)
    
    fixed_count = len(df)
    
    put_metric('RowsRemediated', original_count - fixed_count)
    
    return df
```

---

## 8. Reporting

### 8.1 Data Quality Dashboard

**CloudWatch Dashboard:** `data-quality-metrics`

**Widgets:**
1. **Data Quality Score** (line chart, 30 days)
2. **Null Rate by Column** (heatmap)
3. **Schema Violations** (bar chart)
4. **Data Freshness** (gauge)
5. **Row Count Trend** (line chart)

### 8.2 Daily Data Quality Report

**Scheduled Lambda:** Runs daily at 9am, sends email

**Report Contents:**
- Overall data quality score (0-100)
- Number of schema violations
- Null rate per column
- Duplicate count
- Outlier rate
- Data freshness
- Top 5 violated rules

---

## 9. References

- **Great Expectations:** https://greatexpectations.io
- **AWS Glue Data Quality:** https://docs.aws.amazon.com/glue/latest/dg/glue-data-quality.html
- **Data Quality Dimensions:** https://www.talend.com/resources/what-is-data-quality/

---

**Document Owner:** Data Platform Lead  
**Review Frequency:** Quarterly  
**Next Review:** 2026-01-21  
**Classification:** Internal

