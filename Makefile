# Skydive Forecast - Makefile

.PHONY: help start stop logs test build clean status

.DEFAULT_GOAL := help

help: ## Show available commands
	@echo "Usage: make [target]"
	@echo ""
	@echo "Available targets:"
	@grep -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | awk 'BEGIN {FS = ":.*?## "}; {printf "  %-15s %s\n", $$1, $$2}'

start: ## Start all services
	docker-compose up -d

stop: ## Stop all services
	docker-compose down

logs: ## Follow logs of all services
	docker-compose logs -f

test: ## Run tests for all services
	@for dir in ../skydive-forecast-*/; do \
		if [ -f "$$dir/pom.xml" ]; then \
			echo "Testing: $$dir"; \
			(cd "$$dir" && mvn test -q) || exit 1; \
		fi \
	done

build: ## Build all Docker images
	docker-compose build

status: ## Show status of containers
	docker-compose ps

clean: ## Stop and remove containers and volumes
	docker-compose down -v
