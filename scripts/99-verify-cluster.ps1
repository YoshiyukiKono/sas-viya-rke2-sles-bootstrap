. "$PSScriptRoot\common.ps1"

$cmd = @"
set -euxo pipefail
export KUBECONFIG=/etc/rancher/rke2/rke2.yaml
export PATH=/var/lib/rancher/rke2/bin:/usr/local/bin:\$PATH
kubectl get nodes -o wide
kubectl get pods -A
kubectl get sc
kubectl get ns $SasNamespace || true
kubectl version
"@
Invoke-Remote -Host $FirstServer -Command $cmd
