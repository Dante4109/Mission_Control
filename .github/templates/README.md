# Output Templates

This folder contains template formats that agents should use when generating output.

These define the structure and style for agent results, ensuring consistency across different agent types and operations.

## Available Templates

- **json-output.md** - Standard JSON structure for agent results
- **markdown-report.md** - Markdown format for human-readable reports
- **structured-findings.md** - Template for organizing findings by severity/category

## Using Templates in Agent Operations

When running an agent, specify an output template:

```powershell
.\scripts\run-agent.ps1 -TargetPath . -AgentType explore -OutputTemplate json-output
```

Agents will format their results according to the specified template for consistent, parseable output.

## Creating Custom Output Templates

1. Create a new template file describing the output structure
2. Include examples of expected output
3. Document any required fields or sections
4. Reference it when running agents

## Integration with Prompts

- **Prompts/** - Define WHAT agents should do and HOW to think
- **Templates/** - Define HOW agents should FORMAT their output
