param(
    [string[]]$SkillId = @(),
    [switch]$All,
    [switch]$Json
)

$ErrorActionPreference = "Stop"

$scriptRoot = Split-Path -Parent $MyInvocation.MyCommand.Path
$registryPath = Join-Path (Split-Path -Parent $scriptRoot) "specialists.json"
if (-not (Test-Path -LiteralPath $registryPath -PathType Leaf)) {
    throw "Specialist registry not found: $registryPath"
}
$registry = Get-Content -LiteralPath $registryPath -Raw | ConvertFrom-Json

function Get-LiveJsonValue {
    param(
        [Parameter(Mandatory = $true)][string]$Url,
        [Parameter(Mandatory = $true)][string]$Property
    )

    try {
        $headers = @{ "User-Agent" = "frontend-quality-suite-preflight" }
        $doc = Invoke-RestMethod -Uri $Url -Headers $headers -Method Get -TimeoutSec 20
        $prop = $doc.PSObject.Properties[$Property]
        if ($null -eq $prop) { return $null }
        $value = [string]$prop.Value
        if ([string]::IsNullOrWhiteSpace($value)) { return $null }
        return $value
    }
    catch {
        return $null
    }
}

function Get-LiveText {
    param([Parameter(Mandatory = $true)][string]$Url)

    try {
        $headers = @{ "User-Agent" = "frontend-quality-suite-preflight" }
        return [string](Invoke-RestMethod -Uri $Url -Headers $headers -Method Get -TimeoutSec 20)
    }
    catch {
        return $null
    }
}

function Get-NormalizedHash {
    param([Parameter(Mandatory = $true)][string]$Text)

    $normalized = $Text -replace "\r\n", "\n"
    $bytes = [Text.Encoding]::UTF8.GetBytes($normalized)
    $sha = [Security.Cryptography.SHA256]::Create()
    try {
        return ([BitConverter]::ToString($sha.ComputeHash($bytes))).Replace("-", "")
    }
    finally {
        $sha.Dispose()
    }
}

function Get-Frontmatter {
    param([Parameter(Mandatory = $true)][string]$Content)

    if (-not $Content.StartsWith("---")) { return $null }
    $match = [regex]::Match($Content, '(?s)\A---\s*\r?\n(?<fm>.*?)\r?\n---')
    if (-not $match.Success) { return $null }
    return $match.Groups["fm"].Value
}

function Get-SkillRecords {
    param([Parameter(Mandatory = $true)][string[]]$Names)

    $wanted = @{}
    foreach ($name in $Names) { $wanted[$name] = $true }

    $profileHome = if ($env:USERPROFILE) { $env:USERPROFILE } else { $HOME }
    $codexHome = if ($env:CODEX_HOME) { $env:CODEX_HOME } else { Join-Path $profileHome ".codex" }
    $projectRoot = (Get-Location).Path

    $roots = @(
        [pscustomobject]@{ Path = (Join-Path $projectRoot ".codex\skills"); Origin = "DIRECT_PROJECT" },
        [pscustomobject]@{ Path = (Join-Path $projectRoot ".agents\skills"); Origin = "DIRECT_PROJECT_LEGACY" },
        [pscustomobject]@{ Path = (Join-Path $codexHome "skills"); Origin = "DIRECT_USER" },
        [pscustomobject]@{ Path = (Join-Path $profileHome ".agents\skills"); Origin = "DIRECT_USER_LEGACY" },
        [pscustomobject]@{ Path = (Join-Path $codexHome "plugins\cache"); Origin = "PLUGIN_CACHE" }
    )

    $records = @()
    $seen = @{}

    foreach ($root in $roots) {
        if (-not (Test-Path -LiteralPath $root.Path -PathType Container)) { continue }

        foreach ($file in @(Get-ChildItem -LiteralPath $root.Path -Filter "SKILL.md" -File -Recurse -ErrorAction SilentlyContinue)) {
            $resolved = $file.FullName
            if ($seen.ContainsKey($resolved)) { continue }
            $seen[$resolved] = $true

            try {
                $text = Get-Content -LiteralPath $resolved -Raw -ErrorAction Stop
                $frontmatter = Get-Frontmatter -Content $text
                if ($null -eq $frontmatter) { continue }

                $nameMatch = [regex]::Match($frontmatter, '(?m)^\s*name\s*:\s*[''"]?(?<v>[^''"\r\n#]+)')
                if (-not $nameMatch.Success) { continue }

                $declared = $nameMatch.Groups["v"].Value.Trim()
                if (-not $wanted.ContainsKey($declared)) { continue }

                $version = $null
                $versionMatch = [regex]::Match($frontmatter, '(?m)^\s+version\s*:\s*[''"]?(?<v>[^''"\r\n#]+)')
                if ($versionMatch.Success) {
                    $version = $versionMatch.Groups["v"].Value.Trim()
                }

                $records += [pscustomobject]@{
                    SkillId = $declared
                    Path = $resolved
                    Origin = $root.Origin
                    Version = $version
                    Hash = Get-NormalizedHash -Text $text
                }
            }
            catch {
            }
        }
    }

    return @($records)
}

