# Public Repository Safety Checklist

**Customer Engagement Prediction Platform**  
**Version:** 1.0  
**Last Updated:** 2025-10-21  
**Classification:** Public

---

## Overview

Use this checklist before making the repository public. Run the automated verification script first, then complete the manual checks.

---

## Automated Verification

### Step 1: Run Verification Script

```bash
./scripts/verify_public_repo_safety.sh
```

**Expected Result:** All checks pass (0 errors, 0 warnings)

**If errors found:**
- Fix all errors before proceeding
- Re-run script until all errors are resolved

**If warnings found:**
- Review warnings and fix if applicable
- Some warnings may be acceptable (document why)

---

## Manual Checklist

### 1. Secrets & Credential Hygiene

- [ ] **No real AWS credentials in code**
  - [ ] No `AKIA` access keys (except test values for LocalStack)
  - [ ] No `ASIA` temporary access keys
  - [ ] No hardcoded `aws_secret_access_key` values
  - [ ] All test credentials clearly marked as "test" or "LocalStack"

- [ ] **No API keys or tokens**
  - [ ] No OpenAI API keys (`sk-*`)
  - [ ] No Slack tokens (`xoxp-*`)
  - [ ] No GitHub tokens (`ghp_*`, `gho_*`)
  - [ ] No other third-party API keys

- [ ] **No private keys or certificates**
  - [ ] No `.pem` files
  - [ ] No `.key` files
  - [ ] No `.p12` files
  - [ ] No `.crt` files (unless public certificates)

- [ ] **Environment variables documented**
  - [ ] `.env.example` file exists with all variables
  - [ ] All variables have descriptions
  - [ ] Dummy placeholders used (not real values)
  - [ ] AWS Secrets Manager usage documented

- [ ] **No state files committed**
  - [ ] No `terraform.tfstate` files
  - [ ] No `terraform.tfstate.backup` files
  - [ ] `.gitignore` includes `*.tfstate*`

---

### 2. No Private/Customer Data

- [ ] **No PII (Personally Identifiable Information)**
  - [ ] No real names, emails, phone numbers
  - [ ] No addresses or locations
  - [ ] No user IDs or internal IDs
  - [ ] All data is synthetic (uses Faker)

- [ ] **No real datasets**
  - [ ] No production data files
  - [ ] All sample data is clearly labeled as synthetic
  - [ ] Data generation scripts use Faker

- [ ] **No sensitive screenshots**
  - [ ] No AWS console screenshots with account IDs
  - [ ] No screenshots with real credentials
  - [ ] All screenshots use mock data

---

### 3. AWS Account Safety

- [ ] **IAM policies documented**
  - [ ] All wildcard policies (`Resource = "*"`) documented
  - [ ] Warnings added for production use
  - [ ] See `docs/security/iam_policies.md`

- [ ] **Least privilege noted**
  - [ ] Documentation explains why wildcards are used (POC only)
  - [ ] Production hardening guidance provided
  - [ ] See `docs/security/required_permissions.md`

- [ ] **No hardcoded account IDs**
  - [ ] No real AWS account IDs in code
  - [ ] All ARNs use variables or placeholders

---

### 4. Dependency Safety

- [ ] **Lockfiles present**
  - [ ] `requirements.txt` files with pinned versions
  - [ ] `package-lock.json` or `pnpm-lock.yaml` (if using Node.js)
  - [ ] `poetry.lock` (if using Poetry)

- [ ] **Security scanning documented**
  - [ ] README includes security section
  - [ ] Instructions for `pip-audit` or `npm audit`
  - [ ] Dependency scanning process documented

- [ ] **No deprecated dependencies**
  - [ ] All dependencies are maintained
  - [ ] Security vulnerabilities addressed
  - [ ] Deprecated packages replaced or noted

---

### 5. Licensing & Attribution

- [ ] **LICENSE file present**
  - [ ] MIT or Apache-2.0 license (or other open source license)
  - [ ] Copyright notice correct
  - [ ] License is valid and complete

- [ ] **Third-party assets**
  - [ ] All images/icons are permitted for public use
  - [ ] AWS architecture icons follow AWS brand guidelines
  - [ ] Attribution provided where required

---

### 6. "Not Production" Disclaimers

- [ ] **README includes disclaimer**
  - [ ] Explicit "POC / Learning Project" statement
  - [ ] Warning about security hardening
  - [ ] Note about IAM wildcard policies
  - [ ] Sandbox account recommendation

