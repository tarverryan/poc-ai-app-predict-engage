#!/usr/bin/env python3
"""
Generate 100,000 dummy customer records for Customer Engagement Prediction Platform

Features:
- 49 features per customer (demographics, engagement, behavior, network, predictions)
- Realistic distributions (beta, power law, poisson, normal)
- Correlated features (sessions → engagement, tenure → LTV)
- Synthetic PII (faker library)
- Output: CSV + Parquet

Usage:
    python data/generate_dummy_data.py

Output:
    customer_engagement_dataset_extended.csv (~50 MB)
    customer_engagement_dataset_extended.parquet (~10 MB)
"""

import numpy as np
import pandas as pd
from faker import Faker
from datetime import datetime, timedelta
import hashlib
import warnings

warnings.filterwarnings('ignore')

# Configuration
NUM_CUSTOMERS = 100_000
RANDOM_SEED = 42
OUTPUT_CSV = "customer_engagement_dataset_extended.csv"
OUTPUT_PARQUET = "customer_engagement_dataset_extended.parquet"

# Initialize
np.random.seed(RANDOM_SEED)
fake = Faker()
Faker.seed(RANDOM_SEED)

print(f"🚀 Generating {NUM_CUSTOMERS:,} customer records...")
print(f"   Random seed: {RANDOM_SEED}")
print()


def generate_customer_ids(n):
    """Generate unique customer IDs (UUID format)"""
    return [fake.uuid4() for _ in range(n)]


def generate_demographics(n):
    """Generate demographic features"""
    print("📊 Generating demographics...")
    
    # Age: Normal distribution (mean=35, std=12), clipped to 18-80
    age = np.clip(np.random.normal(35, 12, n), 18, 80).astype(int)
    
    # Gender: M/F/O/N (not specified)
    gender = np.random.choice(['M', 'F', 'O', 'N'], n, p=[0.48, 0.48, 0.02, 0.02])
    
    # Location: Country-State/City codes
    locations = [
        'US-CA', 'US-NY', 'US-TX', 'US-FL', 'US-WA',
        'UK-LON', 'UK-MAN', 'CA-ON', 'CA-BC', 'AU-NSW',
        'DE-BER', 'FR-IDF', 'JP-TKY', 'BR-SP', 'IN-MH'
    ]
    location = np.random.choice(locations, n)
    
    return age, gender, location


def generate_tenure_and_engagement(n):
    """Generate tenure and engagement metrics with correlation"""
    print("📈 Generating tenure & engagement...")
    
    # Tenure: Exponential distribution (most users are new, some are veterans)
    tenure_months = np.clip(np.random.exponential(12, n), 1, 120).astype(int)
    
    # Sessions: Poisson distribution (mean=5)
    sessions_last_7_days = np.random.poisson(5, n)
    
    # Session duration: Log-normal (most short, some very long)
    session_duration_avg_minutes = np.clip(
        np.random.lognormal(3, 1, n), 1, 180
    ).astype(int)
    
    # Engagement score: Beta distribution (skewed toward low engagement)
    # Add correlation with sessions (higher sessions → higher engagement)
    base_engagement = np.random.beta(2, 5, n)
    session_boost = (sessions_last_7_days / sessions_last_7_days.max()) * 0.3
    engagement_score = np.clip(base_engagement + session_boost, 0, 1)
    
    return tenure_months, sessions_last_7_days, session_duration_avg_minutes, engagement_score


def generate_dating_features(n):
    """Generate dating/matching features (Tinder-like)"""
    print("💘 Generating dating features...")
    
    # Swipes: Poisson distribution
    swipes_right_last_30_days = np.random.poisson(50, n)
    
    # Matches: Lower than swipes (conversion ~20%)
    matches_last_30_days = (swipes_right_last_30_days * np.random.uniform(0.1, 0.3, n)).astype(int)
    
    # Match success rate: Matches / Swipes
    match_success_rate = np.where(
        swipes_right_last_30_days > 0,
        (matches_last_30_days / swipes_right_last_30_days) * 100,
        0
    )
    
    # Connections: Power law (most have few, some have many)
    connections_sent = np.random.pareto(2, n).astype(int) * 5
    connections_received = np.random.pareto(2, n).astype(int) * 5
    total_connections = connections_sent + connections_received
    
    return (swipes_right_last_30_days, matches_last_30_days, match_success_rate,
            connections_sent, connections_received, total_connections)


