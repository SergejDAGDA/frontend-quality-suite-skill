param(
    [ValidateSet("agent-skills", "frontend-production-qa", "impeccable")]
    [string]$Component,

    [switch]$Apply
)

$ErrorActionPreference = "Stop"

Write-Host "Frontend Production QA - targeted dependency maintenance"
Write-Host "========================================================"
Write-Host "No broad or implicit marketplace upgrade is permitted."
Write-Host ""

if (-not $Component) {
    throw "Specify exactly one -Component: agent-skills, frontend-production-qa, or impeccable. No changes made."
}

$plans = @{
    "agent-skills" = @(
        "Owner: addyosmani/agent-skills",
        "Target: agent-skills plugin marketplace and its specialist-skill bundle",
        "Native refresh: codex plugin marketplace upgrade agent-skills",
        "Native materialization: codex plugin add agent-skills@agent-skills"
    )
    "frontend-production-qa" = @(
        "Owner: SergejDAGDA/frontend-quality-suite-skill",
        "Target: frontend-production-qa plugin including bundled frontend-visual-qa and frontend-accessibility-qa",
        "Native refresh: codex plugin marketplace upgrade codex-frontend-production-qa",
        "Native materialization: codex plugin add frontend-production-qa@codex-frontend-production-qa"
    )
    "impeccable" = @(
        "Owner: pbakaus/impeccable",
        "Target: independent Impeccable CLI, skills and potentially hooks",
        "Native update: npx impeccable update",
        "Extra gate: explicitly review hook changes before trusting them"
    )
}

Write-Host "Selected component: $Component"
foreach ($item in $plans[$Component]) { Write-Host "  $item" }
Write-Host ""
Write-Host "Preconditions: identify the active installation and its exact provenance,"
Write-Host "inspect duplicate skill IDs, verify available version and prove a rollback"
Write-Host "that restores package activation/configuration as well as files."
Write-Host "The current Codex marketplace/CLI rollback contract has not been"
Write-Host "verified for this package. A cache directory copy alone is not proof."
Write-Host ""

if (-not $Apply) {
    Write-Host "[PLAN ONLY] No changes made. Run the read-only readiness/update checks."
    exit 0
}

# Safety boundary: unlike the previous implementation this script cannot
# upgrade ALL Git marketplaces, install a different plugin or update Impeccable
# as a side effect. Automatic -Apply stays disabled until the native,
# component-specific restore/activation contract has an executable fixture.
throw "[BLOCKED] Selected update not applied: rollback and active-package identity are NOT VERIFIED. Use an individually authorized native maintenance workstream after proving these gates. No changes made."
