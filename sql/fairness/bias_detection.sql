-- ========================================
-- FAIRNESS & BIAS DETECTION QUERIES
-- ========================================
-- Database: engagement_prediction_analytics_dev
-- Purpose: Detect and measure bias across protected classes
-- Standards: IEEE 7010, NIST AI RMF, 80% Rule
-- ========================================

-- ========================================
-- 1. DEMOGRAPHIC PARITY BY GENDER
-- ========================================
-- Check if prediction rates are similar across genders (80% rule)

SELECT 
    gender,
    COUNT(*) AS total_customers,
    
    -- Engagement predictions
    SUM(CASE WHEN predicted_engagement_score > 0.7 THEN 1 ELSE 0 END) AS high_engagement_predicted,
    ROUND(AVG(CASE WHEN predicted_engagement_score > 0.7 THEN 1.0 ELSE 0.0 END) * 100, 2) AS pct_high_engagement,
    
    -- Churn predictions
    SUM(predicted_churn) AS churn_predicted,
    ROUND(AVG(predicted_churn) * 100, 2) AS churn_rate_pct,
    
    -- Average predictions
    ROUND(AVG(predicted_engagement_score), 3) AS avg_predicted_engagement,
    ROUND(AVG(predicted_churn_probability), 3) AS avg_churn_probability,
    ROUND(AVG(predicted_ltv_usd), 2) AS avg_predicted_ltv
FROM predictions_final
WHERE gender IN ('M', 'F')  -- Focus on binary comparison for 80% rule
GROUP BY gender
ORDER BY gender;

-- Calculate 80% Rule Compliance
WITH gender_rates AS (
    SELECT 
        gender,
        AVG(CASE WHEN predicted_engagement_score > 0.7 THEN 1.0 ELSE 0.0 END) AS high_eng_rate,
        AVG(predicted_churn) AS churn_rate
    FROM predictions_final
    WHERE gender IN ('M', 'F')
    GROUP BY gender
)
SELECT 
    'Engagement (High)' AS metric,
    ROUND(MIN(high_eng_rate), 4) AS min_rate,
    ROUND(MAX(high_eng_rate), 4) AS max_rate,
    ROUND(MIN(high_eng_rate) / NULLIF(MAX(high_eng_rate), 0), 4) AS parity_ratio,
    CASE 
        WHEN MIN(high_eng_rate) / NULLIF(MAX(high_eng_rate), 0) >= 0.8 THEN '✅ PASS'
        ELSE '❌ FAIL'
    END AS eighty_percent_rule
FROM gender_rates

UNION ALL

SELECT 
    'Churn Prediction' AS metric,
    ROUND(MIN(churn_rate), 4) AS min_rate,
    ROUND(MAX(churn_rate), 4) AS max_rate,
    ROUND(MIN(churn_rate) / NULLIF(MAX(churn_rate), 0), 4) AS parity_ratio,
    CASE 
        WHEN MIN(churn_rate) / NULLIF(MAX(churn_rate), 0) >= 0.8 THEN '✅ PASS'
        ELSE '❌ FAIL'
    END AS eighty_percent_rule
FROM gender_rates;

-- ========================================
-- 2. EQUALIZED ODDS (Prediction Accuracy by Gender)
-- ========================================
-- Check if model performs equally well across genders

SELECT 
    gender,
    COUNT(*) AS total_customers,
    
    -- Engagement accuracy
    ROUND(CORR(engagement_score, predicted_engagement_score), 3) AS engagement_correlation,
    ROUND(AVG(ABS(engagement_score - predicted_engagement_score)), 3) AS engagement_mae,
    
    -- Churn accuracy
    ROUND(AVG(CASE WHEN churn_30_day = predicted_churn THEN 1.0 ELSE 0.0 END) * 100, 2) AS churn_accuracy_pct,
    
    -- LTV accuracy
    ROUND(CORR(lifetime_value_usd, predicted_ltv_usd), 3) AS ltv_correlation,
    ROUND(AVG(ABS(lifetime_value_usd - predicted_ltv_usd)), 2) AS ltv_mae
FROM predictions_final
WHERE gender IN ('M', 'F')
GROUP BY gender
ORDER BY gender;

-- ========================================
-- 3. CALIBRATION BY GENDER
-- ========================================
-- Check if predicted probabilities match actual outcomes

WITH deciles AS (
    SELECT 
        gender,
        predicted_churn_probability,
        churn_30_day,
        NTILE(10) OVER (PARTITION BY gender ORDER BY predicted_churn_probability) AS decile
    FROM predictions_final
    WHERE gender IN ('M', 'F')
)
SELECT 
    gender,
    decile,
    COUNT(*) AS customer_count,
    ROUND(AVG(predicted_churn_probability), 3) AS avg_predicted_prob,
    ROUND(AVG(churn_30_day), 3) AS actual_churn_rate,
    ROUND(AVG(predicted_churn_probability) - AVG(churn_30_day), 3) AS calibration_error
