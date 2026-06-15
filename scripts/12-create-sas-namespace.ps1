. "$PSScriptRoot\common.ps1"

$cmd = @"
set -euxo pipefail
export KUBECONFIG=/etc/rancher/rke2/rke2.yaml
export PATH=/var/lib/rancher/rke2/bin:\$PATH
kubectl create namespace $SasNamespace --dry-run=client -o yaml | kubectl apply -f -
kubectl annotate namespace $SasNamespace sas.com/owner="sas-viya" --overwrite
kubectl get ns $SasNamespace
"@
Invoke-Remote -Host $FirstServer -Command $cmd