function Invoke-CodexReadOnly {
    param([string[]]$Arguments)

    if (-not (Get-Command codex -ErrorAction SilentlyContinue)) { return $null }

    try {
        $output = (& codex @Arguments 2>&1 | Out-String)
        if ($LASTEXITCODE -ne 0 -or -not $output.Trim()) { return $null }
        return ($output | ConvertFrom-Json -ErrorAction Stop)
    }
    catch {
        return $null
    }
}

function Compare-VersionText {
    param([string]$Installed, [string]$Author)

    if ([string]::IsNullOrWhiteSpace($Installed) -or [string]::IsNullOrWhiteSpace($Author)) {
        return "UNKNOWN"
    }

    if ($Installed -eq $Author) { return "EQUAL" }

    try {
        $installedVersion = [version]$Installed
        $authorVersion = [version]$Author

        if ($installedVersion -lt $authorVersion) { return "OLDER" }
        if ($installedVersion -gt $authorVersion) { return "NEWER" }
        return "EQUAL"
    }
    catch {
        return "DIFFERENT"
    }
}

function Get-RepositoryIdentity {
    param([string]$Url)

    if ([string]::IsNullOrWhiteSpace($Url)) { return $null }

    $match = [regex]::Match(
        $Url.Trim(),
        '^(?:https://github\.com/|git@github\.com:)(?<owner>[a-zA-Z0-9_.-]+)/(?<repo>[a-zA-Z0-9_.-]+?)(?:\.git)?/?$'
    )
    if (-not $match.Success) { return $null }

    return ($match.Groups["owner"].Value + "/" + $match.Groups["repo"].Value).ToLowerInvariant()
}

