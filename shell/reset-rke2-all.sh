#!/usr/bin/env bash
set -euo pipefail

NODES=(
  10.110.0.191
  10.110.0.192
  10.110.0.193
  10.110.0.195
  10.110.0.196
  10.110.0.197
  10.110.0.198
)

for ip in "${NODES[@]}"; do
  echo "===== RESET RKE2 on ${ip} ====="

  ssh suse@"${ip}" 'bash -s' <<'REMOTE'
set -e

echo "[1] Stop RKE2 services"
sudo systemctl stop rke2-server 2>/dev/null || true
sudo systemctl stop rke2-agent 2>/dev/null || true

echo "[2] Kill all RKE2 processes"
sudo /usr/local/bin/rke2-killall.sh 2>/dev/null || true

echo "[3] Uninstall RKE2"
sudo /usr/local/bin/rke2-uninstall.sh 2>/dev/null || true

echo "[4] Remove RKE2/CNI state"
sudo rm -rf \
  /etc/rancher/rke2 \
  /var/lib/rancher/rke2 \
  /var/lib/cni \
  /var/lib/calico \
  /var/run/calico \
  /run/flannel

echo "[5] Remove CNI links"
sudo ip link delete flannel.1 2>/dev/null || true
for link in $(ip -o link show | awk -F': ' '{print $2}' | grep -E '^(cali|vxlan.calico|cni0)' || true); do
  sudo ip link delete "$link" 2>/dev/null || true
done

echo "[6] Install required packages"
sudo zypper -n install iptables iproute2 nfs-client tcpdump

echo "[7] Fix PATH-sensitive tools"
sudo ln -sf /usr/sbin/iptables /usr/local/bin/iptables
sudo ln -sf /usr/sbin/ip6tables /usr/local/bin/ip6tables || true
sudo ln -sf /usr/sbin/sysctl /usr/local/bin/sysctl

echo "[8] Kernel modules and sysctl"
sudo modprobe br_netfilter
cat <<'SYSCTL' | sudo tee /etc/sysctl.d/99-rke2-network.conf
net.ipv4.ip_forward = 1
net.bridge.bridge-nf-call-iptables = 1
net.bridge.bridge-nf-call-ip6tables = 1
SYSCTL
sudo /usr/sbin/sysctl --system >/dev/null

echo "[9] Verify"
sudo /usr/sbin/sysctl net.ipv4.ip_forward net.bridge.bridge-nf-call-iptables net.bridge.bridge-nf-call-ip6tables
sudo which iptables
echo "OK"
REMOTE

done

echo "===== ALL DONE ====="
