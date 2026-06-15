. $PSScriptRoot\common.ps1

$timestamp = Get-Date -Format "yyyyMMdd-HHmmss"
$outDir = Join-Path $RepoRoot $OutputDir
New-Item -ItemType Directory -Force -Path $outDir | Out-Null
$report = Join-Path $outDir "sas-readiness-$timestamp.txt"

$IngressClassNameToCheck = if (Get-Variable -Name IngressClassName -Scope Global -ErrorAction SilentlyContinue) { $IngressClassName } else { "nginx" }
$TestImageToUse = if (Get-Variable -Name TestImage -Scope Global -ErrorAction SilentlyContinue) { $TestImage } else { "registry.k8s.io/pause:3.9" }
$LbRangeToReport = if (Get-Variable -Name LoadBalancerIPRange -Scope Global -ErrorAction SilentlyContinue) { $LoadBalancerIPRange } else { "not configured in config.ps1" }

$remoteScript = @"
set -euo pipefail
export KUBECONFIG=/etc/rancher/rke2/rke2.yaml
export PATH=/var/lib/rancher/rke2/bin:\$PATH

REPORT=/tmp/sas-readiness.txt
: > \$REPORT

section() {
  echo "" | tee -a \$REPORT
  echo "===== \$1 =====" | tee -a \$REPORT
}

run() {
  echo "" | tee -a \$REPORT
  echo "\$ \$*" | tee -a \$REPORT
  bash -lc "\$*" 2>&1 | tee -a \$REPORT || true
}

section "Cluster identity"
run "hostname"
run "date -Is"
run "kubectl version --output=yaml"
run "kubectl get nodes -o wide"

section "Core pods"
run "kubectl get pods -A -o wide"
run "kubectl get events -A --sort-by=.metadata.creationTimestamp | tail -100"

section "Storage"
run "kubectl get storageclass"
run "kubectl describe storageclass $NfsStorageClassName"
run "kubectl get csidrivers"
run "kubectl get pods -n kube-system | grep -i nfs || true"

section "NFS PVC smoke test"
cat <<PVC | kubectl apply -f -
apiVersion: v1
kind: Namespace
metadata:
  name: sas-readiness-test
---
apiVersion: v1
kind: PersistentVolumeClaim
metadata:
  name: nfs-rwx-test
  namespace: sas-readiness-test
spec:
  accessModes:
    - ReadWriteMany
  storageClassName: $NfsStorageClassName
  resources:
    requests:
      storage: 1Gi
---
apiVersion: v1
kind: Pod
metadata:
  name: nfs-rwx-test
  namespace: sas-readiness-test
spec:
  restartPolicy: Never
  containers:
    - name: test
      image: $TestImageToUse
      command: ["sh", "-c", "echo sas-readiness > /data/test.txt && cat /data/test.txt && sleep 5"]
      volumeMounts:
        - name: data
          mountPath: /data
  volumes:
    - name: data
      persistentVolumeClaim:
        claimName: nfs-rwx-test
PVC
run "kubectl wait --for=condition=Ready pod/nfs-rwx-test -n sas-readiness-test --timeout=180s"
run "kubectl logs -n sas-readiness-test nfs-rwx-test"
run "kubectl get pvc,pv -n sas-readiness-test"
run "kubectl delete namespace sas-readiness-test --wait=false"

section "Ingress and services"
run "kubectl get ingressclass"
run "kubectl get ingressclass $IngressClassNameToCheck -o yaml"
run "kubectl get svc -A"
run "kubectl get svc -A | grep -E 'LoadBalancer|EXTERNAL-IP|ingress|nginx' || true"

section "cert-manager"
run "kubectl get pods -n cert-manager"
run "kubectl get crd | grep cert-manager || true"
run "kubectl get issuers,clusterissuers -A || true"

section "Namespace"
run "kubectl get namespace $SasNamespace -o yaml"

section "Configuration summary"
echo "SAS namespace: $SasNamespace" | tee -a \$REPORT
echo "NFS server: $NfsServer" | tee -a \$REPORT
echo "NFS export: $NfsExportPath" | tee -a \$REPORT
echo "StorageClass: $NfsStorageClassName" | tee -a \$REPORT
echo "Ingress base domain: $IngressBaseDomain" | tee -a \$REPORT
echo "LoadBalancer IP range: $LbRangeToReport" | tee -a \$REPORT
echo "RKE2 version requested: $Rke2Version" | tee -a \$REPORT
echo "RKE2 CNI requested: $Rke2Cni" | tee -a \$REPORT

section "Manual follow-up items"
cat <<ITEMS | tee -a \$REPORT
- Confirm SAS Viya release and supported Kubernetes/RKE2 version.
- Confirm Calico version compatibility.
- Confirm wildcard DNS points to the Ingress LoadBalancer IP.
- Confirm TLS/cert-manager issuer strategy.
- Confirm StorageClass name and RWX requirements with SAS owner.
- Confirm SAS image registry/proxy/air-gap requirements.
- Confirm whether CAS/Compute require dedicated node labels or taints.
ITEMS

cat \$REPORT
"@

Invoke-Remote -Host $FirstServer -Command $remoteScript | Tee-Object -FilePath $report
Write-Host "Saved readiness report: $report" -ForegroundColor Green
