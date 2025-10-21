#!/usr/bin/env python3
"""
Generate CEO Cost Budget Report (PDF)

Professional executive report showing AWS cost analysis across
LocalStack, 100K users, and 60M users scenarios.
"""

import pandas as pd
import numpy as np
from datetime import datetime
from reportlab.lib.pagesizes import letter
from reportlab.lib.units import inch
from reportlab.platypus import (
    SimpleDocTemplate, Paragraph, Spacer, Image, PageBreak, Table, TableStyle
)
from reportlab.lib import colors as rl_colors
from io import BytesIO
import matplotlib.pyplot as plt
import matplotlib.patches as mpatches
import seaborn as sns

# Import custom styles
from report_styles import (
    get_custom_styles, Colors, Fonts, Layout, ChartStyles,
    MARGIN, CONTENT_WIDTH, format_currency
)

# Set matplotlib style
plt.style.use('seaborn-v0_8-darkgrid')
sns.set_palette("husl")

# Output configuration
OUTPUT_PATH = "output/CEO_Cost_Budget_Report_" + datetime.now().strftime("%Y-%m-%d") + ".pdf"

print("=" * 70)
print("GENERATING CEO COST BUDGET REPORT")
print("=" * 70)

# Create PDF document
doc = SimpleDocTemplate(
    OUTPUT_PATH,
    pagesize=letter,
    leftMargin=MARGIN,
    rightMargin=MARGIN,
    topMargin=MARGIN,
    bottomMargin=MARGIN
)

# Get styles
styles = get_custom_styles()
story = []

# ============================================================================
# COVER PAGE
# ============================================================================

story.append(Spacer(1, 1.5*inch))

# Title
story.append(Paragraph(
    "AWS COST BUDGET ANALYSIS",
    styles['CoverTitle']
))
story.append(Spacer(1, 0.3*inch))

# Subtitle
story.append(Paragraph(
    "Customer Engagement Prediction Platform",
    styles['CoverSubtitle']
))
story.append(Paragraph(
    "Infrastructure Cost Projections & Optimization Strategies",
    styles['CoverSubtitle']
))
story.append(Spacer(1, 0.5*inch))

# Key metrics box
cover_metrics = [
    ['Scenario', 'Monthly Cost', 'Annual Cost', 'Cost per User'],
    ['LocalStack (Dev)', '$0', '$0', '$0'],
    ['AWS (100K Users)', '$12', '$144', '$0.00012'],
    ['AWS (60M Users)', '$170', '$2,042', '$0.0000028'],
]

table = Table(cover_metrics, colWidths=[1.8*inch, 1.3*inch, 1.3*inch, 1.3*inch])
table.setStyle(TableStyle([
    ('BACKGROUND', (0, 0), (-1, 0), Colors.NAVY),
    ('TEXTCOLOR', (0, 0), (-1, 0), Colors.WHITE),
    ('FONTNAME', (0, 0), (-1, 0), Fonts.HEADING),
    ('FONTSIZE', (0, 0), (-1, 0), 10),
    ('FONTNAME', (0, 1), (-1, -1), Fonts.BODY),
    ('FONTSIZE', (0, 1), (-1, -1), 9),
    ('ALIGN', (0, 0), (-1, -1), 'CENTER'),
    ('VALIGN', (0, 0), (-1, -1), 'MIDDLE'),
    ('GRID', (0, 0), (-1, -1), 0.5, Colors.GRAY_LIGHT),
    ('BACKGROUND', (0, 1), (-1, -1), Colors.WHITE),
    ('ROWBACKGROUNDS', (0, 1), (-1, -1), [Colors.WHITE, Colors.GRAY_LIGHTER]),
]))

story.append(table)
story.append(Spacer(1, 0.5*inch))

