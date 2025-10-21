"""
Report Analytics Module
Statistical analysis functions for customer engagement data
"""

import pandas as pd
import numpy as np
from sklearn.cluster import KMeans
from sklearn.preprocessing import StandardScaler
from scipy import stats
import warnings

warnings.filterwarnings('ignore')

def load_and_validate_data(filepath):
    """Load parquet file and validate schema"""
    print(f"Loading data from {filepath}...")
    df = pd.read_parquet(filepath)
    
    print(f"✓ Loaded {len(df):,} customer records with {len(df.columns)} features")
    
    # Validate required columns
    required_cols = [
        'customer_id', 'age', 'gender', 'location', 'tenure_months',
        'sessions_last_7_days', 'session_duration_avg_minutes', 'engagement_score',
        'total_connections', 'followers_count', 'churn_30_day', 'lifetime_value_usd'
    ]
    
    missing_cols = [col for col in required_cols if col not in df.columns]
    if missing_cols:
        raise ValueError(f"Missing required columns: {missing_cols}")
    
    return df

def calculate_engagement_metrics(df):
    """Calculate engagement-related metrics"""
    print("Calculating engagement metrics...")
    
    metrics = {
        'avg_engagement_score': df['engagement_score'].mean(),
        'median_engagement_score': df['engagement_score'].median(),
        'engagement_score_std': df['engagement_score'].std(),
        
        # DAU calculation (proxy: customers with sessions in last 7 days)
        'dau_pct': (df['sessions_last_7_days'] > 0).mean() * 100,
        'dau_count': (df['sessions_last_7_days'] > 0).sum(),
        
        # MAU proxy (engagement score > 0.1)
        'mau_pct': (df['engagement_score'] > 0.1).mean() * 100,
        'mau_count': (df['engagement_score'] > 0.1).sum(),
        
        # Session metrics
        'avg_sessions_per_week': df['sessions_last_7_days'].mean(),
        'median_sessions_per_week': df['sessions_last_7_days'].median(),
        'avg_session_duration': df['session_duration_avg_minutes'].mean(),
        'median_session_duration': df['session_duration_avg_minutes'].median(),
        
        # Engagement distribution
        'high_engagement_pct': (df['engagement_score'] >= 0.6).mean() * 100,
        'medium_engagement_pct': ((df['engagement_score'] >= 0.4) & (df['engagement_score'] < 0.6)).mean() * 100,
        'low_engagement_pct': ((df['engagement_score'] >= 0.2) & (df['engagement_score'] < 0.4)).mean() * 100,
        'disengaged_pct': (df['engagement_score'] < 0.2).mean() * 100,
    }
    
    print(f"  DAU: {metrics['dau_pct']:.1f}%")
    print(f"  Avg Engagement Score: {metrics['avg_engagement_score']:.3f}")
    
    return metrics

def analyze_churn(df):
    """Analyze churn patterns"""
    print("Analyzing churn patterns...")
    
    # Overall churn
    churn_rate = df['churn_30_day'].mean() * 100
    
    # Churn by tenure buckets
    df['tenure_bucket'] = pd.cut(
        df['tenure_months'],
        bins=[0, 3, 6, 12, 24, 120],
        labels=['0-3mo', '3-6mo', '6-12mo', '12-24mo', '24+mo']
    )
    churn_by_tenure = df.groupby('tenure_bucket', observed=False)['churn_30_day'].agg(['mean', 'count'])
    churn_by_tenure['mean'] *= 100
    
    # Churn by engagement level
    df['engagement_level'] = pd.cut(
        df['engagement_score'],
        bins=[0, 0.2, 0.4, 0.6, 1.0],
        labels=['Disengaged', 'Low', 'Medium', 'High']
    )
    churn_by_engagement = df.groupby('engagement_level', observed=False)['churn_30_day'].agg(['mean', 'count'])
    churn_by_engagement['mean'] *= 100
    
    # At-risk customers (engagement < 0.3)
    at_risk_count = ((df['engagement_score'] < 0.3) & (df['churn_30_day'] == 0)).sum()
    at_risk_pct = at_risk_count / len(df) * 100
    
    metrics = {
        'overall_churn_rate': churn_rate,
        'first_90_day_churn': churn_by_tenure.loc['0-3mo', 'mean'] if '0-3mo' in churn_by_tenure.index else 0,
        'churn_by_tenure': churn_by_tenure,
        'churn_by_engagement': churn_by_engagement,
        'at_risk_count': at_risk_count,
        'at_risk_pct': at_risk_pct,
    }
    
    print(f"  Overall Churn: {churn_rate:.1f}%")
    print(f"  First 90-day Churn: {metrics['first_90_day_churn']:.1f}%")
    print(f"  At-Risk Customers: {at_risk_count:,} ({at_risk_pct:.1f}%)")
    
    return metrics

