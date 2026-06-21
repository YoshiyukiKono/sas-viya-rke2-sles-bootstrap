for ip in 10.110.0.193 10.110.0.195 10.110.0.198; do
  echo "=== hard reset CNI on $ip ==="
  ssh suse@$ip "sudo systemctl stop rke2-agent && \
    sudo /usr/local/bin/rke2-killall.sh || true; \
    sudo rm -rf /var/lib/cni /var/run/calico /var/lib/calico /run/flannel; \
    sudo systemctl start rke2-agent"
done
