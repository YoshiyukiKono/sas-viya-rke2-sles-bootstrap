# Troubleshooting

## SSH fails

Check:

```powershell
ssh sles@<ip> hostname
```

If using a non-default SSH key, set `$SshKeyPath` in `config/cluster.ps1`.

## sudo fails

The scripts assume passwordless or non-interactive sudo. Confirm:

```bash
sudo -n true
```

## RKE2 server does not start

On the target node:

```bash
sudo systemctl status rke2-server
sudo journalctl -u rke2-server -xe
```

## Worker does not join

Check worker logs:

```bash
sudo systemctl status rke2-agent
sudo journalctl -u rke2-agent -xe
```

Check that port 9345 on the first server is reachable.

## NFS mount issues

On a Kubernetes node:

```bash
showmount -e <nfs-server-ip>
sudo mount -t nfs4 <nfs-server-ip>:/exports/viya /mnt
```

## StorageClass exists but PVC does not bind

Check NFS CSI pods:

```bash
kubectl get pods -n kube-system | grep nfs
kubectl describe pvc <name> -n <namespace>
```
