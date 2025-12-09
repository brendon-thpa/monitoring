
<# 
  start_all.ps1
  Starts Prometheus and Grafana (Windows binaries) by invoking their scripts.

  Usage examples:
    .\start_all.ps1
    .\start_all.ps1 -PromPort 9091 -GrafPort 3200
    .\start_all.ps1 -AdminUser admin -AdminPassword s3cret
#>

[CmdletBinding()]
param(
  [int]$PromPort = 9090,
  [int]$GrafPort = 3000,
  [string]$AdminUser = "admin",
  [string]$AdminPassword = "admin",
  [string]$PromScript = "$PSScriptRoot\start_prometheus.ps1",
  [string]$GrafScript = "$PSScriptRoot\start_grafana.ps1",
  [switch]$SkipGrafana,   # start only Prometheus
  [switch]$SkipPrometheus # start only Grafana
)

$ErrorActionPreference = "Stop"

Write-Host "Root dir     : $PSScriptRoot"
Write-Host "Prom script  : $PromScript"
Write-Host "Graf script  : $GrafScript"
Write-Host "Prom port    : $PromPort"
Write-Host "Graf port    : $GrafPort"
Write-Host "Graf admin   : $AdminUser / $AdminPassword"
Write-Host ""

# Ensure scripts exist
if (-not (Test-Path $PromScript)) { throw "Prometheus start script not found at $PromScript" }
if (-not (Test-Path $GrafScript) -and -not $SkipGrafana) { throw "Grafana start script not found at $GrafScript" }

# Allow running local scripts in this session
Try {
  Set-ExecutionPolicy -Scope Process -ExecutionPolicy Bypass -Force
} Catch {
  Write-Warning "Could not set execution policy (continuing): $($_.Exception.Message)"
}

# Helper to invoke a script with arguments and print progress
function Invoke-StartScript {
  param(
    [string]$ScriptPath,
    [hashtable]$Parameters
  )
  $paramPairs = $Parameters.GetEnumerator() | ForEach-Object { "-$($_.Key) `"$($_.Value)`"" }
  Write-Host "→ Running: $([System.IO.Path]::GetFileName($ScriptPath)) $($paramPairs -join ' ')"
  & $ScriptPath @Parameters
}

# Start Prometheus
if (-not $SkipPrometheus) {
  Invoke-StartScript -ScriptPath $PromScript -Parameters @{ Port = $PromPort }
} else {
  Write-Host "Skipping Prometheus startup (SkipPrometheus switch set)."
}

# Start Grafana
if (-not $SkipGrafana) {
  Invoke-StartScript -ScriptPath $GrafScript -Parameters @{
    Port          = $GrafPort
    AdminUser     = $AdminUser
    AdminPassword = $AdminPassword
  }
} else {
  Write-Host "Skipping Grafana startup (SkipGrafana switch set)."
}

Write-Host ""
Write-Host "✅ Prometheus: http://localhost:$PromPort"
if (-not $SkipGrafana) { Write-Host "✅ Grafana   : http://localhost:$GrafPort  (user: $AdminUser / pass: $AdminPassword)" }
Write-Host ""
