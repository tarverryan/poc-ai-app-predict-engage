# Bedrock Agent Prompts - Customer Engagement

**Category:** Engagement Analysis & Optimization  
**Total Prompts:** 50 comprehensive questions  
**Last Updated:** October 21, 2025

---

## Section 1: Understanding Engagement (10 questions)

### 1.1 What is customer engagement and how is it measured?
**Expected Answer:** Define engagement_score (0-1), explain components (sessions, duration, interactions), describe calculation method, provide interpretation ranges.

### 1.2 What makes a high engagement user?
**Expected Answer:** Characteristics of score >0.6 users - sessions/week >10, duration >15min, active gigs >3, connections >100, profile completeness >80%, content creation, transaction activity. Include specific metrics and percentages.

### 1.3 What are the top 5 features that predict engagement?
**Expected Answer:** 
1. sessions_last_7_days (importance: 0.18)
2. session_duration_avg_minutes (0.14)
3. last_login_days_ago (0.11)
4. followers_count (0.09)
5. total_connections (0.08)
Include feature importance scores and business interpretation.

### 1.4 How does engagement vary by account type?
**Expected Answer:** Compare Free (0.38), Premium (0.72), Enterprise (0.81). Premium users have 3x higher engagement. Explain reasons (features, commitment, use cases).

### 1.5 What is the relationship between engagement and churn?
**Expected Answer:** Strong inverse correlation. Engagement <0.3 = 80%+ churn risk, 0.3-0.5 = 50-80%, 0.5-0.7 = 20-50%, >0.7 = <20%. Show that engagement is the #1 churn predictor.

### 1.6 How does tenure affect engagement levels?
**Expected Answer:** U-shaped curve - low for new users (0.42 for 0-3mo), peaks at 24+ months (0.74). First 90 days critical. Provide specific metrics by tenure bucket.

### 1.7 What is the current average engagement score?
**Expected Answer:** 0.485 platform-wide. Breakdown: Free 0.38, Premium 0.72, Enterprise 0.81. DAU 42.3%, MAU 78.5%, sticky factor 0.54.

### 1.8 How do social network connections impact engagement?
**Expected Answer:** Strong positive correlation. 0-10 connections = 0.28 engagement, 100-200 = 0.71, 200+ = 0.84. Network effects powerful - 100+ connections = 4x higher engagement.

### 1.9 What role does mobile usage play in engagement?
**Expected Answer:** Mobile users 2.5x more active. Mobile-only: 0.52 engagement, Desktop-only: 0.38, Multi-platform: 0.68. 73.2% are mobile users. Mobile-first strategy critical.

### 1.10 How does content creation affect engagement?
**Expected Answer:** Creators (>5 posts/month) have 2x higher retention and 0.68 vs 0.41 engagement. Content types ranked by engagement: Success stories (0.73), Tips (0.68), Gigs (0.61), Personal (0.54), Promo (0.39).

---

## Section 2: Improving Engagement (10 questions)

### 2.1 What are the top 3 strategies to increase customer engagement?
**Expected Answer:**
1. Onboarding optimization (reduce first 90-day churn from 62% to 40%)
2. Premium conversion (increase from 8% to 15%)
3. Network growth (goal: 20 connections in first week)
Include expected impact and ROI.

### 2.2 How can we improve engagement for low-scoring users (0.2-0.4)?
**Expected Answer:** This 23% segment has 61% churn risk. Strategies: Win-back campaigns, feature discovery nudges, personalized recommendations, value demonstration, special incentives. Target outcome: +0.15 engagement score lift.

### 2.3 What interventions work best for at-risk customers?
**Expected Answer:** Segment-specific actions based on churn risk:
- Critical (>80%): Immediate reactivation offers, personal outreach
- High (60-80%): Engagement campaigns, content recommendations
- Medium (40-60%): Feature highlights, success stories
Include Next Best Action model recommendations.

### 2.4 How can we increase sessions per week?
**Expected Answer:** Current avg 8.7 sessions/week. Strategies:
- Push notifications at peak times (3-5 PM Wed/Thu)
- Personalized content recommendations
- Gamification (streaks, badges)
- Daily challenges/quests
Target: 10.5 sessions/week (+21% increase).

