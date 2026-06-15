# SAS Viya Kubernetes Infrastructure Preflight Checklist

This checklist is for the infrastructure owner before handing the Kubernetes cluster to the SAS Viya deployment owner.

## 1. Scope boundary

Confirm the responsibility split:

| Area | Owner | Status |
|---|---|---|
| Proxmox VM creation | Infrastructure owner | TBD |
| SLES OS preparation | Infrastructure owner | TBD |
| RKE2 Kubernetes cluster | Infrastructure owner | TBD |
| NFS server / StorageClass | Infrastructure owner | TBD |
| Ingress Controller | Infrastructure owner or SAS owner | TBD |
| cert-manager | Infrastructure owner or SAS owner | TBD |
| SAS Viya deployment | SAS owner | Out of scope |
| SAS license / order assets | SAS owner | Out of scope |
| SAS container image access / mirror | SAS owner, with infra support | TBD |

## 2. Version alignment

Confirm these values with the SAS Viya owner before deployment:

- Target SAS Viya release: `TBD`
- Required Kubernetes version range: `TBD`
- RKE2 version to install: `TBD`
- CNI: `Calico` unless SAS owner specifies otherwise
- Calico version compatibility: `TBD`
- Container runtime: `containerd` via RKE2

Do not assume that any Kubernetes version is acceptable. Pin the RKE2 version intentionally.

## 3. VM and OS checks

For every SLES VM:

- Hostname is correct.
- Static IP or reserved DHCP address is stable.
- Forward and reverse DNS are correct, if DNS is available.
- SSH access works from the Windows workstation.
- The user can run `sudo`.
- Time synchronization is active.
- `qemu-guest-agent` is installed and running.
- Swap is disabled.
- Required kernel modules are configured.
- Required sysctl settings are configured.
- Disk size is sufficient.
- Worker memory is sufficient for the expected SAS workload.

Suggested checks:

```bash
hostnamectl
ip addr
chronyc tracking || timedatectl
swapon --show
systemctl status qemu-guest-agent
```

## 4. Network and firewall

Confirm:

- All Kubernetes nodes can reach each other.
- Windows workstation can reach the Kubernetes API endpoint.
- Kubernetes API endpoint is stable.
- RKE2 control-plane ports are reachable between control-plane nodes.
- Worker nodes can reach control-plane nodes.
- NFS clients can reach the NFS server.
- Ingress LoadBalancer IP is reachable from SAS users/admins.
- Firewall policy is documented.

For lab environments, disabling firewalld may be acceptable, but document it clearly.

## 5. DNS and FQDN

SAS Viya commonly requires FQDN-based access through Ingress.

Confirm:

- Base domain: `viya.example.local` or equivalent
- Wildcard DNS: `*.viya.example.local`
- DNS points to Ingress LoadBalancer IP
- Kubernetes API DNS name, if used
- DNS TTL and ownership

Example:

```text
viya.example.local       A      192.168.10.220
*.viya.example.local     CNAME  viya.example.local
```

## 6. LoadBalancer

Confirm the LoadBalancer implementation:

- MetalLB, kube-vip, physical LB, or other
- IP range allocated to Kubernetes Services
- IP range does not conflict with DHCP
- ARP/L2 behavior is acceptable on the Proxmox network
- Ingress Service receives an external IP

Example range:

```text
192.168.10.220-192.168.10.240
```

## 7. Storage

Confirm the StorageClass to be used by SAS Viya:

- StorageClass name: `sas-nfs` or equivalent
- Access mode support: confirm whether RWX is required
- Reclaim policy: `Retain` is safer for PoC handoff
- NFS export path
- NFS version
- Expected capacity
- Backup responsibility
- Performance expectations
- Whether NFS is PoC-only or production-acceptable

For a lab, NFS is simple and useful. For production-like evaluation, document that a single NFS VM is a single point of failure.

## 8. TLS and cert-manager

Confirm:

- Is cert-manager installed by infrastructure owner?
- Issuer type: self-signed, internal CA, public CA, or provided certificates
- Who owns certificate rotation?
- Are wildcard certificates required?

## 9. Registry and internet access

Confirm:

- Nodes can pull required Kubernetes images.
- SAS owner has access to SAS container images.
- Proxy settings are required or not.
- Private registry or mirror is required or not.
- Air-gapped deployment is required or not.

If air-gapped, the current bootstrap scripts must be adapted.

## 10. Node labeling and workload placement

Ask the SAS owner whether they require dedicated nodes for CAS, compute, or stateless services.

Possible labels:

```text
workload.sas.com/class=cas
workload.sas.com/class=compute
workload.sas.com/class=general
```

Do not invent final labels without coordination with the SAS owner.

## 11. Handover evidence

Capture and provide:

```bash
kubectl version
kubectl get nodes -o wide
kubectl get pods -A
kubectl get sc
kubectl get ingressclass
kubectl get svc -A
kubectl get events -A --sort-by=.metadata.creationTimestamp
```

Also provide:

- kubeconfig file
- Kubernetes API endpoint
- namespace name
- StorageClass name
- Ingress domain
- LoadBalancer IP range
- known limitations
