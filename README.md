# sas-viya-rke2-sles-bootstrap

Windows PowerShell scripts to prepare SLES VMs and bootstrap an RKE2 Kubernetes cluster with NFS-backed StorageClass for SAS Viya deployment.

## Scope

This repository covers the infrastructure side only:

- Proxmox VM preparation notes
- SLES OS preparation
- optional NFS server setup
- RKE2 HA cluster bootstrap
- NFS CSI StorageClass creation
- cert-manager installation
- optional ingress-nginx installation
- SAS namespace creation
- handover checklist for the SAS Viya owner

It does **not** install SAS Viya itself.

## Assumed topology

```text
nfs-01          192.168.10.90
sas-cp-01       192.168.10.101
sas-cp-02       192.168.10.102
sas-cp-03       192.168.10.103
sas-worker-01   192.168.10.201
sas-worker-02   192.168.10.202
sas-worker-03   192.168.10.203
```

## Prerequisites on Windows

- PowerShell 5.1 or later, PowerShell 7 preferred
- OpenSSH Client enabled
- SSH key access to all SLES VMs
- The SLES user can run `sudo`
- Network reachability from Windows to all VMs

Check SSH:

```powershell
ssh sles@192.168.10.101 hostname
```

## Usage

Copy the example config:

```powershell
Copy-Item .\config\cluster.example.ps1 .\config\cluster.ps1
notepad .\config\cluster.ps1
```

Run scripts in order:

```powershell
Set-ExecutionPolicy -Scope Process Bypass

.\scripts\00-test-ssh.ps1
.\scripts\01-prepare-os.ps1
.\scripts\02-configure-hosts.ps1
.\scripts\03-configure-nfs-server.ps1
.\scripts\04-install-nfs-client.ps1
.\scripts\05-install-rke2-first-server.ps1
.\scripts\06-join-rke2-servers.ps1
.\scripts\07-join-rke2-workers.ps1
.\scripts\08-fetch-kubeconfig.ps1
.\scripts\09-install-nfs-csi.ps1
.\scripts\10-install-cert-manager.ps1
.\scripts\11-install-ingress-nginx.ps1
.\scripts\12-create-sas-namespace.ps1
.\scripts\99-verify-cluster.ps1
.\scripts\13-verify-sas-readiness.ps1
```

## Handover output

After successful execution, provide the SAS Viya owner with:

- `output/kubeconfig-sas.yaml`
- Kubernetes API endpoint
- namespace name
- StorageClass name
- Ingress domain / LB IP range, if configured
- `docs/sas-handover-checklist.md`

## Important notes

- RKE2 installation downloads from the internet. For air-gapped environments, adjust the scripts.
- The default StorageClass uses NFS CSI with `Retain` reclaim policy.
- The NFS server here is a simple PoC/lab design, not an HA storage design.
- For production, confirm SAS Viya Kubernetes, CNI, ingress, and storage prerequisites with the SAS owner.


## Additional planning documents

- `docs/preflight-checklist.md` - items to confirm before SAS Viya deployment
- `docs/dns-loadbalancer-notes.md` - DNS, wildcard, and LoadBalancer planning notes

## SAS readiness report

Run the readiness script after the cluster, StorageClass, cert-manager, ingress, and namespace are configured:

```powershell
.\scripts-verify-sas-readiness.ps1
```

The script writes a timestamped report under `output/`, including cluster state, StorageClass checks, an RWX PVC smoke test, ingress/cert-manager status, and manual follow-up items for the SAS owner.
