#Requires -Version 5.0
<#
.SYNOPSIS
    Neusis Code Installer

.DESCRIPTION
    irm https://get.neusis.ai/install.ps1 | iex
#>

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

# Switch console to UTF-8 so box-drawing characters render correctly
# (needed when script is run via irm | iex rather than from a file)
try { $null = & cmd /c chcp 65001 2>&1 } catch {}
[Console]::OutputEncoding = [System.Text.Encoding]::UTF8
$OutputEncoding             = [System.Text.Encoding]::UTF8

$InstallDir  = Join-Path $env:USERPROFILE '.neusis\bin'
$BinaryPath  = Join-Path $InstallDir 'neusiscode.exe'
$ConfigDir   = Join-Path $env:USERPROFILE '.config\neusiscode'
$ConfigPath  = Join-Path $ConfigDir 'neusiscode.json'
$Repo        = 'Neusis-AI-Org/neusis-code-releases'
$GitHubAPI   = "https://api.github.com/repos/$Repo/releases/latest"
$NeuronUrl   = 'https://neusis-ai-org.github.io/neusis-neuron-releases/install.ps1'

# ── UI ────────────────────────────────────────────────────────────────────────

$Script:Step = 0

function Write-Banner {
    Write-Host ""
    Write-Host "  $([char]0x2588)$([char]0x2588)$([char]0x2588)$([char]0x2557)   $([char]0x2588)$([char]0x2588)$([char]0x2557)$([char]0x2588)$([char]0x2588)$([char]0x2588)$([char]0x2588)$([char]0x2588)$([char]0x2588)$([char]0x2588)$([char]0x2557)$([char]0x2588)$([char]0x2588)$([char]0x2557)   $([char]0x2588)$([char]0x2588)$([char]0x2557)$([char]0x2588)$([char]0x2588)$([char]0x2588)$([char]0x2588)$([char]0x2588)$([char]0x2588)$([char]0x2588)$([char]0x2557)$([char]0x2588)$([char]0x2588)$([char]0x2557)$([char]0x2588)$([char]0x2588)$([char]0x2588)$([char]0x2588)$([char]0x2588)$([char]0x2588)$([char]0x2588)$([char]0x2557)" -ForegroundColor Cyan
    Write-Host "  $([char]0x2588)$([char]0x2588)$([char]0x2588)$([char]0x2588)$([char]0x2557)  $([char]0x2588)$([char]0x2588)$([char]0x2551)$([char]0x2588)$([char]0x2588)$([char]0x2554)$([char]0x2550)$([char]0x2550)$([char]0x2550)$([char]0x2550)$([char]0x255D)$([char]0x2588)$([char]0x2588)$([char]0x2551)   $([char]0x2588)$([char]0x2588)$([char]0x2551)$([char]0x2588)$([char]0x2588)$([char]0x2554)$([char]0x2550)$([char]0x2550)$([char]0x2550)$([char]0x2550)$([char]0x255D)$([char]0x2588)$([char]0x2588)$([char]0x2551)$([char]0x2588)$([char]0x2588)$([char]0x2554)$([char]0x2550)$([char]0x2550)$([char]0x2550)$([char]0x2550)$([char]0x255D)" -ForegroundColor Cyan
    Write-Host "  $([char]0x2588)$([char]0x2588)$([char]0x2554)$([char]0x2588)$([char]0x2588)$([char]0x2557) $([char]0x2588)$([char]0x2588)$([char]0x2551)$([char]0x2588)$([char]0x2588)$([char]0x2588)$([char]0x2588)$([char]0x2588)$([char]0x2557)  $([char]0x2588)$([char]0x2588)$([char]0x2551)   $([char]0x2588)$([char]0x2588)$([char]0x2551)$([char]0x2588)$([char]0x2588)$([char]0x2588)$([char]0x2588)$([char]0x2588)$([char]0x2588)$([char]0x2588)$([char]0x2557)$([char]0x2588)$([char]0x2588)$([char]0x2551)$([char]0x2588)$([char]0x2588)$([char]0x2588)$([char]0x2588)$([char]0x2588)$([char]0x2588)$([char]0x2588)$([char]0x2557)" -ForegroundColor Cyan
    Write-Host "  $([char]0x2588)$([char]0x2588)$([char]0x2551)$([char]0x255A)$([char]0x2588)$([char]0x2588)$([char]0x2557)$([char]0x2588)$([char]0x2588)$([char]0x2551)$([char]0x2588)$([char]0x2588)$([char]0x2554)$([char]0x2550)$([char]0x2550)$([char]0x255D)  $([char]0x2588)$([char]0x2588)$([char]0x2551)   $([char]0x2588)$([char]0x2588)$([char]0x2551)$([char]0x255A)$([char]0x2550)$([char]0x2550)$([char]0x2550)$([char]0x2550)$([char]0x2588)$([char]0x2588)$([char]0x2551)$([char]0x2588)$([char]0x2588)$([char]0x2551)$([char]0x255A)$([char]0x2550)$([char]0x2550)$([char]0x2550)$([char]0x2550)$([char]0x2588)$([char]0x2588)$([char]0x2551)" -ForegroundColor Cyan
    Write-Host "  $([char]0x2588)$([char]0x2588)$([char]0x2551) $([char]0x255A)$([char]0x2588)$([char]0x2588)$([char]0x2588)$([char]0x2588)$([char]0x2551)$([char]0x2588)$([char]0x2588)$([char]0x2588)$([char]0x2588)$([char]0x2588)$([char]0x2588)$([char]0x2588)$([char]0x2557)$([char]0x255A)$([char]0x2588)$([char]0x2588)$([char]0x2588)$([char]0x2588)$([char]0x2588)$([char]0x2588)$([char]0x2554)$([char]0x255D)$([char]0x2588)$([char]0x2588)$([char]0x2588)$([char]0x2588)$([char]0x2588)$([char]0x2588)$([char]0x2588)$([char]0x2551)$([char]0x2588)$([char]0x2588)$([char]0x2551)$([char]0x2588)$([char]0x2588)$([char]0x2588)$([char]0x2588)$([char]0x2588)$([char]0x2588)$([char]0x2588)$([char]0x2551)" -ForegroundColor Cyan
    Write-Host "  $([char]0x255A)$([char]0x2550)$([char]0x255D)  $([char]0x255A)$([char]0x2550)$([char]0x2550)$([char]0x2550)$([char]0x255D)$([char]0x255A)$([char]0x2550)$([char]0x2550)$([char]0x2550)$([char]0x2550)$([char]0x2550)$([char]0x2550)$([char]0x255D) $([char]0x255A)$([char]0x2550)$([char]0x2550)$([char]0x2550)$([char]0x2550)$([char]0x2550)$([char]0x255D) $([char]0x255A)$([char]0x2550)$([char]0x2550)$([char]0x2550)$([char]0x2550)$([char]0x2550)$([char]0x2550)$([char]0x255D)$([char]0x255A)$([char]0x2550)$([char]0x255D)$([char]0x255A)$([char]0x2550)$([char]0x2550)$([char]0x2550)$([char]0x2550)$([char]0x2550)$([char]0x2550)$([char]0x255D)" -ForegroundColor Cyan
    Write-Host ""
    Write-Host "  C O D E   I N S T A L L E R" -ForegroundColor White
    Write-Host "  $([char]0x2500)$([char]0x2500)$([char]0x2500)$([char]0x2500)$([char]0x2500)$([char]0x2500)$([char]0x2500)$([char]0x2500)$([char]0x2500)$([char]0x2500)$([char]0x2500)$([char]0x2500)$([char]0x2500)$([char]0x2500)$([char]0x2500)$([char]0x2500)$([char]0x2500)$([char]0x2500)$([char]0x2500)$([char]0x2500)$([char]0x2500)$([char]0x2500)$([char]0x2500)$([char]0x2500)$([char]0x2500)$([char]0x2500)$([char]0x2500)$([char]0x2500)$([char]0x2500)$([char]0x2500)$([char]0x2500)$([char]0x2500)$([char]0x2500)$([char]0x2500)$([char]0x2500)$([char]0x2500)$([char]0x2500)$([char]0x2500)$([char]0x2500)$([char]0x2500)$([char]0x2500)$([char]0x2500)$([char]0x2500)$([char]0x2500)$([char]0x2500)$([char]0x2500)$([char]0x2500)$([char]0x2500)$([char]0x2500)" -ForegroundColor DarkGray
    Write-Host ""
}

