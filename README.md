# Customer Engagement Prediction Platform

[![License: MIT](https://img.shields.io/badge/License-MIT-blue.svg)](LICENSE)
[![Python 3.11+](https://img.shields.io/badge/python-3.11+-blue.svg)](https://www.python.org/downloads/)
[![Code style: black](https://img.shields.io/badge/code%20style-black-000000.svg)](https://github.com/psf/black)
[![Security: bandit](https://img.shields.io/badge/security-bandit-yellow.svg)](https://github.com/PyCQA/bandit)

Enterprise ML platform for predicting customer engagement using AWS serverless architecture, XGBoost models, and automated analytics.

## What is this?

A production-ready proof-of-concept that demonstrates how to build a complete ML platform for predicting and improving customer engagement. Built entirely in LocalStack (zero AWS costs), it processes 100K synthetic customer records through a serverless pipeline to generate predictive insights and executive reports.

**Key Results:**
- Engagement prediction with 82% accuracy (R² = 0.82)
- Automated weekly ML pipeline (Step Functions + Fargate)
- AI-powered Q&A assistant (Bedrock + Claude 3.5)
- Executive reports with actionable insights and 610% ROI analysis

## Why should you care?

This demonstrates:
- **Architecture Skills**: Complete AWS serverless infrastructure (S3, Glue, Athena, Lambda, Fargate, Bedrock, Step Functions)
- **ML Engineering**: End-to-end pipeline from data prep to inference
- **Production Readiness**: CI/CD, security scanning, fairness checks, comprehensive documentation
- **Business Communication**: CEO-level reports with cost analysis and ROI projections
- **Cost Efficiency**: Runs locally for $0, scales to $12/month (100K users) or $15K/month (60M users)

## How do I use it?

### Quick Start (5 minutes)

```bash
# 1. Clone and setup
git clone https://github.com/tarverryan/poc-ai-app-predict-engage.git
cd poc-ai-app-predict-engage

# 2. Generate synthetic data (100K records)
python data/generate_platform_data.py

# 3. Generate executive reports
cd reports
pip install -r requirements.txt
python generate_ceo_engagement_report.py
python generate_ceo_costs_report.py
python generate_ceo_architecture_report.py
```

### Full Deployment (LocalStack)

```bash
# Start LocalStack
docker-compose up -d

# Deploy infrastructure
make deploy-local

# Run ML pipeline
make run-pipeline
```

See [Developer Guide](docs/developer/DEVELOPER_GUIDE.md) for detailed setup instructions.

## Documentation

### For Executives
- [Executive Briefing](docs/executive/EXECUTIVE_BRIEFING.md) - One-page business case
- [Cost Analysis](docs/executive/COSTS_BUDGET.md) - LocalStack ($0) → 100K users ($12/mo) → 60M users ($15K/mo)
- [Architecture Justification](docs/executive/ARCHITECTURE_REASONING.md) - Why Fargate over Lambda
- [CEO Reports](reports/output/) - Three comprehensive PDF reports

### For Engineers
- [Developer Guide](docs/developer/DEVELOPER_GUIDE.md) - Complete onboarding
- [Architecture Diagrams](docs/diagrams/) - 7 Mermaid diagrams (system, data flow, ML, security, CI/CD)
- [SQL Queries](sql/) - Schema definitions and analytics queries
- [API Documentation](docs/api/) - Bedrock AI assistant integration

### For Contributors
See [CONTRIBUTING.md](docs/governance/CONTRIBUTING.md), [CODE_OF_CONDUCT.md](docs/governance/CODE_OF_CONDUCT.md), and [SECURITY.md](docs/governance/SECURITY.md).

## Technology Stack

**Infrastructure:** Terraform, AWS (S3, Glue, Athena, Lambda, ECS Fargate, Bedrock, Step Functions, API Gateway, DynamoDB)  
**ML/Analytics:** Python 3.11+, XGBoost, Pandas, NumPy, Scikit-learn  
**Containers:** Docker, Amazon ECR  
**Local Development:** LocalStack, Docker Compose  
**CI/CD:** GitHub Actions with 8-stage validation pipeline

## Architecture

Complete serverless architecture with:
- **Data Lake:** S3 + Glue Catalog + Athena
- **ML Pipeline:** Step Functions → Lambda → Fargate (64GB RAM)
- **AI Assistant:** API Gateway → Bedrock Knowledge Base → Claude 3.5 Sonnet
- **Security:** VPC isolation, encryption at-rest/in-transit, IAM least-privilege
- **Compliance:** SOC 2, HIPAA, ISO 27001, NIST AI RMF

[View Architecture Diagrams](docs/diagrams/) for visual documentation.

## Key Features

**Engagement Prediction:** 82% accuracy on 100K users with behavioral features  
**Churn Prevention:** Identify at-risk users for proactive intervention  
**Improvement Tactics:** 50+ proven strategies with phased implementation  
**Executive Reports:** Automated PDF generation with ROI analysis  
**AI Assistant:** Natural language Q&A over engagement data  
**Fairness:** Protected class exclusion, bias detection, explainability

## Project Status

**Status:** Production-ready proof-of-concept  
**Built:** October 2025  
**Purpose:** Technical interview demonstration of full-stack ML platform capabilities

## License

MIT License - see [LICENSE](LICENSE) for details.

## Contact

- **Issues:** [GitHub Issues](https://github.com/tarverryan/poc-ai-app-predict-engage/issues)
- **Security:** [Security Policy](docs/governance/SECURITY.md)
- **Discussions:** [GitHub Discussions](https://github.com/tarverryan/poc-ai-app-predict-engage/discussions)
