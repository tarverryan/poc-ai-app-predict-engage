#!/bin/bash
# Public Repository Safety Verification Script
# This script checks for secrets, prohibited files, and safety issues before making the repo public

set -euo pipefail

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Counters
ERRORS=0
WARNINGS=0
PASSED=0

# Function to print results
print_result() {
    local status=$1
    local message=$2
    case $status in
        PASS)
            echo -e "${GREEN}✓ PASS:${NC} $message"
            ((PASSED++))
            ;;
        WARN)
            echo -e "${YELLOW}⚠ WARN:${NC} $message"
            ((WARNINGS++))
            ;;
        FAIL)
            echo -e "${RED}✗ FAIL:${NC} $message"
            ((ERRORS++))
            ;;
    esac
}

echo "=========================================="
echo "Public Repository Safety Verification"
echo "=========================================="
echo ""

# Get repository root
REPO_ROOT="$(git rev-parse --show-toplevel)"
cd "$REPO_ROOT"

# 1. Check for secret patterns
echo "1. Checking for secret patterns..."

SECRET_PATTERNS=(
    "AKIA[0-9A-Z]{16}"           # AWS Access Key ID
    "ASIA[0-9A-Z]{16}"           # AWS Temporary Access Key
    "aws_secret_access_key"      # AWS Secret Key (hardcoded)
    "BEGIN PRIVATE KEY"           # Private keys
    "BEGIN RSA PRIVATE KEY"       # RSA private keys
    "BEGIN EC PRIVATE KEY"        # EC private keys
    "xoxp-[0-9A-Z-]{80,}"        # Slack tokens
    "sk-[a-zA-Z0-9]{32,}"        # OpenAI/Stripe keys
    "ghp_[a-zA-Z0-9]{36}"        # GitHub personal access tokens
    "gho_[a-zA-Z0-9]{36}"        # GitHub OAuth tokens
)

FOUND_SECRETS=0
for pattern in "${SECRET_PATTERNS[@]}"; do
    # Exclude test credentials, documentation, test scripts, CI configs, and .actrc
    if git grep -iE "$pattern" -- ':!scripts/testing/*' ':!docs/**' ':!docker-compose.yml' ':!.env.example' ':!.github/workflows/*' ':!.actrc' 2>/dev/null | grep -v "test" | grep -v "example" | grep -v "LocalStack" | grep -v "AWS_SECRET_ACCESS_KEY=test" | grep -v "AWS_ACCESS_KEY_ID=test" > /dev/null; then
        print_result "FAIL" "Found potential secret pattern: $pattern"
        git grep -iE "$pattern" -- ':!scripts/testing/*' ':!docs/**' ':!docker-compose.yml' ':!.env.example' ':!.github/workflows/*' ':!.actrc' 2>/dev/null | grep -v "test" | grep -v "example" | grep -v "LocalStack" | grep -v "AWS_SECRET_ACCESS_KEY=test" | grep -v "AWS_ACCESS_KEY_ID=test" | head -5
        FOUND_SECRETS=1
    fi
done

if [ $FOUND_SECRETS -eq 0 ]; then
    print_result "PASS" "No secret patterns found (excluding test credentials)"
fi

# 2. Check for prohibited files
echo ""
echo "2. Checking for prohibited files..."

PROHIBITED_FILES=(
    ".env"
    "terraform.tfstate"
    "terraform.tfstate.backup"
    "*.pem"
    "*.key"
    "*.p12"
    "*.crt"
    "credentials"
    ".aws/credentials"
    "config.json"
)

FOUND_PROHIBITED=0
for pattern in "${PROHIBITED_FILES[@]}"; do
    if find . -name "$pattern" -not -path "./.git/*" -not -path "./node_modules/*" 2>/dev/null | grep -v ".env.example" > /dev/null; then
        print_result "FAIL" "Found prohibited file: $pattern"
        find . -name "$pattern" -not -path "./.git/*" -not -path "./node_modules/*" 2>/dev/null | grep -v ".env.example"
        FOUND_PROHIBITED=1
    fi
done

if [ $FOUND_PROHIBITED -eq 0 ]; then
    print_result "PASS" "No prohibited files found"
fi

# 3. Check for .env.example
echo ""
echo "3. Checking for .env.example file..."

if [ -f ".env.example" ]; then
    print_result "PASS" ".env.example file exists"
else
    print_result "WARN" ".env.example file not found (recommended but not required)"
fi

# 4. Check for placeholder emails
echo ""
echo "4. Checking for placeholder emails..."

PLACEHOLDER_EMAILS=(
    "yourcompany.com"
    "example.com"
    "placeholder"
    "your-email"
)