### 2.5 What drives session duration improvements?
**Expected Answer:** Current avg 18.3 minutes. Drivers:
- Quality content (success stories, how-tos)
- Relevant gig recommendations
- Strong social connections
- In-app messaging/engagement
Target: 22 minutes (+20%).

### 2.6 How can profile completeness improve engagement?
**Expected Answer:** >80% completeness = 50% higher match rate and +0.16 engagement boost. Current avg 67.8%. Strategies:
- Profile completion wizard
- Gamification (badges, points)
- Show benefits (visibility, matches)
- Periodic reminders
Target: 85% avg completeness.

### 2.7 What is the optimal notification strategy?
**Expected Answer:** Based on Next Best Action model:
- Timing: 3-5 PM Wed/Thu (peak activity)
- Frequency: 3-5 per week (avoid fatigue)
- Personalization: Content/gig recommendations >generic updates
- A/B testing: Continuous optimization
Result: 18% engagement uplift, 30% fewer notifications.

### 2.8 How can we leverage network effects for engagement?
**Expected Answer:** Connection strategies:
- Onboarding goal: 20 connections first week
- Smart recommendations (high-affinity matches)
- Connection milestones (gamification)
- Mutual connection discovery
Impact: 100+ connections = 4x engagement, 95% retention.

### 2.9 What content strategies drive highest engagement?
**Expected Answer:** Content type ranking:
1. Success stories (0.73 engagement, 0.58 virality)
2. Tips/How-to (0.68, 0.51)
3. Gig postings (0.61, 0.42)
Feed algorithm should prioritize educational + gig content.

### 2.10 How can we convert free users to premium?
**Expected Answer:** Current 8% conversion, target 15%. Strategies:
- Free trial (14-30 days)
- Feature comparison (value demonstration)
- Social proof (testimonials)
- Targeted discounts (first-time buyer)
- Upsell prompts (when hitting limits)
Impact: +7,000 premium users = $4.9M annual revenue.

---

## Section 3: Churn Prevention (10 questions)

### 3.1 What is the current churn rate and how does it compare to benchmarks?
**Expected Answer:** 37.9% (30-day) churn rate. Benchmarks: SaaS 5-7% monthly, Social 10-15%, Gig economy 25-35%. We're high end of gig economy range. Target: 22% (15% reduction).

### 3.2 What are the early warning signs of churn?
**Expected Answer:** Ranked by churn probability:
1. Last login >30 days (94% churn)
2. Sessions <2/week for 2 weeks (78%)
3. Profile <50% complete (67%)
4. 0 active gigs for 30 days (61%)
5. Declining transaction revenue (58%)
6. Negative sentiment trend (52%)

### 3.3 Which customer segments have highest churn risk?
**Expected Answer:**
- New Users (0-3 months): 62% churn
- At-Risk segment: 89% churn
- Low engagement (<0.2): 94.7% churn
- Free accounts: 45.2% churn
Priority: New user onboarding + at-risk campaigns.

### 3.4 What are the top reasons customers churn?
**Expected Answer:** From exit surveys:
1. Found better alternative (28%)
2. Not enough relevant gigs/connections (24%)
3. Platform too complex (18%)
4. Privacy concerns (12%)
5. Too expensive (11%)
81% is preventable with product improvements.

### 3.5 How can we reduce first 90-day churn?
**Expected Answer:** Current 62%, target 40%. Strategies:
- Day 1-7: Guided onboarding, quick wins
- Day 30: Check-in campaigns, tips
- Day 90: Milestone celebration, rewards
- Personalized support
- Connection goals (20 in first week)
Impact: Save 3,080 customers/cohort = $290K LTV.

### 3.6 What is the ROI of churn prevention campaigns?
**Expected Answer:** 
- Investment: $5/customer intervention
- Saved LTV: $50-200/customer
- ROI: 10-40x per saved customer
- Target: Save 30% of at-risk (2,400 customers)
- Total impact: $360K LTV - $40K cost = $320K net

### 3.7 How does the churn prediction model work?
**Expected Answer:** XGBoost classifier, 28 features, AUC-ROC 0.87. Top predictors:
1. last_login_days_ago (0.22 importance)
2. sessions_last_7_days (0.16)
3. engagement_score (0.12)
Outputs churn probability (0-1). Threshold >0.6 triggers intervention.

