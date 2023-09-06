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
	zarf package deploy zarf-package-*.tar.zst --set device_filter="nvme1n1" --confirm

.PHONY: publish-zarf-package
publish-zarf-package: ## Publish the zarf package and skeleton.
	zarf package publish zarf-package-*.tar.zst oci://ghcr.io/defenseunicorns/packages
	zarf package publish . oci://ghcr.io/defenseunicorns/packages

.PHONY: zarf-init
zarf-init: ## Zarf init.
	zarf init --storage-class=csi-hostpath-sc --confirm

.PHONY: create-cluster # TODO: Make this work for local/dev AWS account
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
