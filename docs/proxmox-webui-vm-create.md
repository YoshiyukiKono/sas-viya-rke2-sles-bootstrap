# Proxmox Web UI VM creation notes

This document describes the intended manual VM creation phase when Proxmox host shell access is unavailable.

## Goal

Create SLES 15 SP7 VMs from:

```text
SLES15-SP7-Minimal-VM.x86_64-Cloud-QU4.qcow2
```

Then use Cloud-Init only for basic VM initialization:

- user
- SSH key
- hostname
- IP address
- DNS

RKE2 and NFS are handled later by PowerShell scripts.

## Recommended VM list

```text
nfs-01
sas-cp-01
sas-cp-02
sas-cp-03
sas-worker-01
sas-worker-02
sas-worker-03
```

## Recommended VM sizing

| Role | vCPU | Memory | Disk |
|---|---:|---:|---:|
| nfs-01 | 4 | 8 GB | 200 GB+ |
| control plane | 4 | 16 GB | 100 GB |
| worker | 16+ | 64 GB+ | 300 GB+ |

For SAS Viya, worker memory matters. Confirm final sizing with the SAS owner.

## Cloud-Init values

Set each VM with:

- User: `sles`
- SSH Public Key: your Windows user's public key
- IP: static preferred
- DNS: your environment DNS
- Search domain: optional

## Notes

If the Proxmox GUI cannot import qcow2 directly, host shell access or an administrator action is needed for `qm importdisk`.
