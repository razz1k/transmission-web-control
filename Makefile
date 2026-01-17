.PHONY: help test test-lint test-shellcheck test-integration test-functional test-all install install-hooks clean docker-test docker-dev docker-dev-arm64 docker-dev-stop docker-ssh docker-clean docker-shellcheck docker-lint

help: ## Show this help message
	@echo 'Usage: make [target]'
	@echo ''
	@echo 'Available targets:'
	@awk 'BEGIN {FS = ":.*?## "} /^[a-zA-Z_-]+:.*?## / {printf "  %-20s %s\n", $$1, $$2}' $(MAKEFILE_LIST)

install: ## Install dependencies
	npm install

install-hooks: ## Install git hooks for pre-push validation
	git config core.hooksPath .githooks
	@echo "Git hooks installed. Pre-push hook will run shellcheck before push."

test: test-all ## Run all tests (alias for test-all)

test-all: test-lint test-shellcheck test-integration test-functional ## Run all tests

test-lint: ## Run linting tests
	./scripts/test-lint.sh

test-shellcheck: ## Run shellcheck on installation scripts (local)
	@if command -v shellcheck >/dev/null 2>&1; then \
		shellcheck -x release/*.sh; \
	else \
		echo "shellcheck not installed locally, use: make docker-shellcheck"; \
	fi

test-integration: ## Run OpenWRT integration tests
	./scripts/test-integration.sh

test-functional: ## Run functional tests with Playwright
	npm run test:functional

test-local: ## Run all tests locally (with optional skip flags)
	./scripts/test-local.sh

docker-test: ## Run tests using Docker Compose
	docker compose -f docker-compose.test.yml up --build --abort-on-container-exit

docker-dev: ## Start development environment (x86_64, OpenWRT 24.10)
	docker compose -f docker-compose.test.yml --profile dev up -d openwrt-dev
	@echo ""
	@echo "Development environment started (x86_64)!"
	@echo "  SSH:          make docker-ssh"
	@echo "  Transmission: http://localhost:9091/transmission/web/"
	@echo ""
	@echo "Stop with: make docker-dev-stop"

docker-dev-arm64: ## Start ARM64 dev environment for Routerich AX3000 (256 MB RAM)
	@echo "Setting up QEMU for ARM64 emulation..."
	@echo "Note: Requires qemu-user-static package or Docker binfmt setup"
	@if [ ! -f /proc/sys/fs/binfmt_misc/qemu-aarch64 ]; then \
		echo "QEMU aarch64 not registered. Trying Docker binfmt..."; \
		docker run --rm --privileged tonistiigi/binfmt --install arm64 || \
		docker run --rm --privileged multiarch/qemu-user-static --reset -p yes || \
		echo "WARNING: Install qemu-user-static: sudo apt-get install qemu-user-static binfmt-support"; \
	fi
	docker compose -f docker-compose.test.yml --profile dev-arm64 up -d openwrt-dev-arm64
	@echo ""
	@echo "ARM64 development environment started!"
	@echo "  Target device: Routerich AX3000 (mediatek/filogic)"
	@echo "  Memory limit:  256 MB (hardware constraint)"
	@echo "  SSH:           make docker-ssh"
	@echo "  Web:           http://localhost:9091/transmission/web/"
	@echo ""
	@echo "Stop with: make docker-dev-stop"

docker-dev-stop: ## Stop development environment
	docker compose -f docker-compose.test.yml --profile dev --profile dev-arm64 down

docker-ssh: ## Connect to dev container via SSH
	ssh -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null -i .ssh/test_key -p 2222 root@localhost

docker-clean: ## Clean up Docker test containers
	docker compose -f docker-compose.test.yml --profile dev down -v

docker-shellcheck: ## Run shellcheck via Docker
	docker compose -f docker-compose.lint.yml run --rm shellcheck

docker-lint: ## Run all linters via Docker
	docker compose -f docker-compose.lint.yml run --rm lint-all

clean: ## Clean test artifacts
	rm -rf node_modules
	rm -rf playwright-report
	rm -rf test-results
