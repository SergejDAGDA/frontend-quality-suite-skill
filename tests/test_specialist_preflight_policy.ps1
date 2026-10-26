$ErrorActionPreference = "Stop"

$root = (Resolve-Path (Join-Path $PSScriptRoot "..")).Path
$skillRoot = Join-Path $root "skills\frontend-production-qa"
$registryPath = Join-Path $skillRoot "specialists.json"
$preflightPath = Join-Path $skillRoot "scripts\preflight-frontend-specialists.ps1"
$updateCheckPath = Join-Path $skillRoot "scripts\check-frontend-updates.ps1"
$bootstrapPath = Join-Path $skillRoot "scripts\bootstrap-frontend-toolchain.ps1"
$orchestratorPath = Join-Path $skillRoot "SKILL.md"
$maintenancePath = Join-Path $skillRoot "references\toolchain-maintenance.md"
$dependenciesPath = Join-Path $skillRoot "dependencies.yaml"
$agentsPath = Join-Path $skillRoot "assets\AGENTS.frontend.fragment.md"
$readmePath = Join-Path $root "README.md"
$readmeRuPath = Join-Path $root "README.ru.md"
$removedManagerPath = Join-Path $skillRoot "scripts\manage-frontend-specialist.ps1"

foreach ($script in @($preflightPath, $updateCheckPath, $bootstrapPath)) {
    $tokens = $null
    $errors = $null
    [void][System.Management.Automation.Language.Parser]::ParseFile(
        $script,
        [ref]$tokens,
        [ref]$errors
    )
    if (@($errors).Count -gt 0) {
        throw "PowerShell syntax errors in $script : $(@($errors) -join '; ')"
    }
}

if (Test-Path -LiteralPath $removedManagerPath) {
    throw "Custom specialist mutation wrapper must remain removed"
}

$registryRaw = Get-Content -LiteralPath $registryPath -Raw
$registry = $registryRaw | ConvertFrom-Json

if ($registry.policy.task_scoped_preflight -ne $true -or
    $registry.policy.live_author_source_required -ne $true -or
    $registry.policy.pinned_external_versions_forbidden -ne $true -or
    $registry.policy.mutation_requires_explicit_user_approval -ne $true) {
    throw "Specialist registry policy invariants are incomplete"
}

if ($registryRaw -match '(?<![A-Za-z0-9])v?\d+\.\d+\.\d+(?![A-Za-z0-9])') {
    throw "Pinned external semantic version found in specialists.json"
}

$expected = @{
    "agent-skills" = @{
        repository = "addyosmani/agent-skills"
        channel = "codex-plugin"
        skills = @("frontend-ui-engineering", "browser-testing-with-devtools")
    }
    "taste" = @{
        repository = "Leonxlnx/taste-skill"
        channel = "codex-plugin"
        skills = @("design-taste-frontend")
    }
    "impeccable" = @{
        repository = "pbakaus/impeccable"
        channel = "provider-cli"
        skills = @("impeccable")
    }
    "motion" = @{
        repository = "motiondivision/ai-kit"
        channel = "provider-installer"
        skills = @("motion")
    }
}

foreach ($key in $expected.Keys) {
    $rows = @($registry.specialists | Where-Object { $_.key -eq $key })
    if ($rows.Count -ne 1) {
        throw "Missing or duplicate registry entry: $key"
    }

    $row = $rows[0]
    if ($row.repository -ne $expected[$key].repository -or
        $row.channel -ne $expected[$key].channel) {
        throw "Registry owner/channel drift for $key"
    }

    foreach ($skill in $expected[$key].skills) {
        if (@($row.skill_ids) -notcontains $skill) {
            throw "Registry Skill ID missing for $key : $skill"
        }
    }

    if (-not $row.author_version.url -or
        $row.author_version.url -notmatch '^https://raw\.githubusercontent\.com/') {
        throw "Live author version source missing for $key"
    }
}

$agent = @($registry.specialists | Where-Object key -eq "agent-skills")[0]
$taste = @($registry.specialists | Where-Object key -eq "taste")[0]
$impeccable = @($registry.specialists | Where-Object key -eq "impeccable")[0]
$motion = @($registry.specialists | Where-Object key -eq "motion")[0]

if ($agent.plugin_id -ne "agent-skills@agent-skills" -or
    $agent.marketplace -ne "agent-skills" -or
    $agent.install.marketplace_source -ne "addyosmani/agent-skills") {
    throw "Agent Skills native identity drifted"
}

