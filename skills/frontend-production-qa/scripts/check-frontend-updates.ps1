$ErrorActionPreference = "Continue"

Write-Host "Frontend Production QA - read-only update evidence"
Write-Host "=================================================="
Write-Host "No upgrades, installs, npx execution or cache writes are performed."
Write-Host ""

$codexHome = if ($env:CODEX_HOME) { $env:CODEX_HOME } else { Join-Path $HOME ".codex" }
$gitAvailable = $null -ne (Get-Command git -ErrorAction SilentlyContinue)

function Get-RemoteHead {
    param([string]$Url)
    if (-not $gitAvailable) { return $null }
    $result = (& git ls-remote $Url HEAD 2>$null | Select-Object -First 1)
    if ($LASTEXITCODE -ne 0 -or -not $result) { return $null }
    $sha = ($result -split "\s+")[0]
    if ($sha -notmatch "^[0-9a-f]{40}$") { return $null }
    return $sha
}

function Get-PackageCache {
    param([string]$Marketplace, [string]$Package)
    $root = Join-Path $codexHome "plugins\cache\$Marketplace\$Package"
    if (-not (Test-Path -LiteralPath $root)) { return @() }
    $rows = @()
    foreach ($folder in @(Get-ChildItem -LiteralPath $root -Directory -ErrorAction SilentlyContinue)) {
        $manifestFile = Join-Path $folder.FullName "plugin.json"
        $version = "UNKNOWN"
        if (Test-Path -LiteralPath $manifestFile) {
            try {
                $manifest = Get-Content -LiteralPath $manifestFile -Raw | ConvertFrom-Json
                if ($manifest.version) { $version = [string]$manifest.version }
            } catch { }
        }
        $sha = $null
        if ($gitAvailable) {
            # A cache path may be inside another Git worktree. Never mistake an
            # enclosing unrelated checkout for provenance of this cached package.
            $top = (& git -C $folder.FullName rev-parse --show-toplevel 2>$null)
            if ($LASTEXITCODE -eq 0 -and $top) {
                $normalizedTop = [IO.Path]::GetFullPath($top.ToString().Trim())
                $normalizedFolder = [IO.Path]::GetFullPath($folder.FullName)
                if ($normalizedTop.TrimEnd('\', '/') -eq $normalizedFolder.TrimEnd('\', '/')) {
                    $candidate = (& git -C $folder.FullName rev-parse HEAD 2>$null)
                    if ($LASTEXITCODE -eq 0 -and $candidate -match "^[0-9a-f]{40}$") {
                        $sha = $candidate.ToString()
                    }
                }
            }
        }
        $rows += [pscustomobject]@{
            Path = $folder.FullName
            Version = $version
            SourceRevision = $sha
        }
    }
    return @($rows)
}

$packages = @(
    @{ Marketplace = "agent-skills"; Package = "agent-skills"; Url = "https://github.com/addyosmani/agent-skills.git" },
    @{ Marketplace = "codex-frontend-production-qa"; Package = "frontend-production-qa"; Url = "https://github.com/SergejDAGDA/frontend-quality-suite-skill.git" }
)

foreach ($spec in $packages) {
    $name = $spec.Package
    Write-Host "$name"
    $upstream = Get-RemoteHead -Url $spec.Url
    Write-Host "  upstream HEAD: $(if ($upstream) { $upstream } else { 'UNKNOWN (offline or inaccessible)' })"
    $installed = @(Get-PackageCache -Marketplace $spec.Marketplace -Package $name)
    if ($installed.Count -eq 0) {
        Write-Host "  cache: MISSING/UNKNOWN"
        Write-Host "  status: UNKNOWN (active installation cannot be inferred)"
        continue
    }
    foreach ($entry in $installed) {
        Write-Host "  cached package: $($entry.Path)"
        Write-Host "    manifest version: $($entry.Version)"
        Write-Host "    git source identity: $(if ($entry.SourceRevision) { $entry.SourceRevision } else { 'UNKNOWN' })"
    }
    if ($installed.Count -eq 1 -and $upstream -and $installed[0].SourceRevision) {
        if ($upstream -eq $installed[0].SourceRevision) {
            Write-Host "  cached source: CURRENT (same revision as upstream HEAD)"
        } else {
            Write-Host "  cached source: DIFFERENT (revision is not upstream HEAD; ancestry unknown)"
        }
    } else {
        Write-Host "  cached source: UNKNOWN (multiple cache versions or missing revision evidence)"
    }
    Write-Host "  active package: UNKNOWN until enabled-plugin/session identity is verified"
    Write-Host "  action: inspect active package before any targeted update"
    Write-Host ""
}

Write-Host "frontend-visual-qa: BUNDLED in frontend-production-qa; do not compare to daymade upstream."
Write-Host "frontend-accessibility-qa: BUNDLED in frontend-production-qa; update only with this plugin."
Write-Host "Chrome DevTools MCP: effective npx @latest runtime version UNKNOWN without runtime evidence."
Write-Host "Impeccable: installed/runtime identity UNKNOWN; npx check is intentionally not invoked."
Write-Host "UNKNOWN is never treated as CURRENT or OUTDATED. No changes made."
