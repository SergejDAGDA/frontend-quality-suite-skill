param(
    [switch]$InstallImpeccable,
    [switch]$Apply
)

$ErrorActionPreference = "Stop"

# Intentional compatibility guard: prior versions executed multiple unrelated
# installation steps. New bootstrap is a read-only native install handoff.
if ($InstallImpeccable -or $Apply) {
    throw "[BLOCKED] Automatic installation is not authorized or rollback-proven. The legacy multi-component bootstrap is disabled. Review the plan and approve each missing required component in the native Codex Desktop installation interface. No changes made."
}

Write-Host "Frontend Production QA — safe bootstrap plan"
Write-Host "============================================="
& (Join-Path $PSScriptRoot "plan-frontend-dependencies.ps1")
if ($LASTEXITCODE -ne 0) {
    throw "Dependency planner failed; no changes made."
}
Write-Host ""
Write-Host "Required Chrome DevTools MCP: verify in the active Desktop environment."
Write-Host "If missing, obtain separate explicit approval for native MCP registration."
Write-Host "For task-time specialist freshness, run preflight-frontend-specialists.ps1."
Write-Host "For an explicitly approved specialist mutation, execute the exact provider-native command from specialists.json, then rerun preflight."
Write-Host "No changes made. Reload Codex Desktop only after separately approved installation."
