.ONESHELL: # Single shell per target

######################
# Make Targets
######################
.PHONY: help
help: ## Show this help message.
	@grep -E '^[a-zA-Z_/-]+:.*?## .*$$' $(MAKEFILE_LIST) \
		| sort \
		| awk 'BEGIN {FS = ":.*?## "; printf "\nUsage:\n"}; {printf "  %-15s %s\n", $$1, $$2}'
	@echo

.PHONY: create-zarf-package
create-zarf-package: ## Build the zarf package.
	zarf package create $(extra_create_args) --confirm

.PHONY: deploy-zarf-package
deploy-zarf-package: ## Deploy the zarf package.
	zarf init --confirm

.PHONY: publish-zarf-init-package
publish-zarf-init-package: ## Publish the zarf init package and skeleton.
	zarf package publish zarf-package-*.tar.zst oci://ghcr.io/defenseunicorns/uds-capability/rook-ceph
	zarf package publish . oci://ghcr.io/defenseunicorns/uds-capability/rook-ceph

.PHONY: remove-zarf-package
remove-zarf-package: ## Remove the zarf package.
	kubectl delete pod -n test test-pod --ignore-not-found
	kubectl delete pvc -n test test-pvc --ignore-not-found
	zarf destroy --confirm

.PHONY: test-zarf-package
test-zarf-package: ## Run a smoke test to validate PVCs work
	cd .github/test-infra/storage
	kubectl apply -f test-manifests.yaml
	kubectl wait --for=jsonpath='{.status.phase}'=Bound -n test pvc/test-pvc
	kubectl wait --for=condition=Ready -n test pod/test-pod --timeout=1m

.PHONY: create-cluster
create-cluster: ## Create a test cluster with terraform
	cd .github/test-infra/rke2
	terraform init -force-copy \
		-backend-config="bucket=uds-ci-state-bucket" \
		-backend-config="key=tfstate/ci/install/uds-rook-$(short_sha)-rke2.tfstate" \
		-backend-config="region=us-west-2" \
		-backend-config="dynamodb_table=uds-ci-state-dynamodb"
	terraform apply -auto-approve
	kubectl apply -f https://raw.githubusercontent.com/rancher/local-path-provisioner/v0.0.24/deploy/local-path-storage.yaml
	kubectl patch storageclass local-path -p '{"metadata": {"annotations":{"storageclass.kubernetes.io/is-default-class":"true"}}}'

.PHONY: create-dev-cluster
create-dev-cluster: ## Create a test cluster with terraform using dev-rke2.tfvars
	cd .github/test-infra/rke2
	terraform init -force-copy \
		-backend-config="bucket=uds-dev-state-bucket" \
		-backend-config="key=tfstate/uds-rook-$$(openssl rand -hex 3)-rke2.tfstate" \
		-backend-config="region=us-west-2" \
		-backend-config="dynamodb_table=uds-dev-state-dynamodb"
	terraform apply -auto-approve -var-file=dev-rke2.tfvars
	kubectl apply -f https://raw.githubusercontent.com/rancher/local-path-provisioner/v0.0.24/deploy/local-path-storage.yaml
	kubectl patch storageclass local-path -p '{"metadata": {"annotations":{"storageclass.kubernetes.io/is-default-class":"true"}}}'

.PHONY: debug-output
debug-output: ## Debug Output for help in CI
	kubectl get pod -A
	kubectl get cephcluster -A
	kubectl get cephblockpool -A
	kubectl get cephfilesystem -A
	kubectl get cephobjectstore -A

.PHONY: delete-cluster
delete-cluster: ## Delete the test cluster with terraform
	cd .github/test-infra/rke2
	terraform destroy -auto-approve

.PHONY: delete-dev-cluster
delete-dev-cluster: ## Delete the test cluster with terraform using dev-rke2.tfvars
	cd .github/test-infra/rke2
	terraform destroy -auto-approve -var-file=dev-rke2.tfvars

.PHONY: dev-deploy
dev-deploy: create-dev-cluster create-zarf-package deploy-zarf-package ## Create cluster and deploy package for dev

.PHONY: test-dev-e2e
test-dev-e2e: create-dev-cluster create-zarf-package deploy-zarf-package test-zarf-package delete-dev-cluster ## Run an e2e test for dev
