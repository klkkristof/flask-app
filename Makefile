.PHONY: help


GREEN  := \033[0;32m
YELLOW := \033[1;33m
NC     := \033[0m

help:
	@echo ""
	@echo "  $(YELLOW)make install$(NC)     - Init installation (for first use)"
	@echo "  $(YELLOW)make start$(NC)       - Minikube start"
	@echo "  $(YELLOW)make stop$(NC)        - Minikube stop"
	@echo "  $(YELLOW)make status$(NC)      - Show status"
	@echo ""
	@echo "  $(YELLOW)make jenkins-url$(NC) - Jenkins URL"
	@echo "  $(YELLOW)make flask-url$(NC)   - Flask URL"
	@echo ""
	@echo "  $(YELLOW)make logs-jenkins$(NC) - Jenkins logs"
	@echo "  $(YELLOW)make logs-flask$(NC)   - Flask logs"
	@echo ""
	@echo "  $(YELLOW)make clean$(NC)       - Clear everything"
	@echo ""



install: 
	@echo "$(GREEN)--Installation init...$(NC)"
	minikube start --driver=docker --memory=4096 --cpus=2
	@echo "$(GREEN)--Applying Kubernetes resources...$(NC)"
	kubectl apply -f k8s/namespace.yaml
	kubectl apply -f k8s/jenkins-pv.yaml
	kubectl apply -f k8s/jenkins-pvc.yaml
	kubectl apply -f k8s/jenkins-serviceaccount.yaml
	kubectl apply -f k8s/jenkins-deployment.yaml
	kubectl apply -f k8s/jenkins-service.yaml
	kubectl apply -f k8s/flask-service.yaml
	@echo "$(YELLOW)--Waiting for Jenkins to be ready...$(NC)"
	kubectl wait --for=condition=ready pod -l app=jenkins -n devops --timeout=300s || true
	@echo ""
	@echo "$(GREEN)Installation finished!$(NC)"
	@echo ""
	@echo "Jenkins URL: http://$$(minikube ip):30080"



start:
	@echo "$(GREEN)Minikube starting...$(NC)"
	minikube start

stop: 
	@echo "$(YELLOW)Minikube stopping...$(NC)"
	minikube stop

restart: stop start



status:
	@echo "$(GREEN)=== Minikube ===$(NC)"
	@minikube status
	@echo ""
	@echo "$(GREEN)=== Pods ===$(NC)"
	@kubectl get pods -n devops
	@echo ""
	@echo "$(GREEN)=== Services ===$(NC)"
	@kubectl get services -n devops



jenkins-url: 
	@echo "$(GREEN)Jenkins URL:$(NC)"
	@minikube service jenkins -n devops --url

flask-url: 
	@echo "$(GREEN)Flask URL:$(NC)"
	@minikube service flask-app -n devops --url 2>/dev/null || echo "Flask offline. Start Jenkins pipeline!"

urls: 
	@minikube service list



logs-jenkins:
	@kubectl logs -f -n devops -l app=jenkins

logs-flask:
	@kubectl logs -f -n devops -l app=flask-app



clean: 
	@echo "$(RED)Deleting namespace...$(NC)"
	@kubectl delete namespace devops 2>/dev/null || true
	@minikube delete
	@echo "$(GREEN)Deleted!$(NC)"



.DEFAULT_GOAL := help
