# AWS S3 Manager - Development Makefile

.PHONY: help install test lint build deploy clean dev-deploy k8s-status

# Configuration
IMAGE_NAME := aws-s3-manager
NAMESPACE := aws-s3-manager
PORT := 30080

help: ## Show this help message
	@echo "AWS S3 Manager - Available Commands:"
	@echo "===================================="
	@grep -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | sort | awk 'BEGIN {FS = ":.*?## "}; {printf "  \033[36m%-15s\033[0m %s\n", $$1, $$2}'

install: ## Install dependencies
	npm ci

test: ## Run tests
	npm test || echo "Tests not configured"

lint: ## Run linting
	npm run lint || echo "Linting not configured"

build: ## Build Docker image
	docker build -t $(IMAGE_NAME):latest .

dev-deploy: build ## Quick deployment for development
	@echo "🚀 Quick development deployment..."
	@kubectl set image deployment/aws-s3-manager-app aws-s3-manager=$(IMAGE_NAME):latest -n $(NAMESPACE)
	@kubectl rollout status deployment/aws-s3-manager-app -n $(NAMESPACE) --timeout=120s
	@echo "✅ Deployment completed!"
	@echo "🌐 Access: http://localhost:$(PORT)"

deploy: ## Full CI/CD deployment
	./scripts/build-and-deploy.sh

k8s-setup: ## Setup Kubernetes deployment
	./deploy-k8s.sh

k8s-status: ## Check Kubernetes status
	@echo "📊 Kubernetes Status:"
	@kubectl get all -n $(NAMESPACE)
	@echo ""
	@echo "🌐 Application URL: http://localhost:$(PORT)"

k8s-logs: ## View application logs
	kubectl logs -f deployment/aws-s3-manager-app -n $(NAMESPACE)

k8s-clean: ## Clean up Kubernetes resources
	kubectl delete namespace $(NAMESPACE) || echo "Namespace not found"

jenkins-setup: ## Setup Jenkins CI/CD
	./setup-jenkins.sh

clean: ## Clean up Docker images
	docker image prune -f
	docker system prune -f

dev: ## Start development server locally
	npm run dev

# Monitoring commands
monitor: ## Monitor application
	@echo "📊 Monitoring AWS S3 Manager..."
	@while true; do \
		clear; \
		echo "=== Kubernetes Status ==="; \
		kubectl get pods -n $(NAMESPACE); \
		echo ""; \
		echo "=== Service Status ==="; \
		kubectl get svc -n $(NAMESPACE); \
		echo ""; \
		echo "=== Application Health ==="; \
		curl -s http://localhost:$(PORT)/api/debug-env | head -3 || echo "Application not responding"; \
		echo ""; \
		echo "Press Ctrl+C to stop monitoring..."; \
		sleep 5; \
	done

# Utility commands
check-health: ## Check application health
	@curl -s http://localhost:$(PORT)/api/debug-env || echo "Application not accessible"

restart: ## Restart the application
	kubectl rollout restart deployment/aws-s3-manager-app -n $(NAMESPACE)

scale: ## Scale the application (usage: make scale REPLICAS=3)
	kubectl scale deployment/aws-s3-manager-app --replicas=${REPLICAS:-2} -n $(NAMESPACE)