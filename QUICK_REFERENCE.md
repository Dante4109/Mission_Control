# Mission Control - Quick Reference

## Setup (One-time)

```powershell
# Open your PowerShell profile
notepad $PROFILE

# Add to the file:
$MissionControlModule = "C:\projects\AppDev\Mission_Control\mission-control.psm1"
if (Test-Path $MissionControlModule) {
    Import-Module $MissionControlModule -Force
}

# Reload PowerShell
. $PROFILE
```

## Link Mission Control to a Repository

From any repository root:

```powershell
LinkMC
```

This creates:
- `.github/agents/` + junction → Mission Control (Copilot)
- `.claude/agents/` + junction → Mission Control (Claude Code)
- `AGENTS.md` (Copilot docs) + `CLAUDE.md` (Claude Code docs)

Then use `Use-Agent` (Claude Code default) or `/agent` in Copilot CLI!

## Common Commands

```powershell
# Link Mission Control to current repository (sets up both Claude Code + Copilot)
LinkMC

# Link to a specific repository
LinkMC -TargetRepo "C:\projects\MyProject"

# Overwrite existing links
LinkMC -Force

# Sync .agent.md files to Claude Code format (run after editing agents)
.\.github\scripts\Sync-Agents.ps1 -Force

# From ANY directory, explore a project (Claude Code — default)
Use-Agent -Type explore -Prompt "Your question here"

# Same, using Copilot instead
Use-Agent -Type explore -Prompt "Your question here" -Provider Copilot

# Code review
Use-Agent -Type code-review -PromptFile code-review-prompt.md

# Task execution
Use-Agent -Type task -Prompt "npm run build && npm test"

# General-purpose
Use-Agent -Type general-purpose -Prompt "Complex multi-step task"

# See available prompts, templates, configs
Show-MissionControlResources
```

## Agent Types

| Type | Best For |
|------|----------|
| `explore` | Understanding code, finding patterns, analyzing structure |
| `task` | Running commands, tests, builds, deployments |
| `code-review` | Security, quality, best practices |
| `general-purpose` | Complex workflows requiring multiple steps |

## Example Workflow

```powershell
# From VDRF_Template without changing directory
cd C:\projects\AppDev\VDRF_Template

# Explore API structure
Use-Agent -Type explore -Prompt "List all API endpoints with their authentication requirements"

# Review code for security
Use-Agent -Type code-review -PromptFile code-review-prompt.md

# Test something
Use-Agent -Type task -Prompt "Run Cypress tests on the auth flow"
```

## Key Directories

```
Mission_Control/
├── .github/
│   ├── agents/          ← Custom agent definitions
│   ├── prompts/         ← Reusable prompts
│   ├── templates/       ← Output formatting
│   ├── config/          ← Settings and configurations
│   ├── scripts/         ← Helper scripts
│   └── outputs/         ← Execution logs and results
```

## Common Prompts

Check what's available:
```powershell
Show-MissionControlResources
```

Then use them:
```powershell
Use-Agent -Type code-review -PromptFile code-review-prompt.md
Use-Agent -Type explore -PromptFile exploration-prompt.md
Use-Agent -Type task -PromptFile task-prompt.md
```

## Create New Resources

### New Prompt
1. Create `Mission_Control\.github\prompts\my-prompt.md`
2. Use it: `Use-Agent -Type explore -PromptFile my-prompt.md`

### New Template
1. Create `Mission_Control\.github\templates\my-template.md`
2. Reference in agent execution

### New Config
1. Create `Mission_Control\.github\config\my-config.json`
2. Use it: `Use-Agent -Type task -Config my-config.json`

## Troubleshooting

```powershell
# Verify installation
$env:MISSION_CONTROL_ROOT  # Should show your Mission_Control path

# Check if function exists
Get-Command Use-Agent

# Reload profile
. $PROFILE

# Check execution policy if scripts won't run
Get-ExecutionPolicy
Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope CurrentUser
```
