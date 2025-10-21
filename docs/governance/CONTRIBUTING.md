# Contributing Guidelines

Thank you for considering contributing to the Customer Engagement Prediction Platform! 🎉

## Table of Contents

- [Code of Conduct](#code-of-conduct)
- [Getting Started](#getting-started)
- [Development Workflow](#development-workflow)
- [Coding Standards](#coding-standards)
- [Testing Requirements](#testing-requirements)
- [Pull Request Process](#pull-request-process)
- [Security](#security)
- [AI Ethics](#ai-ethics)

---

## Code of Conduct

This project adheres to a Code of Conduct. By participating, you are expected to uphold this code. Please report unacceptable behavior to [conduct@yourcompany.com].

See [CODE_OF_CONDUCT.md](CODE_OF_CONDUCT.md) for details.

---

## Getting Started

### Prerequisites

- Python 3.11+
- Docker & Docker Compose
- AWS CLI configured
- Terraform 1.5+
- Git

### Setup Development Environment

```bash
# 1. Fork and clone the repository
git clone https://github.com/yourusername/poc-ai-app-predict-engage.git
cd poc-ai-app-predict-engage

# 2. Create virtual environment
python -m venv venv
source venv/bin/activate  # Windows: venv\Scripts\activate

# 3. Install dependencies
pip install -r requirements.txt
pip install -r requirements-dev.txt  # Development dependencies

# 4. Install pre-commit hooks
pre-commit install

# 5. Run tests to verify setup
pytest
```

---

## Development Workflow

### 1. Create Feature Branch

```bash
git checkout -b feature/your-feature-name
```

Branch naming convention:
- `feature/` - New features
- `fix/` - Bug fixes
- `docs/` - Documentation changes
- `refactor/` - Code refactoring
- `test/` - Test additions/changes
- `chore/` - Build/tooling changes

### 2. Make Changes

- Write clean, well-documented code
- Follow coding standards (see below)
- Add tests for new functionality
- Update documentation as needed

### 3. Test Your Changes

```bash
# Run all tests
pytest

# Run with coverage (must be >80%)
pytest --cov=. --cov-report=html

# Run linters
black .
flake8
mypy .
bandit -r .
```

### 4. Commit Changes

Use conventional commit messages:

```
<type>: <description>

[optional body]

[optional footer]
```

Types:
- `feat`: New feature
- `fix`: Bug fix
- `docs`: Documentation
- `style`: Code style (formatting, etc.)
- `refactor`: Code refactoring
- `test`: Adding/updating tests
- `chore`: Build, tooling, dependencies

Examples:
```
feat: add engagement prediction model

Implements XGBoost model for predicting user engagement
with 82% accuracy (R² = 0.82).

Closes #123
```

### 5. Push and Create Pull Request

```bash
git push origin feature/your-feature-name
```

Then create a PR on GitHub following the PR template.

---

## Coding Standards

### Python

**Style**: Follow PEP 8 with Black formatter

```bash
# Format code
black .

# Check style
flake8

# Type checking
mypy .
```

**Code Quality Rules**:
- Maximum line length: 100 characters
- Use type hints for all functions
- Write docstrings for all public functions/classes (Google style)
- No `print()` statements (use logging)
- No hardcoded credentials or secrets
- Use f-strings for string formatting
- Prefer comprehensions over loops (where readable)

**Example**:
```python
def calculate_engagement_score(
    sessions: int,
    duration: float,
    interactions: int
) -> float:
    """Calculate user engagement score.
    
    Args:
        sessions: Number of sessions in last 7 days
        duration: Average session duration in minutes
        interactions: Number of interactions (likes, comments, shares)
    
    Returns:
        Engagement score (0.0 to 1.0)
    
    Raises:
        ValueError: If inputs are negative
    """
    if any(x < 0 for x in [sessions, duration, interactions]):
        raise ValueError("All inputs must be non-negative")
    
    # Calculate weighted score
    score = (sessions * 0.3 + duration * 0.4 + interactions * 0.3) / 100
    return min(score, 1.0)
```

### Terraform

**Style**: Use `terraform fmt`

```bash
terraform fmt -recursive
```

**Standards**:
- Use modules for reusability
- Tag all resources
- Use variables for configuration
- Document inputs/outputs
- Use remote state
- Enable encryption by default

### SQL

**Style**: Uppercase keywords, snake_case for identifiers

```sql
SELECT 
    customer_id,
    engagement_score,
    DATE(created_at) AS signup_date
FROM 
    customers
WHERE 
    engagement_score > 0.5
ORDER BY 
    engagement_score DESC;
```

---

## Testing Requirements

### Test Coverage

- **Minimum**: 80% code coverage
- **Target**: 90%+ coverage
- All new features must include tests

### Test Types

**1. Unit Tests** (`tests/unit/`)
- Test individual functions/classes
- Mock external dependencies
- Fast execution (<1ms per test)

**2. Integration Tests** (`tests/integration/`)
- Test component interactions
- Use test databases/services
- Moderate execution (<100ms per test)

**3. End-to-End Tests** (`tests/e2e/`)
- Test full workflows
- Use LocalStack for AWS services
- Slower execution (OK to be <10s per test)

**4. Security Tests** (`tests/security/`)
- Vulnerability scanning
- Penetration testing
- Secrets detection

**5. Fairness Tests** (`tests/fairness/`)
- Bias detection (80% rule)
- Demographic parity checks
- Protected class validation

### Running Tests

```bash
# All tests
pytest

# Specific test file
pytest tests/unit/test_analytics.py

# Specific test function
pytest tests/unit/test_analytics.py::test_calculate_engagement

# With coverage
pytest --cov=. --cov-report=html

# Fast tests only (skip slow integration tests)
pytest -m "not slow"
```

---

## Pull Request Process

### Before Submitting

- ✅ All tests pass (`pytest`)
- ✅ Code coverage ≥80% (`pytest --cov`)
- ✅ No linting errors (`flake8`, `black --check`, `mypy`)
- ✅ No security issues (`bandit`, `safety check`)
- ✅ Documentation updated
- ✅ CHANGELOG.md updated (under `[Unreleased]`)

### PR Checklist

Use the PR template (`.github/PULL_REQUEST_TEMPLATE.md`):

```markdown
## Description
[Describe your changes]

## Type of Change
- [ ] Bug fix (non-breaking change fixing an issue)
- [ ] New feature (non-breaking change adding functionality)
- [ ] Breaking change (fix or feature causing existing functionality to not work as expected)
- [ ] Documentation update

## Testing
- [ ] Unit tests added/updated
- [ ] Integration tests added/updated
- [ ] All tests pass locally
- [ ] Code coverage ≥80%

## Security
- [ ] No hardcoded secrets
- [ ] Input validation added
- [ ] Security tests pass
- [ ] Bandit scan clean

## AI Ethics (if applicable)
- [ ] No bias introduced
- [ ] Fairness tests pass
- [ ] Model is explainable
- [ ] No protected class discrimination

## Checklist
- [ ] Code follows style guidelines
- [ ] Self-review completed
- [ ] Documentation updated
- [ ] CHANGELOG.md updated
- [ ] No new warnings
```

### Review Process

1. **Automated Checks**: GitHub Actions run tests, linting, security scans
2. **Code Review**: At least 1 approval required from maintainers
3. **Security Review**: For security-sensitive changes
4. **AI Ethics Review**: For ML model changes
5. **Merge**: Squash and merge (keep history clean)

---

## Security

### Reporting Security Issues

**DO NOT** open public issues for security vulnerabilities.

See [SECURITY.md](SECURITY.md) for reporting process.

### Security Best Practices

- ✅ Never commit secrets, API keys, passwords
- ✅ Use AWS Secrets Manager for credentials
- ✅ Validate all user inputs
- ✅ Use parameterized SQL queries
- ✅ Keep dependencies updated
- ✅ Follow principle of least privilege

---

## AI Ethics

### Bias Prevention

When working with ML models:

1. **No Protected Classes**: Never use race, religion, gender as features
2. **Fairness Testing**: Run bias detection tests
3. **Explainability**: Provide SHAP values, feature importance
4. **Human Oversight**: Document decision processes
5. **Continuous Monitoring**: Check for bias drift

### Required Tests for ML Changes

```python
# tests/fairness/test_model_fairness.py

def test_no_gender_bias(model, test_data):
    """Ensure model doesn't discriminate by gender."""
    male_predictions = model.predict(test_data[test_data['gender'] == 'Male'])
    female_predictions = model.predict(test_data[test_data['gender'] == 'Female'])
    
    # 80% rule: ratio should be 0.8 to 1.25
    ratio = male_predictions.mean() / female_predictions.mean()
    assert 0.8 <= ratio <= 1.25, f"Gender bias detected: ratio={ratio}"

def test_demographic_parity(model, test_data):
    """Ensure equal opportunity across demographics."""
    # Test implementation
    pass
```

---

## Questions?

- **General**: Open a GitHub Discussion
- **Bugs**: Create a GitHub Issue
- **Security**: See SECURITY.md
- **Ethics**: Contact [ethics@yourcompany.com]

Thank you for contributing! 🙏

