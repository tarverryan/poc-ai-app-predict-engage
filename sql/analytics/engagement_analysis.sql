-- ========================================
-- CUSTOMER ENGAGEMENT ANALYSIS QUERIES
-- ========================================
-- Database: engagement_prediction_analytics_dev
-- Purpose: Analytics queries for understanding customer engagement
-- ========================================

-- ========================================
-- 1. HIGH ENGAGEMENT CUSTOMERS
-- ========================================
-- Identify top performers for retention campaigns

SELECT 
    customer_id,
    age,
    gender,
    location,
    tenure_months,
    sessions_last_7_days,
    engagement_score,
    followers_count,
    total_connections,
    lifetime_value_usd,
    social_influence_tier
FROM customers
WHERE engagement_score > 0.7
ORDER BY engagement_score DESC
LIMIT 1000;

-- ========================================
-- 2. AT-RISK CUSTOMERS (High Churn Probability)
-- ========================================
-- Customers who need re-engagement campaigns

SELECT 
    customer_id,
    age,
    gender,
    tenure_months,
    engagement_score,
    sessions_last_7_days,
    churn_30_day,
    lifetime_value_usd,
    last_7_day_engagement_trend,
    CASE 
        WHEN engagement_score < 0.2 THEN 'Critical'
        WHEN engagement_score < 0.3 THEN 'High Risk'
        WHEN engagement_score < 0.5 THEN 'Medium Risk'
        ELSE 'Low Risk'
    END AS risk_category
FROM customers
WHERE churn_30_day = 1 
   OR engagement_score < 0.3
   OR (sessions_last_7_days = 0 AND tenure_months > 3)
ORDER BY engagement_score ASC, lifetime_value_usd DESC
LIMIT 1000;

-- ========================================
-- 3. CUSTOMER SEGMENTATION
-- ========================================
-- Segment by tenure and engagement for targeted strategies

SELECT 
    CASE 
        WHEN tenure_months < 3 THEN 'New (0-3 months)'
        WHEN tenure_months BETWEEN 3 AND 12 THEN 'Growing (3-12 months)'
        WHEN tenure_months BETWEEN 13 AND 24 THEN 'Established (13-24 months)'
        ELSE 'Veteran (24+ months)'
    END AS tenure_segment,
    
    CASE 
        WHEN engagement_score < 0.3 THEN 'Low Engagement'
        WHEN engagement_score BETWEEN 0.3 AND 0.6 THEN 'Medium Engagement'
        ELSE 'High Engagement'
    END AS engagement_segment,
    
    COUNT(*) AS customer_count,
    ROUND(AVG(lifetime_value_usd), 2) AS avg_ltv,
    ROUND(AVG(sessions_last_7_days), 1) AS avg_weekly_sessions,
    ROUND(AVG(engagement_score), 3) AS avg_engagement,
    ROUND(AVG(churn_30_day) * 100, 1) AS churn_rate_pct
FROM customers
GROUP BY 1, 2
ORDER BY 1, 2;

-- ========================================
-- 4. FEATURE CORRELATIONS WITH ENGAGEMENT
-- ========================================
-- Understand which features drive engagement

SELECT 
    'sessions_last_7_days' AS feature,
    ROUND(CORR(sessions_last_7_days, engagement_score), 3) AS correlation
FROM customers
WHERE sessions_last_7_days IS NOT NULL AND engagement_score IS NOT NULL

UNION ALL

SELECT 
    'tenure_months',
    ROUND(CORR(tenure_months, engagement_score), 3)
FROM customers
WHERE tenure_months IS NOT NULL AND engagement_score IS NOT NULL

UNION ALL

SELECT 
    'followers_count',
    ROUND(CORR(followers_count, engagement_score), 3)
FROM customers
WHERE followers_count IS NOT NULL AND engagement_score IS NOT NULL

UNION ALL

SELECT 
    'total_connections',
    ROUND(CORR(total_connections, engagement_score), 3)
FROM customers

UNION ALL

SELECT 
    'content_virality_score',
    ROUND(CORR(content_virality_score, engagement_score), 3)
FROM customers

UNION ALL

SELECT 
    'posts_last_30_days',
    ROUND(CORR(posts_last_30_days, engagement_score), 3)
FROM customers

ORDER BY correlation DESC;

-- ========================================
-- 5. LTV ANALYSIS BY SEGMENT
-- ========================================
-- Identify high-value customer segments

SELECT 
    social_influence_tier,
    COUNT(*) AS customer_count,
    ROUND(AVG(lifetime_value_usd), 2) AS avg_ltv,
    ROUND(MIN(lifetime_value_usd), 2) AS min_ltv,
    ROUND(MAX(lifetime_value_usd), 2) AS max_ltv,
    ROUND(STDDEV(lifetime_value_usd), 2) AS stddev_ltv,
    ROUND(AVG(engagement_score), 3) AS avg_engagement,
    ROUND(AVG(churn_30_day) * 100, 1) AS churn_rate_pct
FROM customers
GROUP BY social_influence_tier
ORDER BY avg_ltv DESC;

