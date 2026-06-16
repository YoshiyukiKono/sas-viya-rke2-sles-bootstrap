# Proxmox Web UI VM Preparation

This repository assumes that SLES VMs already exist and are reachable by SSH from the Windows workstation.

For the concrete Proxmox VE 9 procedure used to import the SLES 15 SP7 qcow2 image and create a reusable VM template, see:

- [proxmox-sles-cloud-image-template.md](./proxmox-sles-cloud-image-template.md)

High-level flow:

```text
Enable Disk image / Import on local storage
  -> Upload SLES15-SP7-Minimal-VM.x86_64-Cloud-QU4.qcow2
  -> Create empty VM 9007
  -> Import qcow2 as VM hard disk
  -> Set boot order to imported disk
  -> Complete JeOS Firstboot once
  -> Add CloudInit Drive
  -> Clean cloud-init and machine-id
  -> Convert VM 9007 to template
  -> Clone into RKE2/NFS nodes
```

After cloning, configure each VM's Cloud-Init settings in the Proxmox UI:

```text
hostname
SSH public key
IP address or DHCP
DNS / search domain
```

Once all VMs are reachable via SSH, run the PowerShell scripts from the Windows workstation.
