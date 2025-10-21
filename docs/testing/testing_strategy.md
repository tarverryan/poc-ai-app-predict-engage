# Testing Strategy

**Customer Engagement Prediction Platform**  
**Version:** 1.0  
**Last Updated:** 2025-10-21  
**Classification:** Internal

---

## Table of Contents

1. [Overview](#overview)
2. [Testing Pyramid](#testing-pyramid)
3. [Unit Testing](#unit-testing)
4. [Integration Testing](#integration-testing)
5. [End-to-End Testing](#end-to-end-testing)
6. [ML Model Testing](#ml-model-testing)
7. [Security Testing](#security-testing)
8. [Performance Testing](#performance-testing)
9. [Data Quality Testing](#data-quality-testing)
10. [Fairness Testing](#fairness-testing)
11. [Infrastructure Testing](#infrastructure-testing)
12. [Test Data Management](#test-data-management)

---

## 1. Overview

**Testing Philosophy:**
- **Shift-Left:** Test early, test often
- **Fast Feedback:** Unit tests < 5s, integration tests < 60s
- **Confidence:** 80% code coverage minimum
- **Automation:** 100% of tests automated in CI/CD

**Testing Tools:**
- **Python:** `pytest`, `pytest-cov`, `moto`, `localstack`
- **Infrastructure:** `terraform validate`, `tfsec`, `Checkov`
- **Security:** `Trivy`, `Safety`, `Prowler`
- **Performance:** `locust`, `k6`
- **ML:** `great_expectations`, `deepchecks`

---

## 2. Testing Pyramid

```
           ┌─────────────┐
           │     E2E     │  10% (slow, expensive)
           │  < 10 tests │
           └─────────────┘
         ┌─────────────────┐
         │  Integration    │  20% (medium speed)
         │   < 50 tests    │
         └─────────────────┘
       ┌───────────────────────┐
       │      Unit Tests       │  70% (fast, cheap)
       │     > 200 tests       │
       └───────────────────────┘
```

**Target Execution Times:**
- Unit: 5 seconds
- Integration: 60 seconds
- E2E: 5 minutes

---

## 3. Unit Testing

### 3.1 Lambda Functions

**Test File:** `tests/unit/test_lambda_predict.py`

```python
import pytest
from moto import mock_dynamodb, mock_s3
from lambda.predict.handler import lambda_handler

@pytest.fixture
def mock_aws():
    """Mock AWS services"""
    with mock_dynamodb(), mock_s3():
        yield

def test_lambda_handler_success(mock_aws):
    """Test successful prediction"""
    event = {
        'customer_id': 'test_123',
        'features': {
            'tenure_months': 12,
            'sessions_last_7_days': 5,
            # ... other features
        }
    }
    
    response = lambda_handler(event, None)
    
    assert response['statusCode'] == 200
    assert 'prediction' in response['body']
    assert 0 <= response['body']['prediction'] <= 1

def test_lambda_handler_missing_features(mock_aws):
    """Test error handling for missing features"""
    event = {'customer_id': 'test_123'}
    
    response = lambda_handler(event, None)
    
    assert response['statusCode'] == 400
    assert 'error' in response['body']

def test_lambda_handler_invalid_customer_id(mock_aws):
    """Test invalid customer ID handling"""
    event = {'customer_id': '', 'features': {}}
    
    response = lambda_handler(event, None)
    
    assert response['statusCode'] == 400
```

### 3.2 ML Model Functions

**Test File:** `tests/unit/test_model.py`

```python
import pytest
import numpy as np
from fargate.training.train import EngagementModel

def test_model_training():
    """Test model training with dummy data"""
    X_train = np.random.rand(100, 20)
    y_train = np.random.rand(100)
    
    model = EngagementModel()
    model.fit(X_train, y_train)
    
    assert model.is_trained()
    assert model.feature_count == 20

def test_model_prediction():
    """Test model prediction"""
    X_train = np.random.rand(100, 20)
    y_train = np.random.rand(100)
    X_test = np.random.rand(10, 20)
    
    model = EngagementModel()
    model.fit(X_train, y_train)
    predictions = model.predict(X_test)
    
    assert len(predictions) == 10
    assert all(0 <= p <= 1 for p in predictions)

def test_model_serialization():
    """Test model save/load"""
    model = EngagementModel()
    model.save('/tmp/test_model.pkl')
    
    loaded_model = EngagementModel.load('/tmp/test_model.pkl')
    
    assert loaded_model.feature_count == model.feature_count
```

### 3.3 Data Processing

**Test File:** `tests/unit/test_data_processing.py`

```python
import pytest
import pandas as pd
from fargate.training.preprocess import preprocess_data

def test_preprocess_data_removes_nulls():
    """Test null removal"""
    df = pd.DataFrame({
        'customer_id': [1, 2, 3],
        'feature1': [1.0, None, 3.0],
        'feature2': [4.0, 5.0, 6.0]
    })
    
    result = preprocess_data(df)
    
    assert len(result) == 2  # One row removed

def test_preprocess_data_scales_features():
    """Test feature scaling"""
    df = pd.DataFrame({
        'feature1': [1, 100, 1000],
        'feature2': [10, 20, 30]
    })
    
    result = preprocess_data(df)
    
    assert result['feature1'].std() < 2  # Normalized

def test_preprocess_data_handles_outliers():
    """Test outlier handling"""
    df = pd.DataFrame({
        'feature1': [1, 2, 3, 1000]  # 1000 is outlier
    })
    
    result = preprocess_data(df, remove_outliers=True)
    
    assert result['feature1'].max() < 100
```

### 3.4 Coverage Requirements

**pytest.ini:**
```ini
[pytest]
minversion = 6.0
addopts = 
    --cov=lambda
    --cov=fargate
    --cov-report=html
    --cov-report=term-missing
    --cov-fail-under=80
testpaths = tests
python_files = test_*.py
python_classes = Test*
python_functions = test_*
```

**Run:**
```bash
pytest --cov --cov-report=html
```

---

## 4. Integration Testing

### 4.1 Lambda + DynamoDB

**Test File:** `tests/integration/test_lambda_dynamodb.py`

```python
import pytest
import boto3
from moto import mock_dynamodb

@pytest.fixture
def dynamodb_table():
    """Create mock DynamoDB table"""
    with mock_dynamodb():
        client = boto3.client('dynamodb', region_name='us-east-1')
        client.create_table(
            TableName='predictions',
            KeySchema=[{'AttributeName': 'customer_id', 'KeyType': 'HASH'}],
            AttributeDefinitions=[
                {'AttributeName': 'customer_id', 'AttributeType': 'S'}
            ],
            BillingMode='PAY_PER_REQUEST'
        )
        yield client

def test_lambda_writes_to_dynamodb(dynamodb_table):
    """Test Lambda writes prediction to DynamoDB"""
    from lambda.predict.handler import lambda_handler
    
    event = {'customer_id': 'test_123', 'features': {...}}
    
    response = lambda_handler(event, None)
    
    # Check DynamoDB
    item = dynamodb_table.get_item(
        TableName='predictions',
        Key={'customer_id': {'S': 'test_123'}}
    )
    
    assert 'Item' in item
    assert item['Item']['prediction']['N'] == response['body']['prediction']
```

### 4.2 Step Functions Workflow

**Test File:** `tests/integration/test_step_functions.py`

```python
import pytest
import boto3
from moto import mock_stepfunctions

@mock_stepfunctions
def test_ml_pipeline_execution():
    """Test Step Functions ML pipeline"""
    client = boto3.client('stepfunctions', region_name='us-east-1')
    
    # Create state machine
    definition = open('terraform/step_functions.json').read()
    arn = client.create_state_machine(
        name='ml-pipeline',
        definition=definition,
        roleArn='arn:aws:iam::123456789012:role/test'
    )['stateMachineArn']
    
    # Start execution
    execution_arn = client.start_execution(
        stateMachineArn=arn,
        input='{"model": "engagement"}'
    )['executionArn']
    
    # Wait for completion (mocked)
    response = client.describe_execution(executionArn=execution_arn)
    
    assert response['status'] == 'SUCCEEDED'
```

### 4.3 LocalStack Integration

**Test File:** `tests/integration/test_localstack.py`

```python
import pytest
import boto3

@pytest.fixture(scope='session')
def localstack_client():
    """Connect to LocalStack"""
    return boto3.client(
        's3',
        endpoint_url='http://localhost:4566',
        aws_access_key_id='test',
        aws_secret_access_key='test'
    )

def test_s3_bucket_creation(localstack_client):
    """Test S3 bucket operations in LocalStack"""
    bucket = 'test-engagement-data'
    
    localstack_client.create_bucket(Bucket=bucket)
    
    response = localstack_client.list_buckets()
    assert bucket in [b['Name'] for b in response['Buckets']]

def test_athena_query_execution(localstack_client):
    """Test Athena query in LocalStack"""
    # LocalStack Pro required for Athena
    athena = boto3.client(
        'athena',
        endpoint_url='http://localhost:4566',
        aws_access_key_id='test',
        aws_secret_access_key='test'
    )
    
    response = athena.start_query_execution(
        QueryString='SELECT * FROM customers LIMIT 10',
        ResultConfiguration={'OutputLocation': 's3://test-results/'}
    )
    
    assert 'QueryExecutionId' in response
```

---

## 5. End-to-End Testing

### 5.1 Full Pipeline Test

**Test File:** `tests/e2e/test_full_pipeline.py`

```python
import pytest
import time
import boto3

@pytest.mark.e2e
@pytest.mark.slow
def test_full_ml_pipeline():
    """Test complete ML pipeline from data to predictions"""
    
    # 1. Upload raw data to S3
    s3 = boto3.client('s3', endpoint_url='http://localhost:4566')
    s3.upload_file('tests/data/customers.csv', 'engagement-raw', 'customers.csv')
    
    # 2. Trigger Step Functions
    sfn = boto3.client('stepfunctions', endpoint_url='http://localhost:4566')
    execution_arn = sfn.start_execution(
        stateMachineArn='arn:aws:states:us-east-1:000000000000:stateMachine:ml-pipeline',
        input='{"model": "engagement"}'
    )['executionArn']
    
    # 3. Wait for completion (max 10 minutes)
    timeout = time.time() + 600
    while time.time() < timeout:
        status = sfn.describe_execution(executionArn=execution_arn)['status']
        if status in ['SUCCEEDED', 'FAILED']:
            break
        time.sleep(10)
    
    assert status == 'SUCCEEDED'
    
    # 4. Verify Athena results table exists
    athena = boto3.client('athena', endpoint_url='http://localhost:4566')
    response = athena.get_table_metadata(
        CatalogName='AwsDataCatalog',
        DatabaseName='engagement_db',
        TableName='predictions_final'
    )
    
    assert response['TableMetadata']['Name'] == 'predictions_final'
    
    # 5. Query predictions
    query_execution_id = athena.start_query_execution(
        QueryString='SELECT COUNT(*) FROM predictions_final',
        ResultConfiguration={'OutputLocation': 's3://test-results/'}
    )['QueryExecutionId']
    
    # Wait for query
    time.sleep(5)
    results = athena.get_query_results(QueryExecutionId=query_execution_id)
    
    count = int(results['ResultSet']['Rows'][1]['Data'][0]['VarCharValue'])
    assert count == 100000  # 100K predictions
```

---

## 6. ML Model Testing

### 6.1 Model Performance Tests

**Test File:** `tests/ml/test_model_performance.py`

```python
import pytest
import numpy as np
from sklearn.metrics import r2_score, mean_squared_error
from fargate.training.train import EngagementModel

def test_model_accuracy_threshold():
    """Test model meets accuracy threshold"""
    X_train, y_train = load_training_data()
    X_test, y_test = load_test_data()
    
    model = EngagementModel()
    model.fit(X_train, y_train)
    predictions = model.predict(X_test)
    
    r2 = r2_score(y_test, predictions)
    rmse = np.sqrt(mean_squared_error(y_test, predictions))
    
    assert r2 > 0.75, f"R² ({r2}) below threshold"
    assert rmse < 0.15, f"RMSE ({rmse}) above threshold"

def test_model_overfitting():
    """Test model doesn't overfit"""
    X_train, y_train = load_training_data()
    X_test, y_test = load_test_data()
    
    model = EngagementModel()
    model.fit(X_train, y_train)
    
    train_score = model.score(X_train, y_train)
    test_score = model.score(X_test, y_test)
    
    # Test score shouldn't be < 20% lower than train score
    assert test_score >= train_score * 0.8
```

### 6.2 Model Drift Tests

**Test File:** `tests/ml/test_model_drift.py`

```python
import pytest
from scipy.stats import ks_2samp
from fargate.monitoring.drift_detection import detect_drift

def test_no_drift_in_training_data():
    """Test training data is stable"""
    X_train_batch1 = load_data('2024-01-01', '2024-01-31')
    X_train_batch2 = load_data('2024-02-01', '2024-02-28')
    
    drift_results = detect_drift(X_train_batch1, X_train_batch2)
    
    for feature, ks_stat in drift_results.items():
        assert ks_stat < 0.1, f"Drift detected in {feature}: {ks_stat}"

def test_drift_detection_alerts():
    """Test drift detection triggers alert"""
    X_train = load_training_data()
    X_production = load_production_data()
    
    # Intentionally shift data
    X_production['tenure_months'] *= 2
    
    drift_results = detect_drift(X_train, X_production)
    
    assert drift_results['tenure_months'] > 0.1
```

### 6.3 Model Explainability Tests

**Test File:** `tests/ml/test_explainability.py`

```python
import pytest
import shap
from fargate.training.train import EngagementModel

def test_shap_values_available():
    """Test SHAP explainability works"""
    X_train, y_train = load_training_data()
    X_test = load_test_data()[0]
    
    model = EngagementModel()
    model.fit(X_train, y_train)
    
    explainer = shap.TreeExplainer(model.model)
    shap_values = explainer.shap_values(X_test[:10])
    
    assert shap_values.shape == X_test[:10].shape

def test_feature_importance_stability():
    """Test feature importance is stable across runs"""
    X_train, y_train = load_training_data()
    
    model1 = EngagementModel(random_state=42)
    model1.fit(X_train, y_train)
    importance1 = model1.feature_importances()
    
    model2 = EngagementModel(random_state=42)
    model2.fit(X_train, y_train)
    importance2 = model2.feature_importances()
    
    np.testing.assert_array_almost_equal(importance1, importance2, decimal=3)
```

---

## 7. Security Testing

### 7.1 Infrastructure Security

**Test File:** `tests/security/test_terraform.sh`

```bash
#!/bin/bash
set -e

echo "Running Terraform security scans..."

# Validate syntax
terraform -chdir=terraform validate

# Security scan with tfsec
tfsec terraform/ --minimum-severity MEDIUM

# Policy compliance with Checkov
checkov -d terraform/ --framework terraform --quiet

# Check for secrets
trufflehog filesystem terraform/ --json

echo "✅ All security scans passed"
```

### 7.2 Container Security

**Test File:** `tests/security/test_docker.sh`

```bash
#!/bin/bash
set -e

echo "Scanning Docker images..."

# Scan training image
trivy image engagement-training:latest --severity HIGH,CRITICAL --exit-code 1

# Scan inference image
trivy image engagement-inference:latest --severity HIGH,CRITICAL --exit-code 1

# Check for malware
clamscan -r fargate/

echo "✅ Container security scans passed"
```

### 7.3 Dependency Scanning

**Test File:** `tests/security/test_dependencies.py`

```python
import pytest
import subprocess

def test_python_dependencies_safe():
    """Test Python dependencies for known vulnerabilities"""
    result = subprocess.run(
        ['safety', 'check', '--json'],
        capture_output=True,
        text=True
    )
    
    assert result.returncode == 0, "Vulnerabilities found in dependencies"

def test_no_outdated_dependencies():
    """Test dependencies are up-to-date"""
    result = subprocess.run(
        ['pip', 'list', '--outdated', '--format=json'],
        capture_output=True,
        text=True
    )
    
    import json
    outdated = json.loads(result.stdout)
    
    # Allow minor version updates, but alert on major
    critical_outdated = [
        p for p in outdated
        if int(p['latest_version'].split('.')[0]) > int(p['version'].split('.')[0])
    ]
    
    assert len(critical_outdated) == 0
```

---

## 8. Performance Testing

### 8.1 Load Testing (API)

**Test File:** `tests/performance/locustfile.py`

```python
from locust import HttpUser, task, between

class EngagementAPIUser(HttpUser):
    wait_time = between(1, 3)
    
    @task
    def predict_engagement(self):
        payload = {
            'customer_id': 'test_123',
            'features': {
                'tenure_months': 12,
                'sessions_last_7_days': 5,
                # ... other features
            }
        }
        
        self.client.post('/predict', json=payload)

# Run:
# locust -f tests/performance/locustfile.py --host=http://localhost:3000
# Target: 100 RPS, p95 < 200ms
```

### 8.2 Stress Testing (Fargate)

**Test File:** `tests/performance/test_fargate_stress.py`

```python
import pytest
import time
import boto3

@pytest.mark.performance
def test_fargate_handles_large_dataset():
    """Test Fargate training with 1M records"""
    
    # Upload 1M record dataset
    upload_large_dataset(rows=1_000_000)
    
    # Trigger training
    ecs = boto3.client('ecs', endpoint_url='http://localhost:4566')
    
    start_time = time.time()
    
    task_arn = ecs.run_task(
        cluster='ml-cluster',
        taskDefinition='training-task',
        launchType='FARGATE'
    )['tasks'][0]['taskArn']
    
    # Wait for completion
    while True:
        task = ecs.describe_tasks(cluster='ml-cluster', tasks=[task_arn])['tasks'][0]
        if task['lastStatus'] == 'STOPPED':
            break
        time.sleep(10)
    
    duration = time.time() - start_time
    
    # Should complete within 30 minutes
    assert duration < 1800, f"Training took {duration}s (max 1800s)"
```

---

## 9. Data Quality Testing

### 9.1 Great Expectations

**Test File:** `tests/data_quality/test_data_validation.py`

```python
import pytest
import great_expectations as ge

def test_raw_data_quality():
    """Test raw customer data meets expectations"""
    df = ge.read_csv('s3://engagement-raw/customers.csv')
    
    # Expectations
    expect = df.expect_column_values_to_not_be_null('customer_id')
    assert expect['success']
    
    expect = df.expect_column_values_to_be_between('age', min_value=18, max_value=100)
    assert expect['success']
    
    expect = df.expect_column_values_to_be_in_set('gender', ['M', 'F', 'O'])
    assert expect['success']
    
    expect = df.expect_column_mean_to_be_between('engagement_score', min_value=0, max_value=1)
    assert expect['success']

def test_training_data_quality():
    """Test training data is ML-ready"""
    X_train, y_train = load_training_data()
    
    # No nulls
    assert X_train.isnull().sum().sum() == 0
    
    # No duplicates
    assert X_train.duplicated().sum() == 0
    
    # Target in range
    assert y_train.min() >= 0 and y_train.max() <= 1
    
    # Reasonable class balance (no extreme imbalance)
    class_balance = (y_train > 0.5).mean()
    assert 0.2 < class_balance < 0.8
```

---

## 10. Fairness Testing

### 10.1 Bias Detection Tests

**Test File:** `tests/fairness/test_bias_detection.py`

```python
import pytest
from aif360.datasets import BinaryLabelDataset
from aif360.metrics import BinaryLabelDatasetMetric
from fargate.fairness.bias_detection import calculate_demographic_parity

def test_demographic_parity_gender():
    """Test gender fairness in predictions"""
    predictions = load_predictions_with_demographics()
    
    male_rate = predictions[predictions['gender'] == 'M']['prediction'].mean()
    female_rate = predictions[predictions['gender'] == 'F']['prediction'].mean()
    
    parity = min(male_rate, female_rate) / max(male_rate, female_rate)
    
    assert parity > 0.80, f"Gender parity ({parity}) below 80% rule"

def test_equalized_odds_age():
    """Test age fairness (equalized odds)"""
    predictions = load_predictions_with_demographics()
    
    young = predictions[predictions['age'] < 30]
    old = predictions[predictions['age'] >= 50]
    
    young_tpr = (young['prediction'] > 0.5)[young['actual'] == 1].mean()
    old_tpr = (old['prediction'] > 0.5)[old['actual'] == 1].mean()
    
    tpr_diff = abs(young_tpr - old_tpr)
    
    assert tpr_diff < 0.1, f"Age TPR difference ({tpr_diff}) too high"

def test_calibration_by_race():
    """Test prediction calibration across protected classes"""
    predictions = load_predictions_with_demographics()
    
    for group in predictions['race'].unique():
        group_data = predictions[predictions['race'] == group]
        
        predicted_prob = group_data['prediction'].mean()
        actual_rate = group_data['actual'].mean()
        
        calibration_error = abs(predicted_prob - actual_rate)
        
        assert calibration_error < 0.05, f"Calibration error for {group}: {calibration_error}"
```

---

## 11. Infrastructure Testing

### 11.1 Terraform Tests

**Test File:** `tests/infrastructure/test_terraform.py`

```python
import pytest
import subprocess
import json

def test_terraform_plan_succeeds():
    """Test Terraform plan runs without errors"""
    result = subprocess.run(
        ['terraform', 'plan', '-out=tfplan', '-var-file=test.tfvars'],
        cwd='terraform/',
        capture_output=True,
        text=True
    )
    
    assert result.returncode == 0
    assert 'Error' not in result.stderr

def test_terraform_cost_estimate():
    """Test infrastructure cost is within budget"""
    # Requires infracost CLI
    result = subprocess.run(
        ['infracost', 'breakdown', '--path', 'terraform/', '--format', 'json'],
        capture_output=True,
        text=True
    )
    
    cost_data = json.loads(result.stdout)
    monthly_cost = cost_data['totalMonthlyCost']
    
    assert float(monthly_cost) < 500, f"Cost ({monthly_cost}) exceeds $500/month budget"
```

---

## 12. Test Data Management

### 12.1 Test Data Generator

**Script:** `tests/data/generate_test_data.py`

```python
import pandas as pd
import numpy as np
from faker import Faker

def generate_test_customers(n=1000):
    """Generate synthetic customer data for testing"""
    fake = Faker()
    
    data = {
        'customer_id': [fake.uuid4() for _ in range(n)],
        'age': np.random.randint(18, 80, n),
        'gender': np.random.choice(['M', 'F', 'O'], n),
        'tenure_months': np.random.randint(1, 120, n),
        'sessions_last_7_days': np.random.poisson(5, n),
        'engagement_score': np.random.beta(2, 5, n),  # Skewed distribution
        # ... other features
    }
    
    return pd.DataFrame(data)

# Generate test datasets
if __name__ == '__main__':
    generate_test_customers(1000).to_csv('tests/data/customers_small.csv', index=False)
    generate_test_customers(10000).to_csv('tests/data/customers_medium.csv', index=False)
    generate_test_customers(100000).to_csv('tests/data/customers_large.csv', index=False)
```

### 12.2 Test Data Fixtures

**File:** `tests/conftest.py`

```python
import pytest
import pandas as pd

@pytest.fixture(scope='session')
def sample_customer_data():
    """Load sample customer data for tests"""
    return pd.read_csv('tests/data/customers_small.csv')

@pytest.fixture(scope='session')
def trained_model():
    """Load pre-trained model for tests"""
    from fargate.training.train import EngagementModel
    return EngagementModel.load('tests/models/test_model.pkl')

@pytest.fixture
def mock_s3_bucket(monkeypatch):
    """Mock S3 bucket for testing"""
    from moto import mock_s3
    with mock_s3():
        import boto3
        s3 = boto3.client('s3', region_name='us-east-1')
        s3.create_bucket(Bucket='test-engagement-data')
        yield s3
```

---

## 13. CI/CD Test Execution

### 13.1 GitHub Actions Workflow

**File:** `.github/workflows/test.yml`

```yaml
name: Test Suite

on: [push, pull_request]

jobs:
  unit-tests:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - uses: actions/setup-python@v5
        with:
          python-version: '3.11'
      - name: Install dependencies
        run: |
          pip install -r requirements-dev.txt
      - name: Run unit tests
        run: |
          pytest tests/unit/ --cov --cov-report=xml
      - name: Upload coverage
        uses: codecov/codecov-action@v3

  integration-tests:
    runs-on: ubuntu-latest
    services:
      localstack:
        image: localstack/localstack:latest
        ports:
          - 4566:4566
    steps:
      - uses: actions/checkout@v4
      - name: Run integration tests
        run: |
          pytest tests/integration/ -v

  security-tests:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - name: Run security scans
        run: |
          bash tests/security/test_terraform.sh
          bash tests/security/test_docker.sh
```

---

## 14. Test Metrics & Reporting

### 14.1 Coverage Badges

```markdown
[![codecov](https://codecov.io/gh/yourorg/engagement-prediction/branch/main/graph/badge.svg)](https://codecov.io/gh/yourorg/engagement-prediction)
```

### 14.2 Test Report

**Generated after each run:**
- HTML coverage report: `htmlcov/index.html`
- JUnit XML: `test-results.xml`
- Performance report: `locust_report.html`

---

## 15. References

- **pytest:** https://pytest.org
- **moto:** https://github.com/spulec/moto
- **great_expectations:** https://greatexpectations.io
- **locust:** https://locust.io
- **AIF360:** https://aif360.mybluemix.net

---

**Document Owner:** Engineering Lead  
**Review Frequency:** Quarterly  
**Next Review:** 2026-01-21  
**Classification:** Internal

