$ErrorActionPreference = "Continue"

function Test-CommandAvailable {
    param([Parameter(Mandatory = $true)][string]$Name)
    return $null -ne (Get-Command $Name -ErrorAction SilentlyContinue)
}

function Get-SkillCandidates {
    param([Parameter(Mandatory = $true)][string]$Name)

    $paths = New-Object System.Collections.Generic.List[string]
    $projectRoot = (Get-Location).Path
    $codexHome = if ($env:CODEX_HOME) { $env:CODEX_HOME } else { Join-Path $HOME ".codex" }

    $direct = @(
        (Join-Path $projectRoot ".codex\skills\$Name\SKILL.md"),
        (Join-Path $codexHome "skills\$Name\SKILL.md")
    )

    foreach ($path in $direct) {
        if (Test-Path -LiteralPath $path) {
            $paths.Add((Resolve-Path -LiteralPath $path).Path)
        }
    }

    $cacheRoot = Join-Path $codexHome "plugins\cache"

    if (Test-Path -LiteralPath $cacheRoot) {
        Get-ChildItem -LiteralPath $cacheRoot -Filter "SKILL.md" -File -Recurse -ErrorAction SilentlyContinue |
            Where-Object {
                $_.Directory.Name -eq $Name -and
                $_.Directory.Parent -and
                $_.Directory.Parent.Name -eq "skills"
            } |
            ForEach-Object {
                if (-not $paths.Contains($_.FullName)) {
                    $paths.Add($_.FullName)
                }
            }
    }

    # Keep old manual installs as a last-resort compatibility fallback.
    foreach ($path in @(
        (Join-Path $projectRoot ".agents\skills\$Name\SKILL.md"),
        (Join-Path $HOME ".agents\skills\$Name\SKILL.md")
    )) {
        if ((Test-Path -LiteralPath $path) -and -not $paths.Contains((Resolve-Path -LiteralPath $path).Path)) {
            $paths.Add((Resolve-Path -LiteralPath $path).Path)
        }
    }

    return @($paths)
}

function Test-SkillPayload {
    param([Parameter(Mandatory = $true)][string]$Name)

    $records = @()
    foreach ($path in @(Get-SkillCandidates -Name $Name)) {
        try {
            $content = Get-Content -LiteralPath $path -Raw -ErrorAction Stop
            if ($content.Length -lt 16 -or -not $content.StartsWith("---")) { continue }
            $match = [regex]::Match(
                $content,
                "(?ms)\A---\s*.*?^\s*name\s*:\s*['\x22]?(?<name>[^'\x22\r\n#]+)"
            )
            if (-not $match.Success) { continue }
            $declared = $match.Groups["name"].Value.Trim()
            if ($declared -ne $Name) {
                Write-Host "[ALIAS/MISMATCH] directory: $Name; frontmatter: $declared; path: $path"
                continue
            }
            $origin = "DIRECT_OR_LEGACY"
            if ($path -match '[\\/]plugins[\\/]cache[\\/]') {
                $origin = "PLUGIN_CACHE (may be inactive or historical)"
            }
            $records += [pscustomobject]@{
                Path = $path
                Hash = (Get-FileHash -LiteralPath $path -Algorithm SHA256).Hash
                Origin = $origin
            }
        }
        catch {
            Write-Host "[UNKNOWN] Could not inspect $path"
        }
    }

    if ($records.Count -eq 0) {
        Write-Host "[MISSING/UNKNOWN] No readable valid $Name payload found"
        return $false
    }
    foreach ($item in @($records | Sort-Object Path)) {
        Write-Host "[FOUND] $Name ($($item.Origin))"
        Write-Host "        path: $($item.Path)"
        Write-Host "        sha256: $($item.Hash)"
    }
    if ($records.Count -gt 1) {
        $distinctHashes = @($records | Select-Object -ExpandProperty Hash -Unique)
        if ($distinctHashes.Count -gt 1) {
            Write-Host "[AMBIGUOUS] $Name has multiple differing valid payloads."
            Write-Host "            Do not update until the active owner is established."
            return $false
        }
        Write-Host "[DUPLICATE] $Name has identical payloads at multiple paths."
        Write-Host "            Only the plugin owner may update a bundled skill."
    }
    Write-Host "[PRESENT] $Name; this scan does NOT prove active-session loading."
    return $true
}

Write-Host "Frontend Production QA - local readiness"
Write-Host "========================================"
Write-Host ""

$runtimeReady = $true
$maintenanceReady = $true

foreach ($command in @("codex", "npx")) {
    if (Test-CommandAvailable $command) {
        Write-Host "[OK] $command"
    }
    else {
        Write-Host "[MISSING] $command"
        $runtimeReady = $false
        $maintenanceReady = $false
    }
}

if (Test-CommandAvailable "git") {
    Write-Host "[OK] git"
}
else {
    Write-Host "[MISSING] git"
    $maintenanceReady = $false
}

Write-Host ""
Write-Host "Required specialist skills"
Write-Host "--------------------------"

foreach ($skill in @(
    "frontend-ui-engineering",
    "browser-testing-with-devtools",
    "frontend-visual-qa",
    "frontend-accessibility-qa"
)) {
    if (-not (Test-SkillPayload -Name $skill)) {
        $runtimeReady = $false
    }
}

Write-Host ""
Write-Host "Chrome DevTools MCP"
Write-Host "-------------------"

$mcpRegistered = $false
if (Test-CommandAvailable "codex") {
    try {
        $mcp = (& codex mcp list 2>&1 | Out-String)
        if ($mcp -match "chrome-devtools") {
            $mcpRegistered = $true
            Write-Host "[REGISTERED] chrome-devtools"
            Write-Host "             Registration does not prove MCP startup or Chrome connectivity."
        }
        else {
            Write-Host "[UNKNOWN] chrome-devtools absent from this CLI result."
            Write-Host "          Isolated CLI may not share active Desktop MCP configuration."
        }
    }
    catch {
        Write-Host "[UNKNOWN] unable to inspect MCP registrations from this CLI."
    }
}

Write-Host ""
Write-Host "Readiness summary"
Write-Host "-----------------"
Write-Host ("FRONTEND TOOLCHAIN FILES: " + $(if ($runtimeReady) { "READY" } else { "NOT READY" }))
Write-Host ("BROWSER MCP CLI: " + $(if ($mcpRegistered) { "REGISTERED (CLI ONLY)" } else { "UNKNOWN; inspect Desktop configuration/runtime" }))
Write-Host "CURRENT CODEX SESSION LOAD: NOT VERIFIED BY THIS SCRIPT"
Write-Host "BROWSER PROCESS/CONNECTION: VERIFY DURING THE FRONTEND TASK"
Write-Host ("TOOLCHAIN MAINTENANCE: " + $(if ($maintenanceReady) { "READY" } else { "NOT READY" }))

if (-not $runtimeReady) {
    exit 1
}
