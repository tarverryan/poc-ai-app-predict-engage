# Customer Engagement Dataset - Data Dictionary

**Dataset:** Customer Engagement Extended  
**Records:** 100,000 customers  
**Features:** 42 attributes  
**Target Variables:** 3 (engagement_score, churn_30_day, lifetime_value_usd)  
**Last Updated:** October 21, 2025

---

## Dataset Overview

This dataset contains comprehensive customer engagement data for a multi-sided marketplace platform combining social networking, gig economy, and professional networking features.

**File Formats:**
- CSV: `customer_engagement_dataset_extended.csv` (37.9 MB)
- Parquet: `customer_engagement_dataset_extended.parquet` (18.7 MB)

**Location:** `s3://engagement-prediction-raw-{env}/customers/`

---

## Feature Catalog

### 1. Customer Identifiers

#### `customer_id`
- **Type:** String
- **Description:** Unique customer identifier (UUID format)
- **Example:** `CUST-001234`
- **Usage:** Primary key, join key
- **Cardinality:** 100,000 unique values

---

### 2. Demographic Features

#### `age`
- **Type:** Integer
- **Range:** 18-75
- **Mean:** 38.9
- **Distribution:** Normal distribution, centered around 35-45
- **Usage:** Demographic segmentation, age cohort analysis
- **Protected Class:** Yes (AI fairness monitoring required)

#### `gender`
- **Type:** Categorical (String)
- **Values:** Male, Female, Non-binary
- **Distribution:** 
  - Male: 45%
  - Female: 45%
  - Non-binary: 10%
- **Usage:** Demographic analysis, fairness testing
- **Protected Class:** Yes (not used as direct feature in models)

#### `location`
- **Type:** Categorical (String)
- **Values:** Urban, Suburban, Rural
- **Distribution:**
  - Urban: 60%
  - Suburban: 30%
  - Rural: 10%
- **Usage:** Geographic segmentation, market analysis

---

### 3. Account & Tenure Features

#### `account_type`
- **Type:** Categorical (String)
- **Values:** Free, Premium, Enterprise
- **Distribution:**
  - Free: 70%
  - Premium: 25%
  - Enterprise: 5%
- **Usage:** Revenue segmentation, feature access analysis
- **Business Impact:** Premium users have 3x higher engagement

#### `tenure_months`
- **Type:** Integer
- **Range:** 0-120 months
- **Mean:** 23.4 months
- **Distribution:** Right-skewed (many new users, few long-term)
- **Usage:** Loyalty analysis, churn prediction
- **Key Insight:** Churn risk highest in first 6 months

---

### 4. Engagement Metrics

#### `sessions_last_7_days`
- **Type:** Integer
- **Range:** 0-50
- **Mean:** 8.7 sessions
- **Distribution:** Normal with long tail
- **Usage:** Primary engagement indicator
- **Threshold:** <3 sessions = low engagement, >10 = high engagement

#### `sessions_last_30_days`
- **Type:** Integer
- **Range:** 0-200
- **Mean:** 35.2 sessions
- **Usage:** Monthly engagement trends

#### `session_duration_avg_minutes`
- **Type:** Float
- **Range:** 1-120 minutes
- **Mean:** 18.3 minutes
- **Usage:** Depth of engagement analysis
- **Quality Indicator:** >15 min = highly engaged

#### `last_login_days_ago`
- **Type:** Integer
- **Range:** 0-180 days
- **Mean:** 3.8 days
- **Usage:** Recency indicator, churn risk
- **Alert Threshold:** >30 days = at-risk customer

---

### 5. Social Network Features

#### `followers_count`
- **Type:** Integer
- **Range:** 0-10,000
- **Mean:** 342.5 followers
- **Distribution:** Power law (few influencers, many with few followers)
- **Usage:** Influence scoring, network effects

#### `following_count`
- **Type:** Integer
- **Range:** 0-5,000
- **Mean:** 287.1 following
- **Usage:** Network activity, social engagement

#### `posts_last_30_days`
- **Type:** Integer
- **Range:** 0-100
- **Mean:** 12.4 posts
- **Usage:** Content creation activity
- **Key Insight:** Creators have 2x higher retention

#### `comments_last_30_days`
- **Type:** Integer
- **Range:** 0-500
- **Mean:** 45.6 comments
- **Usage:** Community participation indicator

#### `shares_last_30_days`
- **Type:** Integer
- **Range:** 0-200
- **Mean:** 8.9 shares
- **Usage:** Content amplification, virality potential

