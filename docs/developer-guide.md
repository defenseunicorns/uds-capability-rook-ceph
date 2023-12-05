# Development and CI workflow

## Local Development Testing

> [!WARNING]  
> Local testing is only validated working for AMD64 Linux machines due to the prerequisites required to run Rook/Ceph with Ironbank images. It is also vital to only run inside of a VM so that Rook does not reformat existing storage. It is recommended to go the cloud based approach instead.

If you are set on local development you can follow [this guide](https://rook.io/docs/rook/v1.12/Contributing/development-environment/#minikube) from Rook to spin up a `minikube` cluster, then build and deploy the package. k3d support and documentation is a WIP.

The [dev cluster values file](../values/dev-cluster-values.yaml) is a good starting point to pass into the `rook-ceph-cluster` chart component during development testing. It will allow you to deploy this package onto a single node cluster with minimal replicas. An example [zarf.yaml](../.github/test-infra/dev/zarf.yaml) is provided which imports the components with this values file as an override.

## CI Workflows / Cloud Based Testing

Due to the small size of standard github runners and challenges with nested virtualization, the CI workflows use a 3 node RKE2 cluster running on AWS that is initialized with terraform. You can borrow the example terraform from [here](../.github/test-infra/rke2) to test in a similar way for your own development. An example [dev tfvars](../.github/test-infra/rke2/dev-rke2.tfvars) file is included in this folder with some of the common overrides that are required.

Prerequisites:
- `docker login` to `registry1.dso.mil`
- active shell has access to your target AWS environment
- `make` 3.82 or higher installed (check with `make --version`)

Using the make targets you can run the same commands as CI to build, deploy, and test the custom init package:
```console
make create-dev-cluster # Note that this will overwrite your default kubeconfig
make create-zarf-package
make deploy-zarf-package
# At this point your cluster should be created with rook/ceph deployed on top
# You can perform your own testing/validation or use the simple make smoketest
make test-zarf-package
make delete-dev-cluster
```

Alternatively you can run more concise make targets for your testing needs:
- `make dev-deploy`: Creates the cluster, initializes with zarf, creates the package, then deploys the package. Ensure you run `make delete-dev-cluster` to teardown once testing is complete.
- `make test-dev-e2e`: Full e2e CI workflow to create, test and destroy.
