param(
    [Parameter(Mandatory = $true)][string]$SkillId,
    [Parameter(Mandatory = $true)][ValidateSet("install", "update")][string]$Action,
    [switch]$Apply
)

$ErrorActionPreference = "Stop"

$scriptRoot = Split-Path -Parent $MyInvocation.MyCommand.Path
$skillRoot = Split-Path -Parent $scriptRoot
$registryPath = Join-Path $skillRoot "specialists.json"
$preflightPath = Join-Path $scriptRoot "preflight-frontend-specialists.ps1"

$registry = Get-Content -LiteralPath $registryPath -Raw | ConvertFrom-Json
$matches = @($registry.specialists | Where-Object { $_.key -eq $SkillId -or @($_.skill_ids) -contains $SkillId })
if ($matches.Count -ne 1) {
    throw "Unknown or ambiguous specialist/Skill ID: $SkillId"
}
$spec = $matches[0]

function Invoke-Preflight {
    $json = (& pwsh -NoLogo -NoProfile -NonInteractive -File $preflightPath -SkillId $spec.key -Json 2>&1 | Out-String)
    if ($LASTEXITCODE -ne 0 -or -not $json.Trim()) {
        throw "Specialist preflight failed: $json"
    }
    $rows = @($json | ConvertFrom-Json)
    if ($rows.Count -ne 1) { throw "Expected exactly one preflight result." }
    return $rows[0]
}

function Invoke-Checked {
    param(
        [Parameter(Mandatory = $true)][string]$Executable,
        [Parameter(Mandatory = $true)][string[]]$Arguments
    )
    Write-Host ("> " + $Executable + " " + ($Arguments -join " "))
    & $Executable @Arguments
    if ($LASTEXITCODE -ne 0) {
        throw "Command failed with exit code $LASTEXITCODE: $Executable $($Arguments -join ' ')"
    }
}

function Get-RepositoryIdentity {
    param([string]$Url)
    if ([string]::IsNullOrWhiteSpace($Url)) { return $null }
    $m = [regex]::Match(
        $Url.Trim(),
        '^(?:https://github\.com/|git@github\.com:)(?<owner>[a-zA-Z0-9_.-]+)/(?<repo>[a-zA-Z0-9_.-]+?)(?:\.git)?/?$'
    )
    if (-not $m.Success) { return $null }
    return ($m.Groups["owner"].Value + "/" + $m.Groups["repo"].Value).ToLowerInvariant()
}

