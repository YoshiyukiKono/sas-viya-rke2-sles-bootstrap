# Copy this file to config/cluster.ps1 and edit values.

$User = "sles"

# Optional: specify SSH private key path. Leave empty to use default ssh-agent/default key.
$SshKeyPath = ""

# NFS server VM. Keep it outside the Kubernetes nodes if possible.
$NfsServer = "192.168.10.90"
$NfsServerName = "nfs-01"
$NfsExportPath = "/exports/viya"
$NfsStorageClassName = "sas-nfs"

# Control plane nodes.
$CpNodes = @(
  @{ Name = "sas-cp-01"; IP = "192.168.10.101" },
  @{ Name = "sas-cp-02"; IP = "192.168.10.102" },
  @{ Name = "sas-cp-03"; IP = "192.168.10.103" }
)

# Worker nodes.
$WorkerNodes = @(
  @{ Name = "sas-worker-01"; IP = "192.168.10.201" },
  @{ Name = "sas-worker-02"; IP = "192.168.10.202" },
  @{ Name = "sas-worker-03"; IP = "192.168.10.203" }
)

$FirstServer = $CpNodes[0].IP
$FirstServerName = $CpNodes[0].Name

# Use a strong value in real environments.
$Rke2Token = "CHANGE-ME-sas-viya-rke2-token"

# Confirm with the target SAS Viya requirements.
$Rke2Version = "v1.33.1+rke2r1"
$Rke2Cni = "calico"

# Optional Kubernetes API VIP or DNS name. Leave empty if not used.
$KubeApiEndpoint = $FirstServer
$KubeApiTlsSans = @($KubeApiEndpoint, $FirstServer, $FirstServerName)

$SasNamespace = "sas-viya"

# Optional ingress domain info used for handover only.
$IngressBaseDomain = "viya.example.local"
$WildcardDnsNote = "Create wildcard DNS such as *.viya.example.local pointing to the ingress LoadBalancer IP."

$OutputDir = "output"

# Optional readiness / handover settings.
$IngressClassName = "nginx"
$LoadBalancerIPRange = "192.168.10.220-192.168.10.240"
$TestImage = "registry.k8s.io/pause:3.9"
