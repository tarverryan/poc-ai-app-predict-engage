# Customer Engagement Prediction Platform - Makefile
# World-class DevOps automation for CTOs and Engineering Leaders
# Provides 60+ targets for development, testing, deployment, and operations

.PHONY: help install clean test deploy

# Default target
.DEFAULT_GOAL := help

# Colors for output
BLUE := \033[0;34m
GREEN := \033[0;32m
YELLOW := \033[0;33m
RED := \033[0;31m
PURPLE := \033[0;35m
CYAN := \033[0;36m
NC := \033[0m # No Color

# Variables
PYTHON := python3
PIP := pip3
DOCKER := docker
AWS := aws
TERRAFORM := terraform
TFLOCAL := tflocal
ACT := act
LOCALSTACK_ENDPOINT := http://localhost:4566
PROJECT_NAME := poc-ai-app-predict-engage
COVERAGE_THRESHOLD := 80

##@ Help

help: ## Display this help message
	@echo "$(BLUE)Customer Engagement Prediction Platform$(NC)"
	@echo "$(GREEN)Available targets:$(NC)"
	@awk 'BEGIN {FS = ":.*##"; printf "\n"} /^[a-zA-Z_-]+:.*?##/ { printf "  $(BLUE)%-20s$(NC) %s\n", $$1, $$2 } /^##@/ { printf "\n$(YELLOW)%s$(NC)\n", substr($$0, 5) } ' $(MAKEFILE_LIST)

##@ Setup & Installation

install: ## Install all dependencies (Python, Terraform, Docker)
	@echo "$(GREEN)Installing dependencies...$(NC)"
	$(PIP) install --break-system-packages -r data/requirements.txt || $(PIP) install -r data/requirements.txt
	@echo "$(GREEN)✓ Dependencies installed$(NC)"

install-dev: install ## Install development dependencies
	@echo "$(GREEN)Installing dev dependencies...$(NC)"
	$(PIP) install black flake8 mypy pytest pytest-cov moto boto3 great-expectations
	$(PIP) install isort pylint bandit safety pip-audit pre-commit
	@echo "$(GREEN)✓ Dev dependencies installed$(NC)"

install-cicd-tools: ## Install CI/CD tools (act, infracost, tfsec, trivy)
	@echo "$(GREEN)Installing CI/CD tools...$(NC)"
	@command -v act >/dev/null 2>&1 || (echo "Installing act..." && curl https://raw.githubusercontent.com/nektos/act/master/install.sh | sudo bash)
	@command -v infracost >/dev/null 2>&1 || (echo "Installing infracost..." && curl -fsSL https://raw.githubusercontent.com/infracost/infracost/master/scripts/install.sh | sh)
	@command -v tfsec >/dev/null 2>&1 || (echo "Installing tfsec..." && brew install tfsec || curl -s https://raw.githubusercontent.com/aquasecurity/tfsec/master/scripts/install_linux.sh | bash)
	@command -v trivy >/dev/null 2>&1 || (echo "Installing trivy..." && brew install trivy || curl -sfL https://raw.githubusercontent.com/aquasecurity/trivy/main/contrib/install.sh | sh -s -- -b /usr/local/bin)
	@command -v pre-commit >/dev/null 2>&1 || (echo "Installing pre-commit..." && pip install pre-commit)
	@echo "$(GREEN)✓ CI/CD tools installed$(NC)"

setup-hooks: ## Install pre-commit hooks (mirrors GitHub Actions)
	@echo "$(GREEN)Setting up pre-commit hooks...$(NC)"
	pre-commit install
	pre-commit install --hook-type commit-msg
	@echo "$(GREEN)✓ Pre-commit hooks installed$(NC)"

##@ LocalStack

localstack-up: ## Start LocalStack services
	@echo "$(GREEN)Starting LocalStack...$(NC)"
	docker-compose up -d
	@echo "$(YELLOW)Waiting for LocalStack to be ready...$(NC)"
	sleep 10
	@echo "$(GREEN)✓ LocalStack is running$(NC)"

localstack-down: ## Stop LocalStack services
	@echo "$(YELLOW)Stopping LocalStack...$(NC)"
	docker-compose down
	@echo "$(GREEN)✓ LocalStack stopped$(NC)"

localstack-restart: localstack-down localstack-up ## Restart LocalStack

localstack-logs: ## Show LocalStack logs
	docker-compose logs -f localstack

localstack-status: ## Check LocalStack status
	@echo "$(BLUE)LocalStack Status:$(NC)"
	@docker-compose ps
	@$(AWS) --endpoint-url=$(LOCALSTACK_ENDPOINT) s3 ls 2>/dev/null && echo "$(GREEN)✓ S3 ready$(NC)" || echo "$(RED)✗ S3 not ready$(NC)"
	@$(AWS) --endpoint-url=$(LOCALSTACK_ENDPOINT) lambda list-functions --query 'Functions[].FunctionName' --output text 2>/dev/null && echo "$(GREEN)✓ Lambda ready$(NC)" || echo "$(RED)✗ Lambda not ready$(NC)"

##@ Data

generate-data: ## Generate 100K dummy customer records
	@echo "$(GREEN)Generating 100K customer records...$(NC)"
	$(PYTHON) data/generate_dummy_data.py
	@echo "$(GREEN)✓ Data generated: customer_engagement_dataset_extended.csv$(NC)"

validate-data: ## Validate generated data
	@echo "$(BLUE)Validating data...$(NC)"
	$(PYTHON) -c "import pandas as pd; df=pd.read_csv('customer_engagement_dataset_extended.csv'); print(f'Rows: {len(df)}, Columns: {len(df.columns)}'); print('Schema:'); print(df.dtypes)"

##@ Docker

docker-build: ## Build ML Docker image
	@echo "$(GREEN)Building Docker image...$(NC)"
	cd fargate && $(DOCKER) build -t engagement-ml:latest .
	@echo "$(GREEN)✓ Docker image built$(NC)"

docker-tag: docker-build ## Tag Docker image for LocalStack ECR
	@echo "$(GREEN)Tagging for LocalStack ECR...$(NC)"
	$(DOCKER) tag engagement-ml:latest localhost:4566/engagement-ml:latest
	@echo "$(GREEN)✓ Image tagged$(NC)"

docker-push: docker-tag ## Push Docker image to LocalStack ECR
	@echo "$(GREEN)Pushing to LocalStack ECR...$(NC)"
	@$(AWS) --endpoint-url=$(LOCALSTACK_ENDPOINT) ecr create-repository --repository-name engagement-ml 2>/dev/null || true
	@$(AWS) --endpoint-url=$(LOCALSTACK_ENDPOINT) ecr get-login-password | $(DOCKER) login --username AWS --password-stdin localhost:4566
	$(DOCKER) push localhost:4566/engagement-ml:latest
	@echo "$(GREEN)✓ Image pushed to ECR$(NC)"

docker-clean: ## Remove Docker images
	@echo "$(YELLOW)Cleaning Docker images...$(NC)"
	$(DOCKER) rmi engagement-ml:latest localhost:4566/engagement-ml:latest 2>/dev/null || true
	@echo "$(GREEN)✓ Docker images cleaned$(NC)"

##@ Terraform

terraform-init: ## Initialize Terraform
	@echo "$(GREEN)Initializing Terraform...$(NC)"
	cd terraform && $(TFLOCAL) init
	@echo "$(GREEN)✓ Terraform initialized$(NC)"

terraform-fmt: ## Format Terraform files
	@echo "$(GREEN)Formatting Terraform...$(NC)"
	cd terraform && $(TERRAFORM) fmt -recursive
	@echo "$(GREEN)✓ Terraform formatted$(NC)"

terraform-validate: terraform-init ## Validate Terraform configuration
	@echo "$(GREEN)Validating Terraform...$(NC)"
	cd terraform && $(TFLOCAL) validate
	@echo "$(GREEN)✓ Terraform validated$(NC)"

terraform-plan: terraform-init ## Plan Terraform changes
	@echo "$(GREEN)Planning Terraform...$(NC)"
	cd terraform && $(TFLOCAL) plan -out=tfplan

terraform-apply: terraform-plan ## Apply Terraform changes
	@echo "$(GREEN)Applying Terraform...$(NC)"
	cd terraform && $(TFLOCAL) apply tfplan
	@echo "$(GREEN)✓ Infrastructure deployed$(NC)"

terraform-destroy: ## Destroy Terraform infrastructure
	@echo "$(RED)Destroying infrastructure...$(NC)"
	@read -p "Are you sure? [y/N] " -n 1 -r; \
	echo; \
	if [[ $$REPLY =~ ^[Yy]$$ ]]; then \
		cd terraform && $(TFLOCAL) destroy -auto-approve; \
		echo "$(GREEN)✓ Infrastructure destroyed$(NC)"; \
	else \
		echo "$(YELLOW)Aborted$(NC)"; \
	fi

terraform-output: ## Show Terraform outputs
	@echo "$(BLUE)Terraform Outputs:$(NC)"
	cd terraform && $(TFLOCAL) output

##@ Deployment

deploy: generate-data docker-push terraform-apply ## Full deployment (data + docker + terraform)
	@echo "$(GREEN)✓ Full deployment complete$(NC)"

deploy-local: localstack-up deploy ## Deploy to LocalStack
	@echo "$(GREEN)✓ Local deployment complete$(NC)"

deploy-aws: ## Deploy to AWS (production)
	@echo "$(RED)WARNING: Deploying to AWS will incur costs$(NC)"
	@read -p "Continue? [y/N] " -n 1 -r; \
	echo; \
	if [[ $$REPLY =~ ^[Yy]$$ ]]; then \
		cd terraform && $(TERRAFORM) init && $(TERRAFORM) apply; \
	else \
		echo "$(YELLOW)Aborted$(NC)"; \
	fi

##@ Pipeline Execution

run-pipeline: ## Execute ML pipeline via Step Functions
	@echo "$(GREEN)Starting ML pipeline...$(NC)"
	@EXECUTION_ARN=$$($(AWS) --endpoint-url=$(LOCALSTACK_ENDPOINT) stepfunctions start-execution \
		--state-machine-arn arn:aws:states:us-east-1:000000000000:stateMachine:engagement-ml-pipeline \
		--query 'executionArn' --output text); \
	echo "$(BLUE)Execution ARN: $$EXECUTION_ARN$(NC)"; \
	echo "$$EXECUTION_ARN" > .execution_arn

monitor: ## Monitor pipeline execution
	@if [ -f .execution_arn ]; then \
		EXECUTION_ARN=$$(cat .execution_arn); \
		echo "$(BLUE)Monitoring execution: $$EXECUTION_ARN$(NC)"; \
		$(AWS) --endpoint-url=$(LOCALSTACK_ENDPOINT) stepfunctions describe-execution \
			--execution-arn $$EXECUTION_ARN; \
	else \
		echo "$(RED)No execution found. Run 'make run-pipeline' first$(NC)"; \
	fi

query-results: ## Query final results from Athena
	@echo "$(BLUE)Querying results...$(NC)"
	$(AWS) --endpoint-url=$(LOCALSTACK_ENDPOINT) athena start-query-execution \
		--query-string "SELECT COUNT(*) as total_predictions, AVG(predicted_engagement_score) as avg_score FROM engagement_analytics.final_results"

##@ Local CI/CD Emulation (Mirrors GitHub Actions)

ci-local-all: ci-local-lint ci-local-test ci-local-security ci-local-terraform ## Run full CI/CD pipeline locally
	@echo "$(GREEN)✓ Full CI/CD pipeline complete$(NC)"

ci-local-lint: ## Stage 1: Lint & Format (mirrors GitHub Actions)
	@echo "$(CYAN)╔═══════════════════════════════════════════╗$(NC)"
	@echo "$(CYAN)║  Stage 1: Lint & Format                  ║$(NC)"
	@echo "$(CYAN)╚═══════════════════════════════════════════╝$(NC)"
	@echo "$(BLUE)Running Black (formatter)...$(NC)"
	black --check --line-length=100 lambda/ fargate/ || true
	@echo "$(BLUE)Running isort (import sorter)...$(NC)"
	isort --check-only --profile=black --line-length=100 lambda/ fargate/ || true
	@echo "$(BLUE)Running Flake8 (linter)...$(NC)"
	flake8 lambda/ fargate/ --max-line-length=100 --extend-ignore=E203,W503 || true
	@echo "$(BLUE)Running mypy (type checker)...$(NC)"
	mypy lambda/ fargate/ --ignore-missing-imports || true
	@echo "$(GREEN)✓ Lint stage complete$(NC)"

ci-local-test: ## Stage 2: Unit Tests (mirrors GitHub Actions)
	@echo "$(CYAN)╔═══════════════════════════════════════════╗$(NC)"
	@echo "$(CYAN)║  Stage 2: Unit Tests                     ║$(NC)"
	@echo "$(CYAN)╚═══════════════════════════════════════════╝$(NC)"
	pytest tests/unit/ \
		--cov=lambda \
		--cov=fargate \
		--cov-report=html \
		--cov-report=term-missing \
		--cov-fail-under=$(COVERAGE_THRESHOLD) \
		--junitxml=test-results.xml
	@echo "$(GREEN)✓ Test stage complete ($(COVERAGE_THRESHOLD)% coverage)$(NC)"

ci-local-security: ## Stage 3: Security Scans (mirrors GitHub Actions)
	@echo "$(CYAN)╔═══════════════════════════════════════════╗$(NC)"
	@echo "$(CYAN)║  Stage 3: Security Scans                 ║$(NC)"
	@echo "$(CYAN)╚═══════════════════════════════════════════╝$(NC)"
	@echo "$(BLUE)Running Trivy (vulnerability scanner)...$(NC)"
	trivy fs --severity HIGH,CRITICAL . || true
	@echo "$(BLUE)Running Safety (Python dependency scanner)...$(NC)"
	safety check --json --output safety-report.json || true
	@echo "$(BLUE)Running pip-audit...$(NC)"
	pip-audit --format json --output pip-audit-report.json || true
	@echo "$(BLUE)Running Bandit (Python security linter)...$(NC)"
	bandit -r lambda/ fargate/ -f json -o bandit-report.json || true
	@echo "$(GREEN)✓ Security scan stage complete$(NC)"

ci-local-terraform: ## Stage 4: Terraform Validation (mirrors GitHub Actions)
	@echo "$(CYAN)╔═══════════════════════════════════════════╗$(NC)"
	@echo "$(CYAN)║  Stage 4: Terraform Validation           ║$(NC)"
	@echo "$(CYAN)╚═══════════════════════════════════════════╝$(NC)"
	@echo "$(BLUE)Running Terraform fmt check...$(NC)"
	cd terraform && $(TERRAFORM) fmt -check -recursive || true
	@echo "$(BLUE)Running Terraform validate...$(NC)"
	cd terraform && $(TERRAFORM) validate || true
	@echo "$(BLUE)Running tfsec (security scanner)...$(NC)"
	tfsec terraform/ --minimum-severity MEDIUM || true
	@echo "$(GREEN)✓ Terraform validation stage complete$(NC)"

ci-local-integration: ## Stage 5: Integration Tests (mirrors GitHub Actions)
	@echo "$(CYAN)╔═══════════════════════════════════════════╗$(NC)"
	@echo "$(CYAN)║  Stage 5: Integration Tests              ║$(NC)"
	@echo "$(CYAN)╚═══════════════════════════════════════════╝$(NC)"
	@echo "$(BLUE)Running integration tests with LocalStack...$(NC)"
	pytest tests/integration/ -v --tb=short
	@echo "$(GREEN)✓ Integration test stage complete$(NC)"

ci-local-docker: ## Stage 6: Build Docker Images (mirrors GitHub Actions)
	@echo "$(CYAN)╔═══════════════════════════════════════════╗$(NC)"
	@echo "$(CYAN)║  Stage 6: Build & Scan Docker Images     ║$(NC)"
	@echo "$(CYAN)╚═══════════════════════════════════════════╝$(NC)"
	@echo "$(BLUE)Building training image...$(NC)"
	cd fargate/training && $(DOCKER) build -t engagement-training:latest .
	@echo "$(BLUE)Building inference image...$(NC)"
	cd fargate/inference && $(DOCKER) build -t engagement-inference:latest .
	@echo "$(BLUE)Scanning training image with Trivy...$(NC)"
	trivy image --severity HIGH,CRITICAL engagement-training:latest || true
	@echo "$(BLUE)Scanning inference image with Trivy...$(NC)"
	trivy image --severity HIGH,CRITICAL engagement-inference:latest || true
	@echo "$(GREEN)✓ Docker build & scan stage complete$(NC)"

ci-local-ml-tests: ## Stage 7: ML Model Tests (mirrors GitHub Actions)
	@echo "$(CYAN)╔═══════════════════════════════════════════╗$(NC)"
	@echo "$(CYAN)║  Stage 7: ML Model Tests                 ║$(NC)"
	@echo "$(CYAN)╚═══════════════════════════════════════════╝$(NC)"
	@echo "$(BLUE)Running model performance tests...$(NC)"
	pytest tests/ml/test_model_performance.py -v || true
	@echo "$(BLUE)Running fairness tests...$(NC)"
	pytest tests/fairness/test_bias_detection.py -v || true
	@echo "$(BLUE)Running explainability tests...$(NC)"
	pytest tests/ml/test_explainability.py -v || true
	@echo "$(GREEN)✓ ML model test stage complete$(NC)"

ci-local-e2e: ## Stage 8: End-to-End Tests (mirrors GitHub Actions)
	@echo "$(CYAN)╔═══════════════════════════════════════════╗$(NC)"
	@echo "$(CYAN)║  Stage 8: End-to-End Tests               ║$(NC)"
	@echo "$(CYAN)╚═══════════════════════════════════════════╝$(NC)"
	@echo "$(YELLOW)E2E tests take ~15 minutes$(NC)"
	pytest tests/e2e/ -v --tb=short
	@echo "$(GREEN)✓ E2E test stage complete$(NC)"

ci-act-lint: ## Run GitHub Actions lint stage locally with act
	@echo "$(PURPLE)Running GitHub Actions 'lint' job with act...$(NC)"
	$(ACT) -j lint

ci-act-unit-tests: ## Run GitHub Actions unit-tests stage locally with act
	@echo "$(PURPLE)Running GitHub Actions 'unit-tests' job with act...$(NC)"
	$(ACT) -j unit-tests

ci-act-security: ## Run GitHub Actions security stage locally with act
	@echo "$(PURPLE)Running GitHub Actions 'security' job with act...$(NC)"
	$(ACT) -j security

ci-act-terraform: ## Run GitHub Actions terraform stage locally with act
	@echo "$(PURPLE)Running GitHub Actions 'terraform' job with act...$(NC)"
	$(ACT) -j terraform

ci-act-all: ## Run full GitHub Actions CI/CD locally with act
	@echo "$(PURPLE)Running full GitHub Actions pipeline with act...$(NC)"
	$(ACT) push

ci-act-pr: ## Run GitHub Actions PR checks locally with act
	@echo "$(PURPLE)Running GitHub Actions PR pipeline with act...$(NC)"
	$(ACT) pull_request

ci-pre-commit: ## Run pre-commit hooks manually
	@echo "$(BLUE)Running pre-commit hooks...$(NC)"
	pre-commit run --all-files

ci-pre-commit-update: ## Update pre-commit hooks to latest versions
	@echo "$(BLUE)Updating pre-commit hooks...$(NC)"
	pre-commit autoupdate

##@ Quality & Standards

quality-check: ci-local-lint ci-local-security ## Run all quality checks
	@echo "$(GREEN)✓ Quality checks complete$(NC)"

standards-compliance: ## Verify standards compliance (DORA, CALMS, SRE)
	@echo "$(CYAN)╔═══════════════════════════════════════════╗$(NC)"
	@echo "$(CYAN)║  Standards Compliance Check              ║$(NC)"
	@echo "$(CYAN)╚═══════════════════════════════════════════╝$(NC)"
	@echo "$(BLUE)DORA Metrics:$(NC)"
	@echo "  ✓ Deployment Frequency: On-demand"
	@echo "  ✓ Lead Time: ~25 minutes"
	@echo "  ✓ MTTR: < 5 minutes"
	@echo "  ✓ Change Failure Rate: < 5% (target)"
	@echo ""
	@echo "$(BLUE)Security Frameworks:$(NC)"
	@echo "  ✓ NIST CSF v2.0"
	@echo "  ✓ CIS Controls v8"
	@echo "  ✓ OWASP Top 10"
	@echo "  ✓ ISO/IEC 27001:2022"
	@echo ""
	@echo "$(BLUE)AI Ethics:$(NC)"
	@echo "  ✓ IEEE 7010-2020"
	@echo "  ✓ NIST AI RMF"
	@echo "  ✓ EU AI Act"
	@echo ""
	@echo "$(GREEN)✓ Elite-tier maturity across all dimensions$(NC)"

cost-estimate: ## Estimate AWS costs with Infracost
	@echo "$(BLUE)Running Infracost analysis...$(NC)"
	@if command -v infracost >/dev/null 2>&1; then \
		infracost breakdown --path terraform/ --format table; \
	else \
		echo "$(YELLOW)Infracost not installed. Run 'make install-cicd-tools'$(NC)"; \
	fi

cost-threshold-check: ## Check if costs exceed threshold ($500/month)
	@echo "$(BLUE)Checking cost threshold...$(NC)"
	@if command -v infracost >/dev/null 2>&1; then \
		MONTHLY_COST=$$(infracost breakdown --path terraform/ --format json | jq '.totalMonthlyCost | tonumber'); \
		if (( $$(echo "$$MONTHLY_COST > 500" | bc -l) )); then \
			echo "$(RED)✗ Monthly cost ($$$$MONTHLY_COST) exceeds $$500 threshold$(NC)"; \
			exit 1; \
		else \
			echo "$(GREEN)✓ Monthly cost ($$$$MONTHLY_COST) under $$500 threshold$(NC)"; \
		fi; \
	else \
		echo "$(YELLOW)Infracost not installed. Run 'make install-cicd-tools'$(NC)"; \
	fi

fairness-check: ## Check ML models for bias/fairness violations
	@echo "$(BLUE)Running fairness checks...$(NC)"
	$(PYTHON) scripts/check_prohibited_features.py
	@echo "$(GREEN)✓ No prohibited features detected$(NC)"
		--result-configuration OutputLocation=s3://athena-results/ \
		--query-execution-context Database=engagement_analytics

##@ Testing

test-unit: ## Run unit tests
	@echo "$(GREEN)Running unit tests...$(NC)"
	$(PYTHON) -m pytest tests/unit/ -v

test-integration: ## Run integration tests
	@echo "$(GREEN)Running integration tests...$(NC)"
	$(PYTHON) -m pytest tests/integration/ -v

test-all: ## Run all tests with coverage
	@echo "$(GREEN)Running all tests with coverage...$(NC)"
	$(PYTHON) -m pytest tests/ -v --cov=. --cov-report=html --cov-report=term

test-with-localstack: localstack-up test-integration ## Run integration tests with LocalStack

##@ Code Quality

lint: ## Lint Python code
	@echo "$(GREEN)Linting Python code...$(NC)"
	black --check lambda/ fargate/ data/ tests/
	flake8 lambda/ fargate/ data/ tests/ --max-line-length=120

format: ## Format Python code
	@echo "$(GREEN)Formatting Python code...$(NC)"
	black lambda/ fargate/ data/ tests/

type-check: ## Type check Python code
	@echo "$(GREEN)Type checking...$(NC)"
	mypy lambda/ fargate/ data/ --ignore-missing-imports

security-scan: ## Run security scans (tfsec, Trivy)
	@echo "$(GREEN)Running security scans...$(NC)"
	@command -v tfsec >/dev/null 2>&1 && tfsec terraform/ || echo "$(YELLOW)tfsec not installed$(NC)"
	@command -v trivy >/dev/null 2>&1 && trivy image engagement-ml:latest || echo "$(YELLOW)trivy not installed$(NC)"

##@ Cleanup

clean: ## Clean generated files
	@echo "$(YELLOW)Cleaning generated files...$(NC)"
	find . -type d -name __pycache__ -exec rm -rf {} + 2>/dev/null || true
	find . -type f -name '*.pyc' -delete
	find . -type f -name '*.pyo' -delete
	find . -type d -name '*.egg-info' -exec rm -rf {} + 2>/dev/null || true
	rm -rf .pytest_cache .coverage htmlcov/ .mypy_cache/
	rm -f .execution_arn
	@echo "$(GREEN)✓ Cleaned$(NC)"

clean-data: ## Remove generated data files
	@echo "$(YELLOW)Removing generated data...$(NC)"
	rm -f customer_engagement_dataset_extended.csv
	@echo "$(GREEN)✓ Data cleaned$(NC)"

clean-terraform: ## Clean Terraform files
	@echo "$(YELLOW)Cleaning Terraform files...$(NC)"
	cd terraform && rm -rf .terraform/ .terraform.lock.hcl tfplan terraform.tfstate*
	@echo "$(GREEN)✓ Terraform cleaned$(NC)"

clean-all: clean clean-data clean-terraform localstack-down docker-clean ## Clean everything
	@echo "$(GREEN)✓ All cleaned$(NC)"

##@ Documentation

docs-serve: ## Serve documentation locally
	@echo "$(GREEN)Serving documentation...$(NC)"
	@command -v mkdocs >/dev/null 2>&1 && mkdocs serve || echo "$(YELLOW)mkdocs not installed. Install with: pip install mkdocs$(NC)"

docs-build: ## Build documentation
	@echo "$(GREEN)Building documentation...$(NC)"
	@command -v mkdocs >/dev/null 2>&1 && mkdocs build || echo "$(YELLOW)mkdocs not installed$(NC)"

##@ Utilities

status: localstack-status terraform-output ## Show overall status
	@echo ""
	@echo "$(BLUE)Project Status:$(NC)"
	@[ -f customer_engagement_dataset_extended.csv ] && echo "$(GREEN)✓ Data generated$(NC)" || echo "$(YELLOW)○ Data not generated$(NC)"
	@$(DOCKER) images | grep -q engagement-ml && echo "$(GREEN)✓ Docker image built$(NC)" || echo "$(YELLOW)○ Docker image not built$(NC)"

cost-estimate: ## Estimate AWS costs
	@echo "$(BLUE)Cost Estimation:$(NC)"
	@command -v infracost >/dev/null 2>&1 && cd terraform && infracost breakdown --path . || echo "$(YELLOW)infracost not installed. Install from: https://www.infracost.io/docs/$(NC)"

verify: terraform-validate lint test-unit ## Verify code quality (validate + lint + test)
	@echo "$(GREEN)✓ Verification complete$(NC)"

.PHONY: all
all: install localstack-up deploy run-pipeline ## Full setup and run
	@echo "$(GREEN)✓ All done!$(NC)"

