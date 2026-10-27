$ErrorActionPreference = "Stop"

$root = (Resolve-Path (Join-Path $PSScriptRoot "..")).Path
$source = Join-Path $root "skills\frontend-production-qa\scripts\preflight-frontend-specialists.ps1"
$tokens = $null
$errors = $null
$ast = [System.Management.Automation.Language.Parser]::ParseFile($source, [ref]$tokens, [ref]$errors)
if (@($errors).Count -gt 0) { throw "Invalid preflight PowerShell syntax" }

# Import selected functions without running the live script entry point.
$functions = @("New-Result", "Get-NormalizedHash", "Get-LiveNpmSkillText", "Inspect-CodexPluginSpecialist", "Inspect-DirectSkillSpecialist")
foreach ($node in $ast.FindAll({ param($n) $n -is [System.Management.Automation.Language.FunctionDefinitionAst] }, $true)) {
    if ($functions -contains $node.Name) { . ([scriptblock]::Create($node.Extent.Text)) }
}
foreach ($name in $functions) {
    if (-not (Get-Command $name -ErrorAction SilentlyContinue)) { throw "Missing $name" }
}

$script:remoteAvailable = $true
$script:remoteChecks = 0
function Test-CurrentChannel {
    param($Spec, [System.Collections.IDictionary]$Result)
    $script:remoteChecks++
    if (-not $script:remoteAvailable) {
        $Result.status = if ($Spec.current_channel.kind -eq "npm-dist-tag") {
            "UNKNOWN_DISTRIBUTION"
        } else {
            "UNKNOWN_REMOTE"
        }
        $Result.detail = "Synthetic upstream outage"
        $Result.suggested_action = "Retry the authoritative provider check before install/update."
        return $false
    }
    $Result.current_version = if ($Spec.key -eq "motion") { "14.2.0" } else { "2.1.5" }
    return $true
}
function Get-SkillRecords { param([string[]]$Names) return @($script:records) }
function Assert-State {
    param($Row, [string]$Expected)
    if ($Row.status -ne $Expected) { throw "Expected $Expected, got $($Row.status): $($Row.detail)" }
}

$taste = [pscustomobject]@{
    key = "taste"; class = "recommended"; skill_ids = @("design-taste-frontend")
    repository = "Leonxlnx/taste-skill"; channel = "codex-plugin"; fresh_session_required = $true
}
$direct = [pscustomobject]@{ Origin = "DIRECT_USER"; SkillId = "design-taste-frontend"; Path = "direct/SKILL.md" }
$cached = [pscustomobject]@{ Origin = "PLUGIN_CACHE"; SkillId = "design-taste-frontend"; Path = "cache/SKILL.md" }

$script:records = @($direct)
$row = Inspect-CodexPluginSpecialist -Spec $taste
Assert-State $row "PROVENANCE_UNKNOWN"
if ($row.detail -notmatch "No duplicate") { throw "Single direct Taste was labeled a duplicate" }

$script:records = @($direct, $cached)
Assert-State (Inspect-CodexPluginSpecialist -Spec $taste) "CONFLICT"
$script:records = @($direct, [pscustomobject]@{
    Origin = "DIRECT_PROJECT"; SkillId = "design-taste-frontend"; Path = "project/SKILL.md"
})
Assert-State (Inspect-CodexPluginSpecialist -Spec $taste) "CONFLICT"

# Duplicate detection must remain authoritative when the provider manifest is offline.
$script:remoteAvailable = $false
$script:records = @($direct, $cached)
$checksBefore = $script:remoteChecks
Assert-State (Inspect-CodexPluginSpecialist -Spec $taste) "CONFLICT"
if ($script:remoteChecks -ne $checksBefore) { throw "Duplicate detection must not depend on Taste network availability" }

$script:records = @($direct, [pscustomobject]@{
    Origin = "DIRECT_PROJECT"; SkillId = "design-taste-frontend"; Path = "project/SKILL.md"
})
Assert-State (Inspect-CodexPluginSpecialist -Spec $taste) "CONFLICT"
if ($script:remoteChecks -ne $checksBefore) { throw "Direct-copy duplicates must not require a provider request" }

$script:records = @($direct)
Assert-State (Inspect-CodexPluginSpecialist -Spec $taste) "PROVENANCE_UNKNOWN"
$script:records = @()
Assert-State (Inspect-CodexPluginSpecialist -Spec $taste) "UNKNOWN_REMOTE"
$script:remoteAvailable = $true

# LF and CRLF versions of the same text must hash identically.
$lfEnd = [string][char]10
$crlfEnd = [string][char]13 + [char]10
$lf = "first" + $lfEnd + "second" + $lfEnd + "third"
$crlf = $lf.Replace($lfEnd, $crlfEnd)
if ((Get-NormalizedHash -Text $lf) -cne (Get-NormalizedHash -Text $crlf)) {
    throw "Get-NormalizedHash does not normalize Windows CRLF to LF"
}
$literalEscapes = 'first\nsecond\nthird'
if ((Get-NormalizedHash -Text $lf) -ceq (Get-NormalizedHash -Text $literalEscapes)) {
    throw "Get-NormalizedHash converted real line breaks to escaped text"
}

