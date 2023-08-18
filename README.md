# UDS Package Rook-Ceph

## Start

### Pre-requisites 
1. RKE2 cluster, see [#Tested with](#tested-with)
2. Cluster nodes meet the [requirements for Rook-Ceph](https://rook.github.io/docs/rook/v1.12/Getting-Started/Prerequisites/prerequisites/)

### Install

1. [Ceph Operator chart](https://rook.github.io/docs/rook/v1.12/Helm-Charts/operator-chart/) - Installs rook to create, configure, and manage Ceph clusters on Kubernetes.
   ```
   helm repo add rook-release https://charts.rook.io/release
   helm install --create-namespace --namespace rook-ceph rook-ceph rook-release/rook-ceph
   # Wait for rook-ceph-operator to be ready
   ```

1. [Ceph Cluster chart](https://rook.github.io/docs/rook/v1.12/Helm-Charts/ceph-cluster-chart/) - Creates Rook resources to configure a Ceph cluster using the Helm package manager. 
   ```
   helm install --create-namespace --namespace rook-ceph rook-ceph-cluster --set operatorNamespace=rook-ceph rook-release/rook-ceph-cluster
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

3. Make rook-ceph the default storageclass 
   ```
   kubectl apply -f manifests/storageclass.yaml
   ```

4. Zarf (v0.29.0) & Metallb
   ```
   zarf -a amd64 init --components git-server --confirm
   zarf -a amd64 package build ##NOTE: Loadbalancer IP Pool (metallb/ipaddresspool.yaml)
   zarf -a amd64 package deploy
   ```

5. DUBBD-RKE2
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

- [ ] Update ZarfPackageConfig to include DUBBD-RKE2 skeleton package
- [ ] Confirm default rook-ceph helm chart values are what is needed/desired
- [ ] Validate scripts/check.sh to ensure nodes are ready for rook-ceph
- [ ] Variables for metallb/ipaddresspool.yaml IP Pool