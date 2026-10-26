param(
    [ValidateSet("all", "agent-skills", "frontend-production-qa")]
    [string]$Component = "all",
    [switch]$Json
)

$ErrorActionPreference = "Stop"

# Read-only inventory and owner-provenance check. This script NEVER installs,
# updates, registers marketplaces, approves hooks or changes Codex configuration.
$targets = @(
    [pscustomobject]@{
        Component = "agent-skills"
        PluginId = "agent-skills@agent-skills"
        Marketplace = "agent-skills"
        ExpectedRepository = "addyosmani/agent-skills"
        EntrySourceKind = "local"
        RequiredSkillIds = @("frontend-ui-engineering", "browser-testing-with-devtools")
    },
    [pscustomobject]@{
        Component = "frontend-production-qa"
        PluginId = "frontend-production-qa@codex-frontend-production-qa"
        Marketplace = "codex-frontend-production-qa"
        ExpectedRepository = "SergejDAGDA/frontend-quality-suite-skill"
        EntrySourceKind = "url"
        RequiredSkillIds = @("frontend-visual-qa", "frontend-accessibility-qa")
    }
)

function Invoke-CodexReadOnly {
    param([string[]]$Arguments)
    try {
        $output = (& codex @Arguments 2>&1 | Out-String)
        if ($LASTEXITCODE -ne 0 -or -not $output.Trim()) { return $null }
        return ($output | ConvertFrom-Json -ErrorAction Stop)
    }
    catch { return $null }
}

function Get-RepositoryIdentity {
    param([string]$Url)
    if ([string]::IsNullOrWhiteSpace($Url)) { return $null }
    $m = [regex]::Match($Url.Trim(),
        '^(?:https://github\.com/|git@github\.com:)(?<owner>[a-zA-Z0-9_.-]+)/(?<repo>[a-zA-Z0-9_.-]+?)(?:\.git)?/?$')
    if (-not $m.Success) { return $null }
    return ($m.Groups["owner"].Value + "/" + $m.Groups["repo"].Value).ToLowerInvariant()
}

