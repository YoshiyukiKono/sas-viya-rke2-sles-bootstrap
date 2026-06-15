# SAS Viya Kubernetes Infrastructure Handover

## Cluster summary

- Kubernetes distribution: RKE2
- OS: SLES 15 SP7
- Kubernetes/RKE2 version: TBD
- CNI: Calico
- SAS namespace: `sas-viya`
- Kubeconfig: `output/kubeconfig-sas.yaml`

## Nodes

| Role | Hostname | IP | vCPU | Memory | Disk |
|---|---|---:|---:|---:|---:|
| NFS | nfs-01 | TBD | TBD | TBD | TBD |
| Control Plane | sas-cp-01 | TBD | TBD | TBD | TBD |
| Control Plane | sas-cp-02 | TBD | TBD | TBD | TBD |
| Control Plane | sas-cp-03 | TBD | TBD | TBD | TBD |
| Worker | sas-worker-01 | TBD | TBD | TBD | TBD |
| Worker | sas-worker-02 | TBD | TBD | TBD | TBD |
| Worker | sas-worker-03 | TBD | TBD | TBD | TBD |

## Access

- Kubernetes API endpoint: TBD
- kubeconfig file: `output/kubeconfig-sas.yaml`
- Admin user/contact: TBD

## DNS / Ingress / LoadBalancer

- Base domain: TBD
- Wildcard DNS: TBD
- Ingress controller: TBD
- IngressClass: TBD
- LoadBalancer implementation: TBD
- LoadBalancer IP range: TBD
- Actual ingress external IP: TBD

## Storage

- StorageClass: TBD
- Provisioner: NFS CSI
- NFS server: TBD
- NFS export path: TBD
- AccessMode support: confirm RWX
- Reclaim policy: Retain
- Known limitation: single NFS VM is PoC/lab-grade unless HA storage is provided.

## TLS / cert-manager

- cert-manager installed: Yes/No
- Issuer/ClusterIssuer: TBD
- Certificate source: self-signed / internal CA / public CA / provided certificates
- Rotation owner: TBD

## Registry / network

- Internet access from nodes: Yes/No
- Proxy required: Yes/No
- Private registry/mirror required: Yes/No
- SAS image access owner: SAS owner

## Verification evidence

Attach or paste output from:

```bash
kubectl version
kubectl get nodes -o wide
kubectl get pods -A
kubectl get sc
kubectl get ingressclass
kubectl get svc -A
```

Also attach:

- `output/sas-readiness-*.txt`

## Open items for SAS owner

- Confirm target SAS Viya release.
- Confirm supported Kubernetes/RKE2 version.
- Confirm Calico compatibility.
- Confirm StorageClass and RWX requirements.
- Confirm Ingress hostnames and TLS strategy.
- Confirm SAS container image registry/proxy/air-gap requirements.
- Confirm whether CAS/Compute require dedicated node labels or taints.
