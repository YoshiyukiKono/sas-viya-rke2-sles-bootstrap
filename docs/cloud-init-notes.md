# Cloud-Init notes

Cloud-Init is intentionally kept simple in this workflow.

## What Cloud-Init should do

- create/login user
- inject SSH public key
- set static IP
- set DNS
- set hostname, if supported by the Proxmox Cloud-Init UI

## What Cloud-Init should not do here

Avoid putting the full RKE2 installation in Cloud-Init.

Reasons:

- RKE2 HA bootstrap requires sequencing.
- Failure handling is easier with explicit scripts.
- Re-running PowerShell scripts is easier than debugging one-shot Cloud-Init failures.

## Division of responsibility

```text
Cloud-Init: VM identity and access
PowerShell: OS prep, NFS, RKE2, add-ons
SAS owner: SAS Viya deployment
```
