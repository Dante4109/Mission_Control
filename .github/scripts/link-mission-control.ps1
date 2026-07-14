#!/usr/bin/env pwsh
<#
.SYNOPSIS
    Link Mission Control agents to any repository

.DESCRIPTION
    Automatically creates the necessary symbolic links and configuration files
    to give any project access to Mission Control agents via the /agent command.
    
    Can be run from any repository root directory.

.PARAMETER TargetRepo
    Path to the target repository (defaults to current directory)

.PARAMETER Force
    Overwrite existing symlinks and configuration files

.EXAMPLE
    # From the repository root
    LinkMC
    
.EXAMPLE
    # From anywhere, specify target repo
    LinkMC -TargetRepo "C:\projects\MyProject"
    
.EXAMPLE
    # Overwrite existing links
    LinkMC -Force
#>

param(
    [Parameter(Mandatory=$false)]
    [string]$TargetRepo = ".",
    
    [Parameter(Mandatory=$false)]
    [switch]$Force
)

$ErrorActionPreference = "Stop"

# Resolve paths
$ResolvedTargetRepo = Resolve-Path $TargetRepo -ErrorAction Stop
$MissionControlRoot = Split-Path -Parent (Split-Path -Parent $PSScriptRoot)

Write-Host ""
Write-Host "╔════════════════════════════════════════════════════════╗"
Write-Host "║         Linking Mission Control to Repository         ║"
Write-Host "╚════════════════════════════════════════════════════════╝"
Write-Host ""
Write-Host "Target Repository:   $($ResolvedTargetRepo.Path)"
Write-Host "Mission Control:     $MissionControlRoot"
Write-Host ""

# Verify Mission Control exists
if (-not (Test-Path $MissionControlRoot)) {
    Write-Error "Mission Control root not found at: $MissionControlRoot"
    exit 1
}

# Create .github/agents directory if it doesn't exist
$AgentsDir = Join-Path $ResolvedTargetRepo ".github\agents"
if (-not (Test-Path $AgentsDir)) {
    New-Item -ItemType Directory -Path $AgentsDir -Force | Out-Null
    Write-Host "✓ Created directory: .github/agents"
}

# Create directory junction to Mission_Control agents (no admin required)
$SymlinkPath = Join-Path $AgentsDir "mission-control"
$MissionControlAgentsPath = Join-Path $MissionControlRoot ".github\agents"

if (Test-Path $SymlinkPath) {
    if ($Force) {
        Remove-Item $SymlinkPath -Force -Recurse | Out-Null
        Write-Host "✓ Removed existing junction (Force mode)"
    } else {
        Write-Host "⚠ Junction already exists at: $SymlinkPath"
        Write-Host "  Use -Force to overwrite"
        Write-Host ""
        exit 0
    }
}

New-Item -ItemType Junction -Path $SymlinkPath -Target $MissionControlAgentsPath | Out-Null
Write-Host "✓ Created junction: .github/agents/mission-control"

# ── Claude Code setup ──────────────────────────────────────────────────────────

# Ensure .claude/agents/ in Mission Control is current
$SyncAgentsScript = Join-Path $MissionControlRoot ".github\scripts\Sync-Agents.ps1"
if (Test-Path $SyncAgentsScript) {
    & $SyncAgentsScript -Force 2>&1 | Out-Null
    Write-Host "✓ Synced agents to Claude Code format"
}

# Create .claude/agents/ in the target repo
$ClaudeAgentsDir = Join-Path $ResolvedTargetRepo ".claude\agents"
if (-not (Test-Path $ClaudeAgentsDir)) {
    New-Item -ItemType Directory -Path $ClaudeAgentsDir -Force | Out-Null
    Write-Host "✓ Created directory: .claude/agents"
}

# Create directory junction: .claude/agents/mission-control -> MissionControl/.claude/agents/
$ClaudeSymlinkPath = Join-Path $ClaudeAgentsDir "mission-control"
$MissionControlClaudeAgentsPath = Join-Path $MissionControlRoot ".claude\agents"

