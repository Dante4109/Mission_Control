# Mission Control

Master workspace and command center for managing multiple projects in daily development workflow.

## Overview

**Mission Control** serves as the central hub for coordinating development across multiple projects in your workspace. It provides:

- **Unified agent orchestration** - Run Claude Code or GitHub Copilot agents against any project
- **Centralized configuration** - Manage settings, prompts, and templates in one place
- **Automation framework** - Pre-built scripts and templates for common development tasks
- **Issue tracking** - BDD-based issue creation with auto-generated acceptance criteria
- **Workflow documentation** - Guides and standards for the entire team

## Directory Structure

### `.github/agents/`

Canonical agent definitions (`*.agent.md`) — the single source of truth. Edit these to update agents for both providers.

- **github-issue-creator** - Transform user stories into BDD-formatted GitHub issues with auto-generated test scenarios

### `.claude/agents/`

Auto-generated Claude Code agent files. Do not edit directly — run `Sync-Agents.ps1` after modifying `.github/agents/`.

### `.github/config/`

Workspace configuration files:

- Default settings for agent operations
- Workspace mappings for multi-project coordination

### `.github/prompts/`

Agent instruction prompts:

- Code review guidelines
- Codebase exploration templates
- Task execution patterns

### `.github/templates/`

Output formatting templates for agent results:

- Issue preview formatting
- Report generation structures
- Output standardization

### `.github/scripts/`

Helper scripts for agent execution and workspace management:

- `run-agent.ps1` - Execute agents with configuration and prompts
- Additional automation utilities

### `.github/outputs/`

Agent execution logs and results (organized by agent type):

- Timestamped results for audit trails
- Debugging information and logs

## Quick Start

### Run an Agent Against a Project

```powershell
# Claude Code (default)
.\.github\scripts\run-agent.ps1 -TargetPath "C:\projects\AppDev\MyProject" -AgentType explore

# GitHub Copilot
.\.github\scripts\run-agent.ps1 -TargetPath "C:\projects\AppDev\MyProject" -AgentType explore -Provider Copilot
```

### Sync Agents After Editing

After adding or modifying a `*.agent.md` file, regenerate the Claude Code format:

```powershell
.\.github\scripts\Sync-Agents.ps1 -Force
```

### Link Mission Control to a Repository

From **any repository root**, link it to Mission Control to enable `/agent` slash commands:

```powershell
LinkMC
```

Or use the full name:
```powershell
Link-MissionControl
```

Options:
```powershell
Link-MissionControl -TargetRepo "C:\projects\MyProject"    # Specific repo
Link-MissionControl -Force                                  # Overwrite existing links
```

This will:
- ✅ Create `.github/agents/` + junction → Mission Control (Copilot)
- ✅ Create `.claude/agents/` + junction → Mission Control (Claude Code)
- ✅ Generate `AGENTS.md` (Copilot docs) + `CLAUDE.md` (Claude Code docs)

### Create a GitHub Issue from Requirements

Use the `github-issue-creator` agent to transform requirements into BDD-formatted issues:

- Automatically generates acceptance criteria (Given/When/Then scenarios)
- Creates meaningful ticket numbers (REPO-XXXX format)
- Previews issues before creation with WhatIf mode

### Customize Agent Behavior

1. Create prompts in `.github/prompts/` for specific instructions
2. Define output formats in `.github/templates/`
3. Configure defaults in `.github/config/`

## Use Cases

### Multi-Project Development

- Coordinate work across multiple projects in your workspace
- Run analyses, tests, and reviews from a single control point
- Maintain consistent standards across all projects

### Automated Issue Management

- Generate well-structured GitHub issues with BDD methodology
- Auto-generate test scenarios from feature descriptions
- Ensure acceptance criteria are measurable and testable

### Code Quality

- Run code reviews with consistent guidelines
- Explore unfamiliar codebases efficiently
- Generate architecture documentation

### Workflow Automation

- Execute builds, tests, and lints across projects
- Standardize development processes
- Reduce manual task execution

## Configuration

### Adding a New Project

