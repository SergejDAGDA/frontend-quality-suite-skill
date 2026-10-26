$ErrorActionPreference = "Stop"

$root = (Resolve-Path (Join-Path $PSScriptRoot "..")).Path
$pluginPath = Join-Path $root "plugin.json"
$manifestPath = Join-Path $root "skills\frontend-production-qa\dependencies.yaml"
$orchestratorPath = Join-Path $root "skills\frontend-production-qa\SKILL.md"
$accessibilityPath = Join-Path $root "skills\frontend-accessibility-qa\SKILL.md"
$contrastPath = Join-Path $root "skills\frontend-accessibility-qa\references\contrast-policy.md"
$agentsPath = Join-Path $root "skills\frontend-production-qa\assets\AGENTS.frontend.fragment.md"
$readmePath = Join-Path $root "README.md"
$readmeRuPath = Join-Path $root "README.ru.md"

$plugin = Get-Content -LiteralPath $pluginPath -Raw | ConvertFrom-Json
if ($plugin.version -ne "1.4.0") {
    throw "plugin.json is not the expected 1.4.0 candidate"
}

$manifest = Get-Content -LiteralPath $manifestPath -Raw
$bundledBlock = [regex]::Match($manifest, '(?ms)^bundled:\s*(?<body>.*?)(?=^recommended:)').Groups['body'].Value
$requiredBlock = [regex]::Match($manifest, '(?ms)^required:\s*(?<body>.*?)(?=^bundled:)').Groups['body'].Value
$recommendedBlock = [regex]::Match($manifest, '(?ms)^recommended:\s*(?<body>.*?)(?=^optional_unmanaged:)').Groups['body'].Value

if ($bundledBlock -notmatch '(?ms)- name:\s*frontend-accessibility-qa\s*\r?\n\s+path:\s*\.\/skills\/frontend-accessibility-qa') {
    throw "frontend-accessibility-qa is not declared as a bundled skill"
}
if ($requiredBlock -match 'wcag-2\.2-aa|apca-contrast|frontend-accessibility-qa' -or
    $recommendedBlock -match 'wcag-2\.2-aa|apca-contrast') {
    throw "External WCAG/APCA skills drifted into runtime dependency classes"
}
if ($manifest -match '84emllc|thrillmade') {
    throw "Reference-only WCAG/APCA upstream leaked into dependency manifest"
}

$accessibility = Get-Content -LiteralPath $accessibilityPath -Raw
if ($accessibility -notmatch '(?m)^name:\s*frontend-accessibility-qa\s*$') {
    throw "Accessibility skill frontmatter ID is missing or wrong"
}
foreach ($requiredText in @(
    'WCAG 2.2 Level A and AA',
    'APCA is an optional perceptual design signal',
    'DESIGN_GUARD',
    'AFFECTED_AUDIT',
    'FULL_AUDIT',
    'must not reopen a completed hard-gate remediation loop more than once'
)) {
    if ($accessibility -notmatch [regex]::Escape($requiredText)) {
        throw "Accessibility policy invariant missing: $requiredText"
    }
}

$contrast = Get-Content -LiteralPath $contrastPath -Raw
if ($contrast -notmatch 'APCA cannot waive WCAG' -or
    $contrast -notmatch 'APCA cannot force a change that creates a WCAG failure') {
    throw "Contrast arbitration invariants are missing"
}

$orchestrator = Get-Content -LiteralPath $orchestratorPath -Raw
foreach ($requiredText in @(
    'frontend-accessibility-qa',
    'WCAG 2.2 A/AA is the hard accessibility gate',
    'DESIGN_GUARD',
    'AFFECTED_AUDIT',
    'FULL_AUDIT',
    'Phase 9 — Accessibility closure'
)) {
    if ($orchestrator -notmatch [regex]::Escape($requiredText)) {
        throw "Orchestrator accessibility routing invariant missing: $requiredText"
    }
}

$agents = Get-Content -LiteralPath $agentsPath -Raw
if ($agents -notmatch 'frontend-accessibility-qa' -or $agents -notmatch 'APCA is advisory') {
    throw "AGENTS routing fragment does not preserve accessibility authority"
}

$readme = Get-Content -LiteralPath $readmePath -Raw
$readmeRu = Get-Content -LiteralPath $readmeRuPath -Raw
if ($readme -notmatch 'frontend-accessibility-qa' -or $readme -notmatch 'WCAG 2.2 Level A/AA') {
    throw "English README does not document bundled accessibility architecture"
}
if ($readmeRu -notmatch 'frontend-accessibility-qa' -or $readmeRu -notmatch 'WCAG 2.2 Level A/AA') {
    throw "Russian README does not document bundled accessibility architecture"
}

Write-Host "Accessibility architecture fixtures PASS."
exit 0
