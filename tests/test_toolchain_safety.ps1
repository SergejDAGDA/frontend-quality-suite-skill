$ErrorActionPreference = "Stop"
$root = (Resolve-Path (Join-Path $PSScriptRoot "..")).Path
$base = Join-Path $root "skills\frontend-production-qa\scripts"
$updater = Join-Path $base "update-frontend-toolchain.ps1"
$bootstrap = Join-Path $base "bootstrap-frontend-toolchain.ps1"
$readiness = Join-Path $base "check-frontend-toolchain.ps1"
$dependencyManifest = Join-Path $root "skills\frontend-production-qa\dependencies.yaml"
$pwsh = (Get-Command pwsh -ErrorAction Stop).Source

# Expected failure tests must run in CHILD processes. An in-process
# 'exit 1' can leave the CI job failed even after the parent prints PASS.
function Invoke-Isolated {
    param(
        [Parameter(Mandatory = $true)][string]$Script,
        [string[]]$Arguments = @()
    )
    $outputLines = & $pwsh -NoLogo -NoProfile -NonInteractive -File $Script @Arguments 2>&1
    $code = $LASTEXITCODE
    return [pscustomobject]@{
        Code = $code
        Output = ($outputLines | Out-String)
    }
}

foreach ($component in @("agent-skills", "frontend-production-qa", "impeccable")) {
    $plan = Invoke-Isolated -Script $updater -Arguments @("-Component", $component)
    if ($plan.Code -ne 0 -or $plan.Output -notmatch "\[PLAN ONLY\]") {
        throw "Read-only plan failed for $component (exit $($plan.Code))"
    }
    $blocked = Invoke-Isolated -Script $updater -Arguments @("-Component", $component, "-Apply")
    if ($blocked.Code -eq 0 -or $blocked.Output -notmatch "\[BLOCKED\]") {
        throw "Unsafe apply was not refused for $component (exit $($blocked.Code))"
    }
}
$missing = Invoke-Isolated -Script $updater -Arguments @("-Apply")
if ($missing.Code -eq 0 -or $missing.Output -notmatch "Specify exactly one") {
    throw "Updater accepted absent component selector"
}

# No native mutations are present in the script, including unscoped fallback.
$source = Get-Content -LiteralPath $updater -Raw
if ($source -match '(?m)^\s*&\s*codex\s+plugin\s+marketplace\s+upgrade(?:\s|$)' -or
    $source -match '(?m)^\s*&\s*npx(?:\s|$)') {
    throw "Update script contains an executable package mutation"
}

# Motion is a conditional external recommendation. The suite must not silently
# promote it into required/bundled ownership or wire its installer into managed
# bootstrap/update scripts.
$manifest = Get-Content -LiteralPath $dependencyManifest -Raw
$requiredBlock = [regex]::Match($manifest, '(?ms)^required:\s*(?<body>.*?)(?=^bundled:)').Groups['body'].Value
$bundledBlock = [regex]::Match($manifest, '(?ms)^bundled:\s*(?<body>.*?)(?=^recommended:)').Groups['body'].Value
$recommendedBlock = [regex]::Match($manifest, '(?ms)^recommended:\s*(?<body>.*?)(?=^optional_unmanaged:)').Groups['body'].Value

if ($requiredBlock -match '(?m)^\s*- name:\s*motion\s*$' -or
    $bundledBlock -match '(?m)^\s*- name:\s*motion\s*$') {
    throw "Motion drifted into required or bundled ownership"
}
if ($recommendedBlock -notmatch '(?ms)^\s*- name:\s*motion\s*\r?\n\s+provider:\s*motiondivision/ai-kit\s*$') {
    throw "Motion is not declared as the expected recommended external specialist"
}

$managedSources = (Get-Content -LiteralPath $updater -Raw) + [Environment]::NewLine +
                  (Get-Content -LiteralPath $bootstrap -Raw)
if ($managedSources -match 'motion-ai') {
    throw "Motion installer was wired into managed bootstrap/update scripts"
}

$fixture = Join-Path ([IO.Path]::GetTempPath()) ("frontend-toolchain-fixture-" + [guid]::NewGuid().ToString("N"))
$previousCodexHome = $env:CODEX_HOME
try {
    $env:CODEX_HOME = Join-Path $fixture "codex"
    $direct = Join-Path $env:CODEX_HOME "skills\frontend-visual-qa\SKILL.md"
    $plugin = Join-Path $env:CODEX_HOME "plugins\cache\codex-frontend-production-qa\frontend-production-qa\1.2.1\skills\frontend-visual-qa\SKILL.md"
    New-Item -ItemType Directory -Force -Path (Split-Path $direct), (Split-Path $plugin) | Out-Null
    $header = "---" + [Environment]::NewLine + "name: frontend-visual-qa" + [Environment]::NewLine + "---"

    Set-Content -LiteralPath $direct -Value ($header + [Environment]::NewLine + "legacy")
    Set-Content -LiteralPath $plugin -Value ($header + [Environment]::NewLine + "bundled")
    $divergent = Invoke-Isolated -Script $readiness
    # Readiness may also report unavailable CLI/browser in a CI runner; the
    # isolated fixture asserts the duplicate diagnosis, not host readiness.
    if ($divergent.Output -notmatch "\[AMBIGUOUS\] frontend-visual-qa") {
        throw "Divergent same-ID copies were not reported"
    }

    Set-Content -LiteralPath $direct -Value ($header + [Environment]::NewLine + "bundled")
    $identical = Invoke-Isolated -Script $readiness
    if ($identical.Output -notmatch "\[DUPLICATE\] frontend-visual-qa") {
        throw "Identical same-ID copies were not reported"
    }
}
finally {
    $env:CODEX_HOME = $previousCodexHome
    if (Test-Path -LiteralPath $fixture) {
        Remove-Item -LiteralPath $fixture -Recurse -Force
    }
}

Write-Host "Scoped dependency safety fixtures PASS."
exit 0