function Write-Step([string]$Label) {
    $Script:Step++
    Write-Host "  [$($Script:Step)] $Label" -ForegroundColor White -NoNewline
}
function Write-Ok([string]$Text)     { Write-Host "  $([char]0x2713) $Text" -ForegroundColor Green }
function Write-Warn([string]$Text)   { Write-Host "  ! $Text" -ForegroundColor Yellow }
function Write-Detail([string]$Text) { Write-Host "      $Text" -ForegroundColor DarkGray }
function Write-Divider               { Write-Host ""; Write-Host "  $([char]0x2500)$([char]0x2500)$([char]0x2500)$([char]0x2500)$([char]0x2500)$([char]0x2500)$([char]0x2500)$([char]0x2500)$([char]0x2500)$([char]0x2500)$([char]0x2500)$([char]0x2500)$([char]0x2500)$([char]0x2500)$([char]0x2500)$([char]0x2500)$([char]0x2500)$([char]0x2500)$([char]0x2500)$([char]0x2500)$([char]0x2500)$([char]0x2500)$([char]0x2500)$([char]0x2500)$([char]0x2500)$([char]0x2500)$([char]0x2500)$([char]0x2500)$([char]0x2500)$([char]0x2500)$([char]0x2500)$([char]0x2500)$([char]0x2500)$([char]0x2500)$([char]0x2500)$([char]0x2500)$([char]0x2500)$([char]0x2500)$([char]0x2500)$([char]0x2500)$([char]0x2500)$([char]0x2500)$([char]0x2500)$([char]0x2500)$([char]0x2500)$([char]0x2500)$([char]0x2500)$([char]0x2500)$([char]0x2500)" -ForegroundColor DarkGray; Write-Host "" }
function Write-Fatal([string]$Msg)   { Write-Host ""; Write-Host "  $([char]0x2717) ERROR: $Msg" -ForegroundColor Red; Write-Host ""; throw $Msg }