def generate_social_features(n, engagement_score):
    """Generate social media features (Instagram-like)"""
    print("📸 Generating social features...")
    
    # Posts: Correlated with engagement
    posts_last_30_days = (engagement_score * 20 + np.random.poisson(5, n)).astype(int)
    
    # Stories: More frequent than posts
    stories_last_30_days = (engagement_score * 30 + np.random.poisson(10, n)).astype(int)
    
    # Followers: Power law distribution (influencer effect)
    followers_count = np.clip(np.random.pareto(1.5, n).astype(int) * 100, 0, 1_000_000)
    
    # Following: Less than followers for influencers
    following_count = np.clip(
        followers_count * np.random.uniform(0.1, 2, n), 0, 10_000
    ).astype(int)
    
    # Profile views: Correlated with followers
    profile_views_received = (followers_count * np.random.uniform(0.05, 0.2, n)).astype(int)
    
    # Content virality: Beta distribution
    content_virality_score = np.random.beta(2, 8, n)
    
    return (posts_last_30_days, stories_last_30_days, followers_count,
            following_count, profile_views_received, content_virality_score)


def generate_gig_features(n):
    """Generate freelance/gig features (Fiverr-like)"""
    print("💼 Generating gig features...")
    
    # Gig applications: Poisson
    gig_applications_sent = np.random.poisson(3, n)
    gig_applications_received = np.random.poisson(2, n)
    
    # Active gigs: Most have 0-3
    active_gigs_count = np.random.poisson(1, n)
    
    # Transaction revenue: Log-normal (most low, some high earners)
    transaction_revenue_last_90_days = np.clip(
        np.random.lognormal(5, 2, n), 0, 50_000
    )
    
    # Job completion rating: Beta distribution (skewed toward high ratings)
    avg_job_completion_rating = np.random.beta(8, 2, n) * 4 + 1  # Scale to 1-5
    
    return (gig_applications_sent, gig_applications_received, active_gigs_count,
            transaction_revenue_last_90_days, avg_job_completion_rating)


def generate_influence_risk(n):
    """Generate influence and risk scores"""
    print("⚖️ Generating influence & risk scores...")
    
    # Influence: Beta distribution
    influence_score = np.random.beta(2, 5, n)
    
    # Risk: Beta distribution (most low risk)
    risk_score = np.random.beta(2, 8, n)
    
    return influence_score, risk_score


def generate_advanced_features(n, engagement_score, tenure_months, followers_count):
    """Generate advanced behavioral features"""
    print("🧠 Generating advanced features...")
    
    # Sentiment: Normal distribution around 0
    avg_sentiment_score = np.clip(np.random.normal(0, 0.3, n), -1, 1)
    
    # Network centrality: Correlated with followers (Eigenvector centrality proxy)
    network_centrality = np.clip(
        (followers_count / followers_count.max()) * 0.7 + np.random.beta(2, 5, n) * 0.3,
        0, 1
    )
    
    # Content diversity: Shannon entropy proxy (uniform = high diversity)
    content_diversity_score = np.random.beta(3, 3, n)
    
    # Session consistency: Beta distribution
    session_consistency_score = np.random.beta(5, 2, n)
    
    # Engagement trend: Slope of recent engagement (-1 to 1)
    last_7_day_engagement_trend = np.random.normal(0, 0.3, n)
    
    # Trust score: Correlated with tenure
    trust_score = np.clip(
        (tenure_months / 120) * 0.5 + np.random.beta(3, 2, n) * 0.5,
        0, 1
    )
    
    # Response time: Log-normal (most fast, some slow)
    response_time_avg_hours = np.clip(np.random.lognormal(1, 1.5, n), 0.1, 72)
    
    # Peak activity hour: Categorical (0-23)
    probabilities = [0.01]*6 + [0.03]*3 + [0.05]*3 + [0.08]*6 + [0.05]*3 + [0.03]*3  # Peak 12-18
    probabilities = np.array(probabilities) / sum(probabilities)  # Normalize to sum to 1
    peak_activity_hour = np.random.choice(range(24), n, p=probabilities)
    
    # Referral count: Poisson
    referral_count = np.random.poisson(2, n)
    
    # Time since first transaction: Related to tenure
    time_since_first_transaction_days = np.clip(
        tenure_months * 30 * np.random.uniform(0.3, 1, n),
        0, tenure_months * 30
    ).astype(int)
    
    # Premium features used: Poisson
    premium_features_used_count = np.random.poisson(3, n)
    
    # Social influence tier: Categorical (based on followers)
    social_influence_tier = pd.cut(
        followers_count,
        bins=[-1, 100, 1000, 10000, 100000, 1_000_000],
        labels=['Nano', 'Micro', 'Mid', 'Macro', 'Mega']
    ).astype(str)
    
    return (avg_sentiment_score, network_centrality, content_diversity_score,
            session_consistency_score, last_7_day_engagement_trend, trust_score,
            response_time_avg_hours, peak_activity_hour, referral_count,
            time_since_first_transaction_days, premium_features_used_count,
            social_influence_tier)