### 3.8 What interventions are most effective for high churn risk users?
**Expected Answer:** Based on Next Best Action model:
- Critical risk (>80%): Discount offers, reactivation bonuses
- High risk (60-80%): Personalized emails, feature demos
- Medium risk (40-60%): Engagement nudges, content recommendations
18% engagement uplift with optimized interventions.

### 3.9 How does Premium status affect churn?
**Expected Answer:** Dramatic impact:
- Free: 45.2% churn
- Premium: 18.3% churn (-60% vs Free)
- Enterprise: 8.1% churn (-82% vs Free)
Premium conversion = #1 retention lever.

### 3.10 What is the relationship between network size and churn?
**Expected Answer:** Inverse correlation:
- 0-10 connections: 59% churn
- 10-50: 38% churn
- 50-100: 22% churn
- 100-200: 11% churn
- 200+: 5% churn
Network effects create lock-in. Goal: 50+ connections for all users.

---

## Section 4: Lifetime Value (LTV) Optimization (10 questions)

### 4.1 What is the average customer lifetime value?
**Expected Answer:** $455.10 average. Distribution:
- Top 10%: $1,200+ (45% of revenue)
- Middle 40%: $300-1,200 (40% of revenue)
- Bottom 50%: <$300 (15% of revenue)
Breakdown by account type: Free $210, Premium $890, Enterprise $2,100.

### 4.2 What factors drive lifetime value?
**Expected Answer:** Regression analysis shows:
- Premium account: +$680
- Tenure (per year): +$180
- Active gigs (per gig): +$95
- Connections (per 100): +$140
- Engagement score: +$420 per 0.1 increase
- Transaction frequency: +$67 per transaction/month
Engagement has highest impact per unit.

### 4.3 How can we increase LTV for existing customers?
**Expected Answer:** Multi-pronged approach:
1. Engagement optimization (+$420 per 0.1 score)
2. Premium conversion ($210 → $890)
3. Gig activation (+$95 per gig)
4. Network growth (+$140 per 100 connections)
5. Transaction stimulation (+$67 per transaction/month)
Combined potential: +$200-400 LTV per user.

### 4.4 What is the LTV:CAC ratio by acquisition channel?
**Expected Answer:**
- Organic: 51.7x ($620 LTV / $12 CAC)
- Referral: 97.5x ($780 / $8) - BEST
- Social: 9.0x ($380 / $42)
- Paid: 4.3x ($290 / $67)
- Email: 28.3x ($510 / $18)
Double down on referral programs.

### 4.5 How does early engagement predict LTV?
**Expected Answer:** Strong correlation (r=0.71). First 30-day engagement score predicts 65% of final LTV variance. Users with >0.6 engagement in first month have $980 avg LTV vs $180 for <0.3. Early wins critical.

### 4.6 What is the payback period for customer acquisition?
**Expected Answer:** Varies by channel and account type:
- Free users: 8-12 months
- Premium: 2-3 months
- Enterprise: <1 month
- Average: 4.2 months
Healthy payback; allows aggressive acquisition.

### 4.7 How do gig workers compare to job seekers in LTV?
**Expected Answer:**
- Gig workers (sellers): $780 LTV, 14% churn
- Job seekers (buyers): $180 LTV, 38% churn
- Both (two-sided): $890 LTV, 12% churn
Strategy: Convert job seekers into two-sided users.

### 4.8 What is the impact of the recommendation system on LTV?
**Expected Answer:** NCF model improves match success 23.7% → 30%+. Impact:
- Higher transaction frequency (+1.2 transactions/month)
- Improved retention (-5% churn)
- Increased LTV (+$85 per user)
- Platform GMV increase (+18%)
ROI: $8.5M annually on 100K users.

### 4.9 How should we prioritize customer segments for LTV growth?
**Expected Answer:** Tier-based strategy:
1. High LTV (>$1,000): White-glove service, retention focus
2. Medium LTV ($300-1,000): Upsell, engagement optimization
3. Low LTV (<$300): Activation campaigns, upgrade incentives
4. New users: Onboarding excellence, quick wins
Resource allocation: 40% high, 40% medium, 20% low/new.

### 4.10 What is the ROI of LTV optimization initiatives?
**Expected Answer:** Example calculations:
- Onboarding improvement: Save 3,080 users × $95 avg = $292K
- Premium conversion: +7,000 users × $680 premium uplift = $4.76M
- Match quality: 100K users × $85 LTV increase = $8.5M
- Network growth: 30K users × $140 per 100 connections = $4.2M
Total potential: $17.8M with $2M investment = 8.9x ROI.