def calculate_ltv_metrics(df):
    """Calculate LTV-related metrics"""
    print("Calculating LTV metrics...")
    
    metrics = {
        'avg_ltv': df['lifetime_value_usd'].mean(),
        'median_ltv': df['lifetime_value_usd'].median(),
        'ltv_std': df['lifetime_value_usd'].std(),
        'total_ltv': df['lifetime_value_usd'].sum(),
        
        # LTV distribution
        'ltv_p25': df['lifetime_value_usd'].quantile(0.25),
        'ltv_p50': df['lifetime_value_usd'].quantile(0.50),
        'ltv_p75': df['lifetime_value_usd'].quantile(0.75),
        'ltv_p90': df['lifetime_value_usd'].quantile(0.90),
        
        # High value customers
        'high_ltv_count': (df['lifetime_value_usd'] >= 1000).sum(),
        'high_ltv_pct': (df['lifetime_value_usd'] >= 1000).mean() * 100,
        'high_ltv_total': df[df['lifetime_value_usd'] >= 1000]['lifetime_value_usd'].sum(),
    }
    
    # Calculate Premium penetration (proxy: top 25% by LTV)
    ltv_threshold = df['lifetime_value_usd'].quantile(0.75)
    premium_pct = (df['lifetime_value_usd'] >= ltv_threshold).mean() * 100
    
    # ARPU (Average Revenue Per User) - monthly proxy
    arpu_monthly = metrics['avg_ltv'] / 12  # Simplification
    
    metrics['premium_pct'] = premium_pct
    metrics['arpu_monthly'] = arpu_monthly
    
    print(f"  Avg LTV: ${metrics['avg_ltv']:.2f}")
    print(f"  Premium % (top 25%): {premium_pct:.1f}%")
    print(f"  ARPU (monthly): ${arpu_monthly:.2f}")
    
    return metrics

def perform_segmentation(df):
    """Perform customer segmentation using K-means clustering"""
    print("Performing customer segmentation...")
    
    # Select features for clustering
    cluster_features = ['engagement_score', 'lifetime_value_usd', 'tenure_months']
    X = df[cluster_features].copy()
    
    # Handle missing values
    X = X.fillna(X.median())
    
    # Standardize features
    scaler = StandardScaler()
    X_scaled = scaler.fit_transform(X)
    
    # Perform K-means clustering (8 segments)
    kmeans = KMeans(n_clusters=8, random_state=42, n_init=10)
    df['segment'] = kmeans.fit_predict(X_scaled)
    
    # Calculate segment statistics
    segment_stats = df.groupby('segment').agg({
        'customer_id': 'count',
        'engagement_score': 'mean',
        'lifetime_value_usd': 'mean',
        'churn_30_day': 'mean',
        'tenure_months': 'mean',
    }).rename(columns={'customer_id': 'count'})
    
    segment_stats['churn_30_day'] *= 100
    segment_stats['pct_of_total'] = segment_stats['count'] / len(df) * 100
    
    # Name segments based on characteristics
    segment_names = {}
    for seg in range(8):
        stats = segment_stats.loc[seg]
        
        if stats['engagement_score'] >= 0.7 and stats['lifetime_value_usd'] >= 1000:
            name = 'Power Users'
        elif stats['engagement_score'] >= 0.6 and stats['lifetime_value_usd'] >= 500:
            name = 'Gig Workers'
        elif stats['lifetime_value_usd'] >= 1500:
            name = 'Enterprise'
        elif stats['engagement_score'] >= 0.6:
            name = 'Social Butterflies'
        elif stats['tenure_months'] <= 3:
            name = 'New Users'
        elif stats['churn_30_day'] >= 70:
            name = 'At-Risk'
        elif stats['engagement_score'] <= 0.4:
            name = 'Lurkers'
        else:
            name = 'Job Seekers'
        
        segment_names[seg] = name
    
    segment_stats['name'] = segment_stats.index.map(segment_names)
    
    # Reorder by priority (high LTV, high engagement first)
    segment_stats['priority_score'] = (
        segment_stats['lifetime_value_usd'] / 1000 +
        segment_stats['engagement_score'] * 2 -
        segment_stats['churn_30_day'] / 50
    )
    segment_stats = segment_stats.sort_values('priority_score', ascending=False)
    
    print(f"  Created 8 customer segments")
    for idx, row in segment_stats.iterrows():
        print(f"    {row['name']}: {row['count']:,} customers ({row['pct_of_total']:.1f}%)")
    
    return df, segment_stats