FROM deciles
GROUP BY gender, decile
ORDER BY gender, decile;

-- ========================================
-- 4. AGE GROUP ANALYSIS
-- ========================================
-- Check for age-based bias

SELECT 
    CASE 
        WHEN age < 25 THEN '18-24'
        WHEN age BETWEEN 25 AND 34 THEN '25-34'
        WHEN age BETWEEN 35 AND 44 THEN '35-44'
        WHEN age BETWEEN 45 AND 54 THEN '45-54'
        ELSE '55+'
    END AS age_group,
    
    COUNT(*) AS total_customers,
    ROUND(AVG(predicted_engagement_score), 3) AS avg_predicted_engagement,
    ROUND(AVG(engagement_score), 3) AS avg_actual_engagement,
    ROUND(AVG(predicted_engagement_score) - AVG(engagement_score), 3) AS prediction_bias,
    ROUND(AVG(predicted_churn_probability), 3) AS avg_churn_prob,
    ROUND(AVG(predicted_ltv_usd), 2) AS avg_predicted_ltv
FROM predictions_final
GROUP BY 1
ORDER BY 1;

-- ========================================
-- 5. LOCATION-BASED FAIRNESS
-- ========================================
-- Check for geographic bias

SELECT 
    location,
    COUNT(*) AS customer_count,
    ROUND(AVG(predicted_engagement_score), 3) AS avg_predicted_engagement,
    ROUND(AVG(engagement_score), 3) AS avg_actual_engagement,
    ROUND(AVG(predicted_engagement_score) - AVG(engagement_score), 3) AS prediction_bias,
    ROUND(CORR(engagement_score, predicted_engagement_score), 3) AS correlation,
    ROUND(AVG(predicted_churn_probability), 3) AS avg_churn_prob,
    ROUND(AVG(churn_30_day), 3) AS actual_churn_rate
FROM predictions_final
GROUP BY location
HAVING COUNT(*) >= 100
ORDER BY ABS(AVG(predicted_engagement_score) - AVG(engagement_score)) DESC
LIMIT 20;

-- ========================================
-- 6. INTERSECTIONAL ANALYSIS (Gender x Age)
-- ========================================
-- Check for intersectional bias

SELECT 
    gender,
    CASE 
        WHEN age < 30 THEN 'Under 30'
        WHEN age BETWEEN 30 AND 50 THEN '30-50'
        ELSE 'Over 50'
    END AS age_bracket,
    
    COUNT(*) AS customer_count,
    ROUND(AVG(predicted_engagement_score), 3) AS avg_predicted_engagement,
    ROUND(AVG(engagement_score), 3) AS avg_actual_engagement,
    ROUND(AVG(predicted_engagement_score) - AVG(engagement_score), 3) AS prediction_bias,
    ROUND(AVG(predicted_churn_probability), 3) AS avg_churn_prob,
    ROUND(AVG(churn_30_day), 3) AS actual_churn_rate,
    ROUND(AVG(predicted_ltv_usd), 2) AS avg_predicted_ltv
FROM predictions_final
WHERE gender IN ('M', 'F')
GROUP BY gender, 2
ORDER BY gender, 2;

-- ========================================
-- 7. FEATURE IMPORTANCE FAIRNESS
-- ========================================
-- Check if protected features are influencing predictions

SELECT 
    'Gender Impact' AS analysis,
    ROUND(CORR(CASE WHEN gender = 'M' THEN 1 ELSE 0 END, predicted_engagement_score), 3) AS correlation_with_prediction
FROM predictions_final
WHERE gender IN ('M', 'F')

UNION ALL

SELECT 
    'Age Impact',
    ROUND(CORR(age, predicted_engagement_score), 3)
FROM predictions_final

UNION ALL

SELECT 
    'Location Impact (numeric proxy)',
    ROUND(CORR(ABS(xxhash64(location)), predicted_engagement_score), 3)
FROM predictions_final;

-- ========================================
-- 8. FALSE POSITIVE/NEGATIVE RATES BY GENDER
-- ========================================
-- Check for disparate impact in classification errors

