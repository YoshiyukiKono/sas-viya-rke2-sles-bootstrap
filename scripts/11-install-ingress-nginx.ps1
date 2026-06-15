. "$PSScriptRoot\common.ps1"

$cmd = @"
set -euxo pipefail
export KUBECONFIG=/etc/rancher/rke2/rke2.yaml
export PATH=/var/lib/rancher/rke2/bin:/usr/local/bin:\$PATH
if ! command -v helm >/dev/null 2>&1; then
  curl https://raw.githubusercontent.com/helm/helm/main/scripts/get-helm-3 | bash
fi
helm repo add ingress-nginx https://kubernetes.github.io/ingress-nginx || true
helm repo update
helm upgrade --install ingress-nginx ingress-nginx/ingress-nginx \
  --namespace ingress-nginx \
  --create-namespace
kubectl get pods -n ingress-nginx
kubectl get svc -n ingress-nginx
"@
Invoke-Remote -Host $FirstServer -Command $cmd
