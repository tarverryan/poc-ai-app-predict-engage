#!/usr/bin/env python3
"""
Check for Prohibited Protected Class Features in Code

This script enforces AI ethics standards by preventing the use of
prohibited features (race, religion, sexual orientation, etc.) in
ML model training or data processing.

Aligns with:
- IEEE 7010-2020 (Well-being Metrics)
- NIST AI Risk Management Framework
- EU AI Act (High-Risk AI Systems)
- ECOA (Equal Credit Opportunity Act)

Exit codes:
- 0: No violations
- 1: Violations found
"""

import re
import sys
from pathlib import Path
from typing import List, Tuple

# Prohibited features (9 protected classes)
PROHIBITED_FEATURES = [
    "race",
    "ethnicity",
    "national_origin",
    "religion",
    "sexual_orientation",
    "marital_status",
    "disability",
    "political_affiliation",
    "military_status",
]

# Allowed features with conditions (require fairness constraints)
CONDITIONAL_FEATURES = {
    "age": "Must include fairness constraints (no age discrimination)",
    "gender": "Must include fairness constraints (80% rule)",
    "location": "Must include fairness constraints (no redlining)",
}

# Proxy features (high correlation with protected classes)
PROXY_FEATURES = {
    "zip_code": "Proxy for race/ethnicity (redlining risk)",
    "income": "Proxy for protected classes",
    "education_level": "Proxy for race/ethnicity",
    "first_name": "Proxy for race/gender",
    "last_name": "Proxy for race/ethnicity",
}


def check_file(file_path: Path) -> List[Tuple[int, str, str]]:
    """
    Check a Python file for prohibited features.

    Args:
        file_path: Path to Python file

    Returns:
        List of violations (line_number, feature, context)
    """
    violations = []

    try:
        with open(file_path, "r", encoding="utf-8") as f:
            lines = f.readlines()

        for i, line in enumerate(lines, start=1):
            # Skip comments and docstrings
            if line.strip().startswith("#") or '"""' in line or "'''" in line:
                continue

            # Check for prohibited features
            for feature in PROHIBITED_FEATURES:
                # Match feature name in various contexts
                patterns = [
                    rf"\b{feature}\b",  # Exact word
                    rf"['\"].*{feature}.*['\"]",  # In string
                    rf"{feature}_",  # Feature prefix
                    rf"_{feature}\b",  # Feature suffix
                ]

                for pattern in patterns:
                    if re.search(pattern, line, re.IGNORECASE):
                        violations.append((i, feature, line.strip()))
                        break

            # Check for conditional features without fairness constraints
            for feature, requirement in CONDITIONAL_FEATURES.items():
                if re.search(rf"\b{feature}\b", line, re.IGNORECASE):
                    # Look for fairness constraint in next 5 lines
                    context = "".join(lines[max(0, i - 1) : i + 5])
                    if "fairness" not in context.lower():
                        violations.append(
                            (i, feature, f"{line.strip()} (Missing: {requirement})")
                        )

            # Check for proxy features
            for feature, warning in PROXY_FEATURES.items():
                if re.search(rf"\b{feature}\b", line, re.IGNORECASE):
                    # This is a warning, not a blocker
                    print(
                        f"⚠️  {file_path}:{i} - Proxy feature '{feature}': {warning}"
                    )

    except Exception as e:
        print(f"Error reading {file_path}: {e}", file=sys.stderr)

    return violations


def main():
    """Main entry point."""
    # Scan Python files in lambda/ and fargate/ directories
    directories = ["lambda", "fargate"]
    violations = []

    for directory in directories:
        dir_path = Path(directory)
        if not dir_path.exists():
            continue

        for py_file in dir_path.rglob("*.py"):
            # Skip test files and __pycache__
            if "test_" in py_file.name or "__pycache__" in str(py_file):
                continue

            file_violations = check_file(py_file)
            for line_num, feature, context in file_violations:
                violations.append((py_file, line_num, feature, context))

    # Report violations
    if violations:
        print("❌ PROHIBITED PROTECTED CLASS FEATURES DETECTED\n")
        print("The following features violate AI ethics standards:\n")

        for file_path, line_num, feature, context in violations:
            print(f"File: {file_path}:{line_num}")
            print(f"Feature: {feature} (PROHIBITED)")
            print(f"Context: {context}")
            print()

        print("=" * 70)
        print("REQUIRED ACTIONS:")
        print("=" * 70)
        print("1. Remove prohibited features from model training")
        print("2. If feature is essential, justify in ADR (Architecture Decision Record)")
        print("3. Add fairness constraints (80% rule, demographic parity)")
        print("4. Document in AI Ethics Framework (docs/ai_ethics_framework.md)")
        print()
        print(f"Total violations: {len(violations)}")
        print()
        print("References:")
        print("- IEEE 7010-2020: https://standards.ieee.org/standard/7010-2020.html")
        print("- NIST AI RMF: https://www.nist.gov/itl/ai-risk-management-framework")
        print("- EU AI Act: https://artificialintelligenceact.eu/")
        print()

        sys.exit(1)

    else:
        print("✅ No prohibited protected class features detected")
        sys.exit(0)


if __name__ == "__main__":
    main()

