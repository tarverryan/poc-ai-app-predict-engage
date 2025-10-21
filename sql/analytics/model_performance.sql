-- ========================================
-- MODEL PERFORMANCE EVALUATION QUERIES
-- ========================================
-- Database: engagement_prediction_ml_dev
-- Purpose: Evaluate ML model performance metrics
-- ========================================

-- ========================================
-- 1. ENGAGEMENT MODEL PERFORMANCE
-- ========================================

SELECT 
    'Engagement Model' AS model_name,
    COUNT(*) AS prediction_count,
    
    -- Regression metrics
    ROUND(SQRT(AVG(POWER(engagement_score - predicted_engagement_score, 2))), 4) AS rmse,
    ROUND(AVG(ABS(engagement_score - predicted_engagement_score)), 4) AS mae,
    ROUND(CORR(engagement_score, predicted_engagement_score), 4) AS r_squared_proxy,
    
    -- Distribution stats
    ROUND(AVG(predicted_engagement_score), 3) AS avg_predicted,
    ROUND(AVG(engagement_score), 3) AS avg_actual,
    ROUND(STDDEV(predicted_engagement_score), 3) AS stddev_predicted,
    ROUND(STDDEV(engagement_score), 3) AS stddev_actual,
    ROUND(MIN(predicted_engagement_score), 3) AS min_predicted,
    ROUND(MAX(predicted_engagement_score), 3) AS max_predicted
FROM predictions_final
WHERE predicted_engagement_score IS NOT NULL AND engagement_score IS NOT NULL;

-- ========================================
-- 2. CHURN MODEL PERFORMANCE
-- ========================================

WITH churn_metrics AS (
    SELECT 
        churn_30_day AS actual,
        predicted_churn AS predicted,
        predicted_churn_probability AS probability,
        CASE 
            WHEN churn_30_day = 1 AND predicted_churn = 1 THEN 'TP'
            WHEN churn_30_day = 0 AND predicted_churn = 1 THEN 'FP'
            WHEN churn_30_day = 1 AND predicted_churn = 0 THEN 'FN'
            ELSE 'TN'
        END AS classification
    FROM predictions_final
    WHERE predicted_churn IS NOT NULL
)
SELECT 
    'Churn Model' AS model_name,
    COUNT(*) AS prediction_count,
    
    -- Classification metrics
    ROUND(SUM(CASE WHEN classification IN ('TP', 'TN') THEN 1.0 ELSE 0.0 END) / COUNT(*), 4) AS accuracy,
    ROUND(SUM(CASE WHEN classification = 'TP' THEN 1.0 ELSE 0.0 END) / 
          NULLIF(SUM(CASE WHEN predicted = 1 THEN 1 ELSE 0 END), 0), 4) AS precision,
    ROUND(SUM(CASE WHEN classification = 'TP' THEN 1.0 ELSE 0.0 END) / 
          NULLIF(SUM(CASE WHEN actual = 1 THEN 1 ELSE 0 END), 0), 4) AS recall,
    
    -- F1 Score (harmonic mean of precision and recall)
    ROUND(2.0 * 
          (SUM(CASE WHEN classification = 'TP' THEN 1.0 ELSE 0.0 END) / NULLIF(SUM(CASE WHEN predicted = 1 THEN 1 ELSE 0 END), 0)) *
          (SUM(CASE WHEN classification = 'TP' THEN 1.0 ELSE 0.0 END) / NULLIF(SUM(CASE WHEN actual = 1 THEN 1 ELSE 0 END), 0)) /
          NULLIF(
              (SUM(CASE WHEN classification = 'TP' THEN 1.0 ELSE 0.0 END) / NULLIF(SUM(CASE WHEN predicted = 1 THEN 1 ELSE 0 END), 0)) +
              (SUM(CASE WHEN classification = 'TP' THEN 1.0 ELSE 0.0 END) / NULLIF(SUM(CASE WHEN actual = 1 THEN 1 ELSE 0 END), 0)),
          0), 4) AS f1_score,
    
    -- Confusion matrix
    SUM(CASE WHEN classification = 'TP' THEN 1 ELSE 0 END) AS true_positives,
    SUM(CASE WHEN classification = 'FP' THEN 1 ELSE 0 END) AS false_positives,
    SUM(CASE WHEN classification = 'FN' THEN 1 ELSE 0 END) AS false_negatives,
    SUM(CASE WHEN classification = 'TN' THEN 1 ELSE 0 END) AS true_negatives
