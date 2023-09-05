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
	zarf package deploy zarf-package-*.tar.zst --confirm

.PHONY: publish-zarf-package
publish-zarf-package: ## Publish the zarf package and skeleton.
	zarf package publish zarf-package-*.tar.zst oci://ghcr.io/defenseunicorns/packages
	zarf package publish . oci://ghcr.io/defenseunicorns/packages

.PHONY: zarf-init
zarf-init: ## Zarf init.
	zarf init --storage-class=csi-hostpath-sc --confirm

.PHONY: create-cluster
create-cluster: ## Create a test cluster with minkube
	minikube start --disk-size=20g --nodes 3 --driver docker
	minikube addons enable volumesnapshots
	minikube addons enable csi-hostpath-driver
	kubectl patch storageclass csi-hostpath-sc -p '{"metadata": {"annotations":{"storageclass.kubernetes.io/is-default-class":"true"}}}'

.PHONY: debug-output
debug-output: ## Debug Output for help in CI
	kubectl get pod -A
	kubectl get cephcluster -A
	kubectl get cephblockpool -A
	kubectl get cephfilesystem -A
	kubectl get cephobjectstore -A

.PHONY: stop-cluster
stop-cluster: ## Stop the test cluster
	minikube stop

.PHONY: delete-cluster
delete-cluster: ## Delete the test cluster
	minikube delete
