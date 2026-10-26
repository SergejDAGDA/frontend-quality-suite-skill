$ErrorActionPreference = "Stop"
$root = (Resolve-Path (Join-Path $PSScriptRoot "..")).Path
$planner = Join-Path $root "skills\frontend-production-qa\scripts\plan-frontend-dependencies.ps1"
$bootstrap = Join-Path $root "skills\frontend-production-qa\scripts\bootstrap-frontend-toolchain.ps1"
$pwsh = (Get-Command pwsh -ErrorAction Stop).Source
$fixture = Join-Path ([IO.Path]::GetTempPath()) ("frontend-install-fixture-" + [guid]::NewGuid().ToString("N"))
$oldPath = $env:PATH
$oldHome = $env:HOME
$oldProfile = $env:USERPROFILE
$oldCodexHome = $env:CODEX_HOME
$oldPluginJson = $env:MOCK_PLUGIN_JSON
$oldMarketJson = $env:MOCK_MARK_JSON
$oldMockLog = $env:MOCK_CODEX_LOG

function Invoke-Child {
    param([string]$Script, [string[]]$Arguments = @())
    $output = (& $pwsh -NoProfile -NonInteractive -File $Script @Arguments 2>&1 | Out-String)
    return [pscustomobject]@{ Output = $output; Code = $LASTEXITCODE }
}
function Set-PluginInventory {
    param([string]$Text)
    Set-Content -LiteralPath $env:MOCK_PLUGIN_JSON -Value $Text -Encoding utf8
}
function Set-Markets {
    param([object[]]$Items)
    Set-Content -LiteralPath $env:MOCK_MARK_JSON -Value (ConvertTo-Json -InputObject @{ marketplaces = @($Items) } -Depth 6 -Compress) -Encoding utf8
}
function Make-Market {
    param([string]$Folder, [string]$Origin, [string]$Name, [string]$Plugin, [object]$Source)
    New-Item -ItemType Directory -Force -Path $Folder | Out-Null
    & git init -q $Folder
    if ($LASTEXITCODE -ne 0) { throw "Cannot make disposable Git marketplace" }
    & git -C $Folder remote add origin $Origin
    if ($LASTEXITCODE -ne 0) { throw "Cannot set disposable Git remote" }
    $catalog = @{ name = $Name; plugins = @( @{ name = $Plugin; source = $Source } ) }
    $catalogPath = Join-Path $Folder ".agents\plugins\marketplace.json"
    New-Item -ItemType Directory -Force -Path (Split-Path $catalogPath) | Out-Null
    Set-Content -LiteralPath $catalogPath -Value (ConvertTo-Json -InputObject $catalog -Depth 7) -Encoding utf8
    Set-Content -LiteralPath (Join-Path $Folder "plugin.json") -Value (ConvertTo-Json -InputObject @{ name = $Plugin; version = "0.6.13" }) -Encoding utf8
}