# Date and confidentiality
story.append(Paragraph(
    f"<b>Report Date:</b> {datetime.now().strftime('%B %d, %Y')}",
    styles['BodyCustom']
))
story.append(Paragraph(
    "<b>Classification:</b> CEO - Confidential",
    styles['BodyCustom']
))
story.append(Paragraph(
    "<b>Architecture:</b> 100% Serverless AWS",
    styles['BodyCustom']
))

story.append(PageBreak())

# ============================================================================
# EXECUTIVE SUMMARY
# ============================================================================

story.append(Paragraph("EXECUTIVE SUMMARY", styles['SectionTitle']))
story.append(Spacer(1, 0.15*inch))

story.append(Paragraph("<b>Purpose</b>", styles['Heading2Custom']))
story.append(Paragraph(
    "This report provides comprehensive AWS infrastructure cost analysis for the Customer Engagement "
    "Prediction Platform across three deployment scenarios: LocalStack (development), 100K users "
    "(production), and 60M users (enterprise scale).",
    styles['BodyCustom']
))
story.append(Spacer(1, 0.1*inch))

story.append(Paragraph("<b>Key Findings</b>", styles['Heading2Custom']))

key_findings = [
    ['Finding', 'Impact'],
    ['LocalStack development is 100% free', 'Zero cost for testing & iteration'],
    ['100K users costs only $12/month', 'Extremely affordable for production POC'],
    ['60M users costs $170/month (optimized)', 'Incredible scale efficiency (600× users)'],
    ['Cost per user drops 98% at scale', 'Fixed costs amortized over larger base'],
    ['Infrastructure <1% of business costs', 'Focus resources on engagement improvement'],
]

table = Table(key_findings, colWidths=[3.5*inch, 3*inch])
table.setStyle(TableStyle([
    ('BACKGROUND', (0, 0), (-1, 0), Colors.NAVY),
    ('TEXTCOLOR', (0, 0), (-1, 0), Colors.WHITE),
    ('FONTNAME', (0, 0), (-1, 0), Fonts.HEADING),
    ('FONTSIZE', (0, 0), (-1, 0), 9),
    ('FONTNAME', (0, 1), (-1, -1), Fonts.BODY),
    ('FONTSIZE', (0, 1), (-1, -1), 8),
    ('ALIGN', (0, 0), (0, -1), 'LEFT'),
    ('ALIGN', (1, 0), (1, -1), 'LEFT'),
    ('VALIGN', (0, 0), (-1, -1), 'MIDDLE'),
    ('GRID', (0, 0), (-1, -1), 0.5, Colors.GRAY_LIGHT),
    ('ROWBACKGROUNDS', (0, 1), (-1, -1), [Colors.WHITE, Colors.GRAY_LIGHTER]),
]))

story.append(table)
story.append(Spacer(1, 0.15*inch))

story.append(Paragraph("<b>Bottom Line</b>", styles['Heading2Custom']))
story.append(Paragraph(
    "AWS infrastructure costs are <b>NOT a constraint</b> for this business. At current scale "
    "(100K users), monthly costs of <b>$12</b> are negligible compared to the <b>$12.6M annual revenue</b> "
    "enabled by the platform. Even at 60M user scale, <b>$170/month</b> infrastructure costs represent "
    "less than 1% of projected revenue. <b>All focus should remain on the $10K/month engagement improvement "
    "initiative with 11,833% ROI</b> - infrastructure is a rounding error.",
    styles['BodyCustom']
))

story.append(PageBreak())

# ============================================================================
# SCENARIO 1: LOCALSTACK (DEVELOPMENT)
# ============================================================================

story.append(Paragraph("SCENARIO 1: LOCALSTACK (DEVELOPMENT)", styles['SectionTitle']))
story.append(Spacer(1, 0.15*inch))

localstack_data = [
    ['Component', 'Monthly Cost', 'Annual Cost'],
    ['LocalStack Community Edition', '$0', '$0'],
    ['Docker Desktop', '$0', '$0'],
    ['Local Compute', '$0', '$0'],
    ['<b>TOTAL</b>', '<b>$0</b>', '<b>$0</b>'],
]

