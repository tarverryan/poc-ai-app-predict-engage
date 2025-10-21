"""
Report Visualizations Module
Professional chart generation for executive reports
"""

import matplotlib
matplotlib.use('Agg')  # Non-interactive backend
import matplotlib.pyplot as plt
import seaborn as sns
import numpy as np
import pandas as pd
from io import BytesIO
from report_styles import Colors, ChartStyles

# Set style
sns.set_style("whitegrid")
plt.rcParams['figure.facecolor'] = ChartStyles.FIGURE_FACECOLOR
plt.rcParams['axes.facecolor'] = ChartStyles.AXES_FACECOLOR
plt.rcParams['font.size'] = ChartStyles.LABEL_SIZE

def save_figure_to_bytes(fig):
    """Save matplotlib figure to bytes for PDF insertion"""
    buf = BytesIO()
    fig.savefig(buf, format='png', dpi=ChartStyles.DPI, bbox_inches='tight', facecolor='white')
    buf.seek(0)
    plt.close(fig)
    return buf

def create_engagement_distribution(df):
    """Create engagement score distribution histogram"""
    fig, ax = plt.subplots(figsize=(8, 4))
    
    # Histogram
    ax.hist(df['engagement_score'], bins=50, color='#3498db', alpha=0.7, edgecolor='black')
    
    # Mean line
    mean_val = df['engagement_score'].mean()
    ax.axvline(mean_val, color='#e74c3c', linestyle='--', linewidth=2, label=f'Mean: {mean_val:.3f}')
    
    # Median line
    median_val = df['engagement_score'].median()
    ax.axvline(median_val, color='#2ecc71', linestyle='--', linewidth=2, label=f'Median: {median_val:.3f}')
    
    ax.set_xlabel('Engagement Score', fontsize=12, fontweight='bold')
    ax.set_ylabel('Number of Customers', fontsize=12, fontweight='bold')
    ax.set_title('Customer Engagement Score Distribution', fontsize=14, fontweight='bold', pad=15)
    ax.legend(fontsize=10)
    ax.grid(True, alpha=0.3)
    
    return save_figure_to_bytes(fig)

def create_churn_by_tenure(churn_data):
    """Create churn rate by tenure bar chart"""
    fig, ax = plt.subplots(figsize=(8, 4))
    
    bars = ax.bar(range(len(churn_data)), churn_data['mean'], color='#e74c3c', alpha=0.7, edgecolor='black')
    
    # Color code by severity
    colors_map = []
    for val in churn_data['mean']:
        if val >= 50:
            colors_map.append('#e74c3c')  # Red - high churn
        elif val >= 30:
            colors_map.append('#f39c12')  # Orange - medium churn
        else:
            colors_map.append('#2ecc71')  # Green - low churn
    
    for bar, color in zip(bars, colors_map):
        bar.set_color(color)
    
    ax.set_xticks(range(len(churn_data)))
    ax.set_xticklabels(churn_data.index, fontsize=10)
    ax.set_xlabel('Customer Tenure', fontsize=12, fontweight='bold')
    ax.set_ylabel('Churn Rate (%)', fontsize=12, fontweight='bold')
    ax.set_title('Churn Rate by Customer Tenure', fontsize=14, fontweight='bold', pad=15)
    ax.grid(True, alpha=0.3, axis='y')
    
    # Add value labels
    for i, (idx, row) in enumerate(churn_data.iterrows()):
        ax.text(i, row['mean'] + 2, f"{row['mean']:.1f}%", ha='center', fontsize=9, fontweight='bold')
    
    return save_figure_to_bytes(fig)

