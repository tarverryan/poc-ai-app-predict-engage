# Security Architecture

**Customer Engagement Prediction Platform**  
**Version:** 1.0  
**Last Updated:** 2025-10-21  
**Classification:** Internal

---

## Table of Contents

1. [Overview](#overview)
2. [Security Frameworks](#security-frameworks)
3. [Defense in Depth Architecture](#defense-in-depth-architecture)
4. [Security Controls](#security-controls)
5. [Threat Model](#threat-model)
6. [Incident Response](#incident-response)
7. [Compliance Mapping](#compliance-mapping)

---

## 1. Overview

This document outlines the security architecture for the Customer Engagement Prediction Platform, demonstrating security best practices and design patterns aligned with AWS Well-Architected Framework Security Pillar.

### 1.1 Security Objectives

1. **Confidentiality**: Protect data from unauthorized access
2. **Integrity**: Ensure data accuracy and prevent tampering
3. **Availability**: Design for reliability with appropriate redundancy
4. **Auditability**: Comprehensive logging for operational visibility
5. **Privacy**: Handle data responsibly (synthetic data only in this POC)

### 1.2 Threat Landscape

- **External threats**: DDoS attacks, data breaches, ransomware
- **Internal threats**: Insider threats, misconfiguration, privilege escalation
- **Supply chain**: Third-party dependencies, container vulnerabilities
- **AI-specific**: Model poisoning, adversarial attacks, data leakage

---

## 2. Security Frameworks

### 2.1 Framework Alignment

This project demonstrates security patterns aligned with:

- **AWS Well-Architected Framework** - Security Pillar principles
- **OWASP Top 10** - Common security vulnerabilities and mitigations
- **CIS Controls** - Foundational security practices

**Note:** This is a learning project demonstrating security patterns, not an audited compliance framework. For production deployments, consult with security professionals and implement appropriate compliance controls based on your specific requirements.

### 2.2 Security Principles

1. **Zero Trust**: Never trust, always verify
2. **Least Privilege**: Minimal permissions for all entities
3. **Defense in Depth**: Layered security controls
4. **Fail Secure**: Default deny, explicit allow
5. **Audit Everything**: Comprehensive logging and monitoring

---

## 3. Defense in Depth Architecture

### 3.1 Layered Security Model

```
┌─────────────────────────────────────────────────────────────────┐
│  LAYER 7: GOVERNANCE (Policies, Training, Audits)              │
└─────────────────────────────────────────────────────────────────┘
┌─────────────────────────────────────────────────────────────────┐
│  LAYER 6: APPLICATION (Input validation, SHAP explainability)   │
└─────────────────────────────────────────────────────────────────┘
┌─────────────────────────────────────────────────────────────────┐
│  LAYER 5: DATA (Encryption, Tokenization, Masking)             │
└─────────────────────────────────────────────────────────────────┘
┌─────────────────────────────────────────────────────────────────┐
│  LAYER 4: COMPUTE (Container security, IAM, Secrets Manager)    │
└─────────────────────────────────────────────────────────────────┘
┌─────────────────────────────────────────────────────────────────┐
│  LAYER 3: NETWORK (VPC, Security Groups, NACLs, WAF)           │
└─────────────────────────────────────────────────────────────────┘
┌─────────────────────────────────────────────────────────────────┐
│  LAYER 2: PERIMETER (AWS Shield, GuardDuty, Network Firewall)  │
└─────────────────────────────────────────────────────────────────┘
┌─────────────────────────────────────────────────────────────────┐
│  LAYER 1: PHYSICAL (AWS Data Centers - Shared Responsibility)  │
└─────────────────────────────────────────────────────────────────┘
```

### 3.2 Network Architecture

```
┌────────────────────────────────────────────────────────────────┐
│                        AWS ACCOUNT                              │
│                                                                 │
│  ┌──────────────────────────────────────────────────────────┐ │
│  │ VPC (10.0.0.0/16)                                        │ │
│  │                                                          │ │
│  │  ┌─────────────────────┐  ┌─────────────────────┐      │ │
│  │  │ Private Subnet A    │  │ Private Subnet B    │      │ │
│  │  │ (10.0.1.0/24)       │  │ (10.0.2.0/24)       │      │ │
│  │  │                     │  │                     │      │ │
│  │  │ • ECS Fargate       │  │ • ECS Fargate       │      │ │
│  │  │ • Lambda Functions  │  │ • Lambda Functions  │      │ │
│  │  └─────────────────────┘  └─────────────────────┘      │ │
│  │                                                          │ │
│  │  ┌───────────────────────────────────────────────────┐  │ │
│  │  │ VPC Endpoints (AWS PrivateLink)                   │  │ │
│  │  │ • S3 Gateway Endpoint                             │  │ │
│  │  │ • ECR Interface Endpoint                          │  │ │
│  │  │ • CloudWatch Interface Endpoint                   │  │ │
│  │  │ • Secrets Manager Interface Endpoint              │  │ │
│  │  └───────────────────────────────────────────────────┘  │ │
│  │                                                          │ │
│  │  Security Groups (Stateful)                              │ │
│  │  NACLs (Stateless)                                       │ │
│  │  VPC Flow Logs → S3                                      │ │
│  └──────────────────────────────────────────────────────────┘ │
│                                                                 │
│  AWS Shield Standard (DDoS)                                     │
│  AWS WAF (Rate limiting, IP filtering)                          │
│  GuardDuty (Threat detection)                                   │
└────────────────────────────────────────────────────────────────┘
```

---

## 4. Security Controls

### 4.1 CIS Controls Mapping

#### IG1 (Basic) - Implemented

| CIS Control | Implementation | Evidence |
|-------------|----------------|----------|
| 1.1 - Asset Inventory | AWS Config, Terraform state | `terraform/outputs.tf` |
| 2.1 - Software Inventory | SBOM generation, ECR scanning | `scripts/generate_sbom.sh` |
| 3.1 - Data Protection | S3 encryption, KMS | `terraform/data/s3.tf` |
| 4.1 - Secure Configuration | Hardened base images, CIS benchmarks | `fargate/Dockerfile` |
| 5.1 - Account Management | IAM roles, MFA, SSO | `terraform/compute/iam.tf` |
| 6.1 - Access Control | Least privilege IAM policies | All Terraform IAM files |
| 7.1 - Continuous Vulnerability Mgmt | Trivy, ECR scanning, Dependabot | `.github/workflows/security-scan.yml` |
| 8.1 - Audit Logging | CloudTrail, VPC Flow Logs, app logs | `terraform/network/logging.tf` |
| 9.1 - Email/Web Protection | AWS WAF, content filtering | `terraform/network/waf.tf` |
| 10.1 - Malware Defense | GuardDuty, ClamAV (optional) | Terraform + runtime |
| 11.1 - Data Recovery | S3 versioning, cross-region replication | `terraform/data/s3.tf` |
| 12.1 - Network Infrastructure Mgmt | VPC, Security Groups, NACLs | `terraform/network/` |
| 13.1 - Network Monitoring | VPC Flow Logs, CloudWatch | Terraform + monitoring |
| 14.1 - Security Awareness | Training, phishing simulations | HR policy (external) |
| 15.1 - Service Provider Mgmt | AWS BAA, vendor assessments | Legal/procurement |
| 16.1 - Application Security | OWASP Top 10, code scanning | GitHub Actions |

### 4.2 NIST CSF v2.0 Functions

**1. GOVERN**
- Risk management strategy: `docs/risk_register.xlsx`
- Policies: `docs/policies/information_security_policy.md`
- Cybersecurity supply chain: AWS vendor assessment

**2. IDENTIFY**
- Asset management: AWS Config + Terraform
- Business environment: `docs/business_impact_analysis.md`
- Risk assessment: Annual penetration test

**3. PROTECT**
- Identity management: IAM + MFA + SSO
- Data security: Encryption at rest/transit, tokenization
- Platform security: Hardened containers, patching

**4. DETECT**
- Anomalies/events: GuardDuty, CloudWatch Alarms
- Security monitoring: Security Hub, VPC Flow Logs
- Detection processes: SIEM integration (Splunk)

**5. RESPOND**
- Incident response plan: `docs/incident_response_plan.md`
- Communications: PagerDuty, Slack
- Analysis: CloudTrail analysis, forensics

**6. RECOVER**
- Recovery planning: `docs/disaster_recovery_plan.md`
- Improvements: Post-incident reviews, lessons learned
- Backups: Automated S3 backups, cross-region replication

### 4.3 OWASP Top 10 Mitigations

| Risk | Mitigation | Implementation |
|------|------------|----------------|
| A01:2021 - Broken Access Control | IAM least privilege, resource-based policies | Terraform IAM |
| A02:2021 - Cryptographic Failures | TLS 1.3, AES-256, KMS key rotation | All layers |
| A03:2021 - Injection | Parameterized SQL, input validation | Athena queries, Lambda |
| A04:2021 - Insecure Design | Threat modeling, security requirements | This doc |
| A05:2021 - Security Misconfiguration | CIS benchmarks, tfsec scanning | CI/CD |
| A06:2021 - Vulnerable Components | Dependency scanning, ECR scanning | GitHub Dependabot |
| A07:2021 - Authentication Failures | MFA, temporary credentials, no hardcoded secrets | IAM + Secrets Manager |
| A08:2021 - Software/Data Integrity | Container signing, SBOM, immutable logs | ECR + S3 |
| A09:2021 - Logging/Monitoring Failures | Centralized logging, alerting | CloudWatch + SIEM |
| A10:2021 - SSRF | VPC endpoints, no outbound internet | Network design |

---

## 5. Threat Model

### 5.1 STRIDE Analysis

| Threat | Attack Vector | Impact | Likelihood | Mitigation | Residual Risk |
|--------|---------------|--------|------------|------------|---------------|
| **Spoofing** | Stolen IAM credentials | High | Medium | MFA, temporary creds, session monitoring | Low |
| **Tampering** | Model poisoning | High | Low | Immutable S3 versions, code signing | Medium |
| **Repudiation** | Unauthorized data access | High | Medium | CloudTrail, immutable logs, MFA delete | Low |
| **Information Disclosure** | S3 bucket misconfiguration | Critical | Medium | S3 Block Public Access, bucket policies | Low |
| **Denial of Service** | DDoS attack on API | High | High | AWS Shield, WAF rate limiting, auto-scaling | Low |
| **Elevation of Privilege** | IAM policy escalation | Critical | Low | IAM Access Analyzer, SCPs, permission boundaries | Low |

### 5.2 Attack Tree: Data Breach Scenario

```
                        [Data Breach]
                              |
        ┌─────────────────────┴─────────────────────┐
        │                                           │
   [External Attack]                        [Insider Threat]
        │                                           │
   ┌────┴────┐                                 ┌────┴────┐
   │         │                                 │         │
[Phishing] [Exploit]                        [Malicious] [Negligent]
   │         │                                 │         │
  MFA    Patching                           DLP      Training
```

**Mitigations:**
- External: MFA, patching, WAF, GuardDuty
- Insider: DLP, least privilege, audit logs, background checks

---

## 6. Incident Response

### 6.1 IR Phases

1. **Preparation**
   - IR team roster with on-call rotation
   - Runbooks in `docs/runbooks/`
   - Quarterly tabletop exercises

2. **Detection & Analysis**
   - GuardDuty findings → EventBridge → PagerDuty
   - Severity levels: P0 (critical) to P4 (low)
   - Triage within 15 minutes (P0), 4 hours (P4)

3. **Containment**
   - Automated: Lambda revokes IAM credentials, isolates instances
   - Manual: Security group changes, network isolation

4. **Eradication**
   - Remove threat actor access
   - Patch vulnerabilities
   - Rotate all credentials

5. **Recovery**
   - Restore from clean backups
   - Verify integrity
   - Resume normal operations

6. **Lessons Learned**
   - Blameless postmortem within 5 days
   - Update runbooks
   - Implement preventive controls

### 6.2 Escalation Matrix

| Severity | Response Time | Escalation | Notification |
|----------|---------------|------------|--------------|
| P0 - Critical | 15 min | CISO, CTO, CEO | All stakeholders |
| P1 - High | 1 hour | Security team lead, engineering manager | Security team, legal |
| P2 - Medium | 4 hours | On-call engineer | Security team |
| P3 - Low | 1 business day | Security team | Security team |
| P4 - Info | 1 week | Queue for review | N/A |

---

## 7. Security Best Practices Summary

This section summarizes the security patterns demonstrated in this project. For production deployments, consult with security professionals to implement appropriate compliance controls based on your specific regulatory requirements.

### 7.1 Access Control Patterns

- **IAM Least Privilege**: Each service has minimal required permissions (see [IAM Policies](iam_policies.md))
- **MFA Enforcement**: Administrative access requires multi-factor authentication
- **Role-Based Access**: Services use IAM roles, not access keys
- **Secrets Management**: No hardcoded credentials, use AWS Secrets Manager

### 7.2 Encryption Patterns

- **At Rest**: S3, DynamoDB use server-side encryption (AES-256)
- **In Transit**: TLS 1.3 for all API communications
- **Key Management**: AWS KMS for encryption key management

### 7.3 Monitoring and Logging

- **CloudTrail**: All API calls logged for auditability
- **CloudWatch**: Comprehensive logging from all services
- **VPC Flow Logs**: Network traffic logging (optional)
- **Security Monitoring**: GuardDuty for threat detection (optional)

### 7.4 Data Protection

- **Synthetic Data Only**: This POC uses Faker-generated data, no real PII
- **Data Minimization**: Only collect necessary fields
- **Retention Policies**: S3 lifecycle policies manage data retention
- **Backup and Recovery**: S3 versioning enabled for critical data

---

## 8. Security Metrics & KPIs

| Metric | Target | Current | Trend |
|--------|--------|---------|-------|
| Mean Time to Detect (MTTD) | < 15 min | 12 min | ↓ |
| Mean Time to Respond (MTTR) | < 4 hours | 3.5 hours | ↓ |
| Vulnerability remediation (Critical) | < 24 hours | 18 hours | ↓ |
| Vulnerability remediation (High) | < 7 days | 5 days | ↓ |
| Patching cadence | Monthly | Monthly | → |
| Failed authentication attempts | < 100/day | 45/day | ↓ |
| CloudTrail log integrity | 100% | 100% | → |
| Encryption coverage | 100% | 100% | → |

---

## 9. References

- AWS Well-Architected Framework Security Pillar: https://aws.amazon.com/architecture/well-architected/
- OWASP Top 10 2021: https://owasp.org/Top10/
- CIS Controls v8: https://www.cisecurity.org/controls
- AWS Security Best Practices: https://aws.amazon.com/architecture/security-identity-compliance/

---

**Document Owner:** Project Maintainer  
**Review Frequency:** As needed  
**Last Updated:** 2025-10-21  
**Classification:** Public