$temp = Join-Path ([IO.Path]::GetTempPath()) ("motion-npm-fixture-" + [guid]::NewGuid().ToString("N"))
try {
    $dir = Join-Path $temp "package\content\skills\motion"
    [void][IO.Directory]::CreateDirectory($dir)
    $payload = "---" + $crlfEnd + "name: motion" + $crlfEnd + "---" + $crlfEnd + "Release fixture"
    $installedLfPayload = $payload.Replace($crlfEnd, $lfEnd)
    [IO.File]::WriteAllText((Join-Path $dir "SKILL.md"), $payload, [Text.Encoding]::UTF8)
    $script:archive = Join-Path $temp "release.tgz"
    & tar -czf $script:archive -C $temp "package/content/skills/motion/SKILL.md"
    if ($LASTEXITCODE -ne 0) { throw "Unable to create release fixture" }
    $sha = [Security.Cryptography.SHA512]::Create()
    try { $script:integrity = [Convert]::ToBase64String($sha.ComputeHash([IO.File]::ReadAllBytes($script:archive))) }
    finally { $sha.Dispose() }

    function Invoke-RestMethod {
        param($Uri, $Headers, $Method, $TimeoutSec)
        return [pscustomobject]@{
            version = "14.2.0"
            dist = [pscustomobject]@{
                tarball = "https://registry.npmjs.org/motion-ai/-/motion-ai-14.2.0.tgz"
                integrity = "sha512-$script:integrity"
            }
        }
    }
    function Invoke-WebRequest {
        param($Uri, $Headers, $OutFile, $TimeoutSec)
        Copy-Item -LiteralPath $script:archive -Destination $OutFile -Force
    }

    $motion = [pscustomobject]@{
        key = "motion"; class = "recommended"; skill_ids = @("motion")
        repository = "motiondivision/ai-kit"; channel = "provider-installer"; fresh_session_required = $true
        current_channel = [pscustomobject]@{
            kind = "npm-dist-tag"; package = "motion-ai"; url = "https://registry.npmjs.org/motion-ai/latest"
        }
        local_version = [pscustomobject]@{ kind = "npm-release-payload" }
    }
    $script:records = @([pscustomobject]@{
        Origin = "DIRECT_USER_LEGACY"; SkillId = "motion"; Path = "motion/SKILL.md"
        Hash = (Get-NormalizedHash -Text $installedLfPayload)
    })
    Assert-State (Inspect-DirectSkillSpecialist -Spec $motion) "INSTALLED_CURRENT"

    # Frozen acceptance matrix: absent provider with unavailable npm must never
    # be reported MISSING or cause an unverified install recommendation.
    $impeccable = [pscustomobject]@{
        key = "impeccable"; class = "recommended"; skill_ids = @("impeccable")
        repository = "pbakaus/impeccable"; channel = "provider-cli"; fresh_session_required = $true
        current_channel = [pscustomobject]@{
            kind = "npm-dist-tag"; package = "impeccable"; url = "https://registry.npmjs.org/impeccable/latest"
        }
        local_version = [pscustomobject]@{ kind = "skill-frontmatter" }
    }
    $installedMotion = $script:records[0]
    $installedImpeccable = [pscustomobject]@{
        Origin = "DIRECT_USER_LEGACY"; SkillId = "impeccable"
        Path = "impeccable/SKILL.md"; Version = "4.3.1"
    }
    $script:remoteAvailable = $false
    foreach ($provider in @($motion, $impeccable)) {
        $script:records = @()
        $row = Inspect-DirectSkillSpecialist -Spec $provider
        Assert-State $row "UNKNOWN_DISTRIBUTION"
        if ($row.suggested_action -match '(?i)^offer.*install') {
            throw "$($provider.key) offered installation without current provider evidence"
        }
    }

    $script:records = @($installedMotion)
    Assert-State (Inspect-DirectSkillSpecialist -Spec $motion) "UNKNOWN_DISTRIBUTION"
    $script:records = @($installedImpeccable)
    Assert-State (Inspect-DirectSkillSpecialist -Spec $impeccable) "UNKNOWN_DISTRIBUTION"

    $script:remoteAvailable = $true
    foreach ($provider in @($motion, $impeccable)) {
        $script:records = @()
        Assert-State (Inspect-DirectSkillSpecialist -Spec $provider) "MISSING"
    }
    $script:records = @($installedMotion)

    # A real direct duplicate remains a conflict while npm is offline.
    $script:remoteAvailable = $false
    $script:records += [pscustomobject]@{
        Origin = "DIRECT_PROJECT"; SkillId = "motion"; Path = "project/motion/SKILL.md"
        Hash = (Get-NormalizedHash -Text $installedLfPayload)
    }
    $checksBefore = $script:remoteChecks
    Assert-State (Inspect-DirectSkillSpecialist -Spec $motion) "CONFLICT"
    if ($script:remoteChecks -ne $checksBefore) { throw "Motion duplicate detection must run before npm requests" }
    $script:records = @($script:records[0])
    $script:remoteAvailable = $true

    $script:records[0].Hash = Get-NormalizedHash -Text "different payload"
    Assert-State (Inspect-DirectSkillSpecialist -Spec $motion) "UPDATE_RECOMMENDED"

    $script:integrity = [Convert]::ToBase64String([Text.Encoding]::UTF8.GetBytes("invalid"))
    Assert-State (Inspect-DirectSkillSpecialist -Spec $motion) "UNKNOWN_DISTRIBUTION"
}
finally {
    if (Test-Path -LiteralPath $temp) {
        Remove-Item -LiteralPath $temp -Recurse -Force -ErrorAction SilentlyContinue
    }
}

Write-Host "Taste/Motion preflight regression fixtures PASS."
exit 0