table = Table(localstack_data, colWidths=[3*inch, 1.5*inch, 1.5*inch])
table.setStyle(TableStyle([
    ('BACKGROUND', (0, 0), (-1, 0), Colors.NAVY),
    ('TEXTCOLOR', (0, 0), (-1, 0), Colors.WHITE),
    ('FONTNAME', (0, 0), (-1, 0), Fonts.HEADING),
    ('FONTSIZE', (0, 0), (-1, 0), 9),
    ('FONTNAME', (0, 1), (-1, -1), Fonts.BODY),
    ('FONTSIZE', (0, 1), (-1, -1), 8),
    ('ALIGN', (1, 0), (-1, -1), 'RIGHT'),
    ('VALIGN', (0, 0), (-1, -1), 'MIDDLE'),
    ('GRID', (0, 0), (-1, -1), 0.5, Colors.GRAY_LIGHT),
    ('BACKGROUND', (0, -1), (-1, -1), Colors.GOLD_LIGHT),
    ('FONTNAME', (0, -1), (-1, -1), Fonts.HEADING),
]))

story.append(table)
story.append(Spacer(1, 0.1*inch))

story.append(Paragraph("<b>Services Included (FREE)</b>", styles['Heading3Custom']))
story.append(Paragraph("• S3 (local filesystem)<br/>"
                      "• Lambda (local execution)<br/>"
                      "• DynamoDB (local database)<br/>"
                      "• API Gateway (local endpoints)<br/>"
                      "• CloudWatch Logs (local logging)", styles['BodyCustom']))
story.append(Spacer(1, 0.1*inch))

story.append(Paragraph("<b>Development Savings</b>", styles['Heading3Custom']))
story.append(Paragraph(
    "LocalStack provides 100% cost-free development environment, saving <b>$144/year</b> compared "
    "to AWS testing. Invaluable for risk-free experimentation and rapid iteration.",
    styles['BodyCustom']
))

story.append(PageBreak())

# ============================================================================
# SCENARIO 2: 100K USERS (AWS PRODUCTION)
# ============================================================================

story.append(Paragraph("SCENARIO 2: 100,000 USERS (AWS PRODUCTION)", styles['SectionTitle']))
story.append(Spacer(1, 0.15*inch))

story.append(Paragraph("<b>Budget-Optimized Configuration</b>", styles['Heading2Custom']))
story.append(Paragraph(
    "Monthly Cost: <b>$12.00</b> | Annual Cost: <b>$144</b> | Cost per User: <b>$0.00012/month</b>",
    styles['BodyCustom']
))
story.append(Spacer(1, 0.1*inch))

# Create cost breakdown chart
fig, (ax1, ax2) = plt.subplots(1, 2, figsize=(10, 4))

# Pie chart
services_100k = ['Glue\n(ETL)', 'CloudWatch', 'Fargate\n(ML)', 'Other']
costs_100k = [5.58, 4.63, 1.48, 0.31]
colors_pie = ['#1e3a5f', '#3498db', '#2ecc71', '#95a5a6']

ax1.pie(costs_100k, labels=services_100k, autopct='%1.1f%%', colors=colors_pie,
        startangle=90, textprops={'fontsize': 8})
ax1.set_title('Cost Distribution (100K Users)', fontsize=10, fontweight='bold')

# Bar chart
ax2.barh(services_100k, costs_100k, color=colors_pie)
ax2.set_xlabel('Monthly Cost ($)', fontsize=8)
ax2.set_title('Cost by Service', fontsize=10, fontweight='bold')
ax2.tick_params(labelsize=7)
ax2.grid(axis='x', alpha=0.3)

# Add value labels
for i, v in enumerate(costs_100k):
    ax2.text(v + 0.1, i, f'${v:.2f}', va='center', fontsize=7)

plt.tight_layout()

