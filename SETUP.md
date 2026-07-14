# Mission Control - PowerShell Profile Setup

This module enables you to use agents from Mission_Control in any project directory without changing directories.

## Installation

### Step 1: Add to PowerShell Profile

Open your PowerShell profile:
```powershell
notepad $PROFILE
```

Add these lines at the end:
```powershell
# Mission Control Workspace
$MissionControlModule = "C:\projects\AppDev\Mission_Control\mission-control.psm1"
if (Test-Path $MissionControlModule) {
    Import-Module $MissionControlModule -Force
}
```

### Step 2: Save and Reload

1. Save the profile file
2. Close PowerShell and reopen it (or run: `. $PROFILE`)

## Usage

### Run an Agent

From any project directory:

```powershell
# Explore code with a custom prompt
Use-Agent -Type explore -Prompt "Find all API endpoints and list them"

# Review code with a standard prompt
Use-Agent -Type code-review -PromptFile code-review-prompt.md

# Run a task with configuration
Use-Agent -Type task -CustomPrompt "Run tests" -Config default-config.json

# General-purpose agent for complex tasks
Use-Agent -Type general-purpose -Prompt "Analyze this project's architecture"
```

### View Available Resources

```powershell
Show-MissionControlResources
```

This lists all available:
- Prompts (in `.github/prompts/`)
- Templates (in `.github/templates/`)
- Configurations (in `.github/config/`)
- Agents (in `.github/agents/`)

## How It Works

1. **Environment Variable**: Sets `$env:MISSION_CONTROL_ROOT` to your central agents folder
2. **Working Directory Context**: Runs agents from your current directory while maintaining full file context
3. **Centralized Resources**: All prompts, templates, and configurations live in one place
4. **Multi-Project Support**: Use the same agents and prompts across all your projects

## Examples

### From VDRF_Template Directory
```powershell
cd C:\projects\AppDev\VDRF_Template
Use-Agent -Type explore -Prompt "What Vue components exist and what do they do?"
```

### From Another Project
```powershell
cd C:\projects\AppDev\AnotherProject
Use-Agent -Type code-review -PromptFile code-review-prompt.md
```

### Without Changing Directories
```powershell
# Run agent against VDRF_Template from any location
Push-Location C:\projects\AppDev\VDRF_Template
Use-Agent -Type explore -Prompt "Analyze the authentication flow"
Pop-Location
```

## Customization

### Create Custom Prompts

Add new files to `Mission_Control\.github\prompts\`:
```
custom-prompt.md
```

Then use them:
```powershell
Use-Agent -Type explore -PromptFile custom-prompt.md
```

### Create Custom Templates

Add new files to `Mission_Control\.github\templates\`:
```
custom-output.template
```

### Create Custom Configurations

Add new JSON files to `Mission_Control\.github\config\`:
```json
{
  "setting": "value"
}
```

Then reference them:
```powershell
Use-Agent -Type task -Config custom-config.json
```

## Troubleshooting

**"Mission Control not found"**
- Verify `$env:MISSION_CONTROL_ROOT` points to the correct folder
- Check that the path in your profile matches the actual Mission_Control location

**Agent not executing**
- Verify `run-agent.ps1` exists at `Mission_Control\.github\scripts\run-agent.ps1`
- Check PowerShell execution policy: `Get-ExecutionPolicy`
- If needed, set it: `Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope CurrentUser`

**Can't see the functions**
- Reload your profile: `. $PROFILE`
- Or restart PowerShell

## Environment Variables

Once loaded, the module sets:

| Variable | Value |
|----------|-------|
| `$env:MISSION_CONTROL_ROOT` | Path to Mission_Control folder |

Add to `$env:PATH`:
| Path |
|------|
| `$MISSION_CONTROL_ROOT\.github\scripts` |

This enables direct access to helper scripts from anywhere.