-- ========================================
-- 6. ENGAGEMENT TRENDS BY LOCATION
-- ========================================
-- Geographic analysis of engagement

SELECT 
    location,
    COUNT(*) AS customer_count,
    ROUND(AVG(engagement_score), 3) AS avg_engagement,
    ROUND(AVG(sessions_last_7_days), 1) AS avg_weekly_sessions,
    ROUND(AVG(lifetime_value_usd), 2) AS avg_ltv,
    ROUND(AVG(churn_30_day) * 100, 1) AS churn_rate_pct
FROM customers
GROUP BY location
HAVING COUNT(*) >= 100  -- Only locations with sufficient sample size
ORDER BY avg_engagement DESC
LIMIT 20;

-- ========================================
-- 7. CONTENT CREATION VS ENGAGEMENT
-- ========================================
-- Analyze impact of content creation on engagement

SELECT 
    CASE 
        WHEN posts_last_30_days = 0 AND stories_last_30_days = 0 THEN 'No Content'
        WHEN posts_last_30_days + stories_last_30_days BETWEEN 1 AND 5 THEN 'Low Activity (1-5)'
        WHEN posts_last_30_days + stories_last_30_days BETWEEN 6 AND 15 THEN 'Medium Activity (6-15)'
        WHEN posts_last_30_days + stories_last_30_days BETWEEN 16 AND 30 THEN 'High Activity (16-30)'
        ELSE 'Very High Activity (30+)'
    END AS content_activity_level,
    
    COUNT(*) AS customer_count,
    ROUND(AVG(engagement_score), 3) AS avg_engagement,
    ROUND(AVG(followers_count), 0) AS avg_followers,
    ROUND(AVG(content_virality_score), 3) AS avg_virality,
    ROUND(AVG(churn_30_day) * 100, 1) AS churn_rate_pct
FROM customers
GROUP BY 1
ORDER BY 
    CASE 
        WHEN content_activity_level = 'No Content' THEN 1
        WHEN content_activity_level = 'Low Activity (1-5)' THEN 2
        WHEN content_activity_level = 'Medium Activity (6-15)' THEN 3
        WHEN content_activity_level = 'High Activity (16-30)' THEN 4
        ELSE 5
    END;

-- ========================================
-- 8. SESSION CONSISTENCY ANALYSIS
-- ========================================
-- Impact of consistent usage on engagement

SELECT 
    CASE 
        WHEN session_consistency_score < 0.3 THEN 'Sporadic Users'
        WHEN session_consistency_score BETWEEN 0.3 AND 0.6 THEN 'Moderate Users'
        ELSE 'Consistent Users'
    END AS consistency_level,
    
    COUNT(*) AS customer_count,
    ROUND(AVG(engagement_score), 3) AS avg_engagement,
    ROUND(AVG(sessions_last_7_days), 1) AS avg_weekly_sessions,
    ROUND(AVG(session_duration_avg_minutes), 1) AS avg_session_duration,
    ROUND(AVG(churn_30_day) * 100, 1) AS churn_rate_pct
FROM customers
GROUP BY 1
ORDER BY avg_engagement DESC;

-- ========================================
-- 9. GIG ECONOMY METRICS
-- ========================================
-- Analyze gig worker engagement and success

SELECT 
    CASE 
        WHEN active_gigs_count = 0 THEN 'No Active Gigs'
        WHEN active_gigs_count = 1 THEN '1 Active Gig'
        WHEN active_gigs_count BETWEEN 2 AND 3 THEN '2-3 Active Gigs'
        ELSE '4+ Active Gigs'
    END AS gig_activity_level,
    
    COUNT(*) AS customer_count,
    ROUND(AVG(transaction_revenue_last_90_days), 2) AS avg_revenue_90d,
    ROUND(AVG(avg_job_completion_rating), 2) AS avg_rating,
    ROUND(AVG(engagement_score), 3) AS avg_engagement,
    ROUND(AVG(churn_30_day) * 100, 1) AS churn_rate_pct
FROM customers
GROUP BY 1
ORDER BY 
    CASE 
        WHEN gig_activity_level = 'No Active Gigs' THEN 1
        WHEN gig_activity_level = '1 Active Gig' THEN 2
        WHEN gig_activity_level = '2-3 Active Gigs' THEN 3
        ELSE 4
    END;

-- ========================================
-- 10. TOP 100 CUSTOMERS BY LTV
-- ========================================
-- Identify VIP customers for special treatment

SELECT 
    customer_id,
    age,
    gender,
    location,
    tenure_months,
    engagement_score,
    sessions_last_7_days,
    lifetime_value_usd,
    social_influence_tier,
    followers_count,
    active_gigs_count,
    transaction_revenue_last_90_days,
    churn_30_day,
    CASE 
        WHEN churn_30_day = 1 THEN '⚠️ At Risk'
        WHEN engagement_score < 0.5 THEN '⚠️ Low Engagement'
        ELSE '✅ Healthy'
    END AS status
FROM customers
ORDER BY lifetime_value_usd DESC
LIMIT 100;

