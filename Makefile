# Makefile for KIND Kubernetes Demo
# Automates building, deploying, and managing the application

# Variables
PROJECT_NAME := go-demo
IMAGE_NAME := go-app
IMAGE_TAG := latest
REGISTRY := localhost:5001
FULL_IMAGE := $(REGISTRY)/$(IMAGE_NAME):$(IMAGE_TAG)
NAMESPACE := go-demo
CLUSTER_NAME := kind

# Colors for output
CYAN := \033[0;36m
GREEN := \033[0;32m
YELLOW := \033[0;33m
RED := \033[0;31m
NC := \033[0m # No Color

.PHONY: help
help: ## Show this help message
	@echo "$(CYAN)KIND Go Nginx Demo - Makefile Commands$(NC)"
	@echo ""
	@grep -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | sort | awk 'BEGIN {FS = ":.*?## "}; {printf "  $(GREEN)%-20s$(NC) %s\n", $$1, $$2}'
	@echo ""

##@ Cluster Management

.PHONY: cluster-create
cluster-create: ## Create KIND cluster with local registry
	@echo "$(CYAN)Creating KIND cluster...$(NC)"
	@if kind get clusters 2>/dev/null | grep -q "^$(CLUSTER_NAME)$$"; then \
		echo "$(YELLOW)Cluster '$(CLUSTER_NAME)' already exists$(NC)"; \
	else \
		kind create cluster --config kind-config.yaml; \
		echo "$(GREEN)✓ Cluster created$(NC)"; \
	fi
	@echo "$(CYAN)Setting up local registry...$(NC)"
	@chmod +x local-registry.sh
	@./local-registry.sh
	@echo "$(GREEN)✓ Cluster and registry ready!$(NC)"

.PHONY: cluster-delete
cluster-delete: ## Delete KIND cluster
	@echo "$(RED)Deleting KIND cluster...$(NC)"
	@kind delete cluster --name $(CLUSTER_NAME)
	@echo "$(YELLOW)Stopping local registry...$(NC)"
	@docker stop kind-registry 2>/dev/null || true
	@docker rm kind-registry 2>/dev/null || true
	@echo "$(GREEN)✓ Cluster deleted$(NC)"

.PHONY: cluster-info
cluster-info: ## Display cluster information
	@echo "$(CYAN)Cluster Information:$(NC)"
	@kubectl cluster-info --context kind-$(CLUSTER_NAME)
	@echo ""
	@echo "$(CYAN)Nodes:$(NC)"
	@kubectl get nodes
	@echo ""
	@echo "$(CYAN)Registry Status:$(NC)"
	@docker ps -f name=kind-registry --format "table {{.Names}}\t{{.Status}}\t{{.Ports}}"

##@ Build & Push

.PHONY: build
build: ## Build Docker image
	@echo "$(CYAN)Building Docker image...$(NC)"
	@cd app && docker build -t $(IMAGE_NAME):$(IMAGE_TAG) .
	@docker tag $(IMAGE_NAME):$(IMAGE_TAG) $(FULL_IMAGE)
	@echo "$(GREEN)✓ Image built: $(FULL_IMAGE)$(NC)"

.PHONY: push
push: ## Push image to local registry
	@echo "$(CYAN)Pushing image to local registry...$(NC)"
	@docker push $(FULL_IMAGE)
	@echo "$(GREEN)✓ Image pushed: $(FULL_IMAGE)$(NC)"

.PHONY: build-push
build-push: build push ## Build and push image

##@ Deployment

.PHONY: deploy
deploy: ## Deploy application to Kubernetes
	@echo "$(CYAN)Deploying to Kubernetes...$(NC)"
	@kubectl apply -f k8s/namespace.yaml
	@kubectl apply -f k8s/deployment.yaml
	@kubectl apply -f k8s/service.yaml
	@kubectl apply -f k8s/ingress.yaml
	@echo "$(GREEN)✓ Application deployed$(NC)"
	@echo ""
	@echo "$(CYAN)Waiting for pods to be ready...$(NC)"
	@kubectl wait --for=condition=ready pod -l app=go-app -n $(NAMESPACE) --timeout=60s
	@echo "$(GREEN)✓ Pods are ready!$(NC)"
	@make status

.PHONY: redeploy
redeploy: build-push rollout ## Rebuild, push, and rolling restart

.PHONY: rollout
rollout: ## Restart deployment (rolling update)
	@echo "$(CYAN)Rolling restart deployment...$(NC)"
	@kubectl rollout restart deployment/go-app -n $(NAMESPACE)
	@kubectl rollout status deployment/go-app -n $(NAMESPACE)
	@echo "$(GREEN)✓ Rollout complete$(NC)"

##@ Access

.PHONY: port-forward
port-forward: ## Port-forward service to localhost:8080
	@echo "$(CYAN)Port-forwarding service to localhost:8080...$(NC)"
	@echo "$(GREEN)Access the app at: http://localhost:8080$(NC)"
	@echo "$(YELLOW)Press Ctrl+C to stop$(NC)"
	@kubectl port-forward -n $(NAMESPACE) service/go-app-service 8080:80

.PHONY: logs
logs: ## View application logs
	@echo "$(CYAN)Streaming logs (Ctrl+C to stop)...$(NC)"
	@kubectl logs -n $(NAMESPACE) -l app=go-app -f --tail=50

##@ Status & Info

.PHONY: status
status: ## Show deployment status
	@echo "$(CYAN)=== Deployment Status ===$(NC)"
	@kubectl get all -n $(NAMESPACE)
	@echo ""
	@echo "$(CYAN)=== Pod Details ===$(NC)"
	@kubectl get pods -n $(NAMESPACE) -o wide

.PHONY: describe
describe: ## Describe deployment
	@kubectl describe deployment go-app -n $(NAMESPACE)

.PHONY: events
events: ## Show recent events
	@kubectl get events -n $(NAMESPACE) --sort-by='.lastTimestamp'

.PHONY: endpoints
endpoints: ## Show service endpoints
	@echo "$(CYAN)Service Endpoints:$(NC)"
	@kubectl get endpoints -n $(NAMESPACE)

##@ Debugging

.PHONY: shell
shell: ## Open shell in a pod
	@echo "$(CYAN)Opening shell in pod...$(NC)"
	@kubectl exec -it -n $(NAMESPACE) $$(kubectl get pod -n $(NAMESPACE) -l app=go-app -o jsonpath='{.items[0].metadata.name}') -- /bin/sh

.PHONY: debug
debug: ## Show debugging information
	@echo "$(CYAN)=== Pods ===$(NC)"
	@kubectl get pods -n $(NAMESPACE) -o wide
	@echo ""
	@echo "$(CYAN)=== Pod Logs ===$(NC)"
	@kubectl logs -n $(NAMESPACE) -l app=go-app --tail=20
	@echo ""
	@echo "$(CYAN)=== Services ===$(NC)"
	@kubectl get svc -n $(NAMESPACE)
	@echo ""
	@echo "$(CYAN)=== Endpoints ===$(NC)"
	@kubectl get endpoints -n $(NAMESPACE)
	@echo ""
	@echo "$(CYAN)=== Recent Events ===$(NC)"
	@kubectl get events -n $(NAMESPACE) --sort-by='.lastTimestamp' | tail -10

##@ Cleanup

.PHONY: clean
clean: ## Delete all Kubernetes resources
	@echo "$(RED)Deleting all resources...$(NC)"
	@kubectl delete -f k8s/ --ignore-not-found=true
	@echo "$(GREEN)✓ Resources deleted$(NC)"

.PHONY: clean-images
clean-images: ## Remove local Docker images
	@echo "$(RED)Removing Docker images...$(NC)"
	@docker rmi $(IMAGE_NAME):$(IMAGE_TAG) 2>/dev/null || true
	@docker rmi $(FULL_IMAGE) 2>/dev/null || true
	@echo "$(GREEN)✓ Images removed$(NC)"

.PHONY: clean-all
clean-all: clean cluster-delete clean-images ## Delete everything (cluster, resources, images)
	@echo "$(GREEN)✓ Complete cleanup done$(NC)"

##@ Scaling

.PHONY: scale-up
scale-up: ## Scale deployment to 5 replicas
	@echo "$(CYAN)Scaling to 5 replicas...$(NC)"
	@kubectl scale deployment go-app -n $(NAMESPACE) --replicas=5
	@echo "$(GREEN)✓ Scaled up$(NC)"
	@kubectl get pods -n $(NAMESPACE)

.PHONY: scale-down
scale-down: ## Scale deployment to 1 replica
	@echo "$(CYAN)Scaling to 1 replica...$(NC)"
	@kubectl scale deployment go-app -n $(NAMESPACE) --replicas=1
	@echo "$(GREEN)✓ Scaled down$(NC)"
	@kubectl get pods -n $(NAMESPACE)

##@ Testing

.PHONY: test-health
test-health: ## Test health endpoint
	@echo "$(CYAN)Testing health endpoint...$(NC)"
	@kubectl run test-pod --image=curlimages/curl:latest --rm -it --restart=Never -n $(NAMESPACE) -- \
		curl -s http://go-app-service/health | head -20

.PHONY: test-api
test-api: ## Test API endpoint
	@echo "$(CYAN)Testing API endpoint...$(NC)"
	@kubectl run test-pod --image=curlimages/curl:latest --rm -it --restart=Never -n $(NAMESPACE) -- \
		curl -s http://go-app-service/api/info | head -20

##@ Quick Start

.PHONY: up
up: cluster-create build-push deploy ## Complete setup: create cluster, build, and deploy
	@echo ""
	@echo "$(GREEN)========================================$(NC)"
	@echo "$(GREEN)✓ Setup complete!$(NC)"
	@echo "$(GREEN)========================================$(NC)"
	@echo ""
	@echo "$(CYAN)Next steps:$(NC)"
	@echo "  1. Run: $(GREEN)make port-forward$(NC)"
	@echo "  2. Visit: $(GREEN)http://localhost:8080$(NC)"
	@echo "  3. View logs: $(GREEN)make logs$(NC)"
	@echo ""

.PHONY: down
down: clean-all ## Complete teardown: delete everything
	@echo "$(GREEN)✓ Complete teardown finished$(NC)"

# Default target
.DEFAULT_GOAL := help
