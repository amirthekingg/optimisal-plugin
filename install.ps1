<#
.SYNOPSIS
  Installs Optimisal's agent skills and OAuth-enabled MCP config on Windows.
.EXAMPLE
  .\integrations\install.ps1 -Client all
  .\integrations\install.ps1 -Client agy
  .\integrations\install.ps1 -Client claude
  .\integrations\install.ps1 -Client codex
#>
param(
  [ValidateSet("all", "claude", "agy", "codex", "grok", "cursor")]
  [string]$Client = "all",
  [string]$BaseUrl = $(if ($env:OPTIMISAL_URL) { $env:OPTIMISAL_URL } else { "https://dashboard.optimisal.app" })
)

$ErrorActionPreference = "Stop"
$Here = Split-Path -Parent $MyInvocation.MyCommand.Path
$RepoRoot = Split-Path -Parent $Here
$McpUrl = "$($BaseUrl.TrimEnd('/'))/mcp"

function Copy-Skills {
  param([string]$Dest)
  New-Item -ItemType Directory -Force -Path $Dest | Out-Null
  Get-ChildItem -Path (Join-Path $Here "skills") -Directory | ForEach-Object {
    $target = Join-Path $Dest $_.Name
    if (Test-Path $target) {
      Remove-Item -Recurse -Force $target
    }
    Copy-Item -Recurse -Force $_.FullName $target
  }
}

function Install-Claude {
  $marketplaceRoot = if (Test-Path (Join-Path $Here ".claude-plugin\marketplace.json")) { $Here } else { $RepoRoot }
  if (Get-Command claude -ErrorAction SilentlyContinue) {
    claude plugin marketplace add $marketplaceRoot | Out-Null
    claude plugin install optimisal@optimisal
    if ($LASTEXITCODE -ne 0) {
      claude mcp add --transport http optimisal $McpUrl
    }
  } else {
    Write-Host "Claude CLI not found. Run in Claude Code:" -ForegroundColor Yellow
    Write-Host "  /plugin marketplace add amirthekingg/optimisal-plugin"
    Write-Host "  /plugin install optimisal@optimisal"
    Write-Host "Or: claude mcp add --transport http optimisal $McpUrl"
  }
}

function Install-Agy {
  $agyHome = if ($env:AGY_HOME) { $env:AGY_HOME } else { Join-Path $HOME ".gemini\config" }
  $dest = Join-Path $agyHome "plugins\optimisal"
  New-Item -ItemType Directory -Force -Path (Split-Path -Parent $dest) | Out-Null
  if (Test-Path $dest) {
    Remove-Item -Recurse -Force $dest
  }
  New-Item -ItemType Directory -Force -Path $dest | Out-Null
  foreach ($item in @("plugin.json", "mcp_config.json", "assets", "rules", "skills")) {
    $src = Join-Path $Here $item
    if (Test-Path $src) {
      Copy-Item -Recurse -Force $src (Join-Path $dest $item)
    }
  }
  Write-Host "Installed Antigravity (AGY) plugin at $dest" -ForegroundColor Green
}

function Install-Codex {
  $codexHome = if ($env:CODEX_HOME) { $env:CODEX_HOME } else { Join-Path $HOME ".codex" }
  Copy-Skills (Join-Path $codexHome "skills")
  Copy-Skills (Join-Path $HOME ".agents\skills")

  $cfg = Join-Path $codexHome "config.toml"
  New-Item -ItemType Directory -Force -Path $codexHome | Out-Null
  $existing = if (Test-Path $cfg) { Get-Content -Raw $cfg } else { "" }
  if ($existing -notmatch '(?m)^\[mcp_servers\.optimisal\]') {
    $block = "`r`n[mcp_servers.optimisal]`r`nurl = `"$McpUrl`"`r`n"
    Add-Content -Path $cfg -Value $block -Encoding UTF8
  }
  Write-Host "Installed Codex skills and MCP config ($McpUrl) in $cfg" -ForegroundColor Green
}

function Install-Grok {
  $grokHome = if ($env:GROK_HOME) { $env:GROK_HOME } else { Join-Path $HOME ".grok" }
  Copy-Skills (Join-Path $grokHome "skills")
  if (Get-Command grok -ErrorAction SilentlyContinue) {
    grok mcp add --transport http optimisal $McpUrl
  } else {
    Write-Host "Installed Grok skills. Run: grok mcp add --transport http optimisal $McpUrl"
  }
}

function Install-Cursor {
  $cursorHome = if ($env:CURSOR_HOME) { $env:CURSOR_HOME } else { Join-Path $HOME ".cursor" }
  Copy-Skills (Join-Path $cursorHome "skills")
  Write-Host "Installed Cursor skills in $cursorHome\skills. Add $McpUrl in Cursor (Settings -> Tools & MCP)."
}

switch ($Client) {
  "all" { Install-Claude; Install-Agy; Install-Codex }
  "claude" { Install-Claude }
  "agy" { Install-Agy }
  "codex" { Install-Codex }
  "grok" { Install-Grok }
  "cursor" { Install-Cursor }
}
