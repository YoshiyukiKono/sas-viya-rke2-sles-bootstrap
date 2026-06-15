# SAS Viya Kubernetes handover checklist

Fill this out before handing the cluster to the SAS Viya owner.

## Cluster

- Kubernetes distribution: RKE2
- OS: SLES 15 SP7
- CNI: Calico
- Control plane nodes:
  - sas-cp-01
  - sas-cp-02
  - sas-cp-03
- Worker nodes:
  - sas-worker-01
  - sas-worker-02
  - sas-worker-03

## Access

- kubeconfig: `output/kubeconfig-sas.yaml`
- API endpoint:
- SAS namespace: `sas-viya`

## Storage

- StorageClass: `sas-nfs`
- Provisioner: `nfs.csi.k8s.io`
- NFS server:
- NFS export path: `/exports/viya`
- ReclaimPolicy: `Retain`

## Ingress / DNS

- Ingress controller:
- LoadBalancer IP:
- Base domain:
- Wildcard DNS:

## TLS

- cert-manager installed: yes/no
- ClusterIssuer/Issuer prepared: yes/no
- TLS ownership: platform team / SAS team

## Validation commands

```bash
kubectl get nodes -o wide
kubectl get pods -A
kubectl get sc
kubectl get ns sas-viya
```

Attach outputs to the handover record.
