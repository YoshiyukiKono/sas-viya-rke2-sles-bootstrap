. "$PSScriptRoot\common.ps1"

$targets = @(@{ Name = $NfsServerName; IP = $NfsServer }) + (Get-AllK8sNodes)
foreach ($node in $targets) {
  $cmd = @"
set -euxo pipefail
sudo hostnamectl set-hostname $($node.Name)
sudo zypper --non-interactive refresh
sudo zypper --non-interactive update
sudo zypper --non-interactive install curl jq vim tar gzip ca-certificates qemu-guest-agent chrony
sudo systemctl enable --now qemu-guest-agent || true
sudo systemctl enable --now chronyd || true
sudo swapoff -a || true
sudo sed -i.bak '/[[:space:]]swap[[:space:]]/ s/^/#/' /etc/fstab || true
sudo modprobe br_netfilter || true
sudo modprobe overlay || true
cat <<'EOM' | sudo tee /etc/modules-load.d/k8s.conf
br_netfilter
overlay
EOM
cat <<'EOM' | sudo tee /etc/sysctl.d/99-kubernetes.conf
net.bridge.bridge-nf-call-iptables = 1
net.bridge.bridge-nf-call-ip6tables = 1
net.ipv4.ip_forward = 1
EOM
sudo sysctl --system
if systemctl is-active --quiet firewalld; then
  echo "firewalld is active. Opening common RKE2/NFS ports."
  sudo firewall-cmd --permanent --add-port=6443/tcp || true
  sudo firewall-cmd --permanent --add-port=9345/tcp || true
  sudo firewall-cmd --permanent --add-port=8472/udp || true
  sudo firewall-cmd --permanent --add-service=nfs || true
  sudo firewall-cmd --permanent --add-service=mountd || true
  sudo firewall-cmd --permanent --add-service=rpc-bind || true
  sudo firewall-cmd --reload || true
else
  echo "firewalld is not active."
fi
"@
  Invoke-Remote -Host $node.IP -Command $cmd
}