if (Test-Path $ClaudeSymlinkPath) {
    if ($Force) {
        Remove-Item $ClaudeSymlinkPath -Force -Recurse | Out-Null
        Write-Host "✓ Removed existing Claude Code junction (Force mode)"
    } else {
        Write-Host "⚠ Claude Code junction already exists: .claude/agents/mission-control"
        Write-Host "  Use -Force to overwrite"
    }
}

if (-not (Test-Path $ClaudeSymlinkPath)) {
    if (Test-Path $MissionControlClaudeAgentsPath) {
        New-Item -ItemType Junction -Path $ClaudeSymlinkPath -Target $MissionControlClaudeAgentsPath | Out-Null
        Write-Host "✓ Created junction: .claude/agents/mission-control"
    } else {
        Write-Warning "Claude Code agents not found at: $MissionControlClaudeAgentsPath"
        Write-Warning "Run Sync-Agents.ps1 first: $SyncAgentsScript"
    }
}

# Create/update AGENTS.md
$AgentsMdPath = Join-Path $ResolvedTargetRepo "AGENTS.md"
$RepoName = (Split-Path -Leaf $ResolvedTargetRepo.Path)
$RepoAbbr = (($RepoName -split '-' | % { $_[0] }) -join '').ToUpper()

$AgentsMdContent = @"
# $RepoName - Available Agents

Custom agents available for this project, sourced from the Mission Control master workspace.

## Quick Start

To use agents in this project:

\`\`\`
/agent
\`\`\`

Then select from the available agents, or directly reference:

\`\`\`
/agent github-issue-creator
Create a GitHub issue for: "Your user story here"
\`\`\`

## GitHub Issue Creator

**Path:** \`Mission_Control\.github\agents\github-issue-creator.agent.md\`

Transform user stories into BDD-formatted GitHub issues with auto-generated test scenarios.

**Trigger Phrases:**
- "create a GitHub issue"
- "generate an issue from this story"
- "create an issue for this user story"
- "turn this into a GitHub issue"
- "make a GitHub issue"

**Use When:**
- Creating well-structured GitHub issues with BDD methodology
- You have a user story needing Given/When/Then scenarios
- You want automatic acceptance criteria generation
- You need consistent ticket numbering ($RepoAbbr-XXXX format)

**Example:**
\`\`\`
/agent github-issue-creator
Create a GitHub issue for: "Users should be able to reset their password via email"
\`\`\`

## Mission Control Agents

All agents from the Mission Control master folder are available for use. To browse and select:

\`\`\`
/agent
\`\`\`

## Using Agents from Mission Control

### Method 1: /agent Slash Command
\`\`\`
/agent
\`\`\`
Select from the list of available agents.

### Method 2: PowerShell Helper
\`\`\`powershell
Use-Agent -Type explore -Prompt "Your prompt here"
Use-Agent -Type code-review -PromptFile code-review-prompt.md
\`\`\`

### Method 3: Run Agent Script Directly
\`\`\`powershell
& "C:\projects\AppDev\Mission_Control\.github\scripts\run-agent.ps1" \`
    -TargetPath "\$(Get-Location)" \`
    -AgentType explore \`
    -CustomPrompt "Your prompt"
\`\`\`

## For More Information

- **Mission Control Setup:** C:\projects\AppDev\Mission_Control\SETUP.md
- **Quick Reference:** C:\projects\AppDev\Mission_Control\QUICK_REFERENCE.md
- **Mission Control README:** C:\projects\AppDev\Mission_Control\README.md
"@

if (Test-Path $AgentsMdPath) {
    if ($Force) {
        Set-Content -Path $AgentsMdPath -Value $AgentsMdContent -Encoding UTF8
        Write-Host "✓ Updated AGENTS.md (Force mode)"
    } else {
        Write-Host "⚠ AGENTS.md already exists"
        Write-Host "  Use -Force to overwrite"
    }
} else {
    Set-Content -Path $AgentsMdPath -Value $AgentsMdContent -Encoding UTF8
    Write-Host "✓ Created AGENTS.md"
}

# Dynamically create top-level wrappers for all agents in Mission Control
$MCAgentsPath = Join-Path $MissionControlRoot ".github\agents"
$AgentFiles = Get-ChildItem $MCAgentsPath -Filter "*.agent.md" -ErrorAction SilentlyContinue

$WrappersCreated = 0
$WrappersUpdated = 0
$WrappersSkipped = 0

foreach ($AgentFile in $AgentFiles) {
    $LocalAgentPath = Join-Path $AgentsDir $AgentFile.Name
    $SourceContent = Get-Content $AgentFile.FullName -Raw -Encoding UTF8

    if (Test-Path $LocalAgentPath) {
        if ($Force) {
            Set-Content -Path $LocalAgentPath -Value $SourceContent -Encoding UTF8
            $WrappersUpdated++
        } else {
            $WrappersSkipped++
        }
    } else {
        Set-Content -Path $LocalAgentPath -Value $SourceContent -Encoding UTF8
        $WrappersCreated++
    }
}

if ($WrappersCreated -gt 0)  { Write-Host "✓ Created $WrappersCreated agent wrapper(s)" }
if ($WrappersUpdated -gt 0)  { Write-Host "✓ Updated $WrappersUpdated agent wrapper(s) (Force mode)" }
if ($WrappersSkipped -gt 0)  { Write-Host "⚠ Skipped $WrappersSkipped existing agent wrapper(s) (use -Force to update)" }

# Create/update CLAUDE.md for Claude Code
$ClaudeMdPath = Join-Path $ResolvedTargetRepo "CLAUDE.md"
$AgentList = ($AgentFiles | ForEach-Object { "- **$($_.BaseName -replace '\.agent$', '')**" }) -join "`n"