# Save to buffer
buf = BytesIO()
plt.savefig(buf, format='png', dpi=ChartStyles.DPI, bbox_inches='tight')
buf.seek(0)
plt.close()

# Add to PDF
img = Image(buf, width=6*inch, height=2.4*inch)
story.append(img)
story.append(Spacer(1, 0.15*inch))

# Detailed cost table
cost_detail_100k = [
    ['Service', 'Monthly Cost', 'Usage', '% of Total'],
    ['AWS Glue (ETL)', '$5.58', '4 jobs/month', '46.5%'],
    ['CloudWatch', '$4.63', '1 dashboard, 20 metrics', '38.6%'],
    ['ECS Fargate (ML)', '$1.48', '8 tasks/month (4 vCPU, 64GB)', '12.3%'],
    ['Athena (Queries)', '$0.10', '50 queries/week', '0.8%'],
    ['CloudTrail', '$0.10', 'Audit logging', '0.8%'],
    ['ECR, Bedrock, Lambda, S3', '$0.11', 'Various', '0.9%'],
]

table = Table(cost_detail_100k, colWidths=[2*inch, 1.2*inch, 2*inch, 1*inch])
table.setStyle(TableStyle([
    ('BACKGROUND', (0, 0), (-1, 0), Colors.NAVY),
    ('TEXTCOLOR', (0, 0), (-1, 0), Colors.WHITE),
    ('FONTNAME', (0, 0), (-1, 0), Fonts.HEADING),
    ('FONTSIZE', (0, 0), (-1, 0), 8),
    ('FONTNAME', (0, 1), (-1, -1), Fonts.BODY),
    ('FONTSIZE', (0, 1), (-1, -1), 7),
    ('ALIGN', (1, 0), (-1, -1), 'RIGHT'),
    ('ALIGN', (0, 0), (0, -1), 'LEFT'),
    ('VALIGN', (0, 0), (-1, -1), 'MIDDLE'),
    ('GRID', (0, 0), (-1, -1), 0.5, Colors.GRAY_LIGHT),
    ('ROWBACKGROUNDS', (0, 1), (-1, -1), [Colors.WHITE, Colors.GRAY_LIGHTER]),
]))

story.append(table)

story.append(PageBreak())

# ============================================================================
# SCENARIO 3: 60M USERS (ENTERPRISE SCALE)
# ============================================================================

story.append(Paragraph("SCENARIO 3: 60,000,000 USERS (ENTERPRISE SCALE)", styles['SectionTitle']))
story.append(Spacer(1, 0.15*inch))

story.append(Paragraph("<b>Optimized Configuration (Recommended)</b>", styles['Heading2Custom']))
story.append(Paragraph(
    "Monthly Cost: <b>$170.20</b> | Annual Cost: <b>$2,042</b> | Cost per User: <b>$0.0000028/month</b>",
    styles['BodyCustom']
))
story.append(Spacer(1, 0.1*inch))

# Create cost breakdown chart for 60M
fig, (ax1, ax2) = plt.subplots(1, 2, figsize=(10, 4))

# Pie chart
services_60m = ['CloudWatch', 'VPC\nEndpoints', 'Glue', 'Other']
costs_60m = [60.00, 40.00, 21.24, 49.96]
colors_pie2 = ['#1e3a5f', '#e74c3c', '#3498db', '#95a5a6']

ax1.pie(costs_60m, labels=services_60m, autopct='%1.1f%%', colors=colors_pie2,
        startangle=90, textprops={'fontsize': 8})
ax1.set_title('Cost Distribution (60M Users)', fontsize=10, fontweight='bold')

# Bar chart
ax2.barh(services_60m, costs_60m, color=colors_pie2)
ax2.set_xlabel('Monthly Cost ($)', fontsize=8)
ax2.set_title('Cost by Service', fontsize=10, fontweight='bold')
ax2.tick_params(labelsize=7)
ax2.grid(axis='x', alpha=0.3)

# Add value labels
for i, v in enumerate(costs_60m):
    ax2.text(v + 1, i, f'${v:.2f}', va='center', fontsize=7)

