. "$PSScriptRoot\common.ps1"

$out = Join-Path $RepoRoot $OutputDir
New-Item -ItemType Directory -Force -Path $out | Out-Null
$local = Join-Path $out "kubeconfig-sas.yaml"
Copy-FromRemote -Host $FirstServer -RemotePath "/etc/rancher/rke2/rke2.yaml" -LocalPath $local
(Get-Content $local) -replace "https://127.0.0.1:6443", "https://$KubeApiEndpoint`:6443" | Set-Content $local
Write-Host "Saved $local"
