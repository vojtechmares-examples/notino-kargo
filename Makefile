.PHONY: infra-up
infra-up:
	(cd infrastructure && terraform init && terraform apply -auto-approve)

.PHONY: infra-down
infra-down:
	(cd infrastructure && terraform destroy -auto-approve)

.PHONY: kubeconfig
kubeconfig:
	(cd infrastructure && terraform output -raw kubeconfig > ./kubeconfig.yaml && chmod 600 ./kubeconfig.yaml)
	@echo
	@echo "DO NOT FORGET TO SET KUBECONFIG ENVIRONMENT VARIABLE"
	@echo "export KUBECONFIG=$(pwd)/infrastructure/kubeconfig.yaml"

.PHONY: install-argocd
install-argocd:
	helm repo add argo https://argoproj.github.io/argo-helm --force-update
	helm upgrade --install -n argocd --create-namespace argocd argo/argo-cd --values ./k8s/values/argo-cd.yaml

.PHONY: install-argorollouts
install-argorollouts:
	helm repo add argo https://argoproj.github.io/argo-helm --force-update
	helm upgrade --install -n argo-rollouts --create-namespace argo-rollouts argo/argo-rollouts --values ./k8s/values/argo-rollouts.yaml

.PHONY: install-kargo
install-kargo:
	helm upgrade --install -n kargo --create-namespace kargo oci://ghcr.io/akuity/kargo-charts/kargo --values ./k8s/values/kargo.yaml
