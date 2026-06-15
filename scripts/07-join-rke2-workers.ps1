. "$PSScriptRoot\common.ps1"

foreach ($node in $WorkerNodes) {
  $cmd = @"
set -euxo pipefail
sudo mkdir -p /etc/rancher/rke2
cat <<'EOM' | sudo tee /etc/rancher/rke2/config.yaml
server: https://$FirstServer:9345
token: "$Rke2Token"
EOM
curl -sfL https://get.rke2.io | sudo INSTALL_RKE2_VERSION="$Rke2Version" INSTALL_RKE2_TYPE="agent" sh -
sudo systemctl enable --now rke2-agent
"@
  Invoke-Remote -Host $node.IP -Command $cmd
}
