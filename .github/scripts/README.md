# Agent Operations Scripts

This folder contains helper scripts for running and managing agent operations.

## Available Scripts

### run-agent.ps1
Main script for executing agents against target folders.

**Usage:**
```powershell
.\run-agent.ps1 -TargetPath <path> -AgentType <type> [-Config <file>] [-Template <file>]
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