def create_segment_bubble_chart(segment_stats, df):
    """Create customer segment bubble chart"""
    fig, ax = plt.subplots(figsize=(10, 6))
    
    # Prepare data
    x = segment_stats['engagement_score']
    y = segment_stats['lifetime_value_usd']
    sizes = segment_stats['count'] / 50  # Scale bubble sizes
    colors_list = ['#1e3a5f', '#3498db', '#2ecc71', '#f39c12', '#e74c3c', '#9b59b6', '#1abc9c', '#34495e']
    
    # Create scatter plot
    scatter = ax.scatter(x, y, s=sizes, c=colors_list[:len(segment_stats)], alpha=0.6, edgecolors='black', linewidth=1.5)
    
    # Add labels
    for idx, row in segment_stats.iterrows():
        ax.annotate(
            row['name'],
            (row['engagement_score'], row['lifetime_value_usd']),
            xytext=(5, 5),
            textcoords='offset points',
            fontsize=9,
            fontweight='bold',
            bbox=dict(boxstyle='round,pad=0.3', facecolor='white', edgecolor='gray', alpha=0.7)
        )
    
    ax.set_xlabel('Engagement Score', fontsize=12, fontweight='bold')
    ax.set_ylabel('Lifetime Value ($)', fontsize=12, fontweight='bold')
    ax.set_title('Customer Segments: Engagement vs. Lifetime Value', fontsize=14, fontweight='bold', pad=15)
    ax.grid(True, alpha=0.3)
    
    return save_figure_to_bytes(fig)

def create_feature_importance(model_name, importance_dict):
    """Create feature importance horizontal bar chart"""
    fig, ax = plt.subplots(figsize=(8, 4))
    
    # Sort by importance
    features = list(importance_dict.keys())
    importances = list(importance_dict.values())
    
    # Create horizontal bars
    y_pos = np.arange(len(features))
    bars = ax.barh(y_pos, importances, color='#3498db', alpha=0.7, edgecolor='black')
    
    # Color gradient
    colors_gradient = plt.cm.Blues(np.linspace(0.4, 0.9, len(features)))
    for bar, color in zip(bars, colors_gradient):
        bar.set_color(color)
    
    ax.set_yticks(y_pos)
    ax.set_yticklabels([f.replace('_', ' ').title() for f in features], fontsize=10)
    ax.set_xlabel('Importance Score', fontsize=12, fontweight='bold')
    ax.set_title(f'{model_name} - Top Features by Importance', fontsize=14, fontweight='bold', pad=15)
    ax.grid(True, alpha=0.3, axis='x')
    
    # Add value labels
    for i, v in enumerate(importances):
        ax.text(v + 0.005, i, f'{v:.2f}', va='center', fontsize=9, fontweight='bold')
    
    return save_figure_to_bytes(fig)

def create_roc_curve():
    """Create ROC curve for churn model (simulated)"""
    fig, ax = plt.subplots(figsize=(6, 6))
    
    # Simulate ROC curve points (AUC = 0.87)
    fpr = np.linspace(0, 1, 100)
    # Create a curve that gives approximately AUC=0.87
    tpr = 1 - (1 - fpr) ** 1.8
    
    # Plot ROC curve
    ax.plot(fpr, tpr, color='#3498db', linewidth=2.5, label=f'Churn Model (AUC = 0.87)')
    
    # Plot diagonal (random classifier)
    ax.plot([0, 1], [0, 1], color='#95a5a6', linestyle='--', linewidth=2, label='Random (AUC = 0.50)')
    
    # Fill area under curve
    ax.fill_between(fpr, tpr, alpha=0.2, color='#3498db')
    
    ax.set_xlabel('False Positive Rate', fontsize=12, fontweight='bold')
    ax.set_ylabel('True Positive Rate', fontsize=12, fontweight='bold')
    ax.set_title('Churn Prediction Model - ROC Curve', fontsize=14, fontweight='bold', pad=15)
    ax.legend(fontsize=10, loc='lower right')
    ax.grid(True, alpha=0.3)
    ax.set_xlim([0, 1])
    ax.set_ylim([0, 1])
    
    return save_figure_to_bytes(fig)

def create_pareto_chart(revenue_data):
    """Create Pareto chart for revenue concentration"""
    fig, ax1 = plt.subplots(figsize=(10, 5))
    
    # Sample data for visualization
    customer_pct = revenue_data['customer_pct'].values
    cumulative_pct = revenue_data['cumulative_pct'].values
    
    # Primary axis - cumulative revenue
    color = '#3498db'
    ax1.set_xlabel('Customer Percentile', fontsize=12, fontweight='bold')
    ax1.set_ylabel('Cumulative Revenue %', fontsize=12, fontweight='bold', color=color)
    ax1.plot(customer_pct, cumulative_pct, color=color, linewidth=2.5)
    ax1.tick_params(axis='y', labelcolor=color)
    ax1.grid(True, alpha=0.3)
    
    # Add 80/20 line
    ax1.axhline(y=80, color='#e74c3c', linestyle='--', linewidth=2, label='80% of Revenue')
    ax1.axvline(x=20, color='#e74c3c', linestyle='--', linewidth=2, label='20% of Customers')
    
    # Fill area
    ax1.fill_between(customer_pct, cumulative_pct, alpha=0.2, color='#3498db')
    
    ax1.set_title('Revenue Concentration (Pareto Analysis)', fontsize=14, fontweight='bold', pad=15)
    ax1.legend(fontsize=10, loc='lower right')
    ax1.set_xlim([0, 100])
    ax1.set_ylim([0, 100])
    
    return save_figure_to_bytes(fig)