try {
    New-Item -ItemType Directory -Force -Path $fixture | Out-Null
    $fakeBin = Join-Path $fixture "bin"
    New-Item -ItemType Directory -Force -Path $fakeBin | Out-Null
    $env:HOME = Join-Path $fixture "home"
    $env:USERPROFILE = $env:HOME
    $env:CODEX_HOME = Join-Path $fixture "codex"
    $env:PATH = "$fakeBin;$oldPath"
    $env:MOCK_PLUGIN_JSON = Join-Path $fixture "plugins.json"
    $env:MOCK_MARK_JSON = Join-Path $fixture "marketplaces.json"
    $env:MOCK_CODEX_LOG = Join-Path $fixture "codex-calls.log"
    New-Item -ItemType Directory -Force -Path $env:HOME, $env:CODEX_HOME | Out-Null

    # Mock CLI; only disposable local Git inspection is real.
    $mock = @'
@echo off
echo %*>>"%MOCK_CODEX_LOG%"
if "%1"=="plugin" (
  if "%2"=="list" (
    type "%MOCK_PLUGIN_JSON%"
    exit /b 0
  )
  if "%2"=="marketplace" (
    if "%3"=="list" (
      type "%MOCK_MARK_JSON%"
      exit /b 0
    )
  )
)
exit /b 9
'@
    Set-Content -LiteralPath (Join-Path $fakeBin "codex.cmd") -Value $mock -Encoding ascii

    $addyRoot = Join-Path $fixture "verified-addy"
    Make-Market -Folder $addyRoot -Origin "https://github.com/addyosmani/agent-skills.git" -Name "agent-skills" -Plugin "agent-skills" -Source @{ source = "local"; path = "./" }
    $frontRoot = Join-Path $fixture "verified-frontend"
    Make-Market -Folder $frontRoot -Origin "https://github.com/SergejDAGDA/frontend-quality-suite-skill.git" -Name "codex-frontend-production-qa" -Plugin "frontend-production-qa" -Source @{ source = "url"; url = "https://github.com/SergejDAGDA/frontend-quality-suite-skill.git"; ref = "main" }
    $markets = @(
        @{ name = "agent-skills"; root = $addyRoot },
        @{ name = "codex-frontend-production-qa"; root = $frontRoot }
    )
    Set-Markets -Items $markets
    Set-PluginInventory -Text @'
{"installed":[],"available":[{"pluginId":"agent-skills@agent-skills","version":"0.6.13"},{"pluginId":"frontend-production-qa@codex-frontend-production-qa","version":"1.2.3"}]}
'@

    foreach ($component in @("agent-skills", "frontend-production-qa")) {
        $result = Invoke-Child -Script $planner -Arguments @("-Component", $component, "-Json")
        if ($result.Code -ne 0) { throw "Verified $component runner failed: $($result.Output)" }
        $row = $result.Output | ConvertFrom-Json
        if ($row.Status -ne "MISSING" -or $row.LocalProvenance -ne "VERIFIED_LOCAL_ORIGIN" -or $row.NativeInstallAction -ne "/plugins" -or $row.PSObject.Properties.Name -contains "InstallLink") {
            throw "Verified $component did not produce strictly native handoff: $($result.Output)"
        }
    }

    # Migration guard: old Git origin must not be silently trusted as the new canonical owner.
    & git -C $frontRoot remote set-url origin "https://github.com/SergejDAGDA/codex-frontend-production-qa.git"
    $legacyOrigin = Invoke-Child -Script $planner -Arguments @("-Component", "frontend-production-qa", "-Json")
    $row = $legacyOrigin.Output | ConvertFrom-Json
    if ($legacyOrigin.Code -ne 0 -or $row.Status -ne "CONFLICT" -or $row.NativeInstallAction) {
        throw "Historical Git origin bypassed the canonical repository owner check: $($legacyOrigin.Output)"
    }
    & git -C $frontRoot remote set-url origin "https://github.com/SergejDAGDA/frontend-quality-suite-skill.git"

    # Reproduces the exact review BLOCKER: same marketplace name, wrong owner root.
    $wrongRoot = Join-Path $fixture "wrong-owner"
    Make-Market -Folder $wrongRoot -Origin "https://github.com/untrusted/different-owner.git" -Name "agent-skills" -Plugin "agent-skills" -Source @{ source = "local"; path = "./" }
    Set-Markets -Items @(@{ name = "agent-skills"; root = $wrongRoot })
    $spoof = Invoke-Child -Script $planner -Arguments @("-Component", "agent-skills", "-Json")
    $row = $spoof.Output | ConvertFrom-Json
    if ($spoof.Code -ne 0 -or $row.Status -ne "CONFLICT" -or $row.NativeInstallAction) {
        throw "Wrong marketplace ownership produced an install recommendation: $($spoof.Output)"
    }

    # Correct owner Git remote, malicious catalog plugin source.
    $badCatalog = Join-Path $frontRoot ".agents\plugins\marketplace.json"
    Set-Content -LiteralPath $badCatalog -Encoding utf8 -Value @'
{"name":"codex-frontend-production-qa","plugins":[{"name":"frontend-production-qa","source":{"source":"url","url":"https://github.com/untrusted/not-the-plugin.git","ref":"main"}}]}
'@
    Set-Markets -Items @(@{ name = "codex-frontend-production-qa"; root = $frontRoot })
    $badSource = Invoke-Child -Script $planner -Arguments @("-Component", "frontend-production-qa", "-Json")
    $row = $badSource.Output | ConvertFrom-Json
    if ($badSource.Code -ne 0 -or $row.Status -ne "CONFLICT" -or $row.NativeInstallAction) {
        throw "Wrong catalog plugin owner produced an install recommendation: $($badSource.Output)"
    }
    Set-Content -LiteralPath $badCatalog -Encoding utf8 -Value @'
{"name":"codex-frontend-production-qa","plugins":[{"name":"frontend-production-qa","source":{"source":"url","url":"https://github.com/SergejDAGDA/frontend-quality-suite-skill.git","ref":"main"}}]}
'@

    Set-Markets -Items $markets
    Set-PluginInventory -Text @'
{"installed":[{"pluginId":"agent-skills@agent-skills","version":"0.6.13","enabled":true}],"available":[]}
'@
    $installed = Invoke-Child -Script $planner -Arguments @("-Component", "agent-skills", "-Json")
    $row = $installed.Output | ConvertFrom-Json
    if ($installed.Code -ne 0 -or $row.Status -ne "INSTALLED" -or $row.NativeInstallAction) {
        throw "Installed package may not receive install action: $($installed.Output)"
    }

    Set-PluginInventory -Text @'
{"installed":[{"pluginId":"agent-skills@agent-skills","version":"0.6.13","enabled":false}],"available":[]}
'@
    $disabled = Invoke-Child -Script $planner -Arguments @("-Component", "agent-skills", "-Json")
    $row = $disabled.Output | ConvertFrom-Json
    if ($disabled.Code -ne 0 -or $row.Status -ne "DISABLED" -or $row.NativeInstallAction) {
        throw "Disabled package may not receive install action"
    }

    Set-PluginInventory -Text @'
{"installed":[],"available":[{"pluginId":"agent-skills@agent-skills","version":"0.6.13"}]}
'@
    $direct = Join-Path $env:CODEX_HOME "skills\frontend-ui-engineering\SKILL.md"
    New-Item -ItemType Directory -Force -Path (Split-Path $direct) | Out-Null
    Set-Content -LiteralPath $direct -Value ("---" + [Environment]::NewLine + "name: frontend-ui-engineering" + [Environment]::NewLine + "---")
    $collision = Invoke-Child -Script $planner -Arguments @("-Component", "agent-skills", "-Json")
    $row = $collision.Output | ConvertFrom-Json
    if ($collision.Code -ne 0 -or $row.Status -ne "CONFLICT" -or $row.NativeInstallAction) {
        throw "Direct skill ID collision did not stop native install recommendation"
    }
    Remove-Item -LiteralPath (Split-Path $direct) -Recurse -Force

    Set-Markets -Items @()
    $missingMarket = Invoke-Child -Script $planner -Arguments @("-Component", "agent-skills", "-Json")
    $row = $missingMarket.Output | ConvertFrom-Json
    if ($missingMarket.Code -ne 0 -or $row.Status -ne "MARKETPLACE_MISSING" -or $row.NativeInstallAction) {
        throw "Unregistered marketplace may not be recommended"
    }

    Set-Markets -Items $markets
    Set-Content -LiteralPath $env:MOCK_PLUGIN_JSON -Value "NOT JSON" -Encoding ascii
    $unknown = Invoke-Child -Script $planner -Arguments @("-Component", "agent-skills", "-Json")
    $row = $unknown.Output | ConvertFrom-Json
    if ($unknown.Code -ne 0 -or $row.Status -ne "UNKNOWN" -or $row.NativeInstallAction) {
        throw "Malformed native inventory may not be recommended"
    }

    $unsafe = Invoke-Child -Script $bootstrap -Arguments @("-Apply")
    if ($unsafe.Code -eq 0 -or $unsafe.Output -notmatch "\[BLOCKED\]") {
        throw "Legacy bootstrap modification must be blocked"
    }

    foreach ($line in @(Get-Content -LiteralPath $env:MOCK_CODEX_LOG)) {
        if ($line -notmatch '^plugin list --available --json$' -and
            $line -notmatch '^plugin marketplace list --json$') {
            throw "Planner executed unexpected native Codex command: $line"
        }
    }
}
finally {
    $env:PATH = $oldPath
    $env:HOME = $oldHome
    $env:USERPROFILE = $oldProfile
    $env:CODEX_HOME = $oldCodexHome
    $env:MOCK_PLUGIN_JSON = $oldPluginJson
    $env:MOCK_MARK_JSON = $oldMarketJson
    $env:MOCK_CODEX_LOG = $oldMockLog
    if (Test-Path -LiteralPath $fixture) {
        Remove-Item -LiteralPath $fixture -Recurse -Force
    }
}
Write-Host "Guided dependency source validation fixtures PASS."
exit 0
