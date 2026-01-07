# Security Policy

## Supported Versions

We release patches for security vulnerabilities for the following versions:

| Version | Supported          |
| ------- | ------------------ |
| 1.0.x   | :white_check_mark: |
| < 1.0   | :x:                |

## Reporting a Vulnerability

We take the security of this project seriously. If you believe you have found a security vulnerability, please report it to us as described below.

### Please DO NOT:

- Open a public GitHub issue for security vulnerabilities
- Discuss the vulnerability in public forums, social media, or chat platforms
- Attempt to exploit the vulnerability against production systems

### Please DO:

**Report privately** via one of these methods:

1. **GitHub Security Advisories** (preferred)
   - Navigate to the Security tab → Advisories → New draft advisory
   - Provide detailed information about the vulnerability

2. **GitHub Security Advisories** (preferred)
   - Navigate to the Security tab → Advisories → New draft advisory
   - Provide detailed information about the vulnerability
   - This method ensures private communication

### What to Include in Your Report

Please provide as much information as possible:

- **Type of vulnerability** (e.g., SQL injection, XSS, authentication bypass)
- **Full paths of source files** related to the vulnerability
- **Location** of the affected code (tag/branch/commit or direct URL)
- **Step-by-step instructions** to reproduce the issue
- **Proof-of-concept or exploit code** (if possible)
- **Potential impact** of the vulnerability
- **Suggested remediation** (if you have ideas)

### Response Timeline

- **Within 24 hours**: Acknowledgment of your report
- **Within 7 days**: Initial assessment and severity classification
- **Within 30 days**: Patch development and testing
- **Within 45 days**: Public disclosure (coordinated with reporter)

### Severity Classification

We use CVSS 3.1 scoring:

- **Critical (9.0-10.0)**: Immediate action required
- **High (7.0-8.9)**: Prioritized for next release
- **Medium (4.0-6.9)**: Addressed in regular release cycle
- **Low (0.1-3.9)**: Backlog for future release

## Security Measures

### Infrastructure Security

- ✅ **Encryption**: AES-256 at rest, TLS 1.3 in transit
- ✅ **Network Isolation**: VPC with private subnets
- ✅ **Access Control**: IAM least-privilege, MFA enforced
- ✅ **Secrets Management**: AWS Secrets Manager (no hardcoded credentials)
- ✅ **Audit Logging**: CloudTrail, VPC Flow Logs enabled
- ✅ **Image Scanning**: ECR vulnerability scanning, SBOM generation

### Application Security

- ✅ **Input Validation**: All user inputs sanitized
- ✅ **SQL Injection Prevention**: Parameterized queries only
- ✅ **XSS Prevention**: Output encoding, CSP headers
- ✅ **CSRF Protection**: Token-based validation
- ✅ **Dependency Scanning**: Automated (Dependabot, Safety)
- ✅ **Static Analysis**: Bandit, SonarQube

### Data Security

- ✅ **PII Protection**: Synthetic data only, no real PII
- ✅ **Data Minimization**: Collect only necessary data
- ✅ **Access Logging**: All data access logged
- ✅ **Retention Policy**: Automated data lifecycle
- ✅ **Backup Encryption**: Encrypted backups

### AI/ML Security

- ✅ **Model Integrity**: Signed models, version control
- ✅ **Bias Detection**: Automated fairness tests
- ✅ **Adversarial Robustness**: Input validation, anomaly detection
- ✅ **Privacy Preservation**: Differential privacy where applicable
- ✅ **Explainability**: SHAP values, audit trails

## Security Best Practices

This project demonstrates security best practices and design patterns:

- **Least Privilege**: IAM policies follow least-privilege principles (see [IAM Policies](../security/iam_policies.md) for details)
- **Secrets Management**: No hardcoded secrets, use AWS Secrets Manager or environment variables
- **Encryption**: Data encrypted at rest (S3, DynamoDB) and in transit (TLS)
- **Logging**: Comprehensive logging via CloudWatch for auditability
- **Access Control**: VPC isolation and security groups for network boundaries

**Note:** This is a learning project, not an audited compliance framework. For production deployments, consult with security professionals and implement appropriate compliance controls based on your specific requirements.

## Security Contacts

- **Security Issues**: Use [GitHub Security Advisories](https://github.com/tarverryan/poc-ai-app-predict-engage/security/advisories/new) (private reporting)
- **General Questions**: Open a [GitHub Discussion](https://github.com/tarverryan/poc-ai-app-predict-engage/discussions) with the "security" label
- **Public Issues**: Create a [GitHub Issue](https://github.com/tarverryan/poc-ai-app-predict-engage/issues) (for non-sensitive security questions)

## Disclosure Policy

When we receive a security vulnerability report:

1. We will work with the reporter to understand and validate the issue
2. We will develop and test a patch
3. We will coordinate public disclosure timing with the reporter
4. We will credit the reporter (unless they prefer to remain anonymous)
5. We will publish a security advisory with details and remediation

Thank you for helping keep our project secure! 🔒

