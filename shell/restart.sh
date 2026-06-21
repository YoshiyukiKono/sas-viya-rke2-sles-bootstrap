
for ip in 10.110.0.192 10.110.0.193 10.110.0.195 10.110.0.196 10.110.0.197 10.110.0.198; do
  echo "=== restart $ip ==="
  ssh suse@$ip "sudo systemctl restart rke2-agent"
done
ssh suse@10.110.0.191 "sudo systemctl restart rke2-server"
