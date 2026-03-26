# Outputs Directory

Agent execution results are stored here, organized by agent type.

## Structure

```
outputs/
├── explore/          # Results from exploration agents
├── task/            # Results from task execution agents
├── code-review/     # Results from code review agents
└── general-purpose/ # Results from general-purpose agents
```

## File Naming

Files follow this pattern: `{agent-type}_{timestamp}.log`

Example: `explore_20240315_143022.log`

## Cleanup

Use the cleanup script periodically to archive old results:

```powershell
.\scripts\cleanup.ps1 -DaysOld 30
```

This keeps the working directory clean while preserving historical results.