---

## Section 5: Predictive Analytics & ML Models (10 questions)

### 5.1 How accurate are the engagement predictions?
**Expected Answer:** XGBoost model performance:
- RMSE: 0.12 (target <0.15) ✅
- MAE: 0.09
- R²: 0.82
- MAPE: 24.3%
Model is highly accurate, explaining 82% of engagement variance.

### 5.2 What features does the churn prediction model use?
**Expected Answer:** 28 features, top 10 by importance:
1. last_login_days_ago (0.22)
2. sessions_last_7_days (0.16)
3. engagement_score (0.12)
4. tenure_months (0.09)
5. transaction_revenue_30_day (0.08)
6. active_gigs_count (0.07)
7. session_duration_avg_minutes (0.06)
8. profile_completeness_pct (0.05)
9. total_connections (0.04)
10. avg_gig_rating (0.03)
Model achieves 87% AUC-ROC.

### 5.3 How does the recommendation system improve match quality?
**Expected Answer:** Neural Collaborative Filtering model:
- Current match success: 23.7% → Target: 30%+
- Precision@10: 82% (8/10 recommendations accepted)
- NDCG@10: 0.89
- Coverage: 87% of inventory
Impact: +15% match success, +22% application conversion, +18% satisfaction.

### 5.4 What anomalies can the system detect?
**Expected Answer:** Isolation Forest + Autoencoders detect:
1. Transaction fraud ($10K+ in 24hrs)
2. Fake profiles (suspicious characteristics)
3. Bot activity (automated behavior)
4. Abuse/spam (excessive posting)
5. Account takeover (sudden behavior changes)
Performance: F1 0.91, Precision 94%, prevents $500K fraud annually.

### 5.5 How does the Next Best Action model work?
**Expected Answer:** Thompson Sampling (Bayesian Bandits) with 8 action types:
1. Push notification
2. Email campaign
3. In-app message
4. Discount offer
5. Content recommendation
6. Connection suggestion
7. Gig alert
8. No action
Learns optimal action per user/context. Result: 18% engagement uplift, 12.3% conversion (vs 7.1% baseline).

### 5.6 What customer segments does the clustering model identify?
**Expected Answer:** 8 segments via K-Means + HDBSCAN:
1. Power Users (8%): High engagement, Premium, LTV $1,450
2. Social Butterflies (15%): High social, low transactions, LTV $320
3. Gig Workers (18%): Active gigs, high transactions, LTV $780
4. Job Seekers (12%): Many applications, LTV $180
5. Lurkers (22%): Browsing, low posting, LTV $210
6. Enterprise (3%): Team features, LTV $2,100
7. New Users (14%): <3mo tenure, LTV $95
8. At-Risk (8%): Declining activity, LTV $150
Silhouette score: 0.71.

### 5.7 How is model performance monitored?
**Expected Answer:** Monitoring strategy:
- Metrics: RMSE, AUC-ROC, R², Precision, Recall (daily for batch, per-request for real-time)
- Data drift: KL divergence, KS test (weekly)
- Alerting: CloudWatch alarms if metrics degrade >10%
- Retraining: Monthly for core models, weekly for recommender, continuous for bandit
Model versioning with automated rollback if underperformance.

### 5.8 What fairness controls are in place for ML models?
**Expected Answer:** Comprehensive fairness framework:
- Protected attributes: Gender, age not used as features
- Metrics: Demographic parity (80% rule), equalized odds, calibration
- Mitigation: Re-sampling, adversarial debiasing, threshold optimization
- Audits: Weekly automated, quarterly human review, annual external audit
All models pass fairness checks ✅.

### 5.9 How do predictions get delivered to end users?
**Expected Answer:** Two paths:
1. Batch inference (weekly): Fargate container, full customer base (100K), 30 minutes, output to Athena + DynamoDB
2. Real-time inference (on-demand): Lambda function, <100ms latency, DynamoDB cache (fallback to direct model)
API Gateway + DynamoDB serve real-time predictions to applications.