plt.tight_layout()

# Save to buffer
buf = BytesIO()
plt.savefig(buf, format='png', dpi=ChartStyles.DPI, bbox_inches='tight')
buf.seek(0)
plt.close()

# Add to PDF
img = Image(buf, width=6*inch, height=2.4*inch)
story.append(img)
story.append(Spacer(1, 0.15*inch))

# Detailed cost table for 60M
cost_detail_60m = [
    ['Service', 'Monthly Cost', 'Optimization', 'Savings'],
    ['CloudWatch', '$60.00', 'Use Prometheus for metrics', '-$73'],
    ['VPC Endpoints', '$40.00', 'Interface endpoints (security)', '-'],
    ['Glue (ETL)', '$21.24', 'Serverless Spark', '-'],
    ['CloudTrail', '$12.50', 'Audit logging', '-'],
    ['Athena', '$12.06', 'Partitioning (80% reduction)', '-$48'],
    ['Fargate (ML)', '$9.37', 'Spot instances (70% discount)', '-$22'],
    ['Bedrock (AI)', '$5.01', 'On-demand pricing', '-'],
    ['Lambda', '$4.71', 'Optimized memory', '-'],
    ['Other Services', '$5.31', 'S3, ECR, Step Functions', '-'],
]

table = Table(cost_detail_60m, colWidths=[1.8*inch, 1.2*inch, 2.2*inch, 1*inch])
table.setStyle(TableStyle([
    ('BACKGROUND', (0, 0), (-1, 0), Colors.NAVY),
    ('TEXTCOLOR', (0, 0), (-1, 0), Colors.WHITE),
    ('FONTNAME', (0, 0), (-1, 0), Fonts.HEADING),
    ('FONTSIZE', (0, 0), (-1, 0), 8),
    ('FONTNAME', (0, 1), (-1, -1), Fonts.BODY),
    ('FONTSIZE', (0, 1), (-1, -1), 7),
    ('ALIGN', (1, 0), (-1, -1), 'RIGHT'),
    ('ALIGN', (0, 0), (0, -1), 'LEFT'),
    ('VALIGN', (0, 0), (-1, -1), 'MIDDLE'),
    ('GRID', (0, 0), (-1, -1), 0.5, Colors.GRAY_LIGHT),
    ('ROWBACKGROUNDS', (0, 1), (-1, -1), [Colors.WHITE, Colors.GRAY_LIGHTER]),
]))

story.append(table)

story.append(PageBreak())

# ============================================================================
# COST COMPARISON & SCALING
# ============================================================================

story.append(Paragraph("COST SCALING ANALYSIS", styles['SectionTitle']))
story.append(Spacer(1, 0.15*inch))

# Create scaling chart
fig, ax = plt.subplots(figsize=(8, 4))

users = [0.1, 1, 10, 60]  # in millions
costs = [12, 45, 98, 170]
cost_per_user = [0.00012, 0.000045, 0.0000098, 0.0000028]

ax.plot(users, costs, marker='o', linewidth=2, markersize=8, color='#1e3a5f', label='Monthly Cost ($)')
ax.set_xlabel('Users (Millions)', fontsize=ChartStyles.LABEL_SIZE)
ax.set_ylabel('Monthly Cost ($)', fontsize=ChartStyles.LABEL_SIZE)
ax.set_title('Cost Scaling: 100K → 60M Users', fontsize=ChartStyles.TITLE_SIZE, fontweight='bold')
ax.grid(alpha=0.3)
ax.tick_params(labelsize=ChartStyles.TICK_SIZE)

# Add value labels
for i, (u, c) in enumerate(zip(users, costs)):
    ax.annotate(f'${c}', xy=(u, c), xytext=(5, 5), textcoords='offset points',
                fontsize=7, fontweight='bold')

