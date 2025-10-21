# Pull Request

## Description
<!-- Provide a clear and concise description of your changes -->

## Type of Change
<!-- Check all that apply -->
- [ ] Bug fix (non-breaking change which fixes an issue)
- [ ] New feature (non-breaking change which adds functionality)
- [ ] Breaking change (fix or feature that would cause existing functionality to not work as expected)
- [ ] Documentation update
- [ ] Infrastructure/configuration change
- [ ] Performance improvement
- [ ] Code refactoring
- [ ] Test additions/improvements

## Related Issues
<!-- Link related issues here -->
Closes #
Related to #

## Changes Made
<!-- Summarize the key changes in this PR -->
-
-
-

## Testing
<!-- Describe the tests you ran and how to reproduce them -->

### Unit Tests
- [ ] All existing unit tests pass
- [ ] New unit tests added (if applicable)
- [ ] Test coverage maintained or improved

### Integration Tests
- [ ] Integration tests pass
- [ ] Tested with LocalStack
- [ ] Tested end-to-end pipeline (if applicable)

### Manual Testing
<!-- Describe any manual testing performed -->
1.
2.
3.

## Screenshots/Logs
<!-- If applicable, add screenshots or logs to demonstrate the changes -->

## Checklist
<!-- Check all that apply -->

### Code Quality
- [ ] My code follows the project's style guidelines
- [ ] I have performed a self-review of my own code
- [ ] I have commented my code, particularly in hard-to-understand areas
- [ ] My changes generate no new warnings
- [ ] Code is formatted with Black (Python) and `terraform fmt` (Terraform)
- [ ] Linting passes (flake8, mypy)

### Documentation
- [ ] I have updated the documentation accordingly
- [ ] I have updated `CHANGELOG.md`
- [ ] Docstrings are added/updated (Python)
- [ ] README is updated (if needed)

### Infrastructure & Dependencies
- [ ] Terraform changes validated with `terraform validate`
- [ ] No hardcoded secrets or credentials
- [ ] New dependencies added to requirements.txt (if applicable)
- [ ] Docker image builds successfully (if applicable)

### Security & Compliance
- [ ] No sensitive data in code or logs
- [ ] Security scan passes (tfsec, Trivy)
- [ ] PII handling follows compliance requirements
- [ ] IAM permissions follow least-privilege principle

### Cost & Performance
- [ ] Cost impact analyzed (for infrastructure changes)
- [ ] Performance impact considered
- [ ] No unnecessary resource provisioning

## Deployment Notes
<!-- Any special deployment considerations? -->

### Breaking Changes
<!-- If this is a breaking change, explain the migration path -->

### Rollback Plan
<!-- How can this change be rolled back if needed? -->

## Reviewer Notes
<!-- Any specific areas you'd like reviewers to focus on? -->

---

**By submitting this PR, I confirm that:**
- My contribution is made under the MIT License
- I have read and followed the [Contributing Guidelines](../docs/contributing.md)
- I have tested my changes thoroughly