function Get-MarketplaceEvidence {
    param($Spec)

    $marketplaces = Invoke-CodexReadOnly -Arguments @("plugin", "marketplace", "list", "--json")
    if ($null -eq $marketplaces -or $null -eq $marketplaces.marketplaces) {
        return [pscustomobject]@{ State = "UNKNOWN"; Detail = "Marketplace inventory unavailable." }
    }

    $hits = @($marketplaces.marketplaces | Where-Object { $_.name -eq $Spec.marketplace })
    if ($hits.Count -eq 0) {
        return [pscustomobject]@{ State = "MISSING"; Detail = "Expected marketplace is not registered." }
    }
    if ($hits.Count -gt 1) {
        return [pscustomobject]@{ State = "CONFLICT"; Detail = "Duplicate marketplace records exist." }
    }

    if (-not (Get-Command git -ErrorAction SilentlyContinue)) {
        return [pscustomobject]@{ State = "UNKNOWN"; Detail = "Git is unavailable for marketplace provenance verification." }
    }

    try {
        $root = [string]$hits[0].root
        if (-not (Test-Path -LiteralPath $root -PathType Container)) {
            return [pscustomobject]@{ State = "UNKNOWN"; Detail = "Marketplace checkout root is missing." }
        }

        $root = (Resolve-Path -LiteralPath $root).Path.TrimEnd('\', '/')
        $top = (& git -C $root rev-parse --show-toplevel 2>$null | Out-String).Trim()
        if ($LASTEXITCODE -ne 0 -or -not $top) {
            return [pscustomobject]@{ State = "UNKNOWN"; Detail = "Marketplace root is not a readable Git checkout." }
        }

        $resolvedTop = (Resolve-Path -LiteralPath $top).Path.TrimEnd('\', '/')
        if (-not [string]::Equals($root, $resolvedTop, [StringComparison]::OrdinalIgnoreCase)) {
            return [pscustomobject]@{ State = "CONFLICT"; Detail = "Marketplace root does not equal the Git checkout root." }
        }

        $origin = (& git -C $root remote get-url origin 2>$null | Out-String).Trim()
        $observed = Get-RepositoryIdentity -Url $origin
        $expected = ([string]$Spec.repository).ToLowerInvariant()

        if ($observed -ne $expected) {
            return [pscustomobject]@{ State = "CONFLICT"; Detail = "Marketplace Git origin does not match the expected author repository." }
        }

        $catalogPath = Join-Path $root ".agents\plugins\marketplace.json"
        if (-not (Test-Path -LiteralPath $catalogPath -PathType Leaf)) {
            return [pscustomobject]@{ State = "UNKNOWN"; Detail = "Marketplace catalog is unavailable." }
        }

        $catalog = Get-Content -LiteralPath $catalogPath -Raw | ConvertFrom-Json
        if ($catalog.name -ne $Spec.marketplace) {
            return [pscustomobject]@{ State = "CONFLICT"; Detail = "Marketplace catalog name does not match the expected marketplace." }
        }

        $pluginName = ([string]$Spec.plugin_id -split '@', 2)[0]
        $entries = @($catalog.plugins | Where-Object { $_.name -eq $pluginName })
        if ($entries.Count -ne 1) {
            return [pscustomobject]@{ State = "CONFLICT"; Detail = "Marketplace catalog does not contain exactly one expected plugin entry." }
        }

        $source = $entries[0].source
        if ($source.source -eq "url") {
            if ((Get-RepositoryIdentity -Url ([string]$source.url)) -ne $expected) {
                return [pscustomobject]@{ State = "CONFLICT"; Detail = "Marketplace plugin entry points to a different repository." }
            }
        }
        elseif ($source.source -eq "local") {
            if ([string]$source.path -ne "./") {
                return [pscustomobject]@{ State = "CONFLICT"; Detail = "Local marketplace plugin entry does not resolve to the verified checkout root." }
            }
        }
        else {
            return [pscustomobject]@{ State = "CONFLICT"; Detail = "Unsupported marketplace plugin source kind." }
        }

        return [pscustomobject]@{ State = "VERIFIED"; Detail = "Git origin and catalog source match the author's repository." }
    }
    catch {
        return [pscustomobject]@{ State = "UNKNOWN"; Detail = "Marketplace provenance could not be verified reliably." }
    }
}

function New-Result {
    param($Spec)

    return [ordered]@{
        key = $Spec.key
        class = $Spec.class
        skill_ids = @($Spec.skill_ids)
        repository = $Spec.repository
        channel = $Spec.channel
        status = "UNKNOWN"
        installed_version = $null
        author_version = $null
        distribution_version = $null
        session_load = "UNVERIFIED"
        fresh_session_required = [bool]$Spec.fresh_session_required
        detail = ""
        suggested_action = ""
        evidence = @()
    }
}

function Test-AuthorDistribution {
    param(
        $Spec,
        [System.Collections.IDictionary]$Result
    )

    if ($Spec.author_version) {
        $Result.author_version = Get-LiveJsonValue -Url $Spec.author_version.url -Property $Spec.author_version.property
    }

    if ($Spec.distribution_version) {
        $Result.distribution_version = Get-LiveJsonValue -Url $Spec.distribution_version.url -Property $Spec.distribution_version.property
    }

    if ($Spec.author_version -and -not $Result.author_version) {
        $Result.status = "UNKNOWN_REMOTE"
        $Result.detail = "Could not read the current version from the author's live source."
        $Result.suggested_action = "Do not claim this specialist is current; retry the live author check."
        return $false
    }

    if ($Spec.distribution_version -and -not $Result.distribution_version) {
        $Result.status = "UNKNOWN_DISTRIBUTION"
        $Result.detail = "Author version is available but the official distribution version could not be read."
        $Result.suggested_action = "Do not mutate this specialist until author and distribution evidence can be compared."
        return $false
    }

    if ($Spec.distribution_version -and $Result.author_version -ne $Result.distribution_version) {
        $Result.status = "SOURCE_DIVERGENCE"
        $Result.detail = "The author's current manifest and the official install distribution report different versions."
        $Result.suggested_action = "Do not auto-select an update; inspect the author's release/install guidance."
        return $false
    }

    return $true
}

function Inspect-CodexPluginSpecialist {
    param($Spec)

    $result = New-Result -Spec $Spec
    if (-not (Test-AuthorDistribution -Spec $Spec -Result $result)) {
        return [pscustomobject]$result
    }

    $records = @(Get-SkillRecords -Names @($Spec.skill_ids))
    $direct = @($records | Where-Object { $_.Origin -notmatch '^PLUGIN_CACHE$' })

    if ($direct.Count -gt 0) {
        $result.status = "CONFLICT"
        $result.detail = "Direct user/project copies collide with a plugin-owned specialist."
        $result.suggested_action = "Resolve duplicate ownership before install/update."
        $result.evidence = @($direct | ForEach-Object { "$($_.SkillId): $($_.Path)" })
        return [pscustomobject]$result
    }

    $marketEvidence = Get-MarketplaceEvidence -Spec $Spec
    $plugins = Invoke-CodexReadOnly -Arguments @("plugin", "list", "--available", "--json")

    if ($null -eq $plugins -or $null -eq $plugins.installed) {
        $result.status = "UNKNOWN_LOCAL"
        $result.detail = "Native Codex plugin inventory is unavailable."
        $result.suggested_action = "Do not claim the specialist is installed/current."
        return [pscustomobject]$result
    }

    $installed = @($plugins.installed | Where-Object { $_.pluginId -eq $Spec.plugin_id })

    if ($installed.Count -gt 1) {
        $result.status = "CONFLICT"
        $result.detail = "Native Codex reports duplicate installed plugin records."
        $result.suggested_action = "Resolve plugin ownership before use."
        return [pscustomobject]$result
    }

    if ($installed.Count -eq 0) {
        switch ($marketEvidence.State) {
            "MISSING" { $result.status = "MARKETPLACE_MISSING" }
            "CONFLICT" { $result.status = "CONFLICT" }
            "UNKNOWN" { $result.status = "UNKNOWN_LOCAL" }
            default { $result.status = "MISSING" }
        }

        $result.detail = "The specialist plugin is not installed in native Codex inventory. " + $marketEvidence.Detail
        $result.suggested_action = "Offer the exact author-owned native plugin installation before use."
        return [pscustomobject]$result
    }

    if ($marketEvidence.State -eq "CONFLICT") {
        $result.status = "CONFLICT"
        $result.detail = $marketEvidence.Detail
        $result.suggested_action = "Resolve marketplace ownership before using or updating this specialist."
        return [pscustomobject]$result
    }

    if ($marketEvidence.State -ne "VERIFIED") {
        $result.status = "PROVENANCE_UNKNOWN"
        $result.detail = "Installed plugin exists, but marketplace ownership is not verified. " + $marketEvidence.Detail
        $result.suggested_action = "Reconcile the author-owned marketplace before claiming this specialist is current."
        return [pscustomobject]$result
    }

    $item = $installed[0]
    $result.installed_version = [string]$item.version

    if ($item.enabled -ne $true) {
        $result.status = "DISABLED"
        $result.detail = "The specialist plugin is installed but disabled."
        $result.suggested_action = "Enable it in the native Codex plugin UI, then start a fresh session."
        return [pscustomobject]$result
    }

    $comparison = Compare-VersionText -Installed $result.installed_version -Author $result.author_version

    switch ($comparison) {
        "EQUAL" {
            $result.status = "INSTALLED_CURRENT"
            $result.detail = "Installed native plugin version matches the author's live manifest."
            $result.suggested_action = "Resolve the exact Skill ID in the current session before invoking it."
        }
        "OLDER" {
            $result.status = "UPDATE_AVAILABLE"
            $result.detail = "Installed native plugin version is older than the author's live manifest."
            $result.suggested_action = "Offer a targeted author-owned plugin update before use."
        }
        "NEWER" {
            $result.status = "DIFFERENT"
            $result.detail = "Installed version is newer than the author's current live manifest."
            $result.suggested_action = "Do not downgrade automatically; inspect provenance."
        }
        default {
            $result.status = "DIFFERENT"
            $result.detail = "Installed and author versions differ but cannot be safely ordered."
            $result.suggested_action = "Inspect provenance before mutation."
        }
    }

    $cacheRecords = @($records | Where-Object { $_.Origin -eq "PLUGIN_CACHE" })
    if ($cacheRecords.Count -eq 0) {
        $result.evidence += "Native registration found; readable cached Skill payload not found."
    }
    else {
        $result.evidence += @($cacheRecords | ForEach-Object { "$($_.SkillId): $($_.Path)" })
    }

    return [pscustomobject]$result
}

function Inspect-DirectSkillSpecialist {
    param($Spec)

    $result = New-Result -Spec $Spec
    if (-not (Test-AuthorDistribution -Spec $Spec -Result $result)) {
        return [pscustomobject]$result
    }

    $records = @(Get-SkillRecords -Names @($Spec.skill_ids))

    if ($records.Count -eq 0) {
        $result.status = "MISSING"
        $result.detail = "No readable Skill payload with the declared Skill ID was found."
        $result.suggested_action = "Offer the author's current install path before use."
        return [pscustomobject]$result
    }

    if ($records.Count -gt 1) {
        $result.status = "CONFLICT"
        $result.detail = "Multiple copies of the same external Skill ID were found."
        $result.suggested_action = "Resolve duplicate ownership before use or update."
        $result.evidence = @($records | ForEach-Object { "$($_.Origin): $($_.Path)" })
        return [pscustomobject]$result
    }

    $record = $records[0]
    $result.evidence = @("$($record.Origin): $($record.Path)")

    if ($Spec.local_version.kind -eq "skill-frontmatter") {
        $result.installed_version = $record.Version

        if (-not $record.Version) {
            $result.status = "UNKNOWN_LOCAL"
            $result.detail = "Installed skill does not expose the expected version metadata."
            $result.suggested_action = "Do not claim it is current; inspect or refresh from the author."
            return [pscustomobject]$result
        }

        $comparison = Compare-VersionText -Installed $record.Version -Author $result.author_version

        switch ($comparison) {
            "EQUAL" {
                $result.status = "INSTALLED_CURRENT"
                $result.detail = "Installed skill version matches the author's live manifest."
                $result.suggested_action = "Resolve the Skill ID in the current session before use."
            }
            "OLDER" {
                $result.status = "UPDATE_AVAILABLE"
                $result.detail = "Installed skill version is older than the author's live manifest."
                $result.suggested_action = "Offer the author's targeted update before use."
            }
            default {
                $result.status = "DIFFERENT"
                $result.detail = "Installed and author versions differ without safe downgrade assumptions."
                $result.suggested_action = "Inspect provenance before mutation."
            }
        }

        return [pscustomobject]$result
    }

    if ($Spec.local_version.kind -eq "payload-hash") {
        $liveText = Get-LiveText -Url $Spec.author_payload.url

        if (-not $liveText) {
            $result.status = "UNKNOWN_REMOTE"
            $result.detail = "Could not read the author's current Skill payload."
            $result.suggested_action = "Do not claim Motion is current; retry the author payload check."
            return [pscustomobject]$result
        }

        $authorHash = Get-NormalizedHash -Text $liveText

        if ($record.Hash -eq $authorHash) {
            $result.status = "INSTALLED_CURRENT"
            $result.detail = "Installed Skill payload matches the author's current payload."
            $result.suggested_action = "Resolve the Skill ID and required MCP capability in the current session before use."
        }
        else {
            $result.status = "UPDATE_RECOMMENDED"
            $result.detail = "Installed Skill payload differs from the author's current payload; this skill does not expose an installed semantic version."
            $result.suggested_action = "Offer a refresh through the author's current installer before use; do not invent a local version number."
        }

        return [pscustomobject]$result
    }

    $result.status = "UNKNOWN_LOCAL"
    $result.detail = "No supported local-version adapter is configured."
    return [pscustomobject]$result
}

$specs = @($registry.specialists)

if (-not $All) {
    if ($SkillId.Count -eq 0) {
        $specs = @($specs | Where-Object { $_.class -eq "required" })
    }
    else {
        $selected = @()

        foreach ($id in $SkillId) {
            $matches = @($specs | Where-Object { @($_.skill_ids) -contains $id -or $_.key -eq $id })

            if ($matches.Count -eq 0) {
                throw "Unknown specialist/Skill ID: $id"
            }

            foreach ($match in $matches) {
                if (-not (@($selected.key) -contains $match.key)) {
                    $selected += $match
                }
            }
        }

        $specs = $selected
    }
}

$results = @()

foreach ($spec in $specs) {
    if ($spec.channel -eq "codex-plugin") {
        $results += Inspect-CodexPluginSpecialist -Spec $spec
    }
    else {
        $results += Inspect-DirectSkillSpecialist -Spec $spec
    }
}

if ($Json) {
    ConvertTo-Json -InputObject @($results) -Depth 8
    exit 0
}

Write-Host "Frontend Production QA - task-scoped specialist preflight"
Write-Host "========================================================="
Write-Host "Current versions come from live author/distribution sources; no external versions are pinned here."

foreach ($row in $results) {
    Write-Host ""
    Write-Host "$($row.key): $($row.status)"
    Write-Host "  skills: $([string]::Join(', ', @($row.skill_ids)))"
    Write-Host "  owner: $($row.repository)"

    if ($row.installed_version) {
        Write-Host "  installed: $($row.installed_version)"
    }
    if ($row.author_version) {
        Write-Host "  author current: $($row.author_version)"
    }
    if ($row.distribution_version) {
        Write-Host "  distribution current: $($row.distribution_version)"
    }

    Write-Host "  session load: $($row.session_load)"
    Write-Host "  evidence: $($row.detail)"

    if ($row.suggested_action) {
        Write-Host "  next: $($row.suggested_action)"
    }

    foreach ($item in @($row.evidence)) {
        Write-Host "  source: $item"
    }
}

Write-Host ""
Write-Host "No changes made. After any install/update, start a fresh session when required and re-run preflight."
