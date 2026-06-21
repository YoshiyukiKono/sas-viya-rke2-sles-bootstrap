cat <<'EOF' | kubectl apply -f -
apiVersion: v1
kind: PersistentVolumeClaim
metadata:
  name: test-rwx-pvc
spec:
  accessModes:
    - ReadWriteMany
  storageClassName: viya-nfs
  resources:
    requests:
      storage: 1Gi
EOF