def analyze_revenue_concentration(df):
    """Analyze revenue concentration (Pareto analysis)"""
    print("Analyzing revenue concentration...")
    
    # Sort by LTV descending
    df_sorted = df.sort_values('lifetime_value_usd', ascending=False).reset_index(drop=True)
    df_sorted['cumulative_ltv'] = df_sorted['lifetime_value_usd'].cumsum()
    df_sorted['cumulative_pct'] = df_sorted['cumulative_ltv'] / df_sorted['lifetime_value_usd'].sum() * 100
    df_sorted['customer_pct'] = (df_sorted.index + 1) / len(df_sorted) * 100
    
    # Find key thresholds
    top_10_pct_revenue = df_sorted[df_sorted['customer_pct'] <= 10]['lifetime_value_usd'].sum()
    top_20_pct_revenue = df_sorted[df_sorted['customer_pct'] <= 20]['lifetime_value_usd'].sum()
    total_revenue = df_sorted['lifetime_value_usd'].sum()
    
    metrics = {
        'top_10_pct_revenue': top_10_pct_revenue,
        'top_10_pct_contribution': (top_10_pct_revenue / total_revenue * 100),
        'top_20_pct_revenue': top_20_pct_revenue,
        'top_20_pct_contribution': (top_20_pct_revenue / total_revenue * 100),
        'pareto_data': df_sorted[['customer_pct', 'cumulative_pct']].iloc[::1000],  # Sample for plotting
    }
    
    print(f"  Top 10% customers: {metrics['top_10_pct_contribution']:.1f}% of revenue")
    print(f"  Top 20% customers: {metrics['top_20_pct_contribution']:.1f}% of revenue")
    
    return metrics

def calculate_cohort_retention(df):
    """Calculate cohort retention matrix"""
    print("Calculating cohort retention...")
    
    # Create cohort matrix based on tenure
    cohort_data = []
    for tenure in range(0, 25, 3):  # 0, 3, 6, ..., 24 months
        cohort = df[(df['tenure_months'] >= tenure) & (df['tenure_months'] < tenure + 3)]
        if len(cohort) > 0:
            retention = (1 - cohort['churn_30_day'].mean()) * 100
            cohort_data.append({
                'tenure_start': tenure,
                'cohort_size': len(cohort),
                'retention_rate': retention,
            })
    
    cohort_df = pd.DataFrame(cohort_data)
    
    print(f"  Calculated retention for {len(cohort_df)} cohorts")
    
    return cohort_df

def simulate_model_performance():
    """Simulate ML model performance metrics (based on documented performance)"""
    print("Simulating ML model performance...")
    
    models = {
        'Engagement Predictor': {
            'type': 'Regression',
            'rmse': 0.12,
            'mae': 0.09,
            'r2': 0.82,
            'target': 'engagement_score',
        },
        'Churn Predictor': {
            'type': 'Classification',
            'auc_roc': 0.87,
            'accuracy': 0.853,
            'precision': 0.821,
            'recall': 0.789,
            'f1': 0.805,
            'target': 'churn_30_day',
        },
        'LTV Predictor': {
            'type': 'Regression',
            'rmse': 89.50,
            'mae': 67.30,
            'r2': 0.78,
            'target': 'lifetime_value_usd',
        },
    }
    
    # Generate feature importance (based on documented top features)
    feature_importance = {
        'Engagement Predictor': {
            'sessions_last_7_days': 0.18,
            'session_duration_avg_minutes': 0.14,
            'last_login_days_ago': 0.11,
            'followers_count': 0.09,
            'total_connections': 0.08,
        },
        'Churn Predictor': {
            'last_login_days_ago': 0.22,
            'sessions_last_7_days': 0.16,
            'engagement_score': 0.12,
            'tenure_months': 0.09,
            'total_connections': 0.08,
        },
        'LTV Predictor': {
            'tenure_months': 0.24,
            'engagement_score': 0.18,
            'total_connections': 0.14,
            'followers_count': 0.11,
            'sessions_last_7_days': 0.09,
        },
    }
    
    print(f"  Generated performance metrics for {len(models)} models")
    
    return models, feature_importance

def calculate_all_metrics(df):
    """Calculate all metrics for the report"""
    print("\n" + "="*60)
    print("CALCULATING ALL METRICS")
    print("="*60 + "\n")
    
    metrics = {}
    
    # 1. Engagement metrics
    metrics['engagement'] = calculate_engagement_metrics(df)
    
    # 2. Churn analysis
    metrics['churn'] = analyze_churn(df)
    
    # 3. LTV metrics
    metrics['ltv'] = calculate_ltv_metrics(df)
    
    # 4. Revenue concentration
    metrics['revenue_concentration'] = analyze_revenue_concentration(df)
    
    # 5. Cohort analysis
    metrics['cohort'] = calculate_cohort_retention(df)
    
    # 6. Model performance
    metrics['models'], metrics['feature_importance'] = simulate_model_performance()
    
    print("\n" + "="*60)
    print("✓ ALL METRICS CALCULATED")
    print("="*60 + "\n")
    
    return metrics

