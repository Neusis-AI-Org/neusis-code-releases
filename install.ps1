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

# Verify the archive against the release's SHA256SUMS.txt before installing it.
$SumsTmp = Join-Path $env:TEMP "neusiscode-$([System.IO.Path]::GetRandomFileName()).sha256"
try {
    Invoke-Download -Uri "https://github.com/$Repo/releases/download/v$Latest/SHA256SUMS.txt" -OutFile $SumsTmp
} catch {
    Remove-Item $Tmp -ErrorAction SilentlyContinue
    Write-Fatal "Could not download SHA256SUMS.txt for v$Latest."
}
$Expected = $null
foreach ($Line in (Get-Content -Path $SumsTmp)) {
    $Parts = $Line.Trim() -split '\s+', 2
    if ($Parts.Count -eq 2 -and $Parts[1].TrimStart('*') -eq $Archive) { $Expected = $Parts[0].ToLowerInvariant(); break }
}
Remove-Item $SumsTmp -ErrorAction SilentlyContinue
if (-not $Expected) {
    Remove-Item $Tmp -ErrorAction SilentlyContinue
    Write-Fatal "SHA256SUMS.txt for v$Latest has no entry for $Archive."
}
$Actual = (Get-FileHash -Path $Tmp -Algorithm SHA256).Hash.ToLowerInvariant()
if ($Actual -ne $Expected) {
    Remove-Item $Tmp -ErrorAction SilentlyContinue
    Write-Fatal "Checksum mismatch for $Archive (expected $Expected, got $Actual). Not installing."
}
Write-Ok "Checksum verified"

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

# Step 5 — config. The installer sets only its own settings ($schema, the API key, the default model, the
# registry, disabled_providers and the neusis-neuron server) and keeps everything else in the file. The binary just
# installed reads and writes the JSONC as Bun (BUN_BE_BUN=1), so nothing else is needed. Secrets reach it through the
# environment, and it runs from the install dir with --no-env-file, so nothing in the current directory applies.
$ConfigJs = @'
// Reads or updates ~/.config/neusiscode/neusiscode.json. Run by the neusiscode binary as Bun (BUN_BE_BUN=1).
// read: prints one installer-owned value (NEUSIS_CONFIG_FIELD). write: sets the installer-owned settings and keeps
// everything else; prints created, updated (previous file saved as .bak) or unchanged (file not touched).
const fs = require("node:fs")
const env = process.env
const file = env.NEUSIS_CONFIG_PATH
const text = fs.existsSync(file) ? fs.readFileSync(file, "utf8") : ""
const body = text.replace(/^﻿/, "")
// Bun.JSONC.parse ignores anything after the first value, which neusiscode rejects. The extra array element makes
// such content (a pasted second object, a stray brace or comma) an error, so those files take the fallback.
const values = body.trim() ? Bun.JSONC.parse(`[${body}\n,0]`) : [{}, 0]
if (values.length !== 2) throw new Error("unexpected content after the config object")
const config = values[0]
const isObject = (value) => value !== null && typeof value === "object" && !Array.isArray(value)
if (!isObject(config)) throw new Error("the config is not a JSON object")
const neuron = isObject(config.mcp) && isObject(config.mcp["neusis-neuron"]) ? config.mcp["neusis-neuron"] : undefined
if (env.NEUSIS_CONFIG_MODE === "read") {
  const command = Array.isArray(neuron?.command) ? neuron.command : []
  const at = command.findIndex((arg) => arg === "--kb-repo" || String(arg).startsWith("--kb-repo="))
  const value = {
    apiKey: config.provider?.neusiscode?.options?.apiKey,
    kbRepo: at < 0 ? undefined : command[at] === "--kb-repo" ? command[at + 1] : command[at].slice("--kb-repo=".length),
    pat: neuron?.environment?.GITHUB_PERSONAL_ACCESS_TOKEN,
    hasNeuron: neuron ? "yes" : undefined,
  }[env.NEUSIS_CONFIG_FIELD]
  process.stdout.write(typeof value === "string" ? value : "")
} else {
  const SCHEMA = "https://docs.neusis.ai/config.json"
  const before = JSON.stringify(config)
  const merged = "$schema" in config ? config : { $schema: SCHEMA, ...config }
  merged.$schema = SCHEMA
  merged.model ??= "neusiscode/auto"
  const child = (parent, key) => (isObject(parent[key]) ? parent[key] : (parent[key] = {}))
  if (env.NEUSIS_API_KEY) child(child(child(merged, "provider"), "neusiscode"), "options").apiKey = env.NEUSIS_API_KEY
  merged.registry ??= { repos: [{ url: "https://github.com/Neusis-AI-Org/neusiscode-registry" }] }
  const disabled = Array.isArray(merged.disabled_providers) ? merged.disabled_providers : []
  for (const id of ["opencode", "github-copilot"]) if (!disabled.includes(id)) disabled.push(id)
  merged.disabled_providers = disabled
  // An existing neusis-neuron entry is the user's: the installer only adds one.
  if (env.NEUSIS_KB_REPO && !neuron) {
    child(merged, "mcp")["neusis-neuron"] = {
      type: "local",
      command: ["neusis-neuron-mcp", "stdio", "--kb-repo", env.NEUSIS_KB_REPO],
      ...(env.NEUSIS_NEURON_PAT ? { environment: { GITHUB_PERSONAL_ACCESS_TOKEN: env.NEUSIS_NEURON_PAT } } : {}),
      enabled: true,
    }
  }
  if (text.trim() && JSON.stringify(merged) === before) {
    process.stdout.write("unchanged")
  } else {
    if (text.trim()) fs.copyFileSync(file, `${file}.bak`)
    // The file holds the API key: owner-only when created.
    fs.writeFileSync(file, `${JSON.stringify(merged, null, 2)}\n`, { mode: 0o600 })
    process.stdout.write(text.trim() ? "updated" : "created")
  }
}
'@

