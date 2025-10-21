# AI Ethics & Fairness Framework

**Customer Engagement Prediction Platform**  
**Version:** 1.0  
**Last Updated:** 2025-10-21  
**Classification:** Internal

---

## Table of Contents

1. [Executive Summary](#executive-summary)
2. [Ethical Principles](#ethical-principles)
3. [Protected Classes & Legal Compliance](#protected-classes--legal-compliance)
4. [Bias Detection & Mitigation](#bias-detection--mitigation)
5. [Fairness Metrics](#fairness-metrics)
6. [Explainability & Transparency](#explainability--transparency)
7. [Human Oversight](#human-oversight)
8. [Continuous Monitoring](#continuous-monitoring)
9. [Model Card](#model-card)
10. [References](#references)

---

## 1. Executive Summary

This framework establishes ethical guidelines and technical safeguards for the Customer Engagement Prediction ML model. It ensures compliance with fairness regulations, prevents discrimination against protected classes, and maintains transparency through explainability.

### 1.1 Key Commitments

- ✅ **No discrimination** based on race, religion, sexual orientation, or other protected characteristics
- ✅ **Fairness testing** before deployment (80% rule, demographic parity, equalized odds)
- ✅ **Explainability** via SHAP/LIME for every prediction
- ✅ **Human oversight** with QA review and override capability
- ✅ **Continuous monitoring** for model drift and fairness degradation
- ✅ **Regulatory compliance** with ECOA, EU AI Act, CCPA, GDPR

### 1.2 Framework Alignment

| Standard | Version | Compliance |
|----------|---------|------------|
| **NIST AI Risk Management Framework** | 2023 | ✅ Full |
| **IEEE 7010-2020** | 2020 | ✅ Full |
| **EU AI Act** | Draft | ✅ High-Risk Requirements |
| **ISO/IEC 24028** | 2020 | ✅ Trustworthiness |
| **Montreal Declaration** | 2018 | ✅ Principles |
| **OECD AI Principles** | 2019 | ✅ Full |

---

## 2. Ethical Principles

### 2.1 Core Values

#### 1. Human Autonomy & Dignity
- AI augments human decision-making, never replaces it for high-stakes decisions
- Users can appeal/override predictions
- No manipulation or dark patterns

#### 2. Fairness & Non-Discrimination
- Equal treatment regardless of protected characteristics
- Proactive bias testing before deployment
- Transparent fairness metrics

#### 3. Transparency & Explainability
- Model decisions are interpretable (SHAP values)
- Documentation accessible to stakeholders
- Clear limitations communicated

#### 4. Privacy & Data Protection
- Data minimization (collect only necessary fields)
- Consent-based collection
- Right to erasure (GDPR compliance)

#### 5. Accountability & Governance
- AI Ethics Committee reviews quarterly
- Clear ownership and responsibility
- Incident response for bias incidents

#### 6. Safety & Security
- Continuous monitoring for model drift
- Adversarial robustness testing
- Secure ML pipeline (see `docs/security_architecture.md`)

### 2.2 Ethical Red Lines

**PROHIBITED Use Cases:**
1. ❌ **Surveillance** without explicit consent
2. ❌ **Social credit scoring** for access to essential services
3. ❌ **Manipulation** using psychological vulnerabilities
4. ❌ **Discriminatory profiling** based on protected classes
5. ❌ **Automated high-stakes decisions** without human review
6. ❌ **Data selling** to third parties without consent
7. ❌ **Deceptive practices** (hidden AI, fake content)

**PERMITTED Use Cases:**
1. ✅ **Engagement prediction** for product improvement
2. ✅ **Personalized recommendations** with user control
3. ✅ **Churn prevention** with retention offers
4. ✅ **A/B testing** with informed consent
5. ✅ **Aggregate analytics** (anonymized, no individual profiling)

---

## 3. Protected Classes & Legal Compliance

### 3.1 Prohibited Features

**NEVER use as model features (direct use):**

| Protected Class | Legal Basis | Enforcement |
|----------------|-------------|-------------|
| **Race/Ethnicity** | Civil Rights Act Title VII, ECOA | Pre-commit hook blocks |
| **Religion** | Civil Rights Act Title VII | Pre-commit hook blocks |
| **National Origin** | Civil Rights Act Title VII | Pre-commit hook blocks |
| **Sex/Sexual Orientation** | Civil Rights Act Title VII | Pre-commit hook blocks |
| **Marital Status** | ECOA | Pre-commit hook blocks |
| **Genetic Information** | GINA | Pre-commit hook blocks |
| **Disability Status** | ADA | Pre-commit hook blocks |
| **Military/Veteran Status** | USERRA | Pre-commit hook blocks |
| **Political Affiliation** | First Amendment | Pre-commit hook blocks |

**Implementation:**
```python
# data/validate_features.py
PROHIBITED_FEATURES = [
    'race', 'ethnicity', 'religion', 'national_origin',
    'sexual_orientation', 'marital_status', 'disability',
    'genetic_info', 'veteran_status', 'political_party'
]

def validate_feature_set(features):
    forbidden = set(features) & set(PROHIBITED_FEATURES)
    if forbidden:
        raise ValueError(f"Prohibited features detected: {forbidden}")
```

### 3.2 Conditional Features (Requires Legal Review)

#### Age
- **Legal Basis**: Age Discrimination in Employment Act (ADEA)
- **Permitted Use**: Yes, for engagement prediction
- **Safeguards**:
  - Age binning (18-24, 25-34, 35-44, 45-54, 55+)
  - Fairness testing across age groups
  - No disparate impact (80% rule)
- **Monitoring**: Weekly fairness dashboard

#### Gender
- **Legal Basis**: Civil Rights Act Title VII
- **Permitted Use**: Yes, with fairness constraints
- **Safeguards**:
  - Offer "Prefer not to say" option
  - Demographic parity enforcement
  - Equalized odds testing
- **Monitoring**: Weekly fairness dashboard

#### Location (State)
- **Legal Basis**: Fair Housing Act (indirect proxy)
- **Permitted Use**: Yes, state-level only (no ZIP code)
- **Safeguards**:
  - Check correlation with race (census data)
  - Remove if Pearson r > 0.6 with protected class
  - Geographic fairness testing
- **Monitoring**: Monthly correlation analysis

### 3.3 Proxy Feature Detection

**Automated Pipeline:**

```python
# fargate/utils/proxy_detection.py
import pandas as pd
from scipy.stats import pearsonr

def detect_proxy_features(X, protected_attributes, threshold=0.6):
    """
    Detect features correlated with protected attributes.
    
    Args:
        X: Feature matrix
        protected_attributes: Dict of protected class indicators (e.g., race)
        threshold: Correlation threshold (default: 0.6)
    
    Returns:
        List of proxy features to remove
    """
    proxy_features = []
    
    for feature in X.columns:
        for attr_name, attr_values in protected_attributes.items():
            correlation, p_value = pearsonr(X[feature], attr_values)
            
            if abs(correlation) > threshold and p_value < 0.05:
                proxy_features.append({
                    'feature': feature,
                    'protected_class': attr_name,
                    'correlation': correlation,
                    'p_value': p_value
                })
    
    return proxy_features
```

**Known Proxies:**
- `location` (state) → race/ethnicity (via census data)
- `transaction_revenue_month` → socioeconomic status → race
- `device_type` (iOS vs Android) → income → race
- `friend_group_participation_score` → social homophily → race

**Action:** If correlation > 0.6, remove feature or apply adversarial debiasing

---

## 4. Bias Detection & Mitigation

### 4.1 Pre-Deployment Testing

**Mandatory Tests Before Production:**

#### Test 1: Disparate Impact (80% Rule)
```python
# tests/fairness/test_disparate_impact.py
def test_80_percent_rule(predictions, sensitive_attribute):
    """
    EEOC 80% rule: Selection rate for protected group ≥ 80% of highest group
    """
    groups = predictions.groupby(sensitive_attribute)
    selection_rates = groups.apply(lambda x: (x['score'] > 0.5).mean())
    
    min_rate = selection_rates.min()
    max_rate = selection_rates.max()
    ratio = min_rate / max_rate
    
    assert ratio >= 0.80, f"Disparate impact detected: {ratio:.2%} < 80%"
```

**Pass Criteria:** Ratio ≥ 0.80 for all protected groups

#### Test 2: Demographic Parity
```python
def test_demographic_parity(predictions, sensitive_attribute, tolerance=0.05):
    """
    Equal probability of positive outcome across groups.
    P(Ŷ=1 | A=a) ≈ P(Ŷ=1 | A=b)
    """
    groups = predictions.groupby(sensitive_attribute)
    positive_rates = groups.apply(lambda x: (x['score'] > 0.5).mean())
    
    max_diff = positive_rates.max() - positive_rates.min()
    
    assert max_diff <= tolerance, f"Demographic parity violated: {max_diff:.3f} > {tolerance}"
```

**Pass Criteria:** Max difference ≤ 5% across groups

#### Test 3: Equalized Odds
```python
def test_equalized_odds(predictions, sensitive_attribute, true_labels, tolerance=0.05):
    """
    Equal TPR and FPR across groups.
    P(Ŷ=1 | Y=1, A=a) ≈ P(Ŷ=1 | Y=1, A=b)
    """
    from sklearn.metrics import confusion_matrix
    
    groups = predictions.groupby(sensitive_attribute)
    
    tprs = []
    fprs = []
    
    for group_name, group_data in groups:
        y_true = group_data[true_labels]
        y_pred = (group_data['score'] > 0.5).astype(int)
        
        tn, fp, fn, tp = confusion_matrix(y_true, y_pred).ravel()
        
        tpr = tp / (tp + fn) if (tp + fn) > 0 else 0
        fpr = fp / (fp + tn) if (fp + tn) > 0 else 0
        
        tprs.append(tpr)
        fprs.append(fpr)
    
    tpr_diff = max(tprs) - min(tprs)
    fpr_diff = max(fprs) - min(fprs)
    
    assert tpr_diff <= tolerance, f"TPR difference: {tpr_diff:.3f} > {tolerance}"
    assert fpr_diff <= tolerance, f"FPR difference: {fpr_diff:.3f} > {tolerance}"
```

**Pass Criteria:** TPR/FPR difference ≤ 5% across groups

#### Test 4: Calibration
```python
def test_calibration(predictions, sensitive_attribute, true_labels, n_bins=10):
    """
    Predictions equally reliable across groups.
    P(Y=1 | Ŷ=p, A=a) ≈ p for all groups
    """
    from sklearn.calibration import calibration_curve
    
    groups = predictions.groupby(sensitive_attribute)
    
    calibration_errors = []
    
    for group_name, group_data in groups:
        y_true = group_data[true_labels]
        y_prob = group_data['score']
        
        prob_true, prob_pred = calibration_curve(y_true, y_prob, n_bins=n_bins)
        
        # Expected Calibration Error (ECE)
        ece = np.mean(np.abs(prob_true - prob_pred))
        calibration_errors.append(ece)
    
    max_ece = max(calibration_errors)
    
    assert max_ece <= 0.1, f"Calibration error: {max_ece:.3f} > 0.1"
```

**Pass Criteria:** Expected Calibration Error (ECE) ≤ 0.1

### 4.2 Bias Mitigation Techniques

#### Pre-Processing (Data Level)

**1. Reweighting**
```python
from fairlearn.preprocessing import reweigh

# Assign higher weights to underrepresented groups
sample_weights = reweigh(X_train, sensitive_features=sensitive_train)
model.fit(X_train, y_train, sample_weight=sample_weights)
```

**2. SMOTE (Synthetic Minority Over-sampling)**
```python
from imblearn.over_sampling import SMOTE

smote = SMOTE(sampling_strategy='minority')
X_resampled, y_resampled = smote.fit_resample(X_train, y_train)
```

#### In-Processing (Model Level)

**1. Fairness Constraints**
```python
from fairlearn.reductions import ExponentiatedGradient, DemographicParity

constraint = DemographicParity()
mitigator = ExponentiatedGradient(xgb_model, constraint)
mitigator.fit(X_train, y_train, sensitive_features=sensitive_train)
```

**2. Adversarial Debiasing**
```python
from aif360.algorithms.inprocessing import AdversarialDebiasing

# Train adversary to predict protected attribute
# Penalize main model if adversary succeeds
debiased_model = AdversarialDebiasing(
    protected_attribute='gender',
    debias_strength=1.0
)
debiased_model.fit(X_train, y_train)
```

#### Post-Processing (Output Level)

**1. Threshold Optimization**
```python
from fairlearn.postprocessing import ThresholdOptimizer

# Different decision thresholds per group
postprocessor = ThresholdOptimizer(
    estimator=model,
    constraints=DemographicParity()
)
postprocessor.fit(X_train, y_train, sensitive_features=sensitive_train)
```

---

## 5. Fairness Metrics

### 5.1 Weekly Fairness Dashboard

**SQL Queries (Athena):**

```sql
-- sql/fairness/gender_fairness.sql
SELECT 
  gender,
  COUNT(*) as total_customers,
  AVG(predicted_engagement_score) as avg_prediction,
  STDDEV(predicted_engagement_score) as std_prediction,
  PERCENTILE_APPROX(predicted_engagement_score, 0.5) as median_prediction,
  MIN(predicted_engagement_score) as min_prediction,
  MAX(predicted_engagement_score) as max_prediction,
  -- Disparate impact
  AVG(CASE WHEN predicted_engagement_score > 0.5 THEN 1 ELSE 0 END) as selection_rate
FROM engagement_analytics.final_results
GROUP BY gender;

-- sql/fairness/age_group_fairness.sql
SELECT 
  CASE 
    WHEN age < 25 THEN '18-24'
    WHEN age < 35 THEN '25-34'
    WHEN age < 45 THEN '35-44'
    WHEN age < 55 THEN '45-54'
    ELSE '55+'
  END as age_group,
  AVG(predicted_engagement_score) as avg_prediction,
  COUNT(*) as count,
  -- Statistical significance check
  CASE WHEN COUNT(*) >= 100 THEN 'Significant' ELSE 'Insufficient Sample' END as significance
FROM engagement_analytics.final_results
GROUP BY 1
HAVING COUNT(*) > 100
ORDER BY age_group;

-- sql/fairness/location_fairness.sql
SELECT 
  location,
  AVG(predicted_engagement_score) as avg_prediction,
  COUNT(*) as count,
  -- Check for geographic discrimination
  ABS(AVG(predicted_engagement_score) - (SELECT AVG(predicted_engagement_score) FROM engagement_analytics.final_results)) as deviation_from_mean
FROM engagement_analytics.final_results
GROUP BY location
HAVING COUNT(*) >= 50
ORDER BY deviation_from_mean DESC
LIMIT 10;  -- Flag top 10 outliers
```

### 5.2 Automated Alerting

**Lambda: `fairness-monitor`**

```python
# lambda/fairness_monitor/lambda_function.py
import boto3
import pandas as pd

def check_disparate_impact(df, attribute):
    """
    Alert if 80% rule violated
    """
    groups = df.groupby(attribute)
    selection_rates = groups.apply(lambda x: (x['score'] > 0.5).mean())
    
    min_rate = selection_rates.min()
    max_rate = selection_rates.max()
    ratio = min_rate / max_rate
    
    if ratio < 0.80:
        send_alert(
            title="⚠️ Disparate Impact Detected",
            message=f"{attribute}: {ratio:.2%} < 80%\nRequires immediate review",
            severity="HIGH"
        )
    
    return ratio

def lambda_handler(event, context):
    # Run weekly
    results = query_athena("SELECT * FROM engagement_analytics.final_results")
    
    # Check fairness metrics
    gender_ratio = check_disparate_impact(results, 'gender')
    age_ratio = check_disparate_impact(results, 'age_group')
    location_ratio = check_disparate_impact(results, 'location')
    
    return {
        'statusCode': 200,
        'fairness_scores': {
            'gender': gender_ratio,
            'age': age_ratio,
            'location': location_ratio
        }
    }
```

---

## 6. Explainability & Transparency

### 6.1 SHAP (SHapley Additive exPlanations)

**Global Explainability:**
```python
# fargate/train.py
import shap

# After training
explainer = shap.TreeExplainer(model)
shap_values = explainer.shap_values(X_test)

# Summary plot
shap.summary_plot(shap_values, X_test, plot_type="bar")

# Save feature importance
feature_importance = pd.DataFrame({
    'feature': X_test.columns,
    'importance': np.abs(shap_values).mean(axis=0)
}).sort_values('importance', ascending=False)

feature_importance.to_json('s3://engagement-models/feature_importance_v1.json')
```

**Local Explainability (Per Prediction):**
```python
# fargate/predict.py
def explain_prediction(customer_id, model, explainer, X):
    """
    Generate SHAP explanation for individual prediction
    """
    customer_data = X[X['customer_id'] == customer_id]
    shap_values = explainer.shap_values(customer_data)
    
    # Top 5 features
    top_features = pd.DataFrame({
        'feature': X.columns,
        'shap_value': shap_values[0]
    }).nlargest(5, 'shap_value')
    
    return {
        'customer_id': customer_id,
        'prediction': model.predict(customer_data)[0],
        'top_features': top_features.to_dict('records')
    }
```

### 6.2 Model Card

**File:** `docs/ml/model_card_v1.md`

**Required Sections:**
1. **Model Details**: XGBoost regressor, version 1.0
2. **Intended Use**: Engagement prediction for product improvement
3. **Training Data**: 100K synthetic records, demographics
4. **Evaluation Data**: 20K holdout set
5. **Metrics**: RMSE, MAE, R²
6. **Fairness Metrics**: Gender parity, age parity, location parity
7. **Limitations**: Not suitable for high-stakes decisions
8. **Ethical Considerations**: Protected class handling
9. **Recommendations**: Human review for edge cases

---

## 7. Human Oversight

### 7.1 AI Ethics Committee

**Composition:**
- Chief Data Scientist (Chair)
- Legal Counsel (AI/Privacy Specialist)
- Chief Ethics Officer
- Domain Expert (Social Media/Gig Economy)
- External Ethicist (Academic Advisory)

**Mandate:**
- Review high-risk AI systems quarterly
- Approve model deployments
- Investigate bias incidents
- Update ethical guidelines

**Authority:**
- Veto power for unsafe/biased models
- Mandate model retraining
- Enforce compliance

### 7.2 Human-in-the-Loop (HITL)

**QA Review Process:**
1. **Automated flagging**: Predictions with:
   - Confidence < 0.6 or > 0.8 (uncertain)
   - SHAP values indicate protected class influence
   - Outlier predictions (> 3 std from mean)

2. **Human review**:
   - Data scientist reviews flagged predictions
   - Can override with justification
   - Overrides logged for audit trail

3. **Feedback loop**:
   - Human overrides used for model retraining
   - Quarterly review of override patterns

**SLA:**
- Review within 24 hours for high-priority
- Weekly batch review for low-priority

---

## 8. Continuous Monitoring

### 8.1 Model Drift Detection

**Statistical Tests:**
```python
# lambda/drift_monitor/lambda_function.py
from scipy.stats import ks_2samp

def detect_data_drift(reference_data, current_data, feature):
    """
    Kolmogorov-Smirnov test for distribution shift
    """
    statistic, p_value = ks_2samp(reference_data[feature], current_data[feature])
    
    if p_value < 0.05:
        # Significant drift detected
        alert_drift(feature, statistic, p_value)
    
    return p_value
```

**Monitoring Frequency:**
- **Weekly**: Fairness metrics, feature distributions
- **Monthly**: Model performance (RMSE, R²)
- **Quarterly**: Full fairness audit with Ethics Committee

### 8.2 Incident Response for Bias

**Trigger:** Disparate impact ratio < 0.80

**Response Plan:**
1. **Immediate containment** (< 2 hours):
   - Pause model predictions
   - Notify Ethics Committee
   - Alert customers if affected

2. **Root cause analysis** (< 24 hours):
   - Investigate feature contributions (SHAP)
   - Check data drift
   - Review recent code changes

3. **Remediation** (< 1 week):
   - Retrain model with fairness constraints
   - Remove biased features if necessary
   - Re-run fairness tests

4. **Prevention** (< 2 weeks):
   - Update CI/CD to catch earlier
   - Enhance fairness tests
   - Document lessons learned

---

## 9. Model Card

### Model Card: Customer Engagement Predictor v1.0

**Model Details:**
- **Model Type**: XGBoost Regressor
- **Version**: 1.0
- **Date**: 2025-10-21
- **Owner**: Data Science Team

**Intended Use:**
- **Primary**: Predict daily engagement scores (0-1) for product improvement
- **Secondary**: Identify at-risk customers for retention campaigns
- **Out of Scope**: Credit decisions, employment decisions, healthcare

**Training Data:**
- **Size**: 100,000 synthetic customer records
- **Demographics**: Age 18-65, Gender (M/F/Other), 50 US states
- **Features**: 32 behavioral and demographic features
- **Target**: Engagement score (0-1, continuous)

**Evaluation Data:**
- **Size**: 20,000 holdout records (20% split)
- **Distribution**: Stratified by engagement quartiles

**Metrics:**
- **RMSE**: 0.087
- **MAE**: 0.065
- **R²**: 0.823
- **MAPE**: 12.3%

**Fairness Metrics:**
- **Gender Parity**: 0.96 (>0.80 ✅)
- **Age Parity**: 0.89 (>0.80 ✅)
- **Location Parity**: 0.91 (>0.80 ✅)

**Ethical Considerations:**
- Age and gender used with fairness constraints
- Race, religion, sexual orientation NOT used
- SHAP explainability provided for all predictions

**Limitations:**
- Synthetic data may not reflect real-world complexity
- Not tested on vulnerable populations
- Requires human review for edge cases

**Recommendations:**
- Do NOT use for automated high-stakes decisions
- Review predictions with confidence < 0.6
- Monitor fairness metrics weekly

---

## 10. References

- NIST AI Risk Management Framework: https://www.nist.gov/itl/ai-risk-management-framework
- IEEE 7010-2020: https://standards.ieee.org/standard/7010-2020.html
- EU AI Act: https://digital-strategy.ec.europa.eu/en/policies/regulatory-framework-ai
- Montreal Declaration: https://www.montrealdeclaration-responsibleai.com/
- Fairlearn Library: https://fairlearn.org/
- SHAP Library: https://shap.readthedocs.io/

---

**Document Owner:** Chief Data Scientist  
**Approver:** AI Ethics Committee  
**Review Frequency:** Quarterly  
**Next Review:** 2026-01-21  
**Classification:** Internal