FROM churn_metrics;

-- ========================================
-- 3. LTV MODEL PERFORMANCE
-- ========================================

SELECT 
    'LTV Model' AS model_name,
    COUNT(*) AS prediction_count,
    
    -- Regression metrics
    ROUND(SQRT(AVG(POWER(lifetime_value_usd - predicted_ltv_usd, 2))), 2) AS rmse,
    ROUND(AVG(ABS(lifetime_value_usd - predicted_ltv_usd)), 2) AS mae,
    ROUND(CORR(lifetime_value_usd, predicted_ltv_usd), 4) AS r_squared_proxy,
    
    -- Business metrics
    ROUND(AVG(predicted_ltv_usd), 2) AS avg_predicted_ltv,
    ROUND(AVG(lifetime_value_usd), 2) AS avg_actual_ltv,
    ROUND(SUM(predicted_ltv_usd), 2) AS total_predicted_ltv,
    ROUND(SUM(lifetime_value_usd), 2) AS total_actual_ltv,
    ROUND((SUM(predicted_ltv_usd) - SUM(lifetime_value_usd)) / NULLIF(SUM(lifetime_value_usd), 0) * 100, 2) AS pct_error
FROM predictions_final
WHERE predicted_ltv_usd IS NOT NULL AND lifetime_value_usd IS NOT NULL;

-- ========================================
-- 4. ANOMALY DETECTION PERFORMANCE
-- ========================================

SELECT 
    'Anomaly Detection' AS model_name,
    COUNT(*) AS total_customers,
    SUM(is_anomaly) AS anomalies_detected,
    ROUND(AVG(is_anomaly) * 100, 2) AS anomaly_rate_pct,
    ROUND(AVG(anomaly_score), 4) AS avg_anomaly_score,
    ROUND(MIN(anomaly_score), 4) AS min_anomaly_score,
    ROUND(MAX(anomaly_score), 4) AS max_anomaly_score,
    
    -- Profile of anomalies
    ROUND(AVG(CASE WHEN is_anomaly = 1 THEN engagement_score ELSE NULL END), 3) AS anomaly_avg_engagement,
    ROUND(AVG(CASE WHEN is_anomaly = 0 THEN engagement_score ELSE NULL END), 3) AS normal_avg_engagement
FROM predictions_final
WHERE is_anomaly IS NOT NULL;

-- ========================================
-- 5. MODEL PERFORMANCE BY SEGMENT
-- ========================================

SELECT 
    CASE 
        WHEN engagement_score < 0.3 THEN 'Low Engagement'
        WHEN engagement_score BETWEEN 0.3 AND 0.6 THEN 'Medium Engagement'
        ELSE 'High Engagement'
    END AS segment,
    
    COUNT(*) AS customer_count,
    
    -- Engagement predictions
    ROUND(SQRT(AVG(POWER(engagement_score - predicted_engagement_score, 2))), 4) AS engagement_rmse,
    ROUND(CORR(engagement_score, predicted_engagement_score), 4) AS engagement_correlation,
    
    -- Churn predictions
    ROUND(AVG(CASE WHEN churn_30_day = predicted_churn THEN 1.0 ELSE 0.0 END), 4) AS churn_accuracy,
    
    -- LTV predictions  
    ROUND(AVG(ABS(lifetime_value_usd - predicted_ltv_usd)), 2) AS ltv_mae
FROM predictions_final
GROUP BY 1
ORDER BY 1;

-- ========================================
-- 6. PREDICTION CONFIDENCE ANALYSIS
-- ========================================

SELECT 
    CASE 
        WHEN predicted_churn_probability < 0.3 THEN 'Low Risk (< 30%)'
        WHEN predicted_churn_probability BETWEEN 0.3 AND 0.7 THEN 'Medium Risk (30-70%)'
        ELSE 'High Risk (> 70%)'
    END AS risk_category,
    
    COUNT(*) AS customer_count,
    ROUND(AVG(predicted_churn_probability), 3) AS avg_predicted_prob,
    ROUND(AVG(churn_30_day), 3) AS actual_churn_rate,
    ROUND(AVG(predicted_churn_probability) - AVG(churn_30_day), 3) AS calibration_error,
    
    -- Model confidence
    ROUND(STDDEV(predicted_churn_probability), 3) AS prediction_spread
