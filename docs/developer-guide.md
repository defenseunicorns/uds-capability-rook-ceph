# Development and CI workflow

## Local Development Testing

> [!WARNING]  
> Local testing is only validated working for AMD64 Linux machines due to the prerequisites required to run Rook/Ceph with Ironbank images. It is also vital to only run inside of a VM so that Rook does not reformat existing storage. It is recommended to go the cloud based approach instead.

If you are set on local development you can follow [this guide](https://rook.io/docs/rook/v1.12/Contributing/development-environment/#minikube) from Rook to spin up a `minikube` cluster, then use the script to init and deploy the package. These may need modification to fully support local development and PRs are appreciated to identify and fix issues.

## CI Workflows / Cloud Based Testing

Due to the small size of github runners and challenges with nested virtualization, the CI workflows use a 3 node RKE2 cluster running on AWS that is initialized with terraform. You can borrow the example terraform from `.github/test-infra/rke2` to test in a similar way for your own development. The `dev-rke2.tfvars` file contains the common fields you will need to override. In addition your AWS environment needs a bucket and DynamoDB table for your state storage. The script assumes these are in `us-west-2`, the bucket is named `uds-dev-state-bucket`, and the table `uds-dev-state-dynamodb`. If you have a different bucket/table or a different region you can customize the init in `scripts/helper.sh`.

Prerequisites:
- You have done a `docker login` to `registry1.dso.mil`
- Active shell has access to your target AWS environment

Using the helper script you can run the same commands as CI:
```console
./scripts/helper.sh create-zarf-package --zarf-create-args "--skip-sbom"
./scripts/helper.sh create-cloud-cluster --dev-terraform # Note that this will overwrite your default kubeconfig
./scripts/helper.sh zarf-init
./scripts/helper.sh deploy-zarf-package
# At this point your cluster should be created with rook/ceph deployed on top
# You can perform your own testing/validation or use the simple script smoketest
./scripts/helper.sh test-zarf-package
./scripts/helper.sh remove-zarf-package
./scripts/helper.sh delete-cloud-cluster --dev-terraform
```

Alternatively you can run more concise helper script commands for your testing needs:
- `./scripts/helper.sh dev-deploy --zarf-create-args "--skip-sbom" --dev-terraform`: Creates the cluster, initializes with zarf, creates the package, then deploys the package. Ensure you run `./scripts/helper.sh delete-cloud-cluster --dev-terraform` to teardown once testing is complete.
- `./scripts/helper.sh test-dev-e2e --zarf-create-args "--skip-sbom" --dev-terraform`: Full e2e CI workflow to create, test and destroy.
