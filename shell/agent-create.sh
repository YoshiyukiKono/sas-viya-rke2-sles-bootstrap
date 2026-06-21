TOKEN=$(ssh suse@10.110.0.191 "sudo cat /var/lib/rancher/rke2/server/node-token")

for entry in \
  "10.110.0.192 viya-control" \
  "10.110.0.193 viya-compute" \
  "10.110.0.195 viya-default" \
  "10.110.0.196 viya-cas" \
  "10.110.0.197 viya-stateful" \
  "10.110.0.198 viya-stateless"
do
  set -- $entry
  IP="$1"
  HOST="$2"

  echo "=== install agent on $HOST ($IP) ==="

  ssh suse@$IP "sudo mkdir -p /etc/rancher/rke2 && cat <<EOF | sudo tee /etc/rancher/rke2/config.yaml
server: https://10.110.0.191:9345
token: $TOKEN
node-ip: $IP
EOF
curl -sfL https://get.rke2.io | INSTALL_RKE2_TYPE=agent sudo sh -
sudo systemctl enable rke2-agent
sudo systemctl start rke2-agent"
done