#### `likes_received_last_30_days`
- **Type:** Integer
- **Range:** 0-5,000
- **Mean:** 234.7 likes
- **Usage:** Content quality indicator, social validation

---

### 6. Gig Economy Features

#### `active_gigs_count`
- **Type:** Integer
- **Range:** 0-20
- **Mean:** 2.3 gigs
- **Usage:** Freelancer activity level
- **Key Insight:** 3+ active gigs = 90% retention

#### `completed_gigs_count`
- **Type:** Integer
- **Range:** 0-500
- **Mean:** 18.7 gigs
- **Usage:** Experience level, trust indicator

#### `gig_applications_sent`
- **Type:** Integer
- **Range:** 0-100
- **Mean:** 7.2 applications
- **Usage:** Job seeker activity, engagement

#### `gig_applications_received`
- **Type:** Integer
- **Range:** 0-200
- **Mean:** 14.3 applications
- **Usage:** Gig poster activity, demand indicator

#### `avg_gig_rating`
- **Type:** Float
- **Range:** 1.0-5.0
- **Mean:** 4.2
- **Usage:** Quality indicator, trust score
- **Threshold:** <3.5 = quality concern, >4.5 = top performer

---

### 7. Transaction Features

#### `transaction_count_last_30_days`
- **Type:** Integer
- **Range:** 0-50
- **Mean:** 3.8 transactions
- **Usage:** Financial activity, platform monetization

#### `transaction_revenue_30_day`
- **Type:** Float (USD)
- **Range:** $0-$10,000
- **Mean:** $234.60
- **Usage:** Revenue analysis, LTV prediction
- **Key Metric:** Platform takes 10-20% commission

#### `transaction_revenue_last_90_days`
- **Type:** Float (USD)
- **Range:** $0-$30,000
- **Mean:** $687.40
- **Usage:** Quarterly revenue trends

#### `avg_transaction_value`
- **Type:** Float (USD)
- **Range:** $10-$5,000
- **Mean:** $156.30
- **Usage:** Transaction size analysis, pricing strategy

---

### 8. Professional Network Features

#### `total_connections`
- **Type:** Integer
- **Range:** 0-2,000
- **Mean:** 187.5 connections
- **Usage:** Professional network size
- **Key Insight:** 100+ connections = 4x higher engagement

#### `profile_views_received`
- **Type:** Integer
- **Range:** 0-1,000
- **Mean:** 45.2 views
- **Usage:** Profile visibility, attractiveness

#### `profile_completeness_pct`
- **Type:** Float (Percentage)
- **Range:** 0-100%
- **Mean:** 67.8%
- **Usage:** Profile quality, conversion predictor
- **Threshold:** >80% = 50% higher match rate

#### `skills_listed`
- **Type:** Integer
- **Range:** 0-50
- **Mean:** 8.4 skills
- **Usage:** Expertise indicator, matching quality

---

### 9. Content & Engagement Quality

#### `content_virality_score`
- **Type:** Float
- **Range:** 0-1
- **Mean:** 0.34
- **Calculation:** (shares × 10 + likes × 1 + comments × 5) / followers
- **Usage:** Content quality, influencer identification

#### `engagement_score`
- **Type:** Float (Target Variable)
- **Range:** 0-1
- **Mean:** 0.485
- **Definition:** Composite score of daily active usage likelihood
- **Calculation:** Weighted combination of sessions, duration, interactions
- **Usage:** PRIMARY ML TARGET for engagement prediction
- **Business Goal:** Maximize this score

#### `avg_sentiment_score`
- **Type:** Float
- **Range:** -1 to +1
- **Mean:** 0.12 (slightly positive)
- **Source:** NLP analysis of user content/messages
- **Usage:** Sentiment trends, customer satisfaction proxy

---

### 10. Matching & Success Features

#### `match_success_rate`
- **Type:** Float (Percentage)
- **Range:** 0-100%
- **Mean:** 23.7%
- **Definition:** % of gig applications that resulted in hire
- **Usage:** Matching quality, algorithm effectiveness

#### `swipe_like_ratio`
- **Type:** Float
- **Range:** 0-1
- **Mean:** 0.31
- **Definition:** Likes / Total swipes (for connection matching)
- **Usage:** User selectivity, matching preferences

