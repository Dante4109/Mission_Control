# Agent Prompts

This folder contains instruction prompts for common agent tasks. Prompts define what agents should do and how they should approach the work.

## Available Prompts

### code-review-prompt.md
Instructions for code review operations. Defines review focus, severity levels, and analysis approach.

### exploration-prompt.md
Instructions for exploring and understanding codebases. Defines what to analyze and how to structure findings.

### task-prompt.md
Instructions for task execution (builds, tests, deploys). Defines success criteria, error handling, and reporting.

## Creating Custom Prompts

1. Copy an existing prompt
2. Modify the instructions for your use case
3. Reference it in your configuration file
4. Reference it when calling agents

## Variables

Prompts support these variables (substituted at runtime):

- `${TARGET_PATH}` - Full path to target folder
- `${WORKSPACE_ROOT}` - Root of the workspace
- `${AGENT_TYPE}` - Type of agent being used
- `${TIMESTAMP}` - Current timestamp
- `${PROJECT_NAME}` - Inferred project name from target path

## Usage

When running an agent, specify the prompt:

```powershell
.\scripts\run-agent.ps1 -TargetPath . -AgentType explore -Prompt code-review-prompt.md
```