$ClaudeMdContent = @"
# $RepoName - Claude Code Project Context

This project is linked to Mission Control and has access to shared AI agents.
Ticket prefix for this repo: **$RepoAbbr** (e.g., $RepoAbbr-0001)

## Available Agents

$AgentList

### github-issue-creator

Transform user stories into BDD-formatted GitHub issues.

**Trigger phrases:**
- "create a GitHub issue"
- "generate an issue from this story"
- "turn this into a GitHub issue"
- "make a GitHub issue for"

**Ticket format:** $RepoAbbr-XXXX

## Using Agents

### Claude Code (default)
Just describe what you want and Claude Code will select the right agent:
``````
Create a GitHub issue for: "Users should be able to reset their password via email"
``````

Or run explicitly via PowerShell:
``````powershell
Use-Agent -Type explore -Prompt "Your prompt here"
Use-Agent -Type code-review -PromptFile code-review-prompt.md
``````

### GitHub Copilot
``````
/agent github-issue-creator
Create a GitHub issue for: "Your user story here"
``````

Or via PowerShell:
``````powershell
Use-Agent -Type explore -Prompt "Your prompt here" -Provider Copilot
``````

## Key Paths

- **Claude Code agents:** `.claude/agents/` → linked to $MissionControlRoot\.claude\agents\
- **Copilot agents:** `.github/agents/` → linked to $MissionControlRoot\.github\agents\
- **Prompts:** $MissionControlRoot\.github\prompts\
"@

if (Test-Path $ClaudeMdPath) {
    if ($Force) {
        Set-Content -Path $ClaudeMdPath -Value $ClaudeMdContent -Encoding UTF8
        Write-Host "✓ Updated CLAUDE.md (Force mode)"
    } else {
        Write-Host "⚠ CLAUDE.md already exists"
        Write-Host "  Use -Force to overwrite"
    }
} else {
    Set-Content -Path $ClaudeMdPath -Value $ClaudeMdContent -Encoding UTF8
    Write-Host "✓ Created CLAUDE.md"
}

Write-Host ""
Write-Host "╔════════════════════════════════════════════════════════╗"
Write-Host "║            ✓ Mission Control Linked                   ║"
Write-Host "╚════════════════════════════════════════════════════════╝"
Write-Host ""
Write-Host "Next Steps:"
Write-Host "  1. Stage changes:    git add ."
Write-Host "  2. Commit:           git commit -m 'Link Mission Control agents'"
Write-Host "  3. Use (Claude Code): Use-Agent -Type explore -Prompt '...'"
Write-Host "  4. Use (Copilot):     /agent  or  Use-Agent ... -Provider Copilot"
Write-Host ""
Write-Host "Available agents:"
$AgentFiles | ForEach-Object { Write-Host "  • $($_.BaseName -replace '\.agent$', '')" }
Write-Host ""
