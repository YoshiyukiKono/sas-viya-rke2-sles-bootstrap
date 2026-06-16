# Proxmox VE 9: SLES 15 SP7 Cloud/JeOS Image Template Creation

This note records the Web UI procedure used to import `SLES15-SP7-Minimal-VM.x86_64-Cloud-QU4.qcow2` into Proxmox VE 9.0.x and turn it into a reusable VM template for later RKE2/SAS Viya worker and control-plane nodes.

The goal is not to install SAS Viya here. The goal is to create a clean SLES 15 SP7 VM template that can be cloned into:

```text
nfs-01
sas-cp-01
sas-cp-02
sas-cp-03
sas-worker-01
sas-worker-02
sas-worker-03
```

## Environment observed

```text
Proxmox VE: 9.0.3
Node: node12
Storage:
  local   Directory /var/lib/vz
  stor4b  Proxmox Backup Server storage, backup only
Image:
  SLES15-SP7-Minimal-VM.x86_64-Cloud-QU4.qcow2
```

`stor4b` was confirmed to be backup-only. Therefore the SLES image and VM disks were handled under `local`.

## 1. Enable Disk image and Import content on local storage

Open:

```text
Datacenter
  -> Storage
  -> local
  -> Edit
```

In `Content`, enable at least:

```text
Disk image
Import
ISO image
Container template
Backup
```

`Disk image` allows VM disks to be stored in `local`. `Import` allows uploaded disk images such as qcow2 to appear in the storage's Import view.

## 2. Upload the qcow2 image

Open:

```text
local (node12)
  -> Import
  -> Upload
```

Upload:

```text
SLES15-SP7-Minimal-VM.x86_64-Cloud-QU4.qcow2
```

After upload, the file should appear under:

```text
local (node12)
  -> Import
```

Example:

```text
Name:   SLES15-SP7-Minimal-VM.x86_64-Cloud-QU4.qcow2
Format: qcow2
Size:   approximately 360 MiB
```

## 3. Create an empty template VM

Use the top-right `Create VM` button.

Recommended values:

```text
VM ID: 9007
Name:  sles15sp7-template
OS:    Do not use any media
CPU:   2 cores
Memory: 4 GiB
Network: VirtIO, bridge=vmbr0
Disk: create a small temporary disk, for example 32 GiB
```

The temporary disk is created only because the Web UI wizard expects a disk. It will not be the final boot disk.

## 4. Import the qcow2 image into the VM

Open:

```text
local (node12)
  -> Import
```

Select:

```text
SLES15-SP7-Minimal-VM.x86_64-Cloud-QU4.qcow2
```

Click:

```text
Import
```

The dialog is named `Import Hard Disk`. Choose:

```text
Target Guest: 9007 (sles15sp7-template)
```

After the import, open:

```text
VM 9007
  -> Hardware
```

Observed result:

```text
Hard Disk (scsi0)  local:9007/vm-9007-disk-0.qcow2,size=32G
Hard Disk (scsi1)  local:9007/vm-9007-disk-1.qcow2,size=1585M
```

In this case:

```text
scsi0 = temporary disk from the VM creation wizard
scsi1 = imported SLES 15 SP7 Cloud/JeOS image
```

## 5. Change boot order to the imported image

Open:

```text
VM 9007
  -> Options
  -> Boot Order
  -> Edit
```

Move `scsi1` to the first position.

Recommended boot order:

```text
1. scsi1
2. scsi0
3. ide2
4. net0
```

Click `OK`.

## 6. Start the VM and complete JeOS Firstboot

Start VM 9007 and open the console.

The imported image may show:

```text
JeOS Firstboot
Welcome to SUSE Linux Enterprise Server 15 SP7
```

This is expected for the SLES Minimal/JeOS image. If Firstboot is canceled, it reappears after reboot. Therefore complete it once for the template base.

Recommended settings:

```text
Language: English (US)
Keyboard: English (US)
Timezone: Asia/Tokyo
User: sles, or use root only for template preparation
```

English (US) keyboard is recommended for server template work because Linux console, SSH, shell commands, and automation commonly assume US key layout.

## 7. Verify the OS and cloud-init

After login, verify:

```bash
cat /etc/os-release
cloud-init --version
systemctl status cloud-init
```

Expected examples:

```text
PRETTY_NAME="SUSE Linux Enterprise Server 15 SP7"
/usr/bin/cloud-init 23.3-150100.8.85.4
cloud-init.service: loaded/enabled, inactive (dead)
```

`inactive (dead)` is not necessarily an error. Cloud-init is not a long-running daemon; it runs during boot and exits.

Note: on this image, the valid command is:

```bash
cloud-init --version
```

not:

```bash
cloud-init -version
```

## 8. Add CloudInit Drive

Shut down the VM:

```bash
poweroff
```

Then in Proxmox:

```text
VM 9007
  -> Hardware
  -> Add
  -> CloudInit Drive
```

Use storage:

```text
local
```

This should add a CloudInit drive, typically shown as `ide2`.

## 9. Configure Cloud-Init defaults

Open:

```text
VM 9007
  -> Cloud-Init
```

Set template defaults, for example:

```text
User: sles
Password: optional temporary password
SSH public key: paste the Windows/operator public key
IP Config: DHCP for the template
DNS: optional
```

If the UI provides `Regenerate Image`, run it after changes.

For production-like or repeatable lab use, set only generic template defaults here. Per-node IP addresses and hostnames should be set after cloning.

## 10. Optional: resize the imported boot disk

The imported SLES Cloud/JeOS image may be small, for example around 1.5 GiB.

For a reusable Kubernetes template, resize the boot disk before cloning:

```text
VM 9007
  -> Hardware
  -> select Hard Disk (scsi1)
  -> Disk Action
  -> Resize
```

Example:

```text
+30G
```

For final node sizes, resize clones according to role:

```text
Control-plane nodes: 80-100 GiB
Worker nodes:        100-200+ GiB
NFS node:            according to SAS storage needs
```

## 11. Clean the template before converting

Start the VM one last time and run:

```bash
cloud-init clean
rm -rf /var/lib/cloud/*
truncate -s 0 /etc/machine-id
rm -f /var/lib/dbus/machine-id
```

Optional log cleanup:

```bash
journalctl --rotate
journalctl --vacuum-time=1s
rm -f /var/log/cloud-init*.log
history -c || true
```

Then shut down:

```bash
poweroff
```

## 12. Convert to template

In Proxmox:

```text
VM 9007
  -> More
  -> Convert to Template
```

The template can then be cloned into the RKE2/SAS Viya infrastructure nodes.

## 13. Clone strategy

Create linked or full clones depending on the lab requirement.

For predictable behavior and easier movement/backup, full clone is safer:

```text
sas-cp-01
sas-cp-02
sas-cp-03
sas-worker-01
sas-worker-02
sas-worker-03
nfs-01
```

For each clone, set:

```text
Cloud-Init hostname
Cloud-Init IP address or DHCP reservation
CPU / memory
Disk size
```

Then boot each VM and confirm SSH access from the Windows workstation before running the PowerShell bootstrap scripts.

## Notes and decisions

- `stor4b` was not used because it is configured as backup-only.
- The imported image attached as `scsi1`; therefore Boot Order had to be changed from `scsi0` to `scsi1`.
- The initially created `scsi0` disk was treated as temporary. It can be detached or removed after confirming the imported image boots correctly.
- JeOS Firstboot must be completed once; canceling it causes it to appear again on reboot.
- Cloud-init is present in the image and suitable for clone customization.