# Add cost per user on secondary axis
ax2 = ax.twinx()
ax2.plot(users, [cpu * 1000000 for cpu in cost_per_user], marker='s', linewidth=2,
         markersize=6, color='#e74c3c', linestyle='--', label='Cost per User (×10⁶)')
ax2.set_ylabel('Cost per User (×10⁻⁶)', fontsize=ChartStyles.LABEL_SIZE, color='#e74c3c')
ax2.tick_params(labelsize=ChartStyles.TICK_SIZE, labelcolor='#e74c3c')

# Combined legend
lines1, labels1 = ax.get_legend_handles_labels()
lines2, labels2 = ax2.get_legend_handles_labels()
ax.legend(lines1 + lines2, labels1 + labels2, loc='upper left', fontsize=7)

plt.tight_layout()

buf = BytesIO()
plt.savefig(buf, format='png', dpi=ChartStyles.DPI, bbox_inches='tight')
buf.seek(0)
plt.close()

img = Image(buf, width=6*inch, height=3*inch)
story.append(img)
story.append(Spacer(1, 0.15*inch))

story.append(Paragraph("<b>Key Insight: Cost Efficiency at Scale</b>", styles['Heading2Custom']))
story.append(Paragraph(
    "Cost per user <b>drops 98%</b> when scaling from 100K to 60M users. This dramatic improvement "
    "is driven by fixed costs (VPC, CloudWatch dashboards, Glue catalog) being amortized over a "
    "600× larger user base, combined with batch processing efficiency where the same infrastructure "
    "handles exponentially more data.",
    styles['BodyCustom']
))

story.append(PageBreak())

# ============================================================================
# COST OPTIMIZATION STRATEGIES
# ============================================================================

story.append(Paragraph("COST OPTIMIZATION STRATEGIES", styles['SectionTitle']))
story.append(Spacer(1, 0.15*inch))

optimization_strategies = [
    ['Strategy', 'Potential Savings', 'Implementation'],
    ['S3 Intelligent-Tiering', '40-60%', 'Auto-archive old data to Glacier'],
    ['Fargate Spot Instances', '70%', 'Use for fault-tolerant batch workloads'],
    ['Athena Partitioning', '70-90%', 'Partition by date/user segment'],
    ['CloudWatch Optimization', '50-60%', 'Use Prometheus/Grafana for high-volume'],
    ['VPC Endpoint Strategy', '60-80%', 'S3 Gateway (free) vs Interface Endpoints'],
    ['Lambda Right-Sizing', '30-40%', 'Use Lambda Power Tuning tool'],
]

table = Table(optimization_strategies, colWidths=[2.5*inch, 1.5*inch, 2.5*inch])
table.setStyle(TableStyle([
    ('BACKGROUND', (0, 0), (-1, 0), Colors.NAVY),
    ('TEXTCOLOR', (0, 0), (-1, 0), Colors.WHITE),
    ('FONTNAME', (0, 0), (-1, 0), Fonts.HEADING),
    ('FONTSIZE', (0, 0), (-1, 0), 9),
    ('FONTNAME', (0, 1), (-1, -1), Fonts.BODY),
    ('FONTSIZE', (0, 1), (-1, -1), 8),
    ('ALIGN', (1, 0), (1, -1), 'CENTER'),
    ('VALIGN', (0, 0), (-1, -1), 'MIDDLE'),
    ('GRID', (0, 0), (-1, -1), 0.5, Colors.GRAY_LIGHT),
    ('ROWBACKGROUNDS', (0, 1), (-1, -1), [Colors.WHITE, Colors.GRAY_LIGHTER]),
]))

story.append(table)
story.append(Spacer(1, 0.2*inch))

story.append(Paragraph("<b>Budget Recommendations</b>", styles['Heading2Custom']))

budget_rec = [
    ['User Tier', 'Recommended Budget', 'Allocation'],
    ['100K (Startup/POC)', '$20/month + 20% buffer = $24/month',
     '45% Glue, 30% CloudWatch, 15% Fargate, 10% Other'],
    ['60M (Enterprise)', '$200/month + 20% buffer = $240/month',
     '30% CloudWatch, 20% VPC, 20% Glue, 10% Athena, 10% Fargate, 10% Other'],
]

