. "$PSScriptRoot\common.ps1"

$all = @(@{ Name = $NfsServerName; IP = $NfsServer }) + (Get-AllK8sNodes)
$hostsLines = ($all | ForEach-Object { "$($_.IP) $($_.Name)" }) -join "`n"

foreach ($node in $all) {
  $cmd = @"
set -euxo pipefail
sudo cp /etc/hosts /etc/hosts.bak.\\$(date +%Y%m%d%H%M%S)
sudo sed -i '/# sas-viya-rke2-bootstrap begin/,/# sas-viya-rke2-bootstrap end/d' /etc/hosts
cat <<'EOM' | sudo tee -a /etc/hosts
# sas-viya-rke2-bootstrap begin
$hostsLines
# sas-viya-rke2-bootstrap end
EOM
cat /etc/hosts
"@
  Invoke-Remote -Host $node.IP -Command $cmd
}
