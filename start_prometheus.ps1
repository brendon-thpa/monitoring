
<# 
  start_prometheus.ps1
  Starts Prometheus (Windows) as a background process, writes PID & logs.
  Place this script in the same folder that contains the 'prometheus' directory.
#>

[CmdletBinding()]
param(
  [int]$Port = 9090,
  [string]$PrometheusDir = "$PSScriptRoot\prometheus\bin",
  [string]$ExeName = "prometheus.exe",
  [string]$ConfigFile = "prometheus.yml",
  [string]$DataDirName = "data",
  [string]$LogsDirName = "logs"
)

$ErrorActionPreference = "Stop"

# Paths
$ExePath   = Join-Path $PrometheusDir $ExeName
$CfgPath   = Join-Path $PrometheusDir $ConfigFile
$DataDir   = Join-Path $PrometheusDir $DataDirName
$LogsDir   = Join-Path $PrometheusDir $LogsDirName
$OutLog    = Join-Path $LogsDir "prometheus.out.log"
$ErrLog    = Join-Path $LogsDir "prometheus.err.log"
$PidFile   = Join-Path $PrometheusDir "prometheus.pid"

Write-Host "Prometheus directory : $PrometheusDir"
Write-Host "Executable           : $ExePath"
Write-Host "Config               : $CfgPath"
Write-Host "Data dir             : $DataDir"
Write-Host "Logs dir             : $LogsDir"
Write-Host "Port                 : $Port"

# Validate
if (!(Test-Path $ExePath)) { throw "prometheus.exe not found at $ExePath" }
if (!(Test-Path $CfgPath)) { throw "prometheus.yml not found at $CfgPath" }

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
    Write-Warning "Prometheus already running (PID $existingPid)."
    Write-Host "URL: http://localhost:$Port"
    return
  } else {
    Remove-Item $PidFile -Force -ErrorAction SilentlyContinue
  }
}

# Arguments
$Args = @(
  "--config.file=$CfgPath",
  "--storage.tsdb.path=$DataDir",
  "--web.listen-address=0.0.0.0:$Port"
)

Write-Host "Starting Prometheus…"
$proc = Start-Process -FilePath $ExePath `
                      -ArgumentList $Args `
                      -NoNewWindow `
                      -PassThru `
                      -RedirectStandardOutput $OutLog `
                      -RedirectStandardError  $ErrLog

# Give it a moment
Start-Sleep -Milliseconds 800

# Save PID
$proc.Id | Out-File -FilePath $PidFile -Encoding ascii -Force

Write-Host "Prometheus started. PID: $($proc.Id)"
Write-Host "Logs:"
Write-Host "  $OutLog"
Write-Host "  $ErrLog"
Write-Host "URL: http://localhost:$Port"