if ($taste.plugin_id -ne "taste-skill@taste-skill" -or
    $taste.marketplace -ne "taste-skill" -or
    $taste.install.marketplace_source -ne "Leonxlnx/taste-skill") {
    throw "Taste native identity drifted"
}

foreach ($npmSpec in @($impeccable, $motion)) {
    if (-not $npmSpec.distribution_version.url -or
        $npmSpec.distribution_version.url -notmatch '^https://registry\.npmjs\.org/.+/latest$') {
        throw "Current npm distribution source missing for $($npmSpec.key)"
    }

    foreach ($action in @("install", "update")) {
        $args = @($npmSpec.$action.args)
        if (@($args | Where-Object { $_ -match '@latest$' }).Count -lt 1) {
            throw "$($npmSpec.key) $action does not explicitly request @latest"
        }
    }
}

if ($motion.local_version.kind -ne "payload-hash" -or -not $motion.author_payload.url) {
    throw "Motion must use author payload comparison instead of an invented local semantic version"
}

$preflight = Get-Content -LiteralPath $preflightPath -Raw
foreach ($requiredText in @(
    "Get-MarketplaceEvidence",
    "INSTALLED_CURRENT",
    "UPDATE_AVAILABLE",
    "UPDATE_RECOMMENDED",
    "PROVENANCE_UNKNOWN",
    "SOURCE_DIVERGENCE",
    "UNKNOWN_REMOTE",
    "UNKNOWN_DISTRIBUTION",
    "UNKNOWN_LOCAL"
)) {
    if ($preflight -notmatch [regex]::Escape($requiredText)) {
        throw "Preflight invariant missing: $requiredText"
    }
}

if ($preflight -notmatch 'Invoke-RestMethod') {
    throw "Preflight does not read live remote evidence"
}

$updateCheck = Get-Content -LiteralPath $updateCheckPath -Raw
if ($updateCheck -notmatch 'preflight-frontend-specialists\.ps1' -or
    $updateCheck -notmatch '-All') {
    throw "check-frontend-updates.ps1 does not delegate to unified live preflight"
}

$orchestrator = Get-Content -LiteralPath $orchestratorPath -Raw
foreach ($requiredText in @(
    "Specialist preflight and live-version policy",
    "Current-version truth must be read from the author's live source at preflight time",
    "INSTALLED_NOT_ACTIVE",
    "When an update is available, do not silently keep using the stale specialist",
    "execute the provider's official channel directly",
    "Never update all marketplaces/packages"
)) {
    if ($orchestrator -notmatch [regex]::Escape($requiredText)) {
        throw "Orchestrator preflight invariant missing: $requiredText"
    }
}

if ($orchestrator -match 'manage-frontend-specialist\.ps1') {
    throw "Removed custom mutation wrapper is still referenced by the orchestrator"
}

$maintenance = Get-Content -LiteralPath $maintenancePath -Raw
if ($maintenance -notmatch 'Do not maintain a second custom package manager' -or
    $maintenance -notmatch 'Only after explicit approval' -or
    $maintenance -match 'manage-frontend-specialist\.ps1') {
    throw "Maintenance policy does not preserve the simplified provider-native mutation model"
}

$manifest = Get-Content -LiteralPath $dependenciesPath -Raw
if ($manifest -notmatch 'design-taste-frontend' -or
    $manifest -notmatch 'motiondivision/ai-kit' -or
    $manifest -notmatch 'pbakaus/impeccable') {
    throw "Dependency manifest lost managed specialist identities"
}

$agents = Get-Content -LiteralPath $agentsPath -Raw
if ($agents -notmatch 'live task-scoped preflight' -or
    $agents -notmatch 'Never mutate third-party frontend skills silently') {
    throw "AGENTS routing fragment lacks proactive preflight/mutation boundary"
}

$readme = Get-Content -LiteralPath $readmePath -Raw
$readmeRu = Get-Content -LiteralPath $readmeRuPath -Raw

if ($readme -notmatch 'Live specialist preflight' -or
    $readme -notmatch 'no current external version numbers' -or
    $readme -match 'manage-frontend-specialist\.ps1') {
    throw "English README lacks the simplified live-version policy"
}

if ($readmeRu -notmatch 'Live specialist preflight' -or
    $readmeRu -notmatch 'Текущие номера версий внешних skills' -or
    $readmeRu -match 'manage-frontend-specialist\.ps1') {
    throw "Russian README lacks the simplified live-version policy"
}

Write-Host "Specialist live-preflight fixtures PASS."
exit 0