# Runs $ConfigJs from a temporary file (Windows PowerShell mangles quotes in native arguments) and returns its output,
# or $null when it fails. The environment and location are restored: this script may run in the user's own session.
function Invoke-ConfigJs([string]$Mode, [string]$Field = '') {
    $Vars = @{
        BUN_BE_BUN          = '1'
        NEUSIS_CONFIG_PATH  = $ConfigPath
        NEUSIS_CONFIG_MODE  = $Mode
        NEUSIS_CONFIG_FIELD = $Field
        NEUSIS_API_KEY      = $ApiKey
        NEUSIS_KB_REPO      = $KbRepo
        NEUSIS_NEURON_PAT   = $NeuronPat
    }
    $Previous = @{}
    $Pushed   = $false
    $PrevEap  = $ErrorActionPreference
    $ScriptJs = Join-Path ([System.IO.Path]::GetTempPath()) "neusiscode-config-$([guid]::NewGuid()).js"
    try {
        [System.IO.File]::WriteAllText($ScriptJs, $ConfigJs, (New-Object System.Text.UTF8Encoding $false))
        foreach ($Name in $Vars.Keys) {
            $Previous[$Name] = [Environment]::GetEnvironmentVariable($Name, 'Process')
            [Environment]::SetEnvironmentVariable($Name, $Vars[$Name], 'Process')
        }
        Push-Location -LiteralPath $InstallDir
        $Pushed = $true
        $ErrorActionPreference = 'Continue'
        $Output = & $BinaryPath --no-env-file $ScriptJs 2>$null
        if ($LASTEXITCODE -ne 0) { return $null }
        return (@($Output) -join "`n")
    } catch {
        return $null
    } finally {
        # Undo the session changes first; a failing Pop-Location must not skip them. [NullString] removes a variable
        # that was not set before (on .NET 9 an empty string would leave it defined).
        $ErrorActionPreference = $PrevEap
        foreach ($Name in $Previous.Keys) {
            if ($null -eq $Previous[$Name]) { [Environment]::SetEnvironmentVariable($Name, [NullString]::Value, 'Process') }
            else { [Environment]::SetEnvironmentVariable($Name, $Previous[$Name], 'Process') }
        }
        Remove-Item -LiteralPath $ScriptJs -Force -ErrorAction SilentlyContinue
        if ($Pushed) { try { Pop-Location } catch { } }
    }
}

$ApiKey    = ''
$KbRepo    = ''
$NeuronPat = ''
$HasNeuron = ''
if (Test-Path $ConfigPath) {
    $Read = Invoke-ConfigJs 'read' 'apiKey'
    if ($null -ne $Read) {
        $ApiKey    = $Read
        $KbRepo    = [string](Invoke-ConfigJs 'read' 'kbRepo')
        $NeuronPat = [string](Invoke-ConfigJs 'read' 'pat')
        $HasNeuron = [string](Invoke-ConfigJs 'read' 'hasNeuron')
    } else {
        # Not valid JSONC: match the values instead, so they survive the rewrite below.
        $Raw = [System.IO.File]::ReadAllText($ConfigPath, [System.Text.Encoding]::UTF8)
        if ($Raw -match '"apiKey"\s*:\s*"([^"]+)"')                       { $ApiKey    = $Matches[1] }
        if ($Raw -match '"--kb-repo"\s*,\s*"([^"]+)"')                    { $KbRepo    = $Matches[1] }
        if ($Raw -match '"GITHUB_PERSONAL_ACCESS_TOKEN"\s*:\s*"([^"]+)"') { $NeuronPat = $Matches[1] }
    }
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
# kb-repo is per-project, so this is an opt-in prompt; blank skips it entirely. A neusis-neuron entry the
# installer cannot read the repo from (another flag form, or the repo set in its environment) is left alone.
if ([string]::IsNullOrWhiteSpace($KbRepo) -and [string]::IsNullOrWhiteSpace($HasNeuron)) {
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

$ConfigResult = Invoke-ConfigJs 'write'
if ($null -ne $ConfigResult) {
    switch ($ConfigResult) {
        'unchanged' { Write-Ok "Configuration up to date" }
        'updated'   { Write-Ok "Configuration updated"; Write-Detail "Your other settings are kept; the previous file is $ConfigPath.bak" }
        default     { Write-Ok "Configuration saved" }
    }
} else {
    # Not valid JSONC, or the binary could not run: keep a copy and write the installer's settings alone.
    if (Test-Path $ConfigPath) {
        Copy-Item -LiteralPath $ConfigPath -Destination "$ConfigPath.bak" -Force
        Write-Warn "Could not read $ConfigPath; saved it as $ConfigPath.bak. Copy your own settings back from there."
    }
    $NL = [Environment]::NewLine
    $Config  = '{' + $NL
    $Config += '  "$schema": "https://docs.neusis.ai/config.json",' + $NL
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
}
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