### 5.10 What is the business ROI of the ML platform?
**Expected Answer:** Annual returns:
- Churn reduction (15%): $750K saved LTV
- Engagement increase (20% DAU): $7.2M additional revenue
- Match quality (+5%): $2.1M additional GMV
- Anomaly detection: $500K fraud prevented
- Operational efficiency: $50K labor saved
Total: $10.6M returns on $37K annual infrastructure cost = 285x ROI.

---

## Section 6: Advanced Analytics (10 additional questions)

### 6.1 What is the correlation between sentiment and engagement?
**Expected Answer:** Moderate positive correlation (r=0.47). Avg sentiment +0.12. Users with positive sentiment (>0.3) have 0.62 engagement vs 0.41 for negative (<-0.3). Causation unclear - happy users engage more OR engagement creates happiness. Sentiment tracking useful for early churn warning.

### 6.2 How does network centrality affect platform value?
**Expected Answer:** Top 10% by centrality (influencers):
- Generate 38% of all content
- Drive 42% of total engagement
- Avg 1,247 followers
- 0.79 engagement score
- 3.2% churn (very loyal)
Disproportionate platform value. Strategy: Influencer programs, early access, monetization.

### 6.3 What is the impact of profile completeness on match success?
**Expected Answer:** Strong correlation. Completeness >80% = 50% higher match rate.
- <50% complete: 12% match success
- 50-80%: 22% match success
- >80%: 33% match success
Current avg 67.8%, target 85%. Profile completion = low-hanging fruit for match quality.

### 6.4 How do weekend users differ from weekday users?
**Expected Answer:** Weekend usage 28.6% of total. Weekend-heavy users (>50% weekend):
- 18% of base
- Lower engagement (0.43 vs 0.52)
- More leisure/social focus (fewer gigs)
- Higher churn (42% vs 36%)
Platform optimization should prioritize weekday experience.

### 6.5 What is the relationship between transaction value and retention?
**Expected Answer:** Non-linear. Sweet spot $100-500/month transactions:
- <$50: 48% churn (low commitment)
- $50-100: 35% churn
- $100-500: 18% churn (optimal)
- $500-1,000: 22% churn
- >$1,000: 28% churn (enterprise, different dynamics)
Encourage moderate regular transactions.

### 6.6 How does content virality predict platform growth?
**Expected Answer:** Viral content (score >0.7) creates network effects:
- Attracts new users (+12% signup rate when viral content shared)
- Increases creator retention (+23%)
- Drives engagement (+0.14 for viral creators' followers)
Platform should algorithmically boost high-quality viral content.

### 6.7 What cohort analysis reveals about user behavior?
**Expected Answer:** Monthly cohorts show:
- Month 1 retention: 58% (42% churn)
- Month 3: 42% (consistent with 62% first-90-day churn)
- Month 6: 35%
- Month 12: 29%
- Month 24: 24% (stable long-term)
Critical points: Month 1, Month 3. Stabilizes after Month 6.

### 6.8 How do multi-platform users behave differently?
**Expected Answer:** Multi-platform (27% of users):
- Highest engagement: 0.68
- Most sessions: 14.3/week
- Longest tenure: 31.2 months avg
- Lowest churn: 12%
- Highest LTV: $740
Cross-platform strategy: Seamless sync, platform-specific features.

### 6.9 What A/B test results inform product decisions?
**Expected Answer:** Recent tests:
1. Onboarding redesign: +18% completion, +8% first-week retention
2. Notification timing: 3-5 PM = +24% open rate vs random
3. Premium pricing: $19/mo beats $15 and $25 (price elasticity)
4. Connection suggestions: Algorithm-based >2x acceptance vs random
5. Feed algorithm: Chronological+relevance hybrid >pure chronological
Data-driven product development.

### 6.10 How can sentiment analysis improve customer experience?
**Expected Answer:** Applications:
1. Early churn warning (negative trend)
2. Support prioritization (angry customers first)
3. Product feedback (feature sentiment)
4. Content moderation (toxic content flagging)
5. Brand monitoring (platform perception)
Current avg +0.12 sentiment. Goal: +0.25 through experience improvements.

---

**Total Prompts:** 60 comprehensive questions  
**Coverage:** Engagement, churn, LTV, ML models, analytics, strategy  
**Usage:** Bedrock Agent knowledge base validation  
**Expected Agent Performance:** >95% answer accuracy with data-driven responses

