. "$PSScriptRoot\common.ps1"

$targets = @(@{ Name = $NfsServerName; IP = $NfsServer }) + (Get-AllK8sNodes)
foreach ($node in $targets) {
  Invoke-Remote -Host $node.IP -Command "hostname; id; sudo -n true && echo sudo-ok"
}
