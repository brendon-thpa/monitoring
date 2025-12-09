
<# 
  start_grafana.ps1
  Starts Grafana (Windows ZIP install) as a background process, writes PID & logs.
  Place this script in the same folder that contains the 'grafana' directory.
#>

[CmdletBinding()]
param(
  [int]$Port = 3000,
  [string]$GrafanaDir = "$PSScriptRoot\grafana",
  [string]$ExeRelPath = "bin\grafana-server.exe",
  [string]$ConfigRelPath = "conf\defaults.ini",
  [string]$DataDirName = "data",
  [string]$LogsDirName = "logs",
  [string]$AdminUser = "admin",
  [string]$AdminPassword = "admin"
)

$ErrorActionPreference = "Stop"

# Paths
$ExePath   = Join-Path $GrafanaDir $ExeRelPath
$CfgPath   = Join-Path $GrafanaDir $ConfigRelPath
$DataDir   = Join-Path $GrafanaDir $DataDirName
$LogsDir   = Join-Path $GrafanaDir $LogsDirName
$OutLog    = Join-Path $LogsDir "grafana.out.log"
$ErrLog    = Join-Path $LogsDir "grafana.err.log"
$PidFile   = Join-Path $GrafanaDir "grafana.pid"

Write-Host "Grafana directory    : $GrafanaDir"
Write-Host "Executable           : $ExePath"
Write-Host "Config               : $CfgPath"
Write-Host "Data dir             : $DataDir"
Write-Host "Logs dir             : $LogsDir"
Write-Host "Port                 : $Port"
Write-Host "Admin credentials    : $AdminUser / $AdminPassword"

# Validate
if (!(Test-Path $ExePath)) { throw "grafana-server.exe not found at $ExePath" }
if (!(Test-Path $CfgPath)) { throw "defaults.ini not found at $CfgPath" }

# Ensure directories
New-Item -ItemType Directory -Force -Path $DataDir | Out-Null
New-Item -ItemType Directory -Force -Path $LogsDir | Out-Null

# Unblock files if needed
Try { Unblock-File -Path $ExePath } Catch {}
Try { Unblock-File -Path $CfgPath } Catch {}

# Check if already running
if (Test-Path $PidFile) {
  $existingPid = Get-Content $PidFile | Select-Object -First 1
  if ($existingPid -and (Get-Process -Id $existingPid -ErrorAction SilentlyContinue)) {
    Write-Warning "Grafana already running (PID $existingPid)."
    Write-Host "URL: http://localhost:$Port"
    return
  } else {
    Remove-Item $PidFile -Force -ErrorAction SilentlyContinue
  }
}

# Arguments per Windows ZIP packaging
$Args = @(
  "--config=$CfgPath",
  "--homepath=$GrafanaDir",
  "--packaging=zip",
  "cfg:default.paths.data=$DataDir",
  "cfg:server.http_port=$Port",
  "cfg:security.admin_user=$AdminUser",
  "cfg:security.admin_password=$AdminPassword"
)

Write-Host "Starting Grafana…"
$proc = Start-Process -FilePath $ExePath `
                      -ArgumentList $Args `
                      -NoNewWindow `
                      -PassThru `
                      -RedirectStandardOutput $OutLog `
                      -RedirectStandardError  $ErrLog

# Give it a moment
Start-Sleep -Seconds 1

# Save PID
$proc.Id | Out-File -FilePath $PidFile -Encoding ascii -Force

Write-Host "Grafana started. PID: $($proc.Id)"
Write-Host "Logs:"
Write-Host "  $OutLog"
Write-Host "  $ErrLog"
Write-Host "URL: http://localhost:$Port"
