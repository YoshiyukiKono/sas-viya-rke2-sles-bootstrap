$ErrorActionPreference = "Stop"

$RepoRoot = Resolve-Path (Join-Path $PSScriptRoot "..")
$ConfigPath = Join-Path $RepoRoot "config\cluster.ps1"
if (-not (Test-Path $ConfigPath)) {
  throw "Missing config\cluster.ps1. Copy config\cluster.example.ps1 first."
}
. $ConfigPath

function Get-SshArgs {
  $args = @()
  if ($SshKeyPath -and $SshKeyPath.Trim() -ne "") {
    $args += @("-i", $SshKeyPath)
  }
  $args += @("-o", "StrictHostKeyChecking=accept-new")
  return $args
}

function Invoke-Remote {
  param(
    [Parameter(Mandatory=$true)][string]$Host,
    [Parameter(Mandatory=$true)][string]$Command
  )
  $sshArgs = Get-SshArgs
  Write-Host "==> $Host" -ForegroundColor Cyan
  $Command | ssh @sshArgs "$User@$Host" "bash -s"
}

function Copy-FromRemote {
  param(
    [Parameter(Mandatory=$true)][string]$Host,
    [Parameter(Mandatory=$true)][string]$RemotePath,
    [Parameter(Mandatory=$true)][string]$LocalPath
  )
  $sshArgs = Get-SshArgs
  scp @sshArgs "$User@$Host`:$RemotePath" $LocalPath
}

function Get-AllK8sNodes {
  return @($CpNodes + $WorkerNodes)
}
