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