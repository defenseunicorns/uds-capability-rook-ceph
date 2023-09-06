# Development and CI workflow

## Local Development Testing

> [!WARNING]  
> Local testing is only validated working for AMD64 Linux machines due to the prerequisites required to run Rook/Ceph with Ironbank images. It is also vital to only run inside of a VM so that Rook does not reformat existing storage. It is recommended to go the cloud based approach instead.

If you are set on local development you can follow [this guide](https://rook.io/docs/rook/v1.12/Contributing/development-environment/#minikube) from Rook to spin up a `minikube` cluster, then use the make targets to init and deploy the package. These may need modification to fully support local development and PRs are appreciated to identify and fix issues.

## CI Workflows / Cloud Based Testing

Due to the small size of github runners and challenges with nested virtualization, the CI workflows use a 3 node RKE2 cluster running on AWS that is initialized with terraform. You can borrow the example terraform from `.github/test-infra/rke2` to test in a similar way for your own development. An example `dev-rke2.tfvars` file is included in this folder with some of the common overrides that are required.

Ensure that you have logged in to `registry1.dso.mil` and you are in a shell with access to your target AWS environment. Then using the make targets you can run the same commands as CI:
```
make create-dev-cluster # Note that this will overwrite your default kubeconfig
make zarf-init
make create-zarf-package extra_create_args="--skip-sbom"
make deploy-zarf-package
# At this point your cluster should be created with rook/ceph deployed on top
# You can perform your own testing/validation or use the simple make smoketest
make test-zarf-package
make delete-dev-cluster
```

Alternatively you can run the single `make test-dev-e2e` target to run through the full test process.
