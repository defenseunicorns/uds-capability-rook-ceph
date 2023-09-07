#!/bin/bash

short_sha=$(git rev-parse --short HEAD)
dev_terraform=""
extra_create_args=""

set -e
script_dir=$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )
infra_dir=${script_dir}/../.github/test-infra

######################
# Functions
######################

show_help() {
  echo
  echo "Available targets are:"
  echo "  show-help: Show this help message"
  echo "  create-zarf-package: Create the zarf package"
  echo "  deploy-zarf-package: Deploy the zarf package"
  echo "  publish-zarf-package: Publish the zarf package and skeleton"
  echo "  test-zarf-package: Run a test on the zarf package functionality"
  echo "  remove-zarf-package: Remove the zarf package from the cluster"
  echo "  zarf-init: Perform a zarf init on the cluster"
  echo "  create-cloud-cluster: Create a cluster using the dev/CI terraform"
  echo "  debug-output: Show some debug output for the attached cluster"
  echo "  delete-cloud-cluster: Delete the cluster using dev/CI terraform"
  echo "  dev-deploy: Create cluster, package, and deploy it"
  echo "  test-dev-e2e: Run the end-to-end workflow copying CI"
  echo
  echo "Modifier flags available:"
  echo "  --zarf-create-args <args>: Pass in additional args for the create-zarf-package (ex: --zarf-create-args '--skip-sbom')"
  echo "  --dev-terraform: Use the dev-rke2.tfvars file for the terraform cluster create/deleteå"
  echo
}

create_zarf_package() {
  zarf package create ${extra_create_args} --confirm
}

deploy_zarf_package() {
  zarf package deploy zarf-package-*.tar.zst --confirm
}

publish_zarf_package() {
  zarf package publish zarf-package-*.tar.zst oci://ghcr.io/defenseunicorns/packages
  zarf package publish . oci://ghcr.io/defenseunicorns/packages
}

test_zarf_package() {
  cd ${infra_dir}/storage
  kubectl apply -f test-manifests.yaml
  kubectl wait --for=jsonpath='{.status.phase}'=Bound -n test pvc/test-pvc
  kubectl wait --for=condition=Ready -n test pod/test-pod --timeout=1m
}

remove_zarf_package() {
  zarf package remove zarf-package-*.tar.zst --confirm
}

zarf_init() {
  zarf tools download-init -a amd64
  zarf init --confirm -a amd64
}

create_cloud_cluster() {
  cd ${infra_dir}/rke2
  if [[ $dev_terraform == "true" ]]; then
    terraform init -force-copy \
      -backend-config="bucket=uds-dev-state-bucket" \
      -backend-config="key=tfstate/dev/uds-rook-${short_sha}-rke2.tfstate" \
      -backend-config="region=us-west-2" \
      -backend-config="dynamodb_table=uds-dev-state-dynamodb"
    terraform apply -auto-approve -var-file=dev-rke2.tfvars
  else
    terraform init -force-copy \
      -backend-config="bucket=uds-ci-state-bucket" \
      -backend-config="key=tfstate/ci/install/uds-rook-${short_sha}-rke2.tfstate" \
      -backend-config="region=us-west-2" \
      -backend-config="dynamodb_table=uds-ci-state-dynamodb"
    terraform apply -auto-approve
  fi
  kubectl apply -f https://raw.githubusercontent.com/rancher/local-path-provisioner/v0.0.24/deploy/local-path-storage.yaml
  kubectl patch storageclass local-path -p '{"metadata": {"annotations":{"storageclass.kubernetes.io/is-default-class":"true"}}}'
}

debug_output() {
  kubectl get pod -A
  kubectl get cephcluster -A
  kubectl get cephblockpool -A
  kubectl get cephfilesystem -A
  kubectl get cephobjectstore -A
}

delete_cloud_cluster() {
  cd ${infra_dir}/rke2
  if [[ $dev_terraform == "true" ]]; then
    terraform destroy -auto-approve -var-file=dev-rke2.tfvars
  else
    terraform destroy -auto-approve
  fi
}

dev_deploy() {
  create_cloud_cluster
  zarf_init
  create_zarf_package
  deploy_zarf_package
}

test_dev_e2e() {
  create_cloud_cluster
  zarf_init
  create_zarf_package
  deploy_zarf_package
  test_zarf_package
  remove_zarf_package
  delete_cloud_cluster
}

######################
# Parse Command-Line Arguments
######################

target=$1

while [[ $# -gt 0 ]]; do
  key="$1"
  case $key in
    --zarf-create-args)
      extra_create_args="$2"
      shift
      shift
      ;;
    --dev-terraform)
      dev_terraform="true"
      shift
      ;;
    *)
      shift
      ;;
  esac
done

######################
# Main Script
######################

case "$target" in
  help)
    show_help
    ;;
  create-zarf-package)
    create_zarf_package
    ;;
  deploy-zarf-package)
    deploy_zarf_package
    ;;
  publish-zarf-package)
    publish_zarf_package
    ;;
  test-zarf-package)
    test_zarf_package
    ;;
  remove-zarf-package)
    remove_zarf_package
    ;;
  zarf-init)
    zarf_init
    ;;
  create-cloud-cluster)
    create_cloud_cluster
    ;;
  debug-output)
    debug_output
    ;;
  delete-cloud-cluster)
    delete_cloud_cluster
    ;;
  dev-deploy)
    dev_deploy
    ;;
  test-dev-e2e)
    test_dev_e2e
    ;;
  *)
    echo "Invalid target."
    show_help
    exit 1
    ;;
esac