#### `avg_job_completion_rating`
- **Type:** Float
- **Range:** 1.0-5.0
- **Mean:** 4.3
- **Usage:** Work quality, client satisfaction

---

### 11. Temporal & Behavioral Features

#### `peak_activity_hour`
- **Type:** Integer (Hour of Day)
- **Range:** 0-23
- **Distribution:** Peaks at 12-18 (afternoon/evening)
- **Usage:** Notification timing, engagement optimization

#### `weekend_usage_pct`
- **Type:** Float (Percentage)
- **Range:** 0-100%
- **Mean:** 28.6%
- **Usage:** Usage pattern analysis

#### `mobile_usage_pct`
- **Type:** Float (Percentage)
- **Range:** 0-100%
- **Mean:** 73.2%
- **Usage:** Platform preference, mobile-first strategy

---

### 12. Network & Graph Features

#### `network_centrality`
- **Type:** Float
- **Range:** 0-1
- **Mean:** 0.18
- **Definition:** Betweenness centrality in social graph
- **Usage:** Influencer identification, network effects

#### `avg_connection_strength`
- **Type:** Float
- **Range:** 0-1
- **Mean:** 0.42
- **Definition:** Interaction frequency with connections
- **Usage:** Relationship quality, network health

---

### 13. Target Variables

#### `churn_30_day`
- **Type:** Binary (Integer)
- **Values:** 0 (retained), 1 (churned)
- **Distribution:** 37.9% churn rate
- **Definition:** No activity in next 30 days
- **Usage:** CHURN PREDICTION ML TARGET
- **Business Impact:** Each churn costs $50-200 LTV

#### `lifetime_value_usd`
- **Type:** Float (USD)
- **Range:** $0-$5,000
- **Mean:** $455.10
- **Definition:** Total revenue generated by customer over lifetime
- **Usage:** LTV PREDICTION ML TARGET
- **Business Goal:** Maximize LTV through engagement

---

## Feature Engineering

### Derived Features (Created During Preprocessing)

1. **engagement_velocity** = (sessions_last_7_days - sessions_last_30_days/4) / sessions_last_30_days
2. **social_influence_score** = content_virality_score × log(followers_count + 1)
3. **transaction_momentum** = transaction_revenue_30_day / (transaction_revenue_last_90_days/3 + 1)
4. **profile_quality_score** = profile_completeness_pct × skills_listed / 100
5. **activity_recency_score** = 1 / (last_login_days_ago + 1)

---

## Data Quality Metrics

### Completeness
- **Overall:** 99.8% complete
- **Missing Values:** <0.2% per feature
- **Missing Handling:** Mean imputation (numeric), mode imputation (categorical)

### Accuracy
- **Validation:** Great Expectations framework
- **Range Checks:** All features within expected ranges
- **Cross-field Validation:** 100% pass rate

### Consistency
- **Duplicate Records:** 0 duplicates
- **Referential Integrity:** 100% maintained
- **Format Compliance:** 100% adherence

### Timeliness
- **Data Freshness:** Daily updates
- **Latency:** <1 hour from event to data availability

---

## Usage Guidelines

### For ML Model Training
- **Train/Test Split:** 80/20 stratified by churn
- **Validation:** 5-fold cross-validation
- **Feature Scaling:** StandardScaler for numeric, OneHotEncoder for categorical
- **Feature Selection:** Recursive Feature Elimination (top 25 features)

### For Analytics
- **Aggregations:** Support daily, weekly, monthly rollups
- **Segmentation:** By account_type, tenure, engagement_score quartiles
- **Cohort Analysis:** By signup month, location, account type

### For Bedrock Agent
- **Context Window:** Full feature set provided
- **Query Types:** Descriptive statistics, correlations, insights, recommendations
- **Response Format:** Natural language with data-driven evidence

---

## Business Insights from Data

### High Engagement Indicators
- Sessions > 10/week
- Session duration > 15 minutes
- Active gigs > 3
- Total connections > 100
- Content virality score > 0.5

### Churn Risk Indicators
- Last login > 14 days
- Sessions < 2/week
- Transaction revenue declining
- Profile completeness < 50%
- No active gigs

### High LTV Indicators
- Premium/Enterprise account
- Tenure > 12 months
- Transaction revenue > $500/month
- Avg gig rating > 4.5
- Network centrality > 0.3

---

**Last Updated:** October 21, 2025  
**Data Version:** 1.0.0  
**Records:** 100,000  
**Next Update:** Real-time (production) or weekly (batch)