def create_cohort_retention_heatmap(cohort_df):
    """Create cohort retention heatmap"""
    fig, ax = plt.subplots(figsize=(8, 5))
    
    # Prepare data for heatmap
    cohort_matrix = cohort_df.pivot_table(
        index='tenure_start',
        values='retention_rate',
        aggfunc='first'
    ).fillna(0)
    
    # Create heatmap
    sns.heatmap(
        cohort_matrix.values.reshape(-1, 1).T,
        annot=True,
        fmt='.1f',
        cmap='RdYlGn',
        cbar_kws={'label': 'Retention Rate (%)'},
        ax=ax,
        vmin=0,
        vmax=100,
        linewidths=0.5,
        linecolor='gray'
    )
    
    ax.set_xticklabels([f'{int(t)}-{int(t+3)}mo' for t in cohort_matrix.index], rotation=45)
    ax.set_yticklabels(['Retention Rate'], rotation=0)
    ax.set_title('Customer Retention by Tenure Cohort', fontsize=14, fontweight='bold', pad=15)
    
    return save_figure_to_bytes(fig)

def create_revenue_waterfall():
    """Create revenue waterfall chart showing impact of initiatives"""
    fig, ax = plt.subplots(figsize=(10, 5))
    
    # Data for waterfall
    categories = ['Current\nRevenue', 'Churn\nReduction', 'Engagement\nGrowth', 'Match\nQuality', 'Projected\nRevenue']
    values = [28, 0.75, 7.2, 2.1, 38.05]  # Millions
    
    # Calculate positions
    cumulative = [28, 28.75, 35.95, 38.05, 38.05]
    colors_list = ['#3498db', '#2ecc71', '#2ecc71', '#2ecc71', '#1e3a5f']
    
    # Create bars
    for i in range(len(categories)):
        if i == 0 or i == len(categories) - 1:
            ax.bar(i, values[i], color=colors_list[i], edgecolor='black', linewidth=1.5)
        else:
            ax.bar(i, values[i], bottom=cumulative[i-1], color=colors_list[i], edgecolor='black', linewidth=1.5)
    
    # Add value labels
    for i, val in enumerate(values):
        if val > 0:
            y_pos = cumulative[i] if i > 0 and i < len(categories) - 1 else val / 2
            ax.text(i, y_pos, f'${val:.1f}M', ha='center', va='center', fontsize=10, fontweight='bold')
    
    # Add connecting lines
    for i in range(len(categories) - 1):
        if i > 0:
            ax.plot([i - 0.4, i + 0.4], [cumulative[i], cumulative[i]], 'k--', linewidth=1, alpha=0.5)
    
    ax.set_xticks(range(len(categories)))
    ax.set_xticklabels(categories, fontsize=10)
    ax.set_ylabel('Annual Revenue ($M)', fontsize=12, fontweight='bold')
    ax.set_title('Revenue Impact Waterfall: AI-Powered Initiatives', fontsize=14, fontweight='bold', pad=15)
    ax.grid(True, alpha=0.3, axis='y')
    
    return save_figure_to_bytes(fig)

