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
	zarf package create --set AGENT_IMAGE_TAG=$$(zarf version) --confirm

.PHONY: deploy-zarf-package
deploy-zarf-package: ## Deploy the zarf package.
	zarf init --components git-server --confirm -a amd64

.PHONY: publish-zarf-init-package
publish-zarf-init-package: ## Publish the zarf custom init package and skeleton.
	zarf package publish zarf-init-*.tar.zst oci://ghcr.io/defenseunicorns/uds-capability/rook-ceph
	zarf package publish . oci://ghcr.io/defenseunicorns/uds-capability/rook-ceph
	zarf tools registry copy ghcr.io/defenseunicorns/uds-capability/rook-ceph/init:$$(zarf version) ghcr.io/defenseunicorns/uds-capability/rook-ceph/init:$$(zarf version)-$$(jq -r '.["."]' .release-please-manifest.json)

.PHONY: publish-zarf-standard-package
publish-zarf-standard-package: ## Publish the zarf standard package and skeleton.
	cd rook-ceph
	zarf package create --confirm
	zarf package publish zarf-package-*.tar.zst oci://ghcr.io/defenseunicorns/uds-capability
	zarf package publish . oci://ghcr.io/defenseunicorns/uds-capability

.PHONY: remove-zarf-package
remove-zarf-package: ## Remove the zarf package.
	kubectl -n rook-ceph patch cephcluster rook-ceph --type merge -p '{"spec":{"cleanupPolicy":{"confirmation":"yes-really-destroy-data"}}}'
	zarf destroy --confirm
	helm uninstall rook-ceph-cluster -n rook-ceph --wait
	helm uninstall rook-ceph -n rook-ceph --wait

.PHONY: test-zarf-package
test-zarf-package: ## Run a smoke test to validate PVCs work
	cd .github/test-infra/storage
	kubectl apply -f test-manifests.yaml
	kubectl wait --for=jsonpath='{.status.phase}'=Bound -n test pvc/test-pvc
	kubectl wait --for=condition=Ready -n test pod/test-pod --timeout=1m
	kubectl delete pod -n test test-pod
	kubectl delete pvc -n test test-pvc

.PHONY: create-cluster
create-cluster: ## Create a test cluster with terraform
	cd .github/test-infra/rke2
	terraform init -force-copy \
		-backend-config="bucket=uds-ci-state-bucket" \
		-backend-config="key=tfstate/ci/install/uds-rook-$(short_sha)-rke2.tfstate" \
		-backend-config="region=us-west-2" \
		-backend-config="dynamodb_table=uds-ci-state-dynamodb"
	terraform apply -auto-approve

.PHONY: create-dev-cluster
create-dev-cluster: ## Create a test cluster with terraform using dev-rke2.tfvars
	cd .github/test-infra/rke2
	terraform init -force-copy \
		-backend-config="bucket=uds-dev-state-bucket" \
		-backend-config="key=tfstate/uds-rook-$$(openssl rand -hex 3)-rke2.tfstate" \
		-backend-config="region=us-west-2" \
		-backend-config="dynamodb_table=uds-dev-state-dynamodb"
	terraform apply -auto-approve -var-file=dev-rke2.tfvars

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