FROM predictions_final
WHERE predicted_churn_probability IS NOT NULL
GROUP BY 1
ORDER BY 
    CASE 
        WHEN risk_category = 'Low Risk (< 30%)' THEN 1
        WHEN risk_category = 'Medium Risk (30-70%)' THEN 2
        ELSE 3
    END;

-- ========================================
-- 7. TIME-BASED MODEL DRIFT (if timestamp available)
-- ========================================

SELECT 
    DATE_TRUNC('day', CAST(prediction_timestamp AS TIMESTAMP)) AS prediction_date,
    COUNT(*) AS predictions,
    ROUND(AVG(predicted_engagement_score), 3) AS avg_engagement_pred,
    ROUND(AVG(predicted_churn_probability), 3) AS avg_churn_prob,
    ROUND(AVG(predicted_ltv_usd), 2) AS avg_ltv_pred,
    model_version
FROM predictions_final
WHERE prediction_timestamp IS NOT NULL
GROUP BY 1, model_version
ORDER BY 1 DESC
LIMIT 30;

-- ========================================
-- 8. MODEL COMPARISON (if multiple versions exist)
-- ========================================

SELECT 
    model_version,
    COUNT(*) AS prediction_count,
    
    -- Engagement
    ROUND(SQRT(AVG(POWER(engagement_score - predicted_engagement_score, 2))), 4) AS engagement_rmse,
    
    -- Churn
    ROUND(AVG(CASE WHEN churn_30_day = predicted_churn THEN 1.0 ELSE 0.0 END), 4) AS churn_accuracy,
    
    -- LTV
    ROUND(SQRT(AVG(POWER(lifetime_value_usd - predicted_ltv_usd, 2))), 2) AS ltv_rmse,
    
    -- Timestamp
    MIN(prediction_timestamp) AS first_prediction,
    MAX(prediction_timestamp) AS last_prediction
FROM predictions_final
WHERE model_version IS NOT NULL
GROUP BY model_version
ORDER BY model_version DESC;

-- ========================================
-- 9. ERROR ANALYSIS (Worst Predictions)
-- ========================================

SELECT 
    customer_id,
    engagement_score AS actual_engagement,
    predicted_engagement_score AS predicted_engagement,
    ABS(engagement_score - predicted_engagement_score) AS error,
    churn_30_day AS actual_churn,
    predicted_churn,
    age,
    gender,
    tenure_months,
    sessions_last_7_days
FROM predictions_final
WHERE predicted_engagement_score IS NOT NULL
ORDER BY ABS(engagement_score - predicted_engagement_score) DESC
LIMIT 100;

-- ========================================
-- 10. OVERALL MODEL SCORECARD
-- ========================================

SELECT 
    'Overall Performance' AS metric_category,
    'Engagement RMSE' AS metric_name,
    CAST(ROUND(SQRT(AVG(POWER(engagement_score - predicted_engagement_score, 2))), 4) AS VARCHAR) AS value
FROM predictions_final
WHERE predicted_engagement_score IS NOT NULL

UNION ALL

SELECT 
    'Overall Performance',
    'Churn Accuracy',
    CAST(ROUND(AVG(CASE WHEN churn_30_day = predicted_churn THEN 1.0 ELSE 0.0 END) * 100, 2) AS VARCHAR) || '%'
FROM predictions_final
WHERE predicted_churn IS NOT NULL

UNION ALL

SELECT 
    'Overall Performance',
    'LTV MAE',
    '$' || CAST(ROUND(AVG(ABS(lifetime_value_usd - predicted_ltv_usd)), 2) AS VARCHAR)
FROM predictions_final
WHERE predicted_ltv_usd IS NOT NULL

UNION ALL

SELECT 
    'Coverage',
    'Total Predictions',
    CAST(COUNT(*) AS VARCHAR)
FROM predictions_final

UNION ALL

SELECT 
    'Coverage',
    'Prediction Rate',
    CAST(ROUND(COUNT(*) * 100.0 / (SELECT COUNT(*) FROM customers), 2) AS VARCHAR) || '%'
FROM predictions_final;

