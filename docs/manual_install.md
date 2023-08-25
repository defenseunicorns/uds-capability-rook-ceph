# UDS Package Rook-Ceph

## Start

### Pre-requisites 
1. RKE2 cluster, see [#Tested with](#tested-with)
2. Cluster nodes meet the [requirements for Rook-Ceph](https://rook.github.io/docs/rook/v1.12/Getting-Started/Prerequisites/prerequisites/)

### Install

1. Create the `rook-ceph` namespace and an `imagePullSecret` for registry1.dso.mil:
   ```console
   kubectl create ns rook-ceph
   kubectl apply -n rook-ceph -f ~/bigbang/local/private-registry.yaml
   kubectl create -n rook-ceph secret docker-registry private-registry --docker-server=registry1.dso.mil --docker-username=<your-username> --docker-password=<your-token>
   # Patch the default service account due to a limitation with rook/ceph private registry pulls
   kubectl patch serviceaccount default -n rook-ceph -p '{"imagePullSecrets": [{"name": "private-registry"}]}'
   ```

1. [Ceph Operator chart](https://rook.github.io/docs/rook/v1.12/Helm-Charts/operator-chart/) - Installs rook to create, configure, and manage Ceph clusters on Kubernetes.
   ```console
   helm repo add rook-release https://charts.rook.io/release
   helm install --create-namespace --namespace rook-ceph rook-ceph rook-release/rook-ceph -f values/operator-values.yaml
   # Wait for rook-ceph-operator to be ready
   kubectl rollout status deployment -n rook-ceph rook-ceph-operator
   ```

1. [Ceph Cluster chart](https://rook.github.io/docs/rook/v1.12/Helm-Charts/ceph-cluster-chart/) - Creates Rook resources to configure a Ceph cluster using the Helm package manager.
   ```console
   helm install --create-namespace --namespace rook-ceph rook-ceph-cluster --set operatorNamespace=rook-ceph rook-release/rook-ceph-cluster -f values/cluster-values.yaml
   # Wait for cluster to be ready
   kubectl wait --for=condition=ready cephcluster -n rook-ceph rook-ceph --timeout=20m
   ```
During this install, you will see various jobs/pods being created (took ~17 minutes):
   ```
    rook-ceph-csi-detect
    rook-ceph-detect-version
    rook-ceph-mon-*
    csi-*[cephfs|rdb]plugin
    csi-*plugin-provisioner
    rook-ceph-crashcollector-*
    rook-ceph-mgr-*
    rook-ceph-osd-*
    rook-ceph-osd-prepare-*
    rook-ceph-md-ceph-filesystem-*
    rook-ceph-rgw-ceph-objectstore-*
   ```
   After completion you should see 3 storage classes

1. Zarf (v0.29.0) & Metallb
   ```
   zarf -a amd64 init --components git-server --confirm
   zarf -a amd64 package deploy oci://docker pull ghcr.io/defenseunicorns/packages/metallb:0.0.1-amd64 # must set IP_ADDRESS_POOL zarf variable
   ```

1. DUBBD-RKE2
   ```
   cd <wherever you have uds-package-dubbd repo clone>/rke2
   zarf -a amd64 package build 
   zarf -a amd64 package deploy zarf-package-dubbd-rke2-amd64-0.6.2.tar.zst
   ```

## Tested with

RKE2 cluster 
- 3 server nodes
- 8 agent nodes
  
Node Specs:
- 6 vCPU cores
- 16GB RAM
- OS Ubuntu 22.04
- OS Disk 25GB
- Data Disk 100GB (/var/lib/rancher)
- Unformated Disk 50GB

## (potential) TODOs 

- [ ] Confirm default rook-ceph helm chart values are what is needed/desired
- [ ] Validate scripts/check.sh to ensure nodes are ready for rook-ceph