table = Table(budget_rec, colWidths=[1.5*inch, 2.2*inch, 2.8*inch])
table.setStyle(TableStyle([
    ('BACKGROUND', (0, 0), (-1, 0), Colors.NAVY),
    ('TEXTCOLOR', (0, 0), (-1, 0), Colors.WHITE),
    ('FONTNAME', (0, 0), (-1, 0), Fonts.HEADING),
    ('FONTSIZE', (0, 0), (-1, 0), 8),
    ('FONTNAME', (0, 1), (-1, -1), Fonts.BODY),
    ('FONTSIZE', (0, 1), (-1, -1), 7),
    ('VALIGN', (0, 0), (-1, -1), 'TOP'),
    ('GRID', (0, 0), (-1, -1), 0.5, Colors.GRAY_LIGHT),
    ('ROWBACKGROUNDS', (0, 1), (-1, -1), [Colors.WHITE, Colors.GRAY_LIGHTER]),
]))

story.append(table)

story.append(PageBreak())

# ============================================================================
# ROI ANALYSIS
# ============================================================================

story.append(Paragraph("RETURN ON INVESTMENT (ROI)", styles['SectionTitle']))
story.append(Spacer(1, 0.15*inch))

story.append(Paragraph("<b>Engagement Improvement Initiative ROI</b>", styles['Heading2Custom']))

roi_data = [
    ['Component', 'Amount', 'Details'],
    ['Investment', '$60,000', '6 months × $10K/month'],
    ['AWS Infrastructure', '$72', '6 months × $12/month (100K users)'],
    ['<b>Total Cost</b>', '<b>$60,072</b>', '<b>Complete initiative cost</b>'],
    ['', '', ''],
    ['Revenue Impact', '+$7.1M/year', '+56% increase from $12.6M baseline'],
    ['Current Revenue', '$12.6M/year', '100K users'],
    ['Projected Revenue', '$19.7M/year', 'After engagement improvements'],
    ['', '', ''],
    ['<b>ROI</b>', '<b>11,833%</b>', '<b>($7.1M / $60K) × 100</b>'],
    ['<b>Payback Period</b>', '<b>3 days</b>', '<b>(60K / 7.1M) × 365 days</b>'],
]

table = Table(roi_data, colWidths=[2*inch, 1.8*inch, 2.7*inch])
table.setStyle(TableStyle([
    ('BACKGROUND', (0, 0), (-1, 0), Colors.NAVY),
    ('TEXTCOLOR', (0, 0), (-1, 0), Colors.WHITE),
    ('FONTNAME', (0, 0), (-1, 0), Fonts.HEADING),
    ('FONTSIZE', (0, 0), (-1, 0), 9),
    ('FONTNAME', (0, 1), (-1, -1), Fonts.BODY),
    ('FONTSIZE', (0, 1), (-1, -1), 8),
    ('ALIGN', (1, 0), (-1, -1), 'RIGHT'),
    ('ALIGN', (0, 0), (0, -1), 'LEFT'),
    ('VALIGN', (0, 0), (-1, -1), 'MIDDLE'),
    ('GRID', (0, 0), (-1, -1), 0.5, Colors.GRAY_LIGHT),
    ('ROWBACKGROUNDS', (0, 1), (-1, -1), [Colors.WHITE, Colors.GRAY_LIGHTER]),
    ('BACKGROUND', (0, 2), (-1, 2), Colors.GOLD_LIGHT),
    ('BACKGROUND', (0, 8), (-1, 9), Colors.GOLD_LIGHT),
    ('FONTNAME', (0, 2), (-1, 2), Fonts.HEADING),
    ('FONTNAME', (0, 8), (-1, 9), Fonts.HEADING),
]))

