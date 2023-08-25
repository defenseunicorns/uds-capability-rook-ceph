# UDS Package Rook-Ceph

## Pre-requisites 
1. RKE2 cluster
2. Cluster nodes meet the [requirements for Rook-Ceph](https://rook.github.io/docs/rook/v1.12/Getting-Started/Prerequisites/prerequisites/)
3. Cluster has been zarf init-ed with a different storage class. The [local-path-provisioner](https://github.com/rancher/local-path-provisioner) is one option, or a similar "simple" storage class.

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

To deploy the package:
```console
zarf package deploy zarf-package-rook-ceph-amd64-*.tar.zst --confirm
```
