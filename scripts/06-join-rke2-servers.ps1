. "$PSScriptRoot\common.ps1"

$joinServers = $CpNodes | Where-Object { $_.IP -ne $FirstServer }
foreach ($node in $joinServers) {
  $tlsSans = @($KubeApiTlsSans + $node.IP + $node.Name) | Sort-Object -Unique
  $tlsSansYaml = ($tlsSans | ForEach-Object { "  - $_" }) -join "`n"
  $cmd = @"
set -euxo pipefail
sudo mkdir -p /etc/rancher/rke2
cat <<'EOM' | sudo tee /etc/rancher/rke2/config.yaml
server: https://$FirstServer:9345
token: "$Rke2Token"
tls-san:
$tlsSansYaml
write-kubeconfig-mode: "0644"
cni: $Rke2Cni
disable:
  - rke2-ingress-nginx
EOM
curl -sfL https://get.rke2.io | sudo INSTALL_RKE2_VERSION="$Rke2Version" INSTALL_RKE2_TYPE="server" sh -
sudo systemctl enable --now rke2-server
"@
  Invoke-Remote -Host $node.IP -Command $cmd
}
