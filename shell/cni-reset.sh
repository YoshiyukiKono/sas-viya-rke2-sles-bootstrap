for ip in 10.110.0.193 10.110.0.195 10.110.0.198; do
  echo "=== reset CNI on $ip ==="
  ssh suse@$ip "sudo systemctl stop rke2-agent && \
    sudo rm -rf /var/lib/cni/networks/* && \
    sudo rm -rf /var/lib/rancher/rke2/agent/containerd/io.containerd.runtime.v2.task/k8s.io/* && \
    sudo systemctl start rke2-agent"
done