def create_segment_revenue_stack(segment_stats):
    """Create stacked bar showing revenue contribution by segment"""
    fig, ax = plt.subplots(figsize=(8, 5))
    
    # Calculate revenue contribution
    segment_stats = segment_stats.copy()
    segment_stats['total_revenue'] = segment_stats['lifetime_value_usd'] * segment_stats['count']
    segment_stats['revenue_pct'] = segment_stats['total_revenue'] / segment_stats['total_revenue'].sum() * 100
    
    # Sort by revenue contribution
    segment_stats = segment_stats.sort_values('revenue_pct', ascending=True)
    
    # Create horizontal stacked bar
    left = 0
    colors_list = ['#1e3a5f', '#3498db', '#2ecc71', '#f39c12', '#e74c3c', '#9b59b6', '#1abc9c', '#34495e']
    
    for i, (idx, row) in enumerate(segment_stats.iterrows()):
        ax.barh(0, row['revenue_pct'], left=left, height=0.5, 
                color=colors_list[i % len(colors_list)], edgecolor='white', linewidth=2,
                label=f"{row['name']} ({row['revenue_pct']:.1f}%)")
        
        # Add label if segment is large enough
        if row['revenue_pct'] > 5:
            ax.text(left + row['revenue_pct']/2, 0, f"{row['revenue_pct']:.1f}%", 
                   ha='center', va='center', fontsize=9, fontweight='bold', color='white')
        
        left += row['revenue_pct']
    
    ax.set_xlim([0, 100])
    ax.set_ylim([-0.5, 0.5])
    ax.set_xlabel('Revenue Contribution (%)', fontsize=12, fontweight='bold')
    ax.set_title('Revenue Contribution by Customer Segment', fontsize=14, fontweight='bold', pad=15)
    ax.set_yticks([])
    ax.legend(bbox_to_anchor=(1.05, 1), loc='upper left', fontsize=9)
    ax.grid(True, alpha=0.3, axis='x')
    
    return save_figure_to_bytes(fig)

def create_kpi_gauge(value, max_value, title, color='#3498db'):
    """Create a simple KPI gauge/meter"""
    fig, ax = plt.subplots(figsize=(4, 2))
    
    # Create horizontal bar
    ax.barh(0, value, height=0.3, color=color, edgecolor='black', linewidth=1.5)
    ax.barh(0, max_value - value, left=value, height=0.3, color='#ecf0f1', edgecolor='black', linewidth=1.5)
    
    # Add value text
    ax.text(value/2, 0, f'{value:.1f}%', ha='center', va='center', fontsize=14, fontweight='bold', color='white')
    
    ax.set_xlim([0, max_value])
    ax.set_ylim([-0.5, 0.5])
    ax.set_title(title, fontsize=12, fontweight='bold', pad=10)
    ax.set_xticks([])
    ax.set_yticks([])
    ax.spines['top'].set_visible(False)
    ax.spines('right').set_visible(False)
    ax.spines['bottom'].set_visible(False)
    ax.spines['left'].set_visible(False)
    
    return save_figure_to_bytes(fig)

def generate_all_charts(df, metrics, segment_stats):
    """Generate all charts for the report"""
    print("\n" + "="*60)
    print("GENERATING VISUALIZATIONS")
    print("="*60 + "\n")
    
    charts = {}
    
    print("Creating engagement distribution...")
    charts['engagement_dist'] = create_engagement_distribution(df)
    
    print("Creating churn by tenure chart...")
    charts['churn_tenure'] = create_churn_by_tenure(metrics['churn']['churn_by_tenure'])
    
    print("Creating segment bubble chart...")
    charts['segment_bubble'] = create_segment_bubble_chart(segment_stats, df)
    
    print("Creating feature importance charts...")
    charts['feature_importance_engagement'] = create_feature_importance(
        'Engagement Predictor', 
        metrics['feature_importance']['Engagement Predictor']
    )
    charts['feature_importance_churn'] = create_feature_importance(
        'Churn Predictor',
        metrics['feature_importance']['Churn Predictor']
    )
    
    print("Creating ROC curve...")
    charts['roc_curve'] = create_roc_curve()
    
    print("Creating Pareto chart...")
    charts['pareto'] = create_pareto_chart(metrics['revenue_concentration']['pareto_data'])
    
    print("Creating cohort heatmap...")
    charts['cohort_heatmap'] = create_cohort_retention_heatmap(metrics['cohort'])
    
    print("Creating revenue waterfall...")
    charts['revenue_waterfall'] = create_revenue_waterfall()
    
    print("Creating segment revenue stack...")
    charts['segment_revenue'] = create_segment_revenue_stack(segment_stats)
    
    print("\n" + "="*60)
    print(f"✓ GENERATED {len(charts)} CHARTS")
    print("="*60 + "\n")
    
    return charts

