
<# 
  stop_pro_graf.ps1
  Stops Prometheus and Grafana (Windows binaries).
  - Uses PID files if available.
  - Falls back to process-name matching if PID files are absent or stale.
  - Tries graceful stop first, then force-kills if needed.

  Usage:
    .\stop_pro_graf.ps1
#>

[CmdletBinding()]
param(
  [string]$PromDir = "$PSScriptRoot\prometheus",
  [string]$GrafDir = "$PSScriptRoot\grafana",
  [int]$GracefulWaitMs = 1500
)

$ErrorActionPreference = "Continue"

function Stop-ByPidFile {
  param(
    [string]$Name,
    [string]$PidFilePath,
    [int]$GracefulWaitMs = 1500
  )

  if (-not (Test-Path -LiteralPath $PidFilePath)) {
    Write-Host "No PID file found for $Name at $PidFilePath."
    return
  }

  # Read first non-empty trimmed line safely
  $pidText = $null
  try {
    $lines = Get-Content -LiteralPath $PidFilePath -ErrorAction Stop
    foreach ($line in $lines) {
      if (-not [string]::IsNullOrWhiteSpace($line)) {
        $pidText = $line.Trim()
        break
      }
    }
  } catch {
    Write-Warning "Failed to read PID file for $Name at ${PidFilePath}: $($_.Exception.Message)"
  }

  if ([string]::IsNullOrWhiteSpace($pidText)) {
    Write-Host "PID file for $Name is empty or invalid: $PidFilePath"
    try { Remove-Item -LiteralPath $PidFilePath -Force -ErrorAction SilentlyContinue } catch {}
    return
  }

  if ($pidText -notmatch '^\d+$') {
    Write-Host "PID file for $Name contains non-numeric value: '$pidText'"
    try { Remove-Item -LiteralPath $PidFilePath -Force -ErrorAction SilentlyContinue } catch {}
    return
  }

  $procId = [int]$pidText
  $proc   = Get-Process -Id $procId -ErrorAction SilentlyContinue
  if (-not $proc) {
    Write-Host "$Name PID $procId from PID file not found; may already be stopped."
    try { Remove-Item -LiteralPath $PidFilePath -Force -ErrorAction SilentlyContinue } catch {}
    return
  }

  Write-Host "Stopping $Name (PID $procId) using PID file: $PidFilePath"
  try { $proc.CloseMainWindow() | Out-Null } catch {}
  Start-Sleep -Milliseconds $GracefulWaitMs

  if (Get-Process -Id $procId -ErrorAction SilentlyContinue) {
    Write-Host "$Name still running; forcing stop..."
    try { Stop-Process -Id $procId -Force } catch {
      Write-Warning "Force stop failed for $Name (PID $procId): $($_.Exception.Message)"
    }
  }

  try { Remove-Item -LiteralPath $PidFilePath -Force -ErrorAction SilentlyContinue } catch {}
}

function Stop-ByName {
  param(
    [string]$Name,
    [string[]]$ProcessNames,
    [int]$GracefulWaitMs = 1500
  )

  $procs = @()
  foreach ($n in $ProcessNames) {
    $found = Get-Process -Name $n -ErrorAction SilentlyContinue
    if ($found) { $procs += $found }
  }

  if ($procs.Count -eq 0) {
    Write-Host "No running processes found by name for $Name."
    return
  }

  foreach ($p in $procs) {
    Write-Host "Stopping $Name process ($($p.ProcessName)) PID $($p.Id)..."
    try { $p.CloseMainWindow() | Out-Null } catch {}
  }

  Start-Sleep -Milliseconds $GracefulWaitMs

  foreach ($p in $procs) {
    if (Get-Process -Id $p.Id -ErrorAction SilentlyContinue) {
      try { Stop-Process -Id $p.Id -Force } catch {
        Write-Warning "Force stop failed for $Name PID $($p.Id): $($_.Exception.Message)"
      }
    }
  }
}

Write-Host "Stopping services..."
Write-Host "Prometheus dir: $PromDir"
Write-Host "Grafana dir   : $GrafDir"
Write-Host ""

# Prometheus
$PromPidFile = Join-Path $PromDir "prometheus.pid"
Stop-ByPidFile -Name "Prometheus" -PidFilePath $PromPidFile -GracefulWaitMs $GracefulWaitMs
Stop-ByName    -Name "Prometheus" -ProcessNames @('prometheus') -GracefulWaitMs $GracefulWaitMs

# Grafana
$GrafPidFile = Join-Path $GrafDir "grafana.pid"
Stop-ByPidFile -Name "Grafana" -PidFilePath $GrafPidFile -GracefulWaitMs $GracefulWaitMs
Stop-ByName    -Name "Grafana" -ProcessNames @('grafana-server') -GracefulWaitMs $GracefulWaitMs

Write-Host ""
Write-Host "All stop operations completed."