def generate_prediction_targets(n, engagement_score, tenure_months, sessions_last_7_days):
    """Generate prediction targets (for multi-model ML)"""
    print("🎯 Generating prediction targets...")
    
    # Churn (30-day): Inverse relationship with engagement
    churn_probability = 1 - engagement_score + np.random.normal(0, 0.1, n)
    churn_30_day = (churn_probability > 0.7).astype(int)
    
    # Lifetime Value: Correlated with tenure and engagement
    base_ltv = tenure_months * 20  # $20/month base
    engagement_multiplier = 1 + engagement_score * 2
    lifetime_value_usd = base_ltv * engagement_multiplier * np.random.lognormal(0, 0.5, n)
    
    # Primary content category: Categorical
    content_categories = ['tech', 'food', 'travel', 'fitness', 'fashion', 
                         'gaming', 'music', 'art', 'business', 'education',
                         'lifestyle', 'other']
    content_category_primary = np.random.choice(content_categories, n)
    
    return churn_30_day, lifetime_value_usd, content_category_primary


def validate_data(df):
    """Validate generated data quality"""
    print("\n✅ Validating data quality...")
    
    issues = []
    
    # Check for nulls
    null_counts = df.isnull().sum()
    if null_counts.any():
        issues.append(f"Null values found: {null_counts[null_counts > 0].to_dict()}")
    
    # Check ranges
    if not ((df['age'] >= 18) & (df['age'] <= 80)).all():
        issues.append("Age out of range (18-80)")
    
    if not ((df['engagement_score'] >= 0) & (df['engagement_score'] <= 1)).all():
        issues.append("Engagement score out of range (0-1)")
    
    if not ((df['avg_sentiment_score'] >= -1) & (df['avg_sentiment_score'] <= 1)).all():
        issues.append("Sentiment score out of range (-1 to 1)")
    
    # Check uniqueness
    if df['customer_id'].duplicated().any():
        issues.append("Duplicate customer IDs found")
    
    # Check correlations (should exist)
    corr_sessions_engagement = df['sessions_last_7_days'].corr(df['engagement_score'])
    if corr_sessions_engagement < 0.3:
        issues.append(f"Low correlation sessions↔engagement: {corr_sessions_engagement:.2f}")
    
    if issues:
        print("   ⚠️ Issues found:")
        for issue in issues:
            print(f"      - {issue}")
        return False
    else:
        print("   ✅ All validation checks passed")
        return True


