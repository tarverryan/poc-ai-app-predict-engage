#!/usr/bin/env python3
"""
Generate 100,000 customer records for Multi-Platform Engagement Prediction
Platforms: Social Media Apps + Dating Apps

Features: 65+ platform-specific features including:
- Social Media: Stories, Reels, Video, Creator monetization, Ad engagement
- Dating Apps: Matches, Conversations, Dates, Profile quality, Premium features
- Universal: Demographics, Engagement, Revenue, Network effects

Usage:
    python data/generate_platform_data.py

Output:
    platform_engagement_dataset.csv (~80 MB)
    platform_engagement_dataset.parquet (~15 MB)
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
OUTPUT_CSV = "platform_engagement_dataset.csv"
OUTPUT_PARQUET = "platform_engagement_dataset.parquet"

# Initialize
np.random.seed(RANDOM_SEED)
fake = Faker()
Faker.seed(RANDOM_SEED)

print(f"🚀 Generating {NUM_CUSTOMERS:,} multi-platform customer records...")
print(f"   Platforms: Social Media + Dating Apps")
print(f"   Random seed: {RANDOM_SEED}")
print()


def generate_customer_ids(n):
    """Generate unique customer IDs"""
    return [fake.uuid4() for _ in range(n)]


def generate_demographics(n):
    """Generate demographics with realistic distributions"""
    print("📊 Generating demographics...")
    
    # Age: 18-65, peak at 25-35 for social/dating
    ages = np.random.beta(2, 5, n) * 47 + 18
    
    # Gender
    genders = np.random.choice(['Male', 'Female', 'Non-binary'], n, p=[0.48, 0.48, 0.04])
    
    # Locations (major metro areas for dating/social)
    locations = np.random.choice([
        'New York', 'Los Angeles', 'Chicago', 'San Francisco', 'Austin',
        'Seattle', 'Miami', 'Boston', 'Denver', 'Atlanta'
    ], n, p=[0.15, 0.12, 0.10, 0.10, 0.08, 0.08, 0.08, 0.08, 0.11, 0.10])
    
    # Tenure (months): Power law distribution (many new, few veterans)
    tenure = np.random.pareto(1.5, n) * 12
    tenure = np.clip(tenure, 0, 84)  # Max 7 years
    
    # Account type
    # Premium conversion ~18% for social, ~25% for dating
    account_types = np.random.choice(['Free', 'Premium'], n, p=[0.79, 0.21])
    
    return {
        'age': ages.astype(int),
        'gender': genders,
        'location': locations,
        'tenure_months': tenure.astype(int),
        'account_type': account_types
    }


def generate_social_media_features(n, age, tenure, account_type):
    """Generate social media platform features (Stories, Reels, Feed)"""
    print("📱 Generating social media features...")
    
    # Base engagement level (correlated with age)
    engagement_base = np.clip((35 - age) / 35, 0.1, 1.0)  # Younger = more engaged
    
    # Stories (Instagram/Facebook)
    stories_posted_week = np.random.poisson(engagement_base * 5, n)
    stories_viewed_day = np.random.poisson(engagement_base * 25, n)
    story_completion_rate = np.random.beta(3, 2, n) * engagement_base
    
    # Reels/Short Video (Short-form video content)
    reels_created_week = np.random.poisson(engagement_base * 3, n)
    reels_watched_day = np.random.poisson(engagement_base * 30, n)
    avg_reel_watch_time_sec = np.random.gamma(10, 2, n)  # Average 20 sec
    reel_completion_rate = np.random.beta(2, 3, n)
    
    # Video watch time (hours per week)
    video_watch_hours_week = np.random.gamma(5, 1, n) * engagement_base
    
    # Engagement rate (likes + comments + shares per post / followers)
    engagement_rate_pct = np.random.beta(2, 10, n) * 100  # Typically 1-10%
    
    # Posting behavior
    posts_last_30_days = np.random.poisson(engagement_base * 8, n)
    comments_posted_week = np.random.poisson(engagement_base * 15, n)
    likes_given_day = np.random.poisson(engagement_base * 50, n)
    shares_last_week = np.random.poisson(engagement_base * 5, n)
    
    # Network metrics
    followers_count = np.random.pareto(2, n) * 100 + 50
    following_count = np.random.pareto(2, n) * 150 + 75
    follower_following_ratio = np.clip(followers_count / following_count, 0, 10)
    
    # Creator metrics (for users who create content)
    is_creator = (reels_created_week + posts_last_30_days > 5).astype(int)
    creator_earnings_month = np.where(is_creator, 
                                     np.random.gamma(3, 50, n) * (account_type == 'Premium'),
                                     0)
    avg_views_per_post = np.where(is_creator,
                                  np.random.pareto(2, n) * 500 + 100,
                                  np.random.pareto(3, n) * 50 + 10)
    
    # Ad engagement (for platform revenue)
    ads_clicked_week = np.random.poisson(engagement_base * 2, n)
    ad_conversion_rate_pct = np.random.beta(1, 20, n) * 100  # Low ~0.5-5%
    
    # Feed/Discovery
    feed_time_minutes_day = np.random.gamma(20, 3, n) * engagement_base
    discover_page_visits_week = np.random.poisson(engagement_base * 10, n)
    
    # Live streaming
    live_streams_watched_week = np.random.poisson(engagement_base * 1, n)
    live_stream_time_minutes_week = np.where(live_streams_watched_week > 0,
                                             np.random.gamma(5, 10, n),
                                             0)
    
    return {
        'stories_posted_week': stories_posted_week.astype(int),
        'stories_viewed_day': stories_viewed_day.astype(int),
        'story_completion_rate_pct': (story_completion_rate * 100).round(1),
        'reels_created_week': reels_created_week.astype(int),
        'reels_watched_day': reels_watched_day.astype(int),
        'avg_reel_watch_time_sec': avg_reel_watch_time_sec.round(1),
        'reel_completion_rate_pct': (reel_completion_rate * 100).round(1),
        'video_watch_hours_week': video_watch_hours_week.round(2),
        'engagement_rate_pct': engagement_rate_pct.round(2),
        'posts_last_30_days': posts_last_30_days.astype(int),
        'comments_posted_week': comments_posted_week.astype(int),
        'likes_given_day': likes_given_day.astype(int),
        'shares_last_week': shares_last_week.astype(int),
        'followers_count': followers_count.astype(int),
        'following_count': following_count.astype(int),
        'follower_following_ratio': follower_following_ratio.round(2),
        'is_creator': is_creator,
        'creator_earnings_month_usd': creator_earnings_month.round(2),
        'avg_views_per_post': avg_views_per_post.astype(int),
        'ads_clicked_week': ads_clicked_week.astype(int),
        'ad_conversion_rate_pct': ad_conversion_rate_pct.round(2),
        'feed_time_minutes_day': feed_time_minutes_day.round(1),
        'discover_page_visits_week': discover_page_visits_week.astype(int),
        'live_streams_watched_week': live_streams_watched_week.astype(int),
        'live_stream_time_minutes_week': live_stream_time_minutes_week.round(1),
    }


def generate_dating_features(n, age, gender, location, tenure, account_type):
    """Generate dating app features (Matches, Swipes, Conversations)"""
    print("💕 Generating dating app features...")
    
    # Attractiveness score (0-100) - affects match rate
    # Simulated based on photo quality, profile completion
    attractiveness = np.random.beta(3, 3, n) * 100
    
    # Profile metrics
    profile_completion_pct = np.random.beta(5, 2, n) * 100
    photo_count = np.random.choice([1, 2, 3, 4, 5, 6, 7, 8, 9], n, 
                                   p=[0.05, 0.08, 0.10, 0.15, 0.20, 0.18, 0.12, 0.08, 0.04])
    profile_quality_score = (profile_completion_pct * 0.4 + attractiveness * 0.4 + photo_count * 10 * 0.2) / 100
    
    # Daily swipe activity
    swipes_right_day = np.random.poisson(15 + profile_quality_score * 30, n)
    swipes_left_day = np.random.poisson(35 + (100 - profile_quality_score) * 15, n)
    total_swipes_day = swipes_right_day + swipes_left_day
    swipe_right_rate_pct = np.where(total_swipes_day > 0,
                                    (swipes_right_day / total_swipes_day) * 100,
                                    0)
    
    # Match metrics
    # Match rate depends on attractiveness, gender, location
    base_match_rate = profile_quality_score * 0.02  # 0-2% of right swipes
    if isinstance(gender, np.ndarray):
        match_multiplier = np.where(gender == 'Female', 3.0, 1.0)  # Women get more matches
    else:
        match_multiplier = 1.0
    
    matches_per_day = np.random.poisson(swipes_right_day * base_match_rate * match_multiplier, n)
    match_rate_pct = np.where(swipes_right_day > 0,
                              (matches_per_day / swipes_right_day) * 100,
                              0)
    total_matches_alltime = np.clip(matches_per_day * tenure * 30, 0, 10000).astype(int)
    
    # Conversation metrics
    messages_sent_day = np.where(matches_per_day > 0,
                                np.random.poisson(matches_per_day * 1.5, n),
                                0)
    messages_received_day = np.where(matches_per_day > 0,
                                    np.random.poisson(matches_per_day * 1.8, n),
                                    0)
    avg_conversation_length = np.random.gamma(5, 2, n)  # Avg 10 messages
    response_rate_pct = np.random.beta(4, 2, n) * 100
    first_message_response_rate_pct = np.random.beta(3, 3, n) * 100
    
    # Date conversion
    dates_scheduled_month = np.where(matches_per_day > 0,
                                    np.random.poisson(matches_per_day * 0.15 * 30, n),
                                    0)
    date_show_up_rate_pct = np.where(dates_scheduled_month > 0,
                                    np.random.beta(8, 2, n) * 100,
                                    0)
    dates_completed_month = (dates_scheduled_month * date_show_up_rate_pct / 100).round(0).astype(int)
    match_to_date_conversion_pct = np.where(total_matches_alltime > 0,
                                           (dates_completed_month / (total_matches_alltime / tenure + 1)) * 100,
                                           0)
    
    # Premium features (Super Likes, Boosts)
    super_likes_used_week = np.where(account_type == 'Premium',
                                    np.random.poisson(5, n),
                                    np.random.poisson(0.5, n))  # Free users get limited
    boosts_used_month = np.where(account_type == 'Premium',
                                np.random.poisson(4, n),
                                0)
    super_like_match_rate_pct = np.random.beta(2, 3, n) * 100  # Higher than regular swipes
    
    # Safety & satisfaction
    users_blocked = np.random.poisson(tenure * 0.3, n)
    users_reported = np.random.poisson(tenure * 0.1, n)
    match_satisfaction_score = np.random.beta(4, 3, n) * 5  # 1-5 scale
    
    # App session behavior
    app_opens_day = np.random.poisson(8 + profile_quality_score * 10, n)
    session_duration_avg_min = np.random.gamma(5, 2, n)
    
    return {
        'profile_completion_pct': profile_completion_pct.round(1),
        'photo_count': photo_count,
        'profile_quality_score': (profile_quality_score * 100).round(1),
        'swipes_right_day': swipes_right_day.astype(int),
        'swipes_left_day': swipes_left_day.astype(int),
        'swipe_right_rate_pct': swipe_right_rate_pct.round(1),
        'matches_per_day': matches_per_day.astype(int),
        'match_rate_pct': match_rate_pct.round(2),
        'total_matches_alltime': total_matches_alltime,
        'messages_sent_day': messages_sent_day.astype(int),
        'messages_received_day': messages_received_day.astype(int),
        'avg_conversation_length': avg_conversation_length.round(1),
        'response_rate_pct': response_rate_pct.round(1),
        'first_message_response_rate_pct': first_message_response_rate_pct.round(1),
        'dates_scheduled_month': dates_scheduled_month.astype(int),
        'date_show_up_rate_pct': date_show_up_rate_pct.round(1),
        'dates_completed_month': dates_completed_month,
        'match_to_date_conversion_pct': np.clip(match_to_date_conversion_pct, 0, 100).round(2),
        'super_likes_used_week': super_likes_used_week.astype(int),
        'boosts_used_month': boosts_used_month.astype(int),
        'super_like_match_rate_pct': super_like_match_rate_pct.round(1),
        'users_blocked': users_blocked.astype(int),
        'users_reported': users_reported.astype(int),
        'match_satisfaction_score': match_satisfaction_score.round(2),
        'app_opens_day': app_opens_day.astype(int),
        'session_duration_avg_min': session_duration_avg_min.round(1),
    }


def generate_revenue_metrics(n, account_type, tenure, social_features, dating_features):
    """Generate revenue and monetization metrics"""
    print("💰 Generating revenue metrics...")
    
    # Premium subscription revenue
    premium_tier = np.where(account_type == 'Premium',
                           np.random.choice(['Gold', 'Platinum'], n, p=[0.7, 0.3]),
                           'Free')
    monthly_subscription_usd = np.where(
        premium_tier == 'Platinum', 29.99,
        np.where(premium_tier == 'Gold', 14.99, 0)
    )
    
    # In-app purchases (boosts, super likes, roses, etc.)
    iap_spending_month_usd = np.where(
        account_type == 'Premium',
        np.random.gamma(2, 8, n),  # Premium users spend more
        np.random.gamma(1, 3, n)   # Free users occasional purchases
    )
    
    # Ad revenue (for free users)
    ad_revenue_generated_month_usd = np.where(
        account_type == 'Free',
        social_features['ads_clicked_week'] * 0.15 * 4,  # $0.15 per click
        0
    )
    
    # Creator monetization (applies to creators only)
    creator_revenue_month_usd = social_features['creator_earnings_month_usd']
    
    # Total revenue per user per month
    total_revenue_month_usd = (monthly_subscription_usd + 
                               iap_spending_month_usd + 
                               ad_revenue_generated_month_usd)
    
    # Lifetime value
    lifetime_value_usd = total_revenue_month_usd * tenure
    
    # Transaction metrics
    total_transactions_alltime = np.random.poisson(tenure * 2 + (account_type == 'Premium') * 10, n)
    avg_transaction_value_usd = np.where(
        total_transactions_alltime > 0,
        lifetime_value_usd / total_transactions_alltime,
        0
    )
    
    return {
        'premium_tier': premium_tier,
        'monthly_subscription_usd': monthly_subscription_usd.round(2),
        'iap_spending_month_usd': iap_spending_month_usd.round(2),
        'ad_revenue_generated_month_usd': ad_revenue_generated_month_usd.round(2),
        'total_revenue_month_usd': total_revenue_month_usd.round(2),
        'lifetime_value_usd': lifetime_value_usd.round(2),
        'total_transactions_alltime': total_transactions_alltime.astype(int),
        'avg_transaction_value_usd': avg_transaction_value_usd.round(2),
    }


def generate_engagement_churn_metrics(n, social_features, dating_features, tenure, revenue_metrics):
    """Generate unified engagement and churn metrics"""
    print("📈 Generating engagement & churn metrics...")
    
    # Overall engagement score (0-1) combining social + dating activity
    social_engagement = (
        social_features['stories_viewed_day'] / 100 * 0.2 +
        social_features['reels_watched_day'] / 100 * 0.2 +
        social_features['feed_time_minutes_day'] / 100 * 0.2 +
        social_features['posts_last_30_days'] / 30 * 0.2 +
        social_features['engagement_rate_pct'] / 10 * 0.2
    )
    
    dating_engagement = (
        dating_features['app_opens_day'] / 20 * 0.2 +
        dating_features['swipes_right_day'] / 50 * 0.2 +
        dating_features['matches_per_day'] / 10 * 0.2 +
        dating_features['messages_sent_day'] / 20 * 0.2 +
        dating_features['dates_completed_month'] / 10 * 0.2
    )
    
    engagement_score = np.clip((social_engagement * 0.5 + dating_engagement * 0.5), 0, 1)
    
    # Sessions
    sessions_last_7_days = (social_features['feed_time_minutes_day'] / 30 * 7 + 
                           dating_features['app_opens_day'] * 7) / 2
    sessions_last_7_days = sessions_last_7_days.astype(int)
    
    # Churn prediction (30-day)
    # Higher engagement, revenue, tenure = lower churn
    churn_probability = (
        (1 - engagement_score) * 0.4 +
        (1 - np.clip(tenure / 24, 0, 1)) * 0.3 +  # New users churn more
        (revenue_metrics['total_revenue_month_usd'] == 0) * 0.2 +  # Free users churn more
        np.random.beta(2, 3, n) * 0.1  # Random factor
    )
    churn_30_day = (churn_probability > 0.5).astype(int)
    
    # Activity recency
    days_since_last_active = np.where(
        engagement_score > 0.3,
        np.random.choice([0, 1, 2, 3], n, p=[0.6, 0.25, 0.10, 0.05]),
        np.random.choice([0, 1, 2, 3, 7, 14, 30], n, p=[0.2, 0.15, 0.15, 0.15, 0.15, 0.10, 0.10])
    )
    
    return {
        'engagement_score': engagement_score.round(3),
        'sessions_last_7_days': sessions_last_7_days,
        'churn_probability': churn_probability.round(3),
        'churn_30_day': churn_30_day,
        'days_since_last_active': days_since_last_active.astype(int),
    }


def generate_platform_type(n):
    """Assign primary platform type to each user"""
    # Some users are primarily social media, some dating, some both
    platform_primary = np.random.choice(
        ['Social_Media', 'Dating', 'Both'], 
        n, 
        p=[0.45, 0.35, 0.20]
    )
    return {'platform_primary': platform_primary}


# Generate all data
print("=" * 70)
print("MULTI-PLATFORM CUSTOMER DATA GENERATION")
print("=" * 70)
print()

# Step 1: IDs and Demographics
customer_ids = generate_customer_ids(NUM_CUSTOMERS)
demographics = generate_demographics(NUM_CUSTOMERS)

# Step 2: Platform type
platform = generate_platform_type(NUM_CUSTOMERS)

# Step 3: Social Media Features
social_features = generate_social_media_features(
    NUM_CUSTOMERS,
    demographics['age'],
    demographics['tenure_months'],
    demographics['account_type']
)

# Step 4: Dating Features
dating_features = generate_dating_features(
    NUM_CUSTOMERS,
    demographics['age'],
    demographics['gender'],
    demographics['location'],
    demographics['tenure_months'],
    demographics['account_type']
)

# Step 5: Revenue Metrics
revenue_metrics = generate_revenue_metrics(
    NUM_CUSTOMERS,
    demographics['account_type'],
    demographics['tenure_months'],
    social_features,
    dating_features
)

# Step 6: Engagement & Churn
engagement_metrics = generate_engagement_churn_metrics(
    NUM_CUSTOMERS,
    social_features,
    dating_features,
    demographics['tenure_months'],
    revenue_metrics
)

# Combine all features
print()
print("🔗 Combining all features...")
data = {
    'customer_id': customer_ids,
    **demographics,
    **platform,
    **social_features,
    **dating_features,
    **revenue_metrics,
    **engagement_metrics,
}

# Create DataFrame
df = pd.DataFrame(data)

# Add timestamp
df['data_generated_at'] = datetime.now().strftime('%Y-%m-%d %H:%M:%S')

print()
print("=" * 70)
print("DATA GENERATION COMPLETE")
print("=" * 70)
print(f"Total Customers:  {len(df):,}")
print(f"Total Features:   {len(df.columns)}")
print(f"Memory Usage:     {df.memory_usage(deep=True).sum() / 1024**2:.1f} MB")
print()

# Display feature summary
print("📋 Feature Summary:")
print(f"   Demographics:           5")
print(f"   Social Media:          25")
print(f"   Dating:                27")
print(f"   Revenue:                8")
print(f"   Engagement/Churn:       5")
print(f"   Metadata:               2")
print(f"   {'─' * 40}")
print(f"   Total:                 {len(df.columns)}")
print()

# Sample statistics
print("📊 Sample Statistics:")
print(f"   Avg Engagement Score:     {df['engagement_score'].mean():.3f}")
print(f"   Churn Rate (30-day):      {df['churn_30_day'].mean():.1%}")
print(f"   Premium Users:            {(df['account_type'] == 'Premium').mean():.1%}")
print(f"   Avg LTV:                  ${df['lifetime_value_usd'].mean():.2f}")
print(f"   Avg Matches/Day:          {df['matches_per_day'].mean():.1f}")
print(f"   Avg Reels Watched/Day:    {df['reels_watched_day'].mean():.1f}")
print(f"   Creators:                 {df['is_creator'].mean():.1%}")
print()

# Save outputs
print("💾 Saving outputs...")
output_dir = "data/raw"
import os
os.makedirs(output_dir, exist_ok=True)

csv_path = f"{output_dir}/{OUTPUT_CSV}"
parquet_path = f"{output_dir}/{OUTPUT_PARQUET}"

df.to_csv(csv_path, index=False)
print(f"   ✓ CSV saved:     {csv_path} ({os.path.getsize(csv_path) / 1024**2:.1f} MB)")

df.to_parquet(parquet_path, index=False, compression='snappy')
print(f"   ✓ Parquet saved: {parquet_path} ({os.path.getsize(parquet_path) / 1024**2:.1f} MB)")

print()
print("=" * 70)
print("✅ SUCCESS! Multi-platform dataset generated.")
print("=" * 70)
print()
print("🎯 Next Steps:")
print("   1. Review data quality: df.head(), df.describe()")
print("   2. Generate executive report with platform-specific insights")
print("   3. Train ML models on 65+ features")
print()

