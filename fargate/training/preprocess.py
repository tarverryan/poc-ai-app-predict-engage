"""
Data loading and feature engineering utilities
"""

import pandas as pd
import awswrangler as wr


def load_data_from_athena(database: str, table: str) -> pd.DataFrame:
    """Load customer data from Athena"""
    query = f"SELECT * FROM {database}.{table}"
    df = wr.athena.read_sql_query(query, database=database)
    return df


def engineer_features(df: pd.DataFrame) -> pd.DataFrame:
    """Engineer additional features from raw data"""
    df = df.copy()
    
    # Engagement features
    df['engagement_per_session'] = df['engagement_score'] / (df['sessions_last_7_days'] + 1)
    df['avg_session_value'] = df['session_duration_avg_minutes'] * df['engagement_score']
    
    # Social features
    df['follower_following_ratio'] = df['followers_count'] / (df['following_count'] + 1)
    df['content_activity_rate'] = (df['posts_last_30_days'] + df['stories_last_30_days']) / 30
    
    # Dating features
    df['match_efficiency'] = df['matches_last_30_days'] / (df['swipes_right_last_30_days'] + 1)
    df['connection_rate'] = df['total_connections'] / (df['tenure_months'] + 1)
    
    # Gig features
    df['gig_success_rate'] = df['active_gigs_count'] / (df['gig_applications_sent'] + 1)
    df['revenue_per_gig'] = df['transaction_revenue_last_90_days'] / (df['active_gigs_count'] + 1)
    
    # Fill NaN/inf values
    df = df.replace([float('inf'), float('-inf')], 0)
    df = df.fillna(0)
    
    return df

