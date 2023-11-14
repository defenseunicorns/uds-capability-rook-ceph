# UDS Capability Rook-Ceph

This package provides a custom zarf init package containing [Rook](https://rook.io/). Rook/Ceph is preconfigured in this package to provide:
- Block storage for typical PVC usage (`ceph-block` storage class)
- RWX storage (`ceph-filesystem` storage class)
- S3-compatible object storage (`ceph-bucket` storage class) 

## Pre-requisites
- Zarf is installed locally with a minimum version of [v0.31.1](https://github.com/defenseunicorns/zarf/releases/tag/v0.31.1)
- A working Kubernetes cluster on v1.26+ and a working kube context pointing to the cluster (or this package can be used to deploy a k3s cluster)
- Cluster nodes meet the [requirements for Rook-Ceph](https://rook.github.io/docs/rook/v1.12/Getting-Started/Prerequisites/prerequisites/). In general you need empty unformatted drives or partitions for Rook to configure for storage.

## Create

To create the `rook-ceph` custom init package:
```console
# Login to the registry
set +o history
export REGISTRY1_USERNAME="YOUR-USERNAME-HERE"
export REGISTRY1_PASSWORD="YOUR-PASSWORD-HERE"
echo $REGISTRY1_PASSWORD | zarf tools registry login registry1.dso.mil --username $REGISTRY1_USERNAME --password-stdin
set -o history

# Create the zarf package
zarf package create --architecture amd64 --confirm --set AGENT_IMAGE_TAG=$(zarf version)
```

## Deploy

This package has several configuration options. The most commonly set ones are:
- `DEVICE_FILTER`: A regex to select specific devices (drives/partitions) for Ceph to use, defaults to all unformatted devices
- `PRIVILEGED_HOSTPATH`: Runs Ceph Pods as privileged to be able to write to `hostPaths` in environments with SELinux restrictions (set to true/false)

These variables can be setup in your zarf config file under the `package.deploy.set` key, or passed in as `--set` values at deploy time.

To deploy the package either follow the steps from above to build it, or pull it down locally:
```console
zarf package pull oci://ghcr.io/defenseunicorns/uds-capability/rook-ceph/init:v0.31.1 # Or latest version
```

Once you have the package locally, init like you would with the standard init package:
```console
zarf init --confirm # Optionally add --set values here
```

## Storage Provisioning

The default storage class will be configured to be `ceph-block`, which provides a standard RWO experience for most applications and PVC needs. To use the RWX capability you can create a PVC with the `ceph-filesystem` storage class. For an S3 compatible bucket you can create a custom resource, `ObjectBucketClaim`, such as the example [here](./examples/bucket.yaml).

## Remove

Removing the Rook-Ceph package is intentionally not "automatic" to prevent unintentional data loss. In order for the package to remove successfully there must be no storage pieces utilizing the Ceph storage (i.e. no PVCs, no buckets) existing in the cluster.

Even after removing the zarf package the default behavior of Rook-Ceph will ensure that no data is lost unintentional. The full cleanup process but can be achieved by following the process in [the Rook docs](https://rook.io/docs/rook/v1.11/Getting-Started/ceph-teardown/). There are pieces you may need to complete prior to removing the zarf package - the below is an example of how to go through the deletion process to fully wipe data:

1. Patch the cephcluster to ensure data is removed: `kubectl -n rook-ceph patch cephcluster rook-ceph --type merge -p '{"spec":{"cleanupPolicy":{"confirmation":"yes-really-destroy-data"}}}'`
1. Cleanup PVCs/buckets, etc - specific to your environment/usage
1. Remove the zarf init package: `zarf destroy --confirm`
1. Cleanup rook/ceph cluster: `helm uninstall rook-ceph-cluster -n rook-ceph`
1. Wait until resources have all been removed then remove the operator: `helm uninstall rook-ceph -n rook-ceph`
1. Delete the data on hosts and zap disks following the [upstream guide](https://rook.io/docs/rook/v1.11/Getting-Started/ceph-teardown/#delete-the-data-on-hosts)
