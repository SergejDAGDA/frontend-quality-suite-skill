$ErrorActionPreference = "Stop"

$root = (Resolve-Path (Join-Path $PSScriptRoot "..")).Path
$pluginPath = Join-Path $root "plugin.json"
$manifestPath = Join-Path $root "skills\frontend-production-qa\dependencies.yaml"
$orchestratorPath = Join-Path $root "skills\frontend-production-qa\SKILL.md"
$dependenciesPath = Join-Path $root "skills\frontend-production-qa\references\dependencies.md"
$agentsPath = Join-Path $root "skills\frontend-production-qa\assets\AGENTS.frontend.fragment.md"
$readmePath = Join-Path $root "README.md"
$readmeRuPath = Join-Path $root "README.ru.md"
$bootstrapPath = Join-Path $root "skills\frontend-production-qa\scripts\bootstrap-frontend-toolchain.ps1"
$updaterPath = Join-Path $root "skills\frontend-production-qa\scripts\update-frontend-toolchain.ps1"

$plugin = Get-Content -LiteralPath $pluginPath -Raw | ConvertFrom-Json
try {
    $pluginVersion = [version]$plugin.version
}
catch {
    throw "plugin.json version is not a parseable release version: $($plugin.version)"
}
if ($pluginVersion -lt [version]"1.5.0") {
    throw "Taste routing requires plugin version 1.5.0 or newer"
}

$manifest = Get-Content -LiteralPath $manifestPath -Raw
$requiredBlock = [regex]::Match($manifest, '(?ms)^required:\s*(?<body>.*?)(?=^bundled:)').Groups['body'].Value
$bundledBlock = [regex]::Match($manifest, '(?ms)^bundled:\s*(?<body>.*?)(?=^recommended:)').Groups['body'].Value
$recommendedBlock = [regex]::Match($manifest, '(?ms)^recommended:\s*(?<body>.*?)(?=^optional_unmanaged:)').Groups['body'].Value
$optionalBlock = [regex]::Match($manifest, '(?ms)^optional_unmanaged:\s*(?<body>.*)$').Groups['body'].Value

if ($requiredBlock -match '(?m)^\s*- name:\s*design-taste-frontend\s*$' -or
    $bundledBlock -match '(?m)^\s*- name:\s*design-taste-frontend\s*$') {
    throw "Taste drifted into required or bundled ownership"
}
if ($recommendedBlock -notmatch '(?ms)^\s*- name:\s*design-taste-frontend\s*\r?\n\s+provider:\s*Leonxlnx/taste-skill\s*$') {
    throw "Taste is not declared as the expected recommended external specialist"
}
if ($optionalBlock -match '(?m)^\s*-\s*taste-skill\s*$') {
    throw "Obsolete taste-skill placeholder remains in optional_unmanaged"
}

$orchestrator = Get-Content -LiteralPath $orchestratorPath -Raw
foreach ($requiredText in @(
    'Use one art-direction authority per task',
    'design-taste-frontend',
    'Do not let Taste and Impeccable independently establish competing visual directions for the same task',
    'do not alternate Taste -> Impeccable -> Taste in a remediation loop',
    'the bundled `frontend-visual-qa` remains the rendered visual-evidence layer',
    'the bundled `frontend-accessibility-qa` and explicit project/legal requirements override Taste house rules'
)) {
    if ($orchestrator -notmatch [regex]::Escape($requiredText)) {
        throw "Taste routing invariant missing: $requiredText"
    }
}

foreach ($skipText in @(
    'ordinary bug fixes',
    'responsive regressions',
    'exact screenshot/reference matching',
    'accessibility remediation',
    'release QA where no redesign is requested'
)) {
    if ($orchestrator -notmatch [regex]::Escape($skipText)) {
        throw "Taste non-trigger invariant missing: $skipText"
    }
}

$dependencies = Get-Content -LiteralPath $dependenciesPath -Raw
if ($dependencies -notmatch 'The current Skill ID is:' -or
    $dependencies -notmatch 'design-taste-frontend' -or
    $dependencies -notmatch 'codex plugin add taste-skill@taste-skill') {
    throw "Taste dependency documentation is incomplete"
}

$agents = Get-Content -LiteralPath $agentsPath -Raw
if ($agents -notmatch 'one art-direction authority per task' -or
    $agents -notmatch 'design-taste-frontend' -or
    $agents -notmatch 'Impeccable may critique/polish inside it') {
    throw "AGENTS routing fragment does not preserve Taste arbitration"
}

$readme = Get-Content -LiteralPath $readmePath -Raw
$readmeRu = Get-Content -LiteralPath $readmeRuPath -Raw
if ($readme -notmatch 'Conditional Taste art-direction specialist' -or
    $readme -notmatch 'design-taste-frontend' -or
    $readme -notmatch 'one art-direction authority per task') {
    throw "English README does not document Taste routing"
}
if ($readmeRu -notmatch 'Условный Taste art-direction specialist' -or
    $readmeRu -notmatch 'design-taste-frontend' -or
    $readmeRu -notmatch 'один art-direction authority') {
    throw "Russian README does not document Taste routing"
}

$managedSources = (Get-Content -LiteralPath $bootstrapPath -Raw) + [Environment]::NewLine +
                  (Get-Content -LiteralPath $updaterPath -Raw)
if ($managedSources -match 'Leonxlnx/taste-skill' -or
    $managedSources -match 'taste-skill@taste-skill') {
    throw "Taste installation was wired into managed bootstrap/update scripts"
}

Write-Host "Design routing fixtures PASS."
exit 0
