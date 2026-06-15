. "$PSScriptRoot\common.ps1"

$cmd = @"
set -euxo pipefail
export KUBECONFIG=/etc/rancher/rke2/rke2.yaml
export PATH=/var/lib/rancher/rke2/bin:/usr/local/bin:\$PATH
if ! command -v helm >/dev/null 2>&1; then
  curl https://raw.githubusercontent.com/helm/helm/main/scripts/get-helm-3 | bash
fi
helm repo add jetstack https://charts.jetstack.io || true
helm repo update
helm upgrade --install cert-manager jetstack/cert-manager \
  --namespace cert-manager \
  --create-namespace \
  --set crds.enabled=true
kubectl rollout status deployment/cert-manager -n cert-manager --timeout=180s || true
kubectl get pods -n cert-manager
"@
Invoke-Remote -Host $FirstServer -Command $cmd
