. "$PSScriptRoot\common.ps1"

$cmd = @"
set -euxo pipefail
export KUBECONFIG=/etc/rancher/rke2/rke2.yaml
export PATH=/var/lib/rancher/rke2/bin:/usr/local/bin:\$PATH
if ! command -v helm >/dev/null 2>&1; then
  curl https://raw.githubusercontent.com/helm/helm/main/scripts/get-helm-3 | bash
fi
helm repo add csi-driver-nfs https://raw.githubusercontent.com/kubernetes-csi/csi-driver-nfs/master/charts || true
helm repo update
helm upgrade --install csi-driver-nfs csi-driver-nfs/csi-driver-nfs --namespace kube-system
cat <<'EOM' | kubectl apply -f -
apiVersion: storage.k8s.io/v1
kind: StorageClass
metadata:
  name: $NfsStorageClassName
provisioner: nfs.csi.k8s.io
parameters:
  server: $NfsServer
  share: $NfsExportPath
reclaimPolicy: Retain
volumeBindingMode: Immediate
mountOptions:
  - nfsvers=4.1
EOM
kubectl get sc
"@
Invoke-Remote -Host $FirstServer -Command $cmd
