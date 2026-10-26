$ErrorActionPreference = "Stop"

$preflight = Join-Path $PSScriptRoot "preflight-frontend-specialists.ps1"
if (-not (Test-Path -LiteralPath $preflight -PathType Leaf)) {
    throw "Unified specialist preflight is missing: $preflight"
}

Write-Host "Frontend Production QA - live specialist update evidence"
Write-Host "========================================================"
Write-Host "Delegating to the task-aware live-source preflight for all managed external specialists."
Write-Host "No external version is pinned in this script and no changes are made."
Write-Host ""

& $preflight -All
exit $LASTEXITCODE
