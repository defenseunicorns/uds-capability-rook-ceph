# UDS Package Rook-Ceph

This package provides a deployment of [Rook](https://rook.io/) within a zarf package. Rook/Ceph is preconfigured in this package to provide:
- Block storage for typical PVC usage (`ceph-block` storage class)
- RWX storage (`ceph-filesystem` storage class)
- S3-compatible object storage (`ceph-bucket` storage class) 

## Pre-requisites
- Zarf is installed locally with a minimum version of [v0.29.1](https://github.com/defenseunicorns/zarf/releases/tag/v0.29.1)
- A working Kubernetes cluster on v1.26+ and a working kube context pointing to the cluster (`kubectl get nodes` <-- this command works)
- Cluster nodes meet the [requirements for Rook-Ceph](https://rook.github.io/docs/rook/v1.12/Getting-Started/Prerequisites/prerequisites/). In general you need empty unformatted drives or partitions for Rook to configure for storage.
- Cluster has been zarf init-ed with a different storage class. An example using the [local-path-provisioner](https://github.com/rancher/local-path-provisioner) is provided below:
    ```console
    kubectl apply -f https://raw.githubusercontent.com/rancher/local-path-provisioner/v0.0.24/deploy/local-path-storage.yaml # deploy the local path provisioner
    kubectl patch storageclass local-path -p '{"metadata": {"annotations":{"storageclass.kubernetes.io/is-default-class":"true"}}}' # set storage class as default
    zarf init -a amd64 # no optional components are required by this package
    ```

## Create

To create the `rook-ceph` UDS package:
```console
# Login to the registry
set +o history
export REGISTRY1_USERNAME="YOUR-USERNAME-HERE"
export REGISTRY1_PASSWORD="YOUR-PASSWORD-HERE"
echo $REGISTRY1_PASSWORD | zarf tools registry login registry1.dso.mil --username $REGISTRY1_USERNAME --password-stdin
set -o history

# Create the zarf package
zarf package create --architecture amd64 --confirm
```

## Deploy

This package has a single configuration option for `device_filter` in the `zarf-config.yaml`. This value can be set to a regex that matches the devices/drives that you want to use for ceph storage. For example, if you wanted to use all devices starting `sd` you could set to `^sd.`. You can also leave the value as an empty string to use all unformatted devices/partitions.

Then to deploy the package:
```console
zarf package deploy zarf-package-rook-ceph-amd64-*.tar.zst --confirm
```

## Storage Provisioning

The default storage class will be configured to be `ceph-block`, which provides a standard RWO experience for most applications and PVC needs. To use the RWX capability you can create a PVC with the `ceph-filesystem` storage class. For an S3 compatible bucket you can create a custom resource, `ObjectBucketClaim`, such as the example [here](./examples/bucket.yaml).

## Remove

Removing the Rook-Ceph package is intentionally not "automatic". In order for the package to remove successfully there must be no storage pieces utilizing the Ceph storage (i.e. no PVCs, no buckets) existing in the cluster.

Even after removing the zarf package the default behavior of Rook-Ceph will ensure that no data is lost unintentional. The full cleanup process but can be achieved by following the process in [the Rook docs](https://rook.io/docs/rook/v1.11/Getting-Started/ceph-teardown/). There are pieces you may need to complete prior to removing the zarf package - the below is an example of how to go through the deletion process to fully wipe data:

1. Patch the cephcluster to ensure data is removed: `kubectl -n rook-ceph patch cephcluster rook-ceph --type merge -p '{"spec":{"cleanupPolicy":{"confirmation":"yes-really-destroy-data"}}}'`
1. Cleanup PVCs/buckets, etc - specific to your environment/usage
1. Remove the zarf package: `zarf package remove zarf-package-rook-ceph-amd64-*.tar.zst --confirm`
1. Delete the data on hosts and zap disks following the [upstream guide](https://rook.io/docs/rook/v1.11/Getting-Started/ceph-teardown/#delete-the-data-on-hosts)