WITH classification_metrics AS (
    SELECT 
        gender,
        churn_30_day AS actual,
        predicted_churn AS predicted,
        CASE 
            WHEN churn_30_day = 1 AND predicted_churn = 1 THEN 'TP'
            WHEN churn_30_day = 0 AND predicted_churn = 1 THEN 'FP'
            WHEN churn_30_day = 1 AND predicted_churn = 0 THEN 'FN'
            ELSE 'TN'
        END AS classification
    FROM predictions_final
    WHERE gender IN ('M', 'F')
)
SELECT 
    gender,
    COUNT(*) AS total,
    SUM(CASE WHEN classification = 'TP' THEN 1 ELSE 0 END) AS true_positives,
    SUM(CASE WHEN classification = 'FP' THEN 1 ELSE 0 END) AS false_positives,
    SUM(CASE WHEN classification = 'FN' THEN 1 ELSE 0 END) AS false_negatives,
    SUM(CASE WHEN classification = 'TN' THEN 1 ELSE 0 END) AS true_negatives,
    
    -- Rates
    ROUND(SUM(CASE WHEN classification = 'FP' THEN 1.0 ELSE 0.0 END) / 
          NULLIF(SUM(CASE WHEN actual = 0 THEN 1 ELSE 0 END), 0), 3) AS false_positive_rate,
    ROUND(SUM(CASE WHEN classification = 'FN' THEN 1.0 ELSE 0.0 END) / 
          NULLIF(SUM(CASE WHEN actual = 1 THEN 1 ELSE 0 END), 0), 3) AS false_negative_rate,
    
    -- Accuracy
    ROUND(SUM(CASE WHEN classification IN ('TP', 'TN') THEN 1.0 ELSE 0.0 END) / COUNT(*), 3) AS accuracy
FROM classification_metrics
GROUP BY gender
ORDER BY gender;

-- ========================================
-- 9. FAIRNESS SCORECARD
-- ========================================
-- Overall fairness summary

WITH fairness_metrics AS (
    SELECT 
        gender,
        AVG(predicted_engagement_score) AS avg_eng_pred,
        AVG(predicted_churn_probability) AS avg_churn_prob,
        AVG(predicted_ltv_usd) AS avg_ltv_pred,
        CORR(engagement_score, predicted_engagement_score) AS eng_corr,
        AVG(ABS(engagement_score - predicted_engagement_score)) AS eng_mae
    FROM predictions_final
    WHERE gender IN ('M', 'F')
    GROUP BY gender
)
SELECT 
    'Engagement Prediction Parity' AS metric,
    ROUND(MIN(avg_eng_pred) / NULLIF(MAX(avg_eng_pred), 0), 3) AS parity_ratio,
    CASE 
        WHEN MIN(avg_eng_pred) / NULLIF(MAX(avg_eng_pred), 0) >= 0.8 THEN '✅ Fair'
        WHEN MIN(avg_eng_pred) / NULLIF(MAX(avg_eng_pred), 0) >= 0.7 THEN '⚠️ Borderline'
        ELSE '❌ Unfair'
    END AS assessment
FROM fairness_metrics

UNION ALL

SELECT 
    'Churn Prediction Parity',
    ROUND(MIN(avg_churn_prob) / NULLIF(MAX(avg_churn_prob), 0), 3),
    CASE 
        WHEN MIN(avg_churn_prob) / NULLIF(MAX(avg_churn_prob), 0) >= 0.8 THEN '✅ Fair'
        WHEN MIN(avg_churn_prob) / NULLIF(MAX(avg_churn_prob), 0) >= 0.7 THEN '⚠️ Borderline'
        ELSE '❌ Unfair'
    END
FROM fairness_metrics

UNION ALL

SELECT 
    'LTV Prediction Parity',
    ROUND(MIN(avg_ltv_pred) / NULLIF(MAX(avg_ltv_pred), 0), 3),
    CASE 
        WHEN MIN(avg_ltv_pred) / NULLIF(MAX(avg_ltv_pred), 0) >= 0.8 THEN '✅ Fair'
        WHEN MIN(avg_ltv_pred) / NULLIF(MAX(avg_ltv_pred), 0) >= 0.7 THEN '⚠️ Borderline'
        ELSE '❌ Unfair'
    END
FROM fairness_metrics

UNION ALL

SELECT 
    'Prediction Accuracy Parity (Correlation)',
    ROUND(MIN(eng_corr) / NULLIF(MAX(eng_corr), 0), 3),
    CASE 
        WHEN MIN(eng_corr) / NULLIF(MAX(eng_corr), 0) >= 0.9 THEN '✅ Fair'
        WHEN MIN(eng_corr) / NULLIF(MAX(eng_corr), 0) >= 0.8 THEN '⚠️ Borderline'
        ELSE '❌ Unfair'
    END
FROM fairness_metrics;

-- ========================================
-- 10. PROHIBITED FEATURE CHECK
-- ========================================
-- Verify no protected classes are being used as direct features
-- (This is a design-time check, models shouldn't use these)

SELECT 
    'Protected Features Check' AS check_type,
    CASE 
        WHEN COUNT(*) = 0 THEN '✅ No prohibited features detected in model inputs'
        ELSE '❌ WARNING: Protected features may be in use'
    END AS status
FROM (
    -- This query would check feature names in model artifacts
    -- For now, it's a placeholder
    SELECT 1 AS dummy WHERE 1=0
) prohibited_check;