- [ ] **Documentation includes warnings**
  - [ ] Cost warnings in relevant docs
  - [ ] Security warnings in IAM policy docs
  - [ ] Production hardening guidance

---

### 7. Cost Safety

- [ ] **Cost documentation**
  - [ ] Cost analysis document exists
  - [ ] Cost safeguards documented
  - [ ] See `docs/deployment/cost_safeguards.md`

- [ ] **Cost warnings**
  - [ ] README includes cost warning
  - [ ] Budget setup instructions provided
  - [ ] Sandbox account recommendation

---

### 8. Observability & Operations

- [ ] **Logs/metrics documented**
  - [ ] CloudWatch log groups documented
  - [ ] Custom metrics namespace documented
  - [ ] See `docs/frameworks/observability_monitoring.md`

- [ ] **Troubleshooting guide**
  - [ ] Common issues documented
  - [ ] Where to find errors documented
  - [ ] See `docs/guides/troubleshooting.md`

---

### 9. Repository Quality

- [ ] **README completeness**
  - [ ] Clear description of project
  - [ ] Prerequisites listed
  - [ ] Quick start instructions
  - [ ] Project status note
  - [ ] Links to documentation

- [ ] **Governance docs**
  - [ ] `CONTRIBUTING.md` exists
  - [ ] `CODE_OF_CONDUCT.md` exists
  - [ ] `SECURITY.md` exists
  - [ ] No placeholder emails (use GitHub links)

- [ ] **Documentation structure**
  - [ ] Architecture diagrams
  - [ ] Developer guide
  - [ ] Deployment guides
  - [ ] Security documentation

---

### 10. Final Verification

- [ ] **Run verification script**
  ```bash
  ./scripts/verify_public_repo_safety.sh
  ```
  - [ ] All checks pass (0 errors)

- [ ] **Test in incognito browser**
  - [ ] Open repository URL in incognito mode
  - [ ] README renders correctly
  - [ ] All links work (not paywalled)
  - [ ] Documentation is readable

- [ ] **Review git history**
  - [ ] No secrets in commit history
  - [ ] No sensitive data in old commits
  - [ ] Consider using `git filter-branch` or BFG if needed

- [ ] **Final review**
  - [ ] All checklist items completed
  - [ ] All documentation reviewed
  - [ ] Ready for public release

---

## Pre-Release Steps

1. **Run automated verification**
   ```bash
   ./scripts/verify_public_repo_safety.sh
   ```

2. **Complete manual checklist**
   - Go through each section above
   - Check off all items
   - Fix any issues found

3. **Test repository**
   - Clone repository in fresh directory
   - Follow README instructions
   - Verify everything works

4. **Final review**
   - Review all documentation
   - Test all links
   - Verify no secrets in code

5. **Make public**
   - Update repository visibility to public
   - Monitor for issues
   - Respond to security reports promptly

---

## Post-Release Monitoring

After making the repository public:

- [ ] **Monitor for security issues**
  - Check GitHub Security tab
  - Review dependency alerts
  - Respond to security reports

- [ ] **Monitor for issues**
  - Check GitHub Issues
  - Review pull requests
  - Respond to questions

- [ ] **Update documentation**
  - Fix any broken links
  - Update based on feedback
  - Keep documentation current

---

## Emergency Response

If secrets are discovered after release:

1. **Immediately rotate credentials**
   - Rotate all exposed credentials
   - Revoke API keys
   - Change passwords

2. **Remove from repository**
   - Remove secrets from code
   - Use `git filter-branch` to remove from history
   - Force push (coordinate with team)

3. **Notify affected parties**
   - Notify security team
   - Review access logs
   - Assess impact

4. **Document incident**
   - Document what was exposed
   - Document remediation steps
   - Update security procedures

---

## References

- [Verification Script](../../scripts/verify_public_repo_safety.sh) - Automated safety checks
- [IAM Policies](../security/iam_policies.md) - IAM policy documentation
- [Secrets Management](../security/secrets_management.md) - Secrets management guide
- [Cost Safeguards](cost_safeguards.md) - Cost control measures
- [Troubleshooting Guide](../guides/troubleshooting.md) - Common issues and solutions

---

## Questions?

For questions about this checklist:
- Review the verification script output
- Check individual documentation files
- See [Security Policy](../governance/SECURITY.md) for security questions