function Assert-MarketplaceOwnership {
    param($Spec)

    if (-not (Get-Command codex -ErrorAction SilentlyContinue)) {
        throw "Codex CLI is unavailable."
    }
    if (-not (Get-Command git -ErrorAction SilentlyContinue)) {
        throw "Git is required to verify marketplace ownership."
    }

    $raw = (& codex plugin marketplace list --json 2>&1 | Out-String)
    if ($LASTEXITCODE -ne 0 -or -not $raw.Trim()) {
        throw "Unable to read native Codex marketplace inventory."
    }
    $markets = $raw | ConvertFrom-Json
    $hits = @($markets.marketplaces | Where-Object { $_.name -eq $Spec.marketplace })
    if ($hits.Count -ne 1) {
        throw "Expected exactly one registered marketplace named $($Spec.marketplace)."
    }

    $root = [string]$hits[0].root
    if (-not (Test-Path -LiteralPath $root -PathType Container)) {
        throw "Marketplace checkout root is missing or inaccessible."
    }
    $resolvedRoot = (Resolve-Path -LiteralPath $root).Path.TrimEnd('\','/')
    $top = (& git -C $resolvedRoot rev-parse --show-toplevel 2>$null | Out-String).Trim()
    if ($LASTEXITCODE -ne 0 -or -not $top) {
        throw "Marketplace root is not a readable Git checkout."
    }
    $resolvedTop = (Resolve-Path -LiteralPath $top).Path.TrimEnd('\','/')
    if (-not [string]::Equals($resolvedRoot, $resolvedTop, [StringComparison]::OrdinalIgnoreCase)) {
        throw "Marketplace root does not match the Git checkout root."
    }
    $origin = (& git -C $resolvedRoot remote get-url origin 2>$null | Out-String).Trim()
    if ($LASTEXITCODE -ne 0 -or -not $origin) {
        throw "Marketplace Git origin is unavailable."
    }

    $observed = Get-RepositoryIdentity -Url $origin
    $expected = ([string]$Spec.repository).ToLowerInvariant()
    if ($observed -ne $expected) {
        throw "Marketplace ownership conflict: expected $expected, observed $observed."
    }

    Write-Host "[VERIFIED] Marketplace Git origin matches $($Spec.repository)."
}

function Print-Plan {
    param($Row)

    Write-Host "Frontend Production QA - specialist mutation plan"
    Write-Host "================================================"
    Write-Host "Specialist: $($spec.key)"
    Write-Host "Skill IDs: $([string]::Join(', ', @($spec.skill_ids)))"
    Write-Host "Owner: $($spec.repository)"
    Write-Host "Channel: $($spec.channel)"
    Write-Host "Requested action: $Action"
    Write-Host "Current status: $($Row.status)"
    if ($Row.installed_version) { Write-Host "Installed version: $($Row.installed_version)" }
    if ($Row.author_version) { Write-Host "Author current: $($Row.author_version)" }
    if ($Row.distribution_version) { Write-Host "Distribution current: $($Row.distribution_version)" }
    Write-Host ""
    Write-Host "Mutation is component-scoped. No unrelated marketplace/package is updated."
    Write-Host "A fresh Codex session may be required before the skill can be relied on."
    Write-Host "No transactional rollback is claimed."
}

$row = Invoke-Preflight
Print-Plan -Row $row

$blockedStatuses = @(
    "CONFLICT",
    "UNKNOWN_REMOTE",
    "UNKNOWN_DISTRIBUTION",
    "UNKNOWN_LOCAL",
    "SOURCE_DIVERGENCE",
    "PROVENANCE_UNKNOWN",
    "DIFFERENT"
)
if ($blockedStatuses -contains $row.status) {
    throw "[BLOCKED] Preflight state $($row.status) does not support a safe automatic mutation. Resolve provenance/evidence first."
}

if ($Action -eq "install" -and $row.status -notin @("MISSING", "MARKETPLACE_MISSING")) {
    if ($row.status -eq "INSTALLED_CURRENT") {
        Write-Host "[NOOP] Specialist is already installed/current."
        exit 0
    }
    throw "[BLOCKED] Install is not appropriate for preflight state $($row.status)."
}

if ($Action -eq "update" -and $row.status -notin @("UPDATE_AVAILABLE", "UPDATE_RECOMMENDED")) {
    if ($row.status -eq "INSTALLED_CURRENT") {
        Write-Host "[NOOP] Specialist already matches the current author source."
        exit 0
    }
    throw "[BLOCKED] Update is not appropriate for preflight state $($row.status)."
}

if (-not $Apply) {
    Write-Host ""
    Write-Host "[PLAN ONLY] No changes made."
    Write-Host "Only run again with -Apply after the user explicitly approves this exact specialist/action."
    exit 0
}

Write-Host ""
Write-Host "[APPLY] Explicit component-scoped mutation requested."

if ($spec.channel -eq "codex-plugin") {
    if (-not (Get-Command codex -ErrorAction SilentlyContinue)) {
        throw "Codex CLI is unavailable."
    }

    if ($row.status -eq "MARKETPLACE_MISSING") {
        Invoke-Checked -Executable "codex" -Arguments @("plugin", "marketplace", "add", [string]$spec.install.marketplace_source)
    }

    Assert-MarketplaceOwnership -Spec $spec

    if ($Action -eq "update") {
        Invoke-Checked -Executable "codex" -Arguments @("plugin", "marketplace", "upgrade", [string]$spec.marketplace)
        Assert-MarketplaceOwnership -Spec $spec
    }

    Invoke-Checked -Executable "codex" -Arguments @("plugin", "add", [string]$spec.plugin_id)
}
elseif ($spec.channel -in @("provider-cli", "provider-installer")) {
    if (-not (Get-Command npx -ErrorAction SilentlyContinue)) {
        throw "npx is unavailable."
    }

    $commandSpec = if ($Action -eq "install") { $spec.install } else { $spec.update }
    $exe = [string]$commandSpec.executable
    $args = @($commandSpec.args | ForEach-Object { [string]$_ })

    if ($spec.key -eq "motion" -and -not [Environment]::UserInteractive) {
        throw "[ENVIRONMENT] Motion's official installer is interactive. Run the displayed current installer in an interactive terminal."
    }

    Invoke-Checked -Executable $exe -Arguments $args
}
else {
    throw "Unsupported mutation channel: $($spec.channel)"
}

Write-Host ""
Write-Host "Post-mutation preflight:"
$post = Invoke-Preflight
Write-Host "  status: $($post.status)"
if ($post.installed_version) { Write-Host "  installed: $($post.installed_version)" }
if ($post.author_version) { Write-Host "  author current: $($post.author_version)" }

if ($post.status -ne "INSTALLED_CURRENT") {
    throw "[NOT VERIFIED] Mutation completed but postflight did not establish a current/usable package state."
}

if ($spec.post_update_note) {
    Write-Host "  note: $($spec.post_update_note)"
}
if ([bool]$spec.fresh_session_required) {
    Write-Host "  RESTART REQUIRED: start a fresh Codex session and resolve the exact Skill ID there before claiming the specialist ran."
}

Write-Host "[DONE] Component mutation completed and package-level postflight ran. Current-session activation is still not implied."
