# Mission Control

Master workspace for managing shared AI agents, prompts, and scripts across multiple projects. Supports both Claude Code and GitHub Copilot as agent providers.

## What This Repo Is

Mission Control is the single source of truth for agent definitions. Other repos link to it via `LinkMC`, which creates directory junctions so they inherit all agents automatically.

## Directory Structure

```
.github/agents/        ← Canonical agent definitions (*.agent.md) — edit these
.github/prompts/       ← Reusable prompt files for agents
.github/config/        ← Workspace configuration
.github/scripts/       ← Helper scripts (run-agent.ps1, link-mission-control.ps1, Sync-Agents.ps1)
.claude/agents/        ← Auto-generated Claude Code agents (do not edit directly — run Sync-Agents.ps1)
```

## Available Agents

### github-issue-creator
Transform user stories into BDD-formatted GitHub issues.

**Trigger phrases:**
- "create a GitHub issue"
- "generate an issue from this story"
- "turn this into a GitHub issue"
- "make a GitHub issue for"

## Agent Workflow (Adding or Updating an Agent)

1. Edit or create `*.agent.md` in `.github/agents/` — this is the canonical source
2. Run `Sync-Agents.ps1` to generate the Claude Code version in `.claude/agents/`
3. Commit both files

```powershell
# After editing .github/agents/my-agent.agent.md:
.\.github\scripts\Sync-Agents.ps1 -Force
```

## Running Agents

### Claude Code (default)
```powershell
Use-Agent -Type explore -Prompt "Your prompt here"
Use-Agent -Type code-review -PromptFile code-review-prompt.md
```

### GitHub Copilot
```powershell
Use-Agent -Type explore -Prompt "Your prompt here" -Provider Copilot
```

Or via Copilot CLI:
```
/agent github-issue-creator
```

## Linking to Other Repos

```powershell
# From any repo root — sets up both Claude Code and Copilot agent access
LinkMC

# Force overwrite existing links
LinkMC -Force
```

## Key Scripts

| Script | Purpose |
|---|---|
| `Sync-Agents.ps1` | Convert `.agent.md` → `.claude/agents/*.md` |
| `run-agent.ps1` | Run an agent against a target path (`-Provider ClaudeCode` or `Copilot`) |
| `link-mission-control.ps1` | Link agents to another repo (creates junctions + AGENTS.md + CLAUDE.md) |