FOUND_PLACEHOLDERS=0
for email in "${PLACEHOLDER_EMAILS[@]}"; do
    if git grep -i "$email" -- ':!scripts/verify_public_repo_safety.sh' ':!docs/governance/CONTRIBUTING.md' ':!docs/governance/SECURITY.md' 2>/dev/null | grep -v "example" | grep -v "placeholder" > /dev/null; then
        # Check if it's in a context that needs updating
        if git grep -i "$email" -- ':!scripts/verify_public_repo_safety.sh' 2>/dev/null | grep -E "(contact|email|@)" > /dev/null; then
            print_result "WARN" "Found placeholder email pattern: $email (consider updating to GitHub links)"
            git grep -i "$email" -- ':!scripts/verify_public_repo_safety.sh' 2>/dev/null | grep -E "(contact|email|@)" | head -3
            FOUND_PLACEHOLDERS=1
        fi
    fi
done

if [ $FOUND_PLACEHOLDERS -eq 0 ]; then
    print_result "PASS" "No problematic placeholder emails found"
fi

# 5. Check for hardcoded AWS account IDs
echo ""
echo "5. Checking for hardcoded AWS account IDs..."

# AWS account IDs are 12 digits
if git grep -E "[0-9]{12}" -- ':!docs/**' ':!data/**' ':!reports/**' 2>/dev/null | grep -v "test" | grep -v "example" | grep -E "(arn:aws|account)" > /dev/null; then
    print_result "WARN" "Found potential AWS account ID (verify it's not a real account ID)"
    git grep -E "[0-9]{12}" -- ':!docs/**' ':!data/**' ':!reports/**' 2>/dev/null | grep -v "test" | grep -v "example" | grep -E "(arn:aws|account)" | head -3
else
    print_result "PASS" "No hardcoded AWS account IDs found"
fi

# 6. Check for real API endpoints
echo ""
echo "6. Checking for real API endpoints..."

if git grep -E "https://.*\.execute-api\..*\.amazonaws\.com" -- ':!docs/**' ':!scripts/verify_public_repo_safety.sh' 2>/dev/null | grep -v "example" > /dev/null; then
    print_result "WARN" "Found potential real API endpoint (verify it's not production)"
    git grep -E "https://.*\.execute-api\..*\.amazonaws\.com" -- ':!docs/**' ':!scripts/verify_public_repo_safety.sh' 2>/dev/null | grep -v "example" | head -3
else
    print_result "PASS" "No real API endpoints found"
fi

# 7. Check for LICENSE file
echo ""
echo "7. Checking for LICENSE file..."

if [ -f "LICENSE" ]; then
    print_result "PASS" "LICENSE file exists"
else
    print_result "FAIL" "LICENSE file not found"
fi

# 8. Check for SECURITY.md
echo ""
echo "8. Checking for SECURITY.md file..."

if [ -f "docs/governance/SECURITY.md" ] || [ -f "SECURITY.md" ]; then
    print_result "PASS" "SECURITY.md file exists"
else
    print_result "WARN" "SECURITY.md file not found (recommended)"
fi

# 9. Check for .gitignore
echo ""
echo "9. Checking for .gitignore file..."

if [ -f ".gitignore" ]; then
    # Check if it includes common patterns
    if grep -q "\.env" .gitignore && grep -q "\.tfstate" .gitignore && grep -q "\.pem" .gitignore; then
        print_result "PASS" ".gitignore exists and includes common patterns"
    else
        print_result "WARN" ".gitignore exists but may be missing some patterns"
    fi
else
    print_result "FAIL" ".gitignore file not found"
fi

# 10. Check for README.md
echo ""
echo "10. Checking for README.md file..."

if [ -f "README.md" ]; then
    # Check for important sections
    if grep -qi "disclaimer\|not production\|poc" README.md; then
        print_result "PASS" "README.md exists and mentions POC/disclaimer"
    else
        print_result "WARN" "README.md exists but may be missing POC/disclaimer section"
    fi
else
    print_result "FAIL" "README.md file not found"
fi

# Summary
echo ""
echo "=========================================="
echo "Verification Summary"
echo "=========================================="
echo -e "${GREEN}Passed:${NC} $PASSED"
echo -e "${YELLOW}Warnings:${NC} $WARNINGS"
echo -e "${RED}Errors:${NC} $ERRORS"
echo ""

if [ $ERRORS -eq 0 ] && [ $WARNINGS -eq 0 ]; then
    echo -e "${GREEN}✓ All checks passed! Repository is safe for public release.${NC}"
    exit 0
elif [ $ERRORS -eq 0 ]; then
    echo -e "${YELLOW}⚠ Some warnings found. Review and fix before making public.${NC}"
    exit 0
else
    echo -e "${RED}✗ Errors found. Fix issues before making repository public.${NC}"
    exit 1
fi

