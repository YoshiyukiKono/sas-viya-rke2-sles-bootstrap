. "$PSScriptRoot\common.ps1"

foreach ($node in (Get-AllK8sNodes)) {
  $cmd = @"
set -euxo pipefail
sudo zypper --non-interactive install nfs-client
showmount -e $NfsServer || true
"@
  Invoke-Remote -Host $node.IP -Command $cmd
}