1. Reference it in `.github/config/default-config.json` workspace mappings
2. Create project-specific configuration if needed
3. Run agents targeting that project

### Custom Prompts and Templates

Templates are organized by purpose:

- **Prompts** (`prompts/`) - Tell agents what to do and how to think
- **Templates** (`templates/`) - Define how agents should format output

Create new files in these directories and reference them when running agents.

## Agent Providers

Mission Control supports both Claude Code and GitHub Copilot:

| Agent type | Best for |
|---|---|
| `explore` | Understand codebases, analyze patterns, answer questions |
| `task` | Execute commands (builds, tests, lints, deployments) |
| `code-review` | Review code for quality, security, and best practices |
| `general-purpose` | Complex multi-step development operations |

```powershell
# Claude Code (default)
Use-Agent -Type explore -Prompt "Your prompt"

# GitHub Copilot
Use-Agent -Type explore -Prompt "Your prompt" -Provider Copilot
```

See `.github/agents/` for canonical agent definitions and `.claude/agents/` for the generated Claude Code versions.

## Linking Mission Control to Repositories

The `LinkMC` command automatically configures any repository to use Mission Control agents.

### From Any Repository Root

```powershell
LinkMC
```

### What LinkMC Does

1. **Creates `.github/agents/` directory** - Standard location for agent definitions
2. **Creates symbolic link** to Mission Control agents (`.github/agents/mission-control`)
3. **Generates local agent definitions** for Copilot CLI discovery via `/agent`
4. **Creates `AGENTS.md`** - Documentation of available agents

### After Linking

**Claude Code (default):**
```powershell
Use-Agent -Type explore -Prompt "Your prompt"
```

Or just describe what you want to Claude Code and it will select the right agent.

**GitHub Copilot:**
```
/agent github-issue-creator
Create a GitHub issue for: "Your user story"
```

### LinkMC Options

```powershell
# Link specific repository
LinkMC -TargetRepo "C:\projects\MyProject"

# Overwrite existing links
LinkMC -Force

# Use full function name
Link-MissionControl
```

### Multiple Repositories

Link Mission Control to multiple projects—they'll all share the same agents, prompts, and configurations:

```powershell
cd C:\projects\ProjectA
LinkMC

cd C:\projects\ProjectB
LinkMC

cd C:\projects\ProjectC
LinkMC -Force  # Re-link if needed
```

Now all projects can use `/agent` and `Use-Agent` commands!

## Issue Creation Workflow

The `github-issue-creator` agent handles:

1. **Input** - Accepts user stories (text or markdown)
2. **Generation** - Auto-creates BDD scenarios if missing
3. **Validation** - Ensures all acceptance criteria are measurable
4. **Creation** - Creates GitHub issues with ticket numbers (MC-0001, etc.)

Example output:

```
MC-0001 Dockerize the project

As a DevOps engineer
I want to containerize the application
So that it can run consistently across environments

Acceptance Criteria:
- Given the application code is ready
  When I build a Docker image
  Then the image should start successfully and pass health checks
```

## Best Practices

- ✅ Use `LinkMC` to link all your repositories to Mission Control
- ✅ Use `WhatIf` mode to preview agent actions before execution
- ✅ Customize prompts for your specific workflow needs
- ✅ Review agent outputs before committing changes
- ✅ Keep templates organized by project type
- ✅ Document custom configurations for team reference

## Documentation

For detailed information, see:

- **[LINK_MISSION_CONTROL.md](./LINK_MISSION_CONTROL.md)** - Complete LinkMC guide and reference
- **[SETUP.md](./SETUP.md)** - PowerShell profile setup
- **[QUICK_REFERENCE.md](./QUICK_REFERENCE.md)** - Quick command cheat sheet

## Contributing

When adding new features:

1. Update `.github/` configurations appropriately
2. Document new prompts or templates
3. Add scripts to `scripts/` for reusable operations
4. Keep agent instructions focused and testable

## Support

For issues with:

- **Agents** - Check `.github/agents/` instructions
- **Configuration** - See `.github/config/`
- **Workflows** - Review `.github/README.md`
- **Output formats** - Examine `.github/templates/`
