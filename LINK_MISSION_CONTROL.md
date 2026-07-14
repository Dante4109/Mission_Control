# LinkMC - Link Mission Control to Any Repository

The `LinkMC` command automatically configures any repository to use Mission Control agents with the Copilot CLI's `/agent` slash command.

## Quick Start

From **any repository root**:

```powershell
LinkMC
```

That's it! Your repository is now linked to Mission Control.

## What LinkMC Does

When you run `LinkMC`, it automatically:

1. **Creates `.github/agents/` directory** - Standard location for Copilot agent definitions
2. **Creates symbolic link** to Mission Control agents at `.github/agents/mission-control/`
3. **Generates local agent definitions** - Makes agents discoverable by Copilot CLI
4. **Creates `AGENTS.md`** - Documentation for available agents in your project

All in one command!

## Usage Examples

### Basic Usage

From your repository root:

```powershell
cd C:\projects\MyProject
LinkMC
```

### Specify a Different Repository

```powershell
LinkMC -TargetRepo "C:\projects\AnotherProject"
```

### Overwrite Existing Setup

```powershell
LinkMC -Force
```

This re-creates all files and symlinks, useful if you want to reset or update.

### Use the Full Function Name

```powershell
Link-MissionControl
```

Both `LinkMC` and `Link-MissionControl` work identically.

## After Linking

### Use `/agent` in Copilot CLI

```
/agent
```

Browse available agents or directly reference one:

```
/agent github-issue-creator
Create a GitHub issue for: "Users should be able to reset their password"
```

### Use PowerShell Helpers

```powershell
Use-Agent -Type explore -Prompt "Find all API endpoints"
Use-Agent -Type code-review -PromptFile code-review-prompt.md
```

### View Available Resources

```powershell
Show-MissionControlResources
```

Lists all prompts, templates, configurations, and agents in Mission Control.

## Files Created by LinkMC

After running `LinkMC`, your repository will have:

```
your-repo/
├── .github/
│   └── agents/
│       ├── mission-control → symlink to Mission_Control/.github/agents
│       └── github-issue-creator.agent.md (local copy)
├── AGENTS.md (documentation)
└── ... (rest of your project)
```

### `.github/agents/mission-control/`

Symbolic link to Mission Control's agent directory. This keeps your repository lightweight while giving you access to all agents, prompts, and templates.

### `.github/agents/github-issue-creator.agent.md`

Local agent definition file that Copilot CLI uses to discover and enable the `github-issue-creator` agent. This file is customized with your repository name and abbreviation.

### `AGENTS.md`

Documentation of available agents for your project, with usage examples and links to Mission Control resources.

## Linking Multiple Repositories

The beauty of LinkMC is that you can link multiple repositories to a single Mission Control instance:

```powershell
# Project A
cd C:\projects\ProjectA
LinkMC

# Project B
cd C:\projects\ProjectB
LinkMC

# Project C
cd C:\projects\ProjectC
LinkMC -Force  # Update if needed
```

All projects now share:
- ✅ Same agents (github-issue-creator, etc.)
- ✅ Same prompts and templates
- ✅ Same configurations
- ✅ Updated centrally in Mission Control

## Troubleshooting

### LinkMC not found

Make sure Mission Control module is loaded:

```powershell
$MissionControlModule = "C:\projects\AppDev\Mission_Control\mission-control.psm1"
if (Test-Path $MissionControlModule) {
    Import-Module $MissionControlModule -Force
}
```

Add this to your PowerShell profile to load it automatically. See `SETUP.md` for details.

### Symlink already exists

Use `-Force` to overwrite:

```powershell
LinkMC -Force
```

### Permission denied on symlink creation

Symlinks typically require admin privileges on Windows. Try:

1. Run PowerShell as Administrator
2. Or check your Windows developer mode settings

### Agent not appearing in `/agent`

Make sure you're in the repository directory and have reloaded Copilot:

```
/restart
/agent
```

## Advanced Options

### Custom Repository

```powershell
# Link a repo from a different location
LinkMC -TargetRepo "C:\Users\YourName\Desktop\my-project"
```

### Reset Everything

```powershell
LinkMC -Force
```

This re-creates all files and symlinks, which is useful if you've manually modified something and want a fresh start.

## Best Practices

1. **Link early** - Add LinkMC to your repository setup process
2. **Commit the changes** - Stage and commit the files LinkMC creates:
   ```powershell
   git add .
   git commit -m 'Link Mission Control agents'
   ```
3. **Share with team** - Commit `.github/agents/github-issue-creator.agent.md` and `AGENTS.md` so teammates get agent support automatically
4. **Symlinks are safe** - The `.github/agents/mission-control` symlink is just a pointer; remove it without affecting Mission Control

## See Also

- **SETUP.md** - How to set up the Mission Control module
- **QUICK_REFERENCE.md** - Quick command reference
- **README.md** - Full Mission Control documentation
