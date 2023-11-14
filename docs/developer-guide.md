# Development and CI workflow

## Local Development Testing

> [!WARNING]  
> Local testing is only validated working for AMD64 Linux machines due to the prerequisites required to run Rook/Ceph with Ironbank images. It is also vital to only run inside of a VM so that Rook does not reformat existing storage. It is recommended to go the cloud based approach instead.

If you are set on local development you can follow [this guide](https://rook.io/docs/rook/v1.12/Contributing/development-environment/#minikube) from Rook to spin up a `minikube` cluster, then use the make targets to init and deploy the package. These may need modification to fully support local development and PRs are appreciated to identify and fix issues.

## CI Workflows / Cloud Based Testing

Due to the small size of github runners and challenges with nested virtualization, the CI workflows use a 3 node RKE2 cluster running on AWS that is initialized with terraform. You can borrow the example terraform from `.github/test-infra/rke2` to test in a similar way for your own development. An example `dev-rke2.tfvars` file is included in this folder with some of the common overrides that are required.

Prerequisites:
- `docker login` to `registry1.dso.mil`
- active shell has access to your target AWS environment
- `make` 3.82 or higher installed (check with `make --version`)

Using the make targets you can run the same commands as CI:
```
make create-dev-cluster # Note that this will overwrite your default kubeconfig
make create-zarf-package extra_create_args="--skip-sbom"
make deploy-zarf-package
# At this point your cluster should be created with rook/ceph deployed on top
# You can perform your own testing/validation or use the simple make smoketest
make test-zarf-package
make delete-dev-cluster
```

Alternatively you can run more concise make targets for your testing needs:
- `make dev-deploy`: Creates the cluster, initializes with zarf, creates the package, then deploys the package. Ensure you run `make delete-dev-cluster` to teardown once testing is complete.
- `make test-dev-e2e`: Full e2e CI workflow to create, test and destroy.