story.append(table)
story.append(Spacer(1, 0.2*inch))

story.append(Paragraph("<b>Infrastructure ROI</b>", styles['Heading2Custom']))
story.append(Paragraph(
    "The $144/year AWS infrastructure cost enables <b>$12.6M in annual revenue</b>. This represents "
    "an infrastructure ROI of <b>8,750,000%</b>. Infrastructure costs are literally a rounding error "
    "compared to business value - less than 0.001% of revenue.",
    styles['BodyCustom']
))

story.append(PageBreak())

# ============================================================================
# RECOMMENDATIONS & NEXT STEPS
# ============================================================================

story.append(Paragraph("RECOMMENDATIONS & NEXT STEPS", styles['SectionTitle']))
story.append(Spacer(1, 0.15*inch))

story.append(Paragraph("<b>For Current 100K User Base</b>", styles['Heading2Custom']))
story.append(Paragraph(
    "1. Approve optimized configuration: <b>$12/month</b><br/>"
    "2. Enable S3 Intelligent-Tiering for automatic cost optimization<br/>"
    "3. Implement Athena partitioning to reduce query costs<br/>"
    "4. Set AWS Budget alerts at $15/month threshold<br/>"
    "5. Review costs quarterly for optimization opportunities",
    styles['BodyCustom']
))
story.append(Spacer(1, 0.15*inch))

story.append(Paragraph("<b>For Future 60M Scale</b>", styles['Heading2Custom']))
story.append(Paragraph(
    "1. Implement all cost optimizations: target <b>$170/month</b><br/>"
    "2. Use Fargate Spot instances for 70% compute savings<br/>"
    "3. Consider Prometheus/Grafana instead of CloudWatch ($73/month savings)<br/>"
    "4. Evaluate Reserved Capacity when usage becomes predictable<br/>"
    "5. Monitor with AWS Cost Anomaly Detection",
    styles['BodyCustom']
))
story.append(Spacer(1, 0.2*inch))

story.append(Paragraph("<b>CEO Decision Required</b>", styles['Heading2Custom']))

decision_box = [
    ['Decision', 'Status'],
    ['☐ Approve $12/month AWS infrastructure budget (100K users)', ''],
    ['☐ Approve $10K/month engagement improvement budget', ''],
    ['☐ Authorize infrastructure cost monitoring & optimization', ''],
    ['☐ Commit to quarterly cost review process', ''],
]

table = Table(decision_box, colWidths=[5*inch, 1*inch])
table.setStyle(TableStyle([
    ('BACKGROUND', (0, 0), (-1, 0), Colors.NAVY),
    ('TEXTCOLOR', (0, 0), (-1, 0), Colors.WHITE),
    ('FONTNAME', (0, 0), (-1, 0), Fonts.HEADING),
    ('FONTSIZE', (0, 0), (-1, 0), 8),
    ('FONTNAME', (0, 1), (-1, -1), Fonts.BODY),
    ('FONTSIZE', (0, 1), (-1, -1), 7),
    ('ALIGN', (1, 0), (-1, -1), 'CENTER'),
    ('VALIGN', (0, 0), (-1, -1), 'MIDDLE'),
    ('GRID', (0, 0), (-1, -1), 0.5, Colors.GRAY_LIGHT),
]))

story.append(table)
story.append(Spacer(1, 0.2*inch))

story.append(Paragraph(
    "<b>Bottom Line for CEO:</b> Infrastructure costs of $12/month (100K users) or $170/month "
    "(60M users) are negligible compared to the $7.1M revenue opportunity from engagement improvements. "
    "Infrastructure is NOT a constraint - focus all resources on the high-ROI engagement initiative.",
    styles['BodyCustom']
))

# Build PDF
doc.build(story)

print("=" * 70)
print("✅ CEO COST BUDGET REPORT GENERATED")
print("=" * 70)
print(f"   Location: {OUTPUT_PATH}")
print("=" * 70)