function Get-MarketplaceOwnership {
    param($MarketplaceRecord, $Target)
    $unknown = { param($why) [pscustomobject]@{ Verified = $false; Kind = "UNKNOWN"; Evidence = $why } }
    $conflict = { param($why) [pscustomobject]@{ Verified = $false; Kind = "CONFLICT"; Evidence = $why } }

    if (-not $MarketplaceRecord.root -or -not (Get-Command git -ErrorAction SilentlyContinue)) {
        return (& $unknown "Marketplace root or read-only Git inspection unavailable.")
    }
    $root = [string]$MarketplaceRecord.root
    if (-not (Test-Path -LiteralPath $root -PathType Container)) {
        return (& $unknown "Marketplace root does not exist or is inaccessible.")
    }
    try {
        $root = (Resolve-Path -LiteralPath $root -ErrorAction Stop).Path.TrimEnd('\', '/')
        $top = (& git -C $root rev-parse --show-toplevel 2>$null | Out-String).Trim()
        if ($LASTEXITCODE -ne 0 -or -not $top) {
            return (& $unknown "Marketplace root is not a readable Git checkout.")
        }
        $resolvedTop = (Resolve-Path -LiteralPath $top -ErrorAction Stop).Path.TrimEnd('\', '/')
        if (-not [string]::Equals($resolvedTop, $root, [StringComparison]::OrdinalIgnoreCase)) {
            return (& $unknown "Marketplace root does not equal the Git checkout root.")
        }
        $origin = (& git -C $root remote get-url origin 2>$null | Out-String).Trim()
        if ($LASTEXITCODE -ne 0 -or -not $origin) {
            return (& $unknown "Git checkout origin is unavailable.")
        }
        $observed = Get-RepositoryIdentity -Url $origin
        $expected = $Target.ExpectedRepository.ToLowerInvariant()
        if ($observed -ne $expected) {
            return (& $conflict "Marketplace Git origin does not match the expected owner repository.")
        }

        $catalogPath = Join-Path $root ".agents\plugins\marketplace.json"
        if (-not (Test-Path -LiteralPath $catalogPath -PathType Leaf)) {
            return (& $unknown "Marketplace catalog is unavailable at the expected checkout root.")
        }
        $catalog = Get-Content -LiteralPath $catalogPath -Raw -ErrorAction Stop | ConvertFrom-Json -ErrorAction Stop
        if ($catalog.name -cne $Target.Marketplace) {
            return (& $conflict "Marketplace catalog name does not match the selected marketplace.")
        }
        $pluginName = ($Target.PluginId -split '@', 2)[0]
        $entries = @($catalog.plugins | Where-Object { $_.name -eq $pluginName })
        if ($entries.Count -ne 1) {
            return (& $conflict "Marketplace catalog does not contain exactly one expected plugin entry.")
        }
        $entry = $entries[0]
        if ($entry.source.source -ne $Target.EntrySourceKind) {
            return (& $conflict "Marketplace plugin source kind does not match the expected package.")
        }
        if ($entry.source.source -eq "local") {
            if ($entry.source.path -ne "./") {
                return (& $conflict "Bundled agent-skills package must resolve to this verified checkout root.")
            }
        }
        elseif ($entry.source.source -eq "url") {
            if ((Get-RepositoryIdentity -Url ([string]$entry.source.url)) -ne $expected) {
                return (& $conflict "Marketplace plugin entry points to a different GitHub repository.")
            }
        }
        else {
            return (& $conflict "Unsupported plugin source kind.")
        }
        $manifestPath = Join-Path $root "plugin.json"
        if (Test-Path -LiteralPath $manifestPath -PathType Leaf) {
            $manifest = Get-Content -LiteralPath $manifestPath -Raw -ErrorAction Stop | ConvertFrom-Json -ErrorAction Stop
            if ($manifest.name -ne $pluginName) {
                return (& $conflict "Source checkout plugin.json declares a different plugin ID.")
            }
        }
        # This confirms the local marketplace's recorded Git provenance and
        # catalog entry, NOT remote authenticity or user trust in its content.
        return [pscustomobject]@{
            Verified = $true
            Kind = "VERIFIED_LOCAL_ORIGIN"
            Evidence = "Git origin and catalog plugin source match the expected repository."
        }
    }
    catch {
        return (& $unknown "Marketplace provenance could not be read reliably.")
    }
}

function Get-DirectCollisionPaths {
    param([string[]]$SkillIds)
    $profileHome = if ($env:USERPROFILE) { $env:USERPROFILE } else { $HOME }
    $codexHome = if ($env:CODEX_HOME) { $env:CODEX_HOME } else { Join-Path $profileHome ".codex" }
    $bases = @(
        (Join-Path $codexHome "skills"),
        (Join-Path $profileHome ".agents\skills"),
        (Join-Path (Get-Location).Path ".codex\skills"),
        (Join-Path (Get-Location).Path ".agents\skills")
    )
    $hits = @()
    foreach ($id in $SkillIds) {
        foreach ($base in @($bases | Sort-Object -Unique)) {
            $candidate = Join-Path (Join-Path $base $id) "SKILL.md"
            if (Test-Path -LiteralPath $candidate -PathType Leaf) {
                $hits += [pscustomobject]@{
                    Id = $id
                    Path = (Resolve-Path -LiteralPath $candidate).Path
                }
            }
        }
    }
    return @($hits)
}

$plugins = Invoke-CodexReadOnly -Arguments @("plugin", "list", "--available", "--json")
$marketplaces = Invoke-CodexReadOnly -Arguments @("plugin", "marketplace", "list", "--json")
$rows = @()

foreach ($target in $targets) {
    if ($Component -ne "all" -and $Component -ne $target.Component) { continue }
    $status = "UNKNOWN"
    $reason = ""
    $version = $null
    $root = $null
    $provenance = "UNKNOWN"
    $collisions = @(Get-DirectCollisionPaths -SkillIds $target.RequiredSkillIds)

    if ($null -eq $plugins -or $null -eq $marketplaces -or
        $null -eq $plugins.installed -or $null -eq $plugins.available -or
        $null -eq $marketplaces.marketplaces) {
        $reason = "Native Codex inventory incomplete or inaccessible; no install recommendation."
    }
    else {
        $installed = @($plugins.installed | Where-Object { $_.pluginId -eq $target.PluginId })
        $available = @($plugins.available | Where-Object { $_.pluginId -eq $target.PluginId })
        $market = @($marketplaces.marketplaces | Where-Object { $_.name -eq $target.Marketplace })

        if ($installed.Count -gt 1 -or $available.Count -gt 1 -or $market.Count -gt 1) {
            $status = "CONFLICT"
            $reason = "Ambiguous duplicate native plugin/marketplace records."
        }
        elseif ($installed.Count -eq 1) {
            $version = $installed[0].version
            $status = if ($installed[0].enabled -eq $true) { "INSTALLED" } else { "DISABLED" }
            $reason = "Native Codex CLI registration only; active Desktop session is unverified."
        }
        elseif ($market.Count -eq 0) {
            $status = "MARKETPLACE_MISSING"
            $reason = "Expected marketplace registration absent; verify and approve source separately."
        }
        elseif ($available.Count -eq 1) {
            $version = $available[0].version
            $root = $market[0].root
            $ownership = Get-MarketplaceOwnership -MarketplaceRecord $market[0] -Target $target
            $provenance = $ownership.Kind
            if (-not $ownership.Verified) {
                $status = $ownership.Kind
                $reason = $ownership.Evidence
            }
            elseif ($collisions.Count -gt 0) {
                $status = "CONFLICT"
                $reason = "Required skill IDs already exist in direct user/project paths."
            }
            else {
                $status = "MISSING"
                $reason = "Native CLI reports package missing; verified local Git origin and catalog entry. Review publisher and full bundled contents in Codex."
            }
        }
        else {
            $reason = "Plugin absent from native installed and available records."
        }
    }

    $rows += [pscustomobject]@{
        Component = $target.Component
        PluginId = $target.PluginId
        ExpectedRepository = $target.ExpectedRepository
        Status = $status
        Version = $version
        MarketplaceRoot = $root
        LocalProvenance = $provenance
        Reason = $reason
        DirectIdCollisions = @($collisions)
        NativeInstallAction = if ($status -eq "MISSING") { "/plugins" } else { $null }
    }
}

if ($Json) {
    ConvertTo-Json -InputObject @($rows) -Depth 6
    exit 0
}
Write-Host "Frontend Production QA — dependency inventory (READ ONLY)"
Write-Host "========================================================"
foreach ($row in $rows) {
    Write-Host ""
    Write-Host "$($row.Component): $($row.Status)"
    Write-Host "  plugin: $($row.PluginId)"
    Write-Host "  expected repository: $($row.ExpectedRepository)"
    Write-Host "  local marketplace provenance: $($row.LocalProvenance)"
    if ($row.Version) { Write-Host "  listed version: $($row.Version)" }
    if ($row.MarketplaceRoot) { Write-Host "  marketplace root: $($row.MarketplaceRoot)" }
    Write-Host "  evidence: $($row.Reason)"
    foreach ($hit in $row.DirectIdCollisions) {
        Write-Host "  [COLLISION] $($hit.Id): $($hit.Path)"
    }
    if ($row.NativeInstallAction) {
        Write-Host "  NEXT: Open /plugins in Codex Desktop, select the verified marketplace,"
        Write-Host "        inspect source, publisher, permissions and EVERY bundled skill ID."
        Write-Host "        Install only after your explicit approval in the native UI."
    }
    else {
        Write-Host "  NEXT: No installation recommendation until the listed state is resolved."
    }
}
Write-Host ""
Write-Host "Native plugin-browser approval is separate from this read-only report."
Write-Host "Chrome DevTools MCP, Impeccable and existing package updates remain out of scope."
Write-Host "No changes made."
