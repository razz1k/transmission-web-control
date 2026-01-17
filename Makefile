.PHONY: help test test-lint test-shellcheck test-integration test-functional test-all install clean docker-test docker-dev docker-dev-stop docker-clean

help: ## Show this help message
	@echo 'Usage: make [target]'
	@echo ''
	@echo 'Available targets:'
	@awk 'BEGIN {FS = ":.*?## "} /^[a-zA-Z_-]+:.*?## / {printf "  %-20s %s\n", $$1, $$2}' $(MAKEFILE_LIST)

install: ## Install dependencies
	npm install

test: test-all ## Run all tests (alias for test-all)

test-all: test-lint test-shellcheck test-integration test-functional ## Run all tests

test-lint: ## Run linting tests
	./scripts/test-lint.sh

test-shellcheck: ## Run shellcheck on installation scripts
	shellcheck release/*.sh || echo "Warning: shellcheck not installed, skipping"

test-integration: ## Run OpenWRT integration tests
	./scripts/test-integration.sh

test-functional: ## Run functional tests with Playwright
	npm run test:functional

test-local: ## Run all tests locally (with optional skip flags)
	./scripts/test-local.sh

docker-test: ## Run tests using Docker Compose
	docker-compose -f docker-compose.test.yml up --build --abort-on-container-exit

docker-dev: ## Start development environment with SSH (port 2222, user: root, pass: root)
	docker-compose -f docker-compose.test.yml --profile dev up -d openwrt-dev
	@echo ""
	@echo "Development environment started!"
	@echo "  SSH:          ssh root@localhost -p 2222 (password: root)"
	@echo "  Transmission: http://localhost:9091/transmission/web/"
	@echo ""
	@echo "Stop with: make docker-dev-stop"

docker-dev-stop: ## Stop development environment
	docker-compose -f docker-compose.test.yml --profile dev down

docker-clean: ## Clean up Docker test containers
	docker-compose -f docker-compose.test.yml --profile dev down -v

clean: ## Clean test artifacts
	rm -rf node_modules
	rm -rf playwright-report
	rm -rf test-results