# ── Helpers ───────────────────────────────────────────────────────────────────

function Invoke-Fetch([string]$Uri) {
    try {
        return (Invoke-RestMethod -Uri $Uri -UseBasicParsing)
    } catch {
        try {
            $wc = New-Object System.Net.WebClient
            return ($wc.DownloadString($Uri) | ConvertFrom-Json)
        } finally {
            if ($wc) { $wc.Dispose() }
        }
    }
}

function Invoke-Download([string]$Uri, [string]$OutFile) {
    try {
        Invoke-WebRequest -Uri $Uri -OutFile $OutFile -UseBasicParsing
    } catch {
        $wc = New-Object System.Net.WebClient
        try   { $wc.DownloadFile($Uri, $OutFile) }
        finally { $wc.Dispose() }
    }
}

function Get-LatestVersion {
    $release = Invoke-Fetch $GitHubAPI
    return ($release.tag_name -replace '^v', '')
}

function Get-InstalledVersion {
    if (-not (Test-Path $BinaryPath)) { return "" }
    try {
        $out = & $BinaryPath --version 2>$null
        if ($out -match '(\d+\.\d+\.\d+)') { return $Matches[1] }
    } catch {}
    return ""
}

# ── Main ──────────────────────────────────────────────────────────────────────

function Invoke-NeuisInstall {

if ([string]::IsNullOrWhiteSpace($env:USERPROFILE)) { Write-Fatal "USERPROFILE is not set." }

Write-Banner

# Step 1 — resolve version
Write-Step "Version"; Write-Host ""
try   { $Latest = Get-LatestVersion }
catch { Write-Fatal "Could not reach GitHub. Check your internet connection." }
if ([string]::IsNullOrWhiteSpace($Latest)) { Write-Fatal "Could not resolve latest version from GitHub Releases." }
Write-Detail "Latest: v$Latest"

$Installed = Get-InstalledVersion
if ($Installed -and $Installed -eq $Latest) {
    Write-Ok "Already up to date (v$Latest)"
    Write-Host ""
    return
}
if ($Installed) { Write-Detail "Installed: v$Installed $([char]0x2192) upgrading to v$Latest" }

# Step 2 — download
Write-Step "Download"; Write-Host ""
$Arch    = if ($env:PROCESSOR_ARCHITECTURE -eq 'ARM64') { 'arm64' } else { 'x64' }
$Archive = "neusiscode-windows-$Arch.zip"
$Url     = "https://github.com/$Repo/releases/download/v$Latest/$Archive"
$Tmp     = Join-Path $env:TEMP "neusiscode-$([System.IO.Path]::GetRandomFileName()).zip"

Write-Detail $Archive
try {
    Invoke-Download -Uri $Url -OutFile $Tmp
} catch {
    Write-Fatal "Download failed. Manual download: https://github.com/$Repo/releases"
}
Write-Ok "Downloaded"

# Step 3 — install binary
Write-Step "Install"; Write-Host ""
New-Item -ItemType Directory -Force -Path $InstallDir | Out-Null
Expand-Archive -Path $Tmp -DestinationPath $InstallDir -Force
Remove-Item $Tmp -ErrorAction SilentlyContinue

Write-Ok "Installed  $([char]0x2192)  $BinaryPath"

# Step 4 — PATH
Write-Step "PATH"; Write-Host ""
$UserPath = [Environment]::GetEnvironmentVariable('Path', 'User')
if (($UserPath -split ';') -contains $InstallDir) {
    Write-Ok "Already in PATH"
} else {
    [Environment]::SetEnvironmentVariable('Path', "$UserPath;$InstallDir", 'User')
    $env:Path = "$env:Path;$InstallDir"
    Write-Ok "Added to PATH"
    Write-Detail $InstallDir
}

# Step 5 — config (always write latest format, preserve secrets if they exist)
$ApiKey    = ''
$KbRepo    = ''
$NeuronPat = ''
if (Test-Path $ConfigPath) {
    $Raw = [System.IO.File]::ReadAllText($ConfigPath, [System.Text.Encoding]::UTF8)
    if ($Raw -match '"apiKey"\s*:\s*"([^"]+)"')                       { $ApiKey    = $Matches[1] }
    if ($Raw -match '"--kb-repo"\s*,\s*"([^"]+)"')                    { $KbRepo    = $Matches[1] }
    if ($Raw -match '"GITHUB_PERSONAL_ACCESS_TOKEN"\s*:\s*"([^"]+)"') { $NeuronPat = $Matches[1] }
}
if ([string]::IsNullOrWhiteSpace($ApiKey)) {
    Write-Divider
    Write-Host "  Authentication" -ForegroundColor White
    Write-Host ""
    Write-Host "  API Key " -ForegroundColor DarkGray -NoNewline
    Write-Host "$([char]0x25B8) " -ForegroundColor Cyan -NoNewline
    $ApiKey = (Read-Host).Trim()
    if ([string]::IsNullOrWhiteSpace($ApiKey)) { Write-Fatal "API key cannot be empty." }
    Write-Host ""
}

# Project Brain - optional neusis-neuron MCP knowledge-base integration.
# kb-repo is per-project, so this is an opt-in prompt; blank skips it entirely.
if ([string]::IsNullOrWhiteSpace($KbRepo)) {
    Write-Divider
    Write-Host "  Project Brain " -ForegroundColor White -NoNewline
    Write-Host "(optional)" -ForegroundColor DarkGray
    Write-Host ""
    Write-Host "  Connect a project-brain knowledge-base repo for richer context." -ForegroundColor DarkGray
    Write-Host "  Leave blank to skip - you can add it to a project's" -ForegroundColor DarkGray
    Write-Host "  .neusiscode\neusiscode.jsonc later." -ForegroundColor DarkGray
    Write-Host ""
    Write-Host "  KB repo (owner/repo) " -ForegroundColor DarkGray -NoNewline
    Write-Host "$([char]0x25B8) " -ForegroundColor Cyan -NoNewline
    $KbRepo = (Read-Host).Trim()
    if (-not [string]::IsNullOrWhiteSpace($KbRepo)) {
        Write-Host "  GitHub token (fine-grained PAT, Contents:Read) " -ForegroundColor DarkGray -NoNewline
        Write-Host "$([char]0x25B8) " -ForegroundColor Cyan -NoNewline
        $NeuronPat = (Read-Host).Trim()
    }
    Write-Host ""
}

# Install the neusis-neuron MCP server when project-brain is configured.
# Runs in a child process so its strict-mode / encoding settings can't leak
# into this script. The install dir is passed via the inherited INSTALL_DIR
# env var rather than string-embedded, so profile paths containing an
# apostrophe (e.g. C:\Users\O'Connor) still work. Non-fatal: a failure here
# must not break the install. ErrorActionPreference is relaxed around the
# call so native stderr isn't turned into a terminating error; both it and
# INSTALL_DIR are restored in finally (this script may run in the user's
# own session via irm | iex).
if (-not [string]::IsNullOrWhiteSpace($KbRepo)) {
    Write-Detail "Installing neusis-neuron-mcp ..."
    $NeuronOk       = $false
    $PrevInstallDir = $env:INSTALL_DIR
    try {
        $env:INSTALL_DIR       = $InstallDir
        $ErrorActionPreference = 'Continue'
        & powershell -NoProfile -ExecutionPolicy Bypass -Command "Invoke-RestMethod '$NeuronUrl' | Invoke-Expression" 2>&1 | Out-Null
        $NeuronOk = ($LASTEXITCODE -eq 0)
    } catch {
        $NeuronOk = $false
    } finally {
        $ErrorActionPreference = 'Stop'
        $env:INSTALL_DIR       = $PrevInstallDir
    }
    if ($NeuronOk) {
        Write-Ok "neusis-neuron-mcp installed"
    } else {
        Write-Warn "neusis-neuron-mcp install failed - project-brain stays inactive until it is installed"
    }
}

Write-Step "Configuration"; Write-Host ""
New-Item -ItemType Directory -Force -Path $ConfigDir | Out-Null

$NL = [Environment]::NewLine
$Config  = '{' + $NL
$Config += '  "$schema": "https://neusis.ai/config.json",' + $NL
$Config += '  "model": "neusiscode/auto",' + $NL
$Config += '  "provider": {' + $NL
$Config += '    "neusiscode": {' + $NL
$Config += '      "options": {' + $NL
$Config += "        `"apiKey`": `"$ApiKey`"" + $NL
$Config += '      }' + $NL
$Config += '    }' + $NL
$Config += '  },' + $NL
$Config += '  "registry": {' + $NL
$Config += '    "repos": [{ "url": "https://github.com/Neusis-AI-Org/neusiscode-registry" }]' + $NL
$Config += '  },' + $NL
$Config += '  "disabled_providers": ["opencode", "github-copilot"]'
if (-not [string]::IsNullOrWhiteSpace($KbRepo)) {
    $Config += ',' + $NL
    $Config += '  "mcp": {' + $NL
    $Config += '    "neusis-neuron": {' + $NL
    $Config += '      "type": "local",' + $NL
    $Config += "      `"command`": [`"neusis-neuron-mcp`", `"stdio`", `"--kb-repo`", `"$KbRepo`"]," + $NL
    if (-not [string]::IsNullOrWhiteSpace($NeuronPat)) {
        $Config += "      `"environment`": { `"GITHUB_PERSONAL_ACCESS_TOKEN`": `"$NeuronPat`" }," + $NL
    }
    $Config += '      "enabled": true' + $NL
    $Config += '    }' + $NL
    $Config += '  }' + $NL
} else {
    $Config += $NL
}
$Config += '}'
[System.IO.File]::WriteAllText($ConfigPath, $Config, (New-Object System.Text.UTF8Encoding $false))
Write-Ok "Configuration saved"
Write-Detail $ConfigPath
if (-not [string]::IsNullOrWhiteSpace($KbRepo)) {
    Write-Detail "project-brain bound to $KbRepo (per-project override: .neusiscode\neusiscode.jsonc)"
}

# Done
Write-Divider
Write-Host "  $([char]0x2713) Neusis Code v$Latest ready!" -ForegroundColor Green
Write-Host ""
if ($Installed) {
    Write-Host "  Updated: v$Installed $([char]0x2192) v$Latest" -ForegroundColor DarkGray
} else {
    Write-Host "  Open a new terminal and run:" -ForegroundColor DarkGray
    Write-Host "    neusiscode" -ForegroundColor Cyan
    Write-Host ""
    Write-Host "  To upgrade later, re-run this installer." -ForegroundColor DarkGray
}
Write-Host ""
Write-Host ""

} # end Invoke-NeuisInstall

try { Invoke-NeuisInstall } catch { }