def main():
    """Main execution"""
    start_time = datetime.now()
    
    # Generate features
    customer_ids = generate_customer_ids(NUM_CUSTOMERS)
    age, gender, location = generate_demographics(NUM_CUSTOMERS)
    tenure_months, sessions_last_7_days, session_duration_avg_minutes, engagement_score = \
        generate_tenure_and_engagement(NUM_CUSTOMERS)
    
    swipes_right_last_30_days, matches_last_30_days, match_success_rate, \
        connections_sent, connections_received, total_connections = \
        generate_dating_features(NUM_CUSTOMERS)
    
    posts_last_30_days, stories_last_30_days, followers_count, \
        following_count, profile_views_received, content_virality_score = \
        generate_social_features(NUM_CUSTOMERS, engagement_score)
    
    gig_applications_sent, gig_applications_received, active_gigs_count, \
        transaction_revenue_last_90_days, avg_job_completion_rating = \
        generate_gig_features(NUM_CUSTOMERS)
    
    influence_score, risk_score = generate_influence_risk(NUM_CUSTOMERS)
    
    avg_sentiment_score, network_centrality, content_diversity_score, \
        session_consistency_score, last_7_day_engagement_trend, trust_score, \
        response_time_avg_hours, peak_activity_hour, referral_count, \
        time_since_first_transaction_days, premium_features_used_count, \
        social_influence_tier = \
        generate_advanced_features(NUM_CUSTOMERS, engagement_score, tenure_months, followers_count)
    
    churn_30_day, lifetime_value_usd, content_category_primary = \
        generate_prediction_targets(NUM_CUSTOMERS, engagement_score, tenure_months, sessions_last_7_days)
    
    # Create DataFrame
    print("\n📦 Creating DataFrame...")
    df = pd.DataFrame({
        # Primary key
        'customer_id': customer_ids,
        
        # Demographics
        'age': age,
        'gender': gender,
        'location': location,
        
        # Tenure & Engagement
        'tenure_months': tenure_months,
        'sessions_last_7_days': sessions_last_7_days,
        'session_duration_avg_minutes': session_duration_avg_minutes,
        'engagement_score': engagement_score,
        
        # Dating/Matching (Tinder-like)
        'swipes_right_last_30_days': swipes_right_last_30_days,
        'matches_last_30_days': matches_last_30_days,
        'match_success_rate': match_success_rate,
        'connections_sent': connections_sent,
        'connections_received': connections_received,
        'total_connections': total_connections,
        
        # Social Media (Instagram-like)
        'posts_last_30_days': posts_last_30_days,
        'stories_last_30_days': stories_last_30_days,
        'followers_count': followers_count,
        'following_count': following_count,
        'profile_views_received': profile_views_received,
        'content_virality_score': content_virality_score,
        
        # Gig/Freelance (Fiverr-like)
        'gig_applications_sent': gig_applications_sent,
        'gig_applications_received': gig_applications_received,
        'active_gigs_count': active_gigs_count,
        'transaction_revenue_last_90_days': transaction_revenue_last_90_days,
        'avg_job_completion_rating': avg_job_completion_rating,
        
        # Influence & Risk
        'influence_score': influence_score,
        'risk_score': risk_score,
        
        # Advanced Features
        'avg_sentiment_score': avg_sentiment_score,
        'network_centrality': network_centrality,
        'content_diversity_score': content_diversity_score,
        'session_consistency_score': session_consistency_score,
        'last_7_day_engagement_trend': last_7_day_engagement_trend,
        'trust_score': trust_score,
        'response_time_avg_hours': response_time_avg_hours,
        'peak_activity_hour': peak_activity_hour,
        'referral_count': referral_count,
        'time_since_first_transaction_days': time_since_first_transaction_days,
        'premium_features_used_count': premium_features_used_count,
        'social_influence_tier': social_influence_tier,
        
        # Prediction Targets
        'churn_30_day': churn_30_day,
        'lifetime_value_usd': lifetime_value_usd,
        'content_category_primary': content_category_primary,
    })
    
    # Validate
    validate_data(df)
    
    # Save CSV
    print(f"\n💾 Saving CSV to {OUTPUT_CSV}...")
    df.to_csv(OUTPUT_CSV, index=False)
    csv_size_mb = pd.io.common.file_path_to_url(OUTPUT_CSV)
    
    # Save Parquet (more efficient for Athena)
    print(f"💾 Saving Parquet to {OUTPUT_PARQUET}...")
    df.to_parquet(OUTPUT_PARQUET, index=False, compression='snappy')
    
    # Summary statistics
    end_time = datetime.now()
    duration = (end_time - start_time).total_seconds()
    
    print("\n" + "="*60)
    print("✅ DATA GENERATION COMPLETE")
    print("="*60)
    print(f"Rows:              {len(df):,}")
    print(f"Columns:           {len(df.columns)}")
    print(f"CSV size:          {OUTPUT_CSV} (~{len(df) * len(df.columns) * 8 / 1024 / 1024:.1f} MB)")
    print(f"Parquet size:      {OUTPUT_PARQUET} (compressed)")
    print(f"Duration:          {duration:.1f} seconds")
    print()
    print("📊 Sample statistics:")
    print(f"   Avg age:                  {df['age'].mean():.1f} years")
    print(f"   Avg tenure:               {df['tenure_months'].mean():.1f} months")
    print(f"   Avg engagement:           {df['engagement_score'].mean():.3f}")
    print(f"   Churn rate:               {df['churn_30_day'].mean()*100:.1f}%")
    print(f"   Avg LTV:                  ${df['lifetime_value_usd'].mean():.2f}")
    print(f"   Correlation (sessions↔eng): {df['sessions_last_7_days'].corr(df['engagement_score']):.3f}")
    print()
    print("✅ Ready for ML pipeline!")
    print("="*60)


if __name__ == "__main__":
    main()

