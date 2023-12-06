# UDS Capability Rook-Ceph

This repository provides a zarf package containing [Rook](https://rook.io/). Rook/Ceph is preconfigured in this package to provide:
- Block storage for typical PVC usage (`ceph-block` storage class)
- RWX storage (`ceph-filesystem` storage class)
- S3-compatible object storage (`ceph-bucket` storage class) 

There are two versions of this package provided:
- A custom zarf init package: Can be used to `zarf init` a fresh cluster, with no other storage class required
- A standard zarf package: Must be used on top of an already `zarf init`-ed cluster

## Pre-requisites
- Zarf is installed locally with a minimum version of [v0.31.1](https://github.com/defenseunicorns/zarf/releases/tag/v0.31.1)
- A working Kubernetes cluster on v1.26+ and a working kube context pointing to the cluster (or this package can be used to deploy a k3s cluster)
- Cluster nodes meet the [requirements for Rook-Ceph](https://rook.github.io/docs/rook/v1.12/Getting-Started/Prerequisites/prerequisites/). In general:
  - Cluster nodes must have empty unformatted drives or partitions for Rook to configure for storage
  - Nodes must have the `lvm2` package installed to support encryption
  - Nodes must have the `rbd` module (default on most linux distributions)
- If using the "standard" package your cluster must have been `zarf init`-ed already
- If using the "custom init" package you must have a version of zarf matching the custom init version

## Create

Typically creating the package is only required if doing development or debugging on the package. Published versions of this package are available in GHCR as OCI packages and can be used to [deploy](#deploy) without needing to create the package.

### Custom Init Package

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

### Standard Package

```console
# Login to the registry
set +o history
export REGISTRY1_USERNAME="YOUR-USERNAME-HERE"
export REGISTRY1_PASSWORD="YOUR-PASSWORD-HERE"
echo $REGISTRY1_PASSWORD | zarf tools registry login registry1.dso.mil --username $REGISTRY1_USERNAME --password-stdin
set -o history

# Create the zarf package
cd rook-ceph && zarf package create --architecture amd64 --confirm
```

## Deploy

This package has a single configuration option:
- `DEVICE_FILTER`: A regex to select specific devices (drives/partitions) for Ceph to use, defaults to all unformatted devices

This variable can be setup in your zarf config file under the `package.deploy.set` key, or passed in as a `--set` value at deploy time.

### Custom Init Package

To deploy the package either follow the steps from above to build it, or pull the published version. Note that two versions are published to OCI:
- `vX.X.X`: This is a version that lines up with your zarf version. If you want the latest rook ceph for a given zarf version pull this way. Note that this tag is the equivalent of a latest tag for the given zarf version and is mutable. If you need a consistent artifact in your deployment process do not use these versions.
- `vX.X.X-Y.Y.Y`: The first version (`vX.X.X`) is in line with your zarf version. The suffixed version (`Y.Y.Y`) is in line with the changelog and releases on this repo. These published packages are immutable and ideal in most scenarios.

First pull the package if using the published release (skip if you have the package built locally):
```console
zarf package pull oci://ghcr.io/defenseunicorns/uds-capability/rook-ceph/init:v0.31.3-0.0.8 # Example version, make sure to check releases!
```

Once you have the package locally, init like you would with the standard init package:
```console
zarf init --confirm # Optionally add --set values here
```

### Standard Package

Deploying the standard package is as easy as any other zarf package. Note that versioning for the standard package is standard semver based on the release/changelog in the repo since it is not dependent on zarf versioning. To deploy from OCI:

```console
zarf package deploy oci://ghcr.io/defenseunicorns/uds-capability/rook-ceph:0.0.8 --confirm # Example version, make sure to check releases!
```

## Usage

Usage of the storage provided by Rook/Ceph is similar to any other storage class in Kubernetes. The default storage class will be configured to be `ceph-block`, which provides standard (RWO) block storage for most applications and PVC needs. To use the RWX capability you can create a PVC with the `ceph-filesystem` storage class. For an S3 compatible bucket you can create a custom resource, `ObjectBucketClaim`, such as the example [here](./examples/bucket.yaml).

## Upgrades

Regardless of which package you used for your initial deployment, upgrades of Rook/Ceph should _typically_ be done with the "standard" zarf package, rather than using a new custom init package. To upgrade simply deploy the new version of the standard package and zarf will upgrade the necessary Rook/Ceph components that need modification.  If you need to upgrade the zarf components (agent, registry, git-server, etc) you can upgrade those with a newer version of the standard zarf init package (`oci://ghcr.io/defenseunicorns/packages/init:$(zarf version)`). The custom init package should only be required for your first init of the cluster.

## Remove

Removing the Rook-Ceph package is intentionally not "automatic" to prevent unintentional data loss. In order for the package to remove successfully there must be no storage pieces utilizing the Ceph storage (i.e. no PVCs, no buckets) existing in the cluster. Assuming you used the custom init your zarf components must be removed (i.e. `zarf destroy`) prior to Rook/Ceph itself, which means you cannot use zarf to remove Rook/Ceph.

The full cleanup process can be achieved by following the process in [the Rook docs](https://rook.io/docs/rook/v1.11/Getting-Started/ceph-teardown/). The below is an example of how to go through the deletion process to fully wipe data, assuming you used the custom init package:

1. Patch the cephcluster to ensure data is removed: `kubectl -n rook-ceph patch cephcluster rook-ceph --type merge -p '{"spec":{"cleanupPolicy":{"confirmation":"yes-really-destroy-data"}}}'`
1. Cleanup user created PVCs/buckets, etc - specific to your environment/usage
1. Remove the zarf init package: `zarf destroy --confirm`
1. Cleanup rook/ceph cluster (you may have to watch and wait for all resources to be removed): `helm uninstall rook-ceph-cluster -n rook-ceph --wait`
1. Wait until all Rook/Ceph resources except the operator have been removed then remove the operator: `helm uninstall rook-ceph -n rook-ceph --wait`
1. Delete the data on hosts and zap disks following the [upstream guide](https://rook.io/docs/rook/v1.11/Getting-Started/ceph-teardown/#delete-the-data-on-hosts)
