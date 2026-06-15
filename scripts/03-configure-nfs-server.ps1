. "$PSScriptRoot\common.ps1"

$cmd = @"
set -euxo pipefail
sudo zypper --non-interactive install nfs-kernel-server
sudo mkdir -p $NfsExportPath
sudo chown nobody:nogroup $NfsExportPath || sudo chown nobody:nobody $NfsExportPath || true
sudo chmod 0777 $NfsExportPath
sudo cp /etc/exports /etc/exports.bak.\$(date +%Y%m%d%H%M%S) || true
sudo sed -i '\#$NfsExportPath#d' /etc/exports || true
echo '$NfsExportPath *(rw,sync,no_root_squash,no_subtree_check)' | sudo tee -a /etc/exports
sudo exportfs -ra
sudo systemctl enable --now nfs-server
sudo exportfs -v
"@
Invoke-Remote -Host $NfsServer -Command $cmd
