# Agent Operations Scripts

This folder contains helper scripts for running and managing agent operations.

## Available Scripts

### run-agent.ps1
Main script for executing agents against target folders. Supports Claude Code (default) and GitHub Copilot.

**Usage:**
```powershell
.\run-agent.ps1 -TargetPath <path> -AgentType <type> [-Provider ClaudeCode|Copilot] [-Config <file>] [-Template <file>]
```

**Examples:**
```powershell
# Claude Code (default)
.\run-agent.ps1 -TargetPath "." -AgentType explore -CustomPrompt "List all API endpoints"

# GitHub Copilot
.\run-agent.ps1 -TargetPath "." -AgentType explore -CustomPrompt "List all API endpoints" -Provider Copilot
```

### Sync-Agents.ps1
Converts canonical `*.agent.md` files from `.github/agents/` to Claude Code format in `.claude/agents/`.
Run this any time you add or modify an agent.

**Usage:**
```powershell
.\Sync-Agents.ps1           # skip existing files
.\Sync-Agents.ps1 -Force    # overwrite all
```

### link-mission-control.ps1
Link Mission Control agents to another repository. Sets up both Claude Code (`.claude/agents/`) and Copilot (`.github/agents/`) junctions, and generates `AGENTS.md` + `CLAUDE.md`.

**Usage:**
```powershell
.\link-mission-control.ps1 [-TargetRepo <path>] [-Force]
```

### view-results.ps1
View and filter agent execution results from the outputs folder.

**Usage:**
```powershell
.\view-results.ps1 -AgentType <type> [-Latest] [-Count <n>]
```

### cleanup.ps1
Archive and clean up old outputs to keep the folder organized.

**Usage:**
```powershell
.\cleanup.ps1 [-ArchiveName <name>] [-DaysOld <n>]
```

## Script Guidelines

- All scripts use consistent parameter naming
- Scripts provide clear status/error messages
- Outputs are timestamped for traceability
- Scripts validate inputs before execution
- **Prompts** from `prompts/` folder define agent instructions
- **Templates** from `templates/` folder define output formatting
