ssh suse@10.110.0.191 "sudo mkdir -p /etc/rancher/rke2 && cat <<'EOF' | sudo tee /etc/rancher/rke2/config.yaml
write-kubeconfig-mode: \"0644\"
tls-san:
  - 10.110.0.191
node-ip: 10.110.0.191
advertise-address: 10.110.0.191
disable: rke2-ingress-nginx
EOF
curl -sfL https://get.rke2.io | sudo sh -
sudo systemctl enable rke2-server
sudo systemctl start rke2-server"
