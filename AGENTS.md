# Mission_Control - Available Agents

Custom agents available for this project, sourced from the Mission Control master workspace.

## Quick Start

To use agents in this project:

\\\
/agent
\\\

Then select from the available agents, or directly reference:

\\\
/agent github-issue-creator
Create a GitHub issue for: "Your user story here"
\\\

## GitHub Issue Creator

**Path:** \Mission_Control\.github\agents\github-issue-creator.agent.md\

Transform user stories into BDD-formatted GitHub issues with auto-generated test scenarios.

**Trigger Phrases:**
- "create a GitHub issue"
- "generate an issue from this story"
- "create an issue for this user story"
- "turn this into a GitHub issue"
- "make a GitHub issue"

**Use When:**
- Creating well-structured GitHub issues with BDD methodology
- You have a user story needing Given/When/Then scenarios
- You want automatic acceptance criteria generation
- You need consistent ticket numbering (M-XXXX format)

**Example:**
\\\
/agent github-issue-creator
Create a GitHub issue for: "Users should be able to reset their password via email"
\\\

## Mission Control Agents

All agents from the Mission Control master folder are available for use. To browse and select:

\\\
/agent
\\\

## Using Agents from Mission Control

### Method 1: /agent Slash Command
\\\
/agent
\\\
Select from the list of available agents.

### Method 2: PowerShell Helper (Claude Code — default)
\\\powershell
Use-Agent -Type explore -Prompt "Your prompt here"
Use-Agent -Type code-review -PromptFile code-review-prompt.md
\\\

### Method 2b: PowerShell Helper (Copilot)
\\\powershell
Use-Agent -Type explore -Prompt "Your prompt here" -Provider Copilot
\\\

### Method 3: Run Agent Script Directly
\\\powershell
# Claude Code (default)
& "C:\projects\AppDev\Mission_Control\.github\scripts\run-agent.ps1" \
    -TargetPath "C:\projects\AppDev\Mission_Control" \
    -AgentType explore \
    -CustomPrompt "Your prompt"

# GitHub Copilot
& "C:\projects\AppDev\Mission_Control\.github\scripts\run-agent.ps1" \
    -TargetPath "C:\projects\AppDev\Mission_Control" \
    -AgentType explore \
    -CustomPrompt "Your prompt" \
    -Provider Copilot
\\\

## For More Information

- **Mission Control Setup:** C:\projects\AppDev\Mission_Control\SETUP.md
- **Quick Reference:** C:\projects\AppDev\Mission_Control\QUICK_REFERENCE.md
- **Mission Control README:** C:\projects\AppDev\Mission_Control\README.md
