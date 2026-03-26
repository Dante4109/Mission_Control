# GitHub Copilot Agent Operations

This folder serves as the master control center for running GitHub Copilot agents against any folder or project in the workspace.

## Structure

- **config/** - Agent configuration files and workspace mappings
- **prompts/** - Agent instruction prompts for common tasks
- **templates/** - Output templates that agents should use for formatting results
- **scripts/** - Helper scripts for running agents and managing operations
- **outputs/** - Agent execution results and logs

## Quick Start

1. Select a target folder/project from the workspace
2. Choose or create an appropriate agent prompt in `prompts/`
3. (Optional) Choose an output template in `templates/`
4. Run the agent using the helper scripts in `scripts/`
5. Results and logs will be saved to `outputs/`

## Usage

### Run Agent Against Target Folder

```powershell
.\scripts\run-agent.ps1 -TargetPath <path> -AgentType <type> [-Prompt <prompt-file>] [-OutputTemplate <template-file>] [-Config <config-file>]
```

**Parameters:**

- `TargetPath`: Full path to the target folder to analyze/process
- `AgentType`: Type of agent (explore, task, code-review, general-purpose)
- `Prompt`: Instruction prompt file from `prompts/` folder (optional)
- `OutputTemplate`: Output template file from `templates/` folder (optional)
- `Config`: Configuration file from `config/` folder (optional)

### Examples

```powershell
# Explore a specific folder
.\scripts\run-agent.ps1 -TargetPath "C:\projects\AppDev\MyProject" -AgentType "explore"

# Run code review with prompt and output template
.\scripts\run-agent.ps1 -TargetPath "." -AgentType "code-review" -Prompt "code-review-prompt.md" -OutputTemplate "json-output"

# Execute task with custom config
.\scripts\run-agent.ps1 -TargetPath "." -AgentType "task" -Config "default-config.json"
```

## Configuration

Place workspace/project-specific agent configurations in `config/`. Each config can define:

- Default agent type for a target folder
- Prompts to use from `prompts/` folder
- Output templates to use from `templates/` folder
- Tool restrictions or settings
- Logging preferences

See `config/default-config.json` for reference.

## Agent Types

- **explore**: Analyze code, answer questions, understand patterns
- **task**: Execute commands (tests, builds, lints)
- **code-review**: Review code changes for quality/bugs
- **general-purpose**: Complex multi-step operations

## Outputs

All agent results are saved to `outputs/` with timestamps for traceability:

```
outputs/
├── explore/
├── task/
├── code-review/
└── general-purpose/
```

## Notes

- Always verify the target folder path is correct before running an agent
- Configuration files support variable substitution (e.g., `${WORKSPACE_ROOT}`)
- Check `outputs/` folder for logs if an agent operation fails
