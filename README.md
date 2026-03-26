# Mission Control

Master workspace and command center for managing multiple projects in daily development workflow.

## Overview

**Mission Control** serves as the central hub for coordinating development across multiple projects in your workspace. It provides:

- **Unified agent orchestration** - Run GitHub Copilot agents against any project
- **Centralized configuration** - Manage settings, prompts, and templates in one place
- **Automation framework** - Pre-built scripts and templates for common development tasks
- **Issue tracking** - BDD-based issue creation with auto-generated acceptance criteria
- **Workflow documentation** - Guides and standards for the entire team

## Directory Structure

### `.github/agents/`

Custom GitHub Copilot agents for specialized tasks:

- **github-issue-creator** - Transform user stories into BDD-formatted GitHub issues with auto-generated test scenarios

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
# From Mission_Control directory
.\.github\scripts\run-agent.ps1 -TargetPath "C:\projects\AppDev\MyProject" -AgentType explore
```

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

## GitHub Copilot Integration

Mission Control is optimized for GitHub Copilot agent operations:

- **explore** - Understand codebases, analyze patterns, answer questions
- **task** - Execute commands (builds, tests, lints, deployments)
- **code-review** - Review code for quality, security, and best practices
- **general-purpose** - Complex multi-step development operations

See `.github/agents/` for specialized agent configurations.

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

- ✅ Use `WhatIf` mode to preview agent actions before execution
- ✅ Customize prompts for your specific workflow needs
- ✅ Review agent outputs before committing changes
- ✅ Keep templates organized by project type
- ✅ Document custom configurations for team reference

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
