. "$PSScriptRoot\common.ps1"

$tlsSansYaml = ($KubeApiTlsSans | Sort-Object -Unique | ForEach-Object { "  - $_" }) -join "`n"

$cmd = @"
set -euxo pipefail
sudo mkdir -p /etc/rancher/rke2
cat <<'EOM' | sudo tee /etc/rancher/rke2/config.yaml
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
sudo /var/lib/rancher/rke2/bin/kubectl --kubeconfig /etc/rancher/rke2/rke2.yaml get nodes
"@
Invoke-Remote -Host $FirstServer -Command $cmd
