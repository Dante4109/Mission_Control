#!/usr/bin/env pwsh
<#
.SYNOPSIS
    Sync Mission Control agent definitions to Claude Code format

.DESCRIPTION
    Reads canonical *.agent.md files from .github/agents/ and generates
    equivalent *.md files for Claude Code in .claude/agents/.

    The body content is copied unchanged; only frontmatter tool names
    are converted from Copilot names to Claude Code names.

    Run this any time you add or modify an agent in .github/agents/.

.PARAMETER SourceDir
    Source directory containing *.agent.md files.
    Defaults to .github/agents/ relative to the repo root.

.PARAMETER OutputDir
    Output directory for Claude Code agent files.
    Defaults to .claude/agents/ relative to the repo root.

.PARAMETER Force
    Overwrite existing Claude Code agent files.

.EXAMPLE
    # From Mission_Control root
    .\.github\scripts\Sync-Agents.ps1

.EXAMPLE
    .\.github\scripts\Sync-Agents.ps1 -Force
#>

param(
    [Parameter(Mandatory=$false)]
    [string]$SourceDir,

    [Parameter(Mandatory=$false)]
    [string]$OutputDir,

    [Parameter(Mandatory=$false)]
    [switch]$Force
)

$ErrorActionPreference = "Stop"

# Resolve repo root from script location (.github/scripts/ -> .github/ -> repo root)
$ScriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$RepoRoot = Split-Path -Parent (Split-Path -Parent $ScriptDir)

if (-not $SourceDir) { $SourceDir = Join-Path $RepoRoot ".github\agents" }
if (-not $OutputDir) { $OutputDir = Join-Path $RepoRoot ".claude\agents" }

# Copilot tool name -> Claude Code tool name(s)
$ToolMap = @{
    'shell'      = @('Bash')
    'read'       = @('Read')
    'search'     = @('Grep', 'Glob')
    'edit'       = @('Edit', 'Write')
    'task'       = @('TaskCreate', 'TaskUpdate', 'TaskList')
    'skill'      = @('Skill')
    'web_search' = @('WebSearch')
    'web_fetch'  = @('WebFetch')
    'ask_user'   = @('AskUserQuestion')
}

Write-Host ""
Write-Host "╔════════════════════════════════════════════════════════╗"
Write-Host "║         Syncing Agents to Claude Code Format          ║"
Write-Host "╚════════════════════════════════════════════════════════╝"
Write-Host "Source: $SourceDir"
Write-Host "Output: $OutputDir"
Write-Host ""

if (-not (Test-Path $SourceDir)) {
    Write-Error "Source directory not found: $SourceDir"
    exit 1
}

if (-not (Test-Path $OutputDir)) {
    New-Item -ItemType Directory -Path $OutputDir -Force | Out-Null
    Write-Host "✓ Created output directory"
}

$AgentFiles = Get-ChildItem $SourceDir -Filter "*.agent.md"

if ($AgentFiles.Count -eq 0) {
    Write-Warning "No .agent.md files found in: $SourceDir"
    exit 0
}

$Created = 0
$Updated = 0
$Skipped = 0

foreach ($File in $AgentFiles) {
    $OutputName = $File.BaseName -replace '\.agent$', ''
    $OutputPath = Join-Path $OutputDir "$OutputName.md"
    $IsUpdate = Test-Path $OutputPath

    if ($IsUpdate -and -not $Force) {
        Write-Host "⚠ Skipped (exists): $OutputName.md  (use -Force to overwrite)"
        $Skipped++
        continue
    }

    $Content = (Get-Content $File.FullName -Raw -Encoding UTF8) -replace "`r`n", "`n"

    # Split on --- delimiters (limit 3 parts: before, frontmatter, body)
    $Parts = $Content -split '(?m)^---\s*$', 3

    if ($Parts.Count -ge 3) {
        $FrontmatterRaw = $Parts[1].Trim()
        $Body = $Parts[2] -replace '^[\r\n]+', ''

        # Convert the tools: [...] line, expanding multi-value mappings
        $FrontmatterLines = $FrontmatterRaw -split "`n"
        $ConvertedLines = foreach ($line in $FrontmatterLines) {
            if ($line -match "^tools:\s*\[(.+)\]") {
                $ToolsStr = $Matches[1]
                $CopilotTools = $ToolsStr -split ',' |
                    ForEach-Object { $_ -replace "['\s`"]+", '' } |
                    Where-Object { $_ -ne '' }

                $ClaudeTools = foreach ($tool in $CopilotTools) {
                    if ($ToolMap.ContainsKey($tool)) { $ToolMap[$tool] } else { $tool }
                }

                $ToolList = ($ClaudeTools | ForEach-Object { "'$_'" }) -join ', '
                "tools: [$ToolList]"
            } else {
                $line
            }
        }

        $ConvertedFrontmatter = $ConvertedLines -join "`n"
        $OutputContent = "---`n$ConvertedFrontmatter`n---`n$Body"
    } else {
        # No frontmatter — copy body as-is
        $OutputContent = $Content
    }

    Set-Content -Path $OutputPath -Value $OutputContent -Encoding UTF8 -NoNewline

    if ($IsUpdate) {
        Write-Host "✓ Updated: $OutputName.md"
        $Updated++
    } else {
        Write-Host "✓ Created: $OutputName.md"
        $Created++
    }
}

Write-Host ""
Write-Host "╔════════════════════════════════════════════════════════╗"
Write-Host "║              ✓ Sync Complete                          ║"
Write-Host "╚════════════════════════════════════════════════════════╝"
if ($Created -gt 0) { Write-Host "  Created: $Created file(s)" }
if ($Updated -gt 0) { Write-Host "  Updated: $Updated file(s)" }
if ($Skipped -gt 0) { Write-Host "  Skipped: $Skipped file(s) (use -Force to overwrite)" }
Write-Host ""
