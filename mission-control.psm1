# Mission Control - Workspace Setup
# Add this to your PowerShell profile to enable agents across all projects

# Set Mission Control root
$env:MISSION_CONTROL_ROOT = "C:\projects\AppDev\Mission_Control"

# Add Mission Control scripts to PATH
$env:PATH = "$env:MISSION_CONTROL_ROOT\.github\scripts;$env:PATH"

# Create helper function for running agents from any directory
function Use-Agent {
    <#
    .SYNOPSIS
        Run AI agents from any project directory (Claude Code or GitHub Copilot)

    .DESCRIPTION
        Execute an agent against the current directory while maintaining full context.
        Defaults to Claude Code; pass -Provider Copilot to use GitHub Copilot.

    .PARAMETER Type
        Agent type: explore, task, code-review, general-purpose

    .PARAMETER Prompt
        Custom instruction/prompt for the agent

    .PARAMETER PromptFile
        Use a prompt file from Mission_Control/prompts/

    .PARAMETER Config
        Configuration from Mission_Control/config/

    .PARAMETER Provider
        AI provider: ClaudeCode (default) or Copilot

    .EXAMPLE
        Use-Agent -Type explore -Prompt "Find all authentication logic"
        Use-Agent -Type code-review -PromptFile code-review-prompt.md
        Use-Agent -Type explore -Prompt "List endpoints" -Provider Copilot
    #>
    
    param(
        [Parameter(Mandatory=$true)]
        [ValidateSet('explore', 'task', 'code-review', 'general-purpose')]
        [string]$Type,

        [Parameter(Mandatory=$false)]
        [string]$Prompt,

        [Parameter(Mandatory=$false)]
        [string]$PromptFile,

        [Parameter(Mandatory=$false)]
        [string]$Config,

        [Parameter(Mandatory=$false)]
        [ValidateSet('ClaudeCode', 'Copilot')]
        [string]$Provider = 'ClaudeCode'
    )
    
    $MissionControl = $env:MISSION_CONTROL_ROOT
    
    if (-not (Test-Path $MissionControl)) {
        Write-Error "Mission Control not found at: $MissionControl"
        return
    }
    
    $RunAgentScript = Join-Path $MissionControl ".github\scripts\run-agent.ps1"
    
    if (-not (Test-Path $RunAgentScript)) {
        Write-Error "run-agent.ps1 not found at Mission Control"
        return
    }
    
    $CurrentDir = Get-Location
    Write-Host ""
    Write-Host "╔════════════════════════════════════════════════════════╗"
    Write-Host "║            Mission Control Agent Execution            ║"
    Write-Host "╚════════════════════════════════════════════════════════╝"
    Write-Host "Working Directory:    $CurrentDir"
    Write-Host "Mission Control Root: $MissionControl"
    Write-Host "Agent Type:           $Type"
    Write-Host "Provider:             $Provider"
    if ($Prompt) { Write-Host "Prompt:               $Prompt" }
    if ($PromptFile) { Write-Host "Prompt File:          $PromptFile" }
    if ($Config) { Write-Host "Config:               $Config" }
    Write-Host ""

    $Arguments = @{
        TargetPath = $CurrentDir.Path
        AgentType  = $Type
        Provider   = $Provider
    }

    if ($PromptFile) { $Arguments['Prompt'] = $PromptFile }
    if ($Prompt) { $Arguments['CustomPrompt'] = $Prompt }
    if ($Config) { $Arguments['Config'] = $Config }

    & $RunAgentScript @Arguments
    
    Write-Host ""
    Write-Host "✓ Agent execution complete"
}

# Create helper function to list available resources
function Show-MissionControlResources {
    <#
    .SYNOPSIS
        List available prompts, templates, and configurations
    #>
    
    $MissionControl = $env:MISSION_CONTROL_ROOT
    
    if (-not (Test-Path $MissionControl)) {
        Write-Error "Mission Control not found"
        return
    }
    
    Write-Host ""
    Write-Host "╔════════════════════════════════════════════════════════╗"
    Write-Host "║          Mission Control Resources                    ║"
    Write-Host "╚════════════════════════════════════════════════════════╝"
    Write-Host ""
    
    Write-Host "📋 PROMPTS:"
    Get-ChildItem (Join-Path $MissionControl ".github\prompts") -Filter "*.md" | % { Write-Host "  • $($_.Name)" }
    
    Write-Host ""
    Write-Host "📑 TEMPLATES:"
    Get-ChildItem (Join-Path $MissionControl ".github\templates") -Filter "*.md" | % { Write-Host "  • $($_.Name)" }
    
    Write-Host ""
    Write-Host "⚙️  CONFIGURATIONS:"
    Get-ChildItem (Join-Path $MissionControl ".github\config") -Filter "*.json" | % { Write-Host "  • $($_.Name)" }
    
    Write-Host ""
    Write-Host "🤖 AGENTS:"
    Get-ChildItem (Join-Path $MissionControl ".github\agents") -Filter "*.md" | % { Write-Host "  • $($_.BaseName)" }
    
    Write-Host ""
}

# Create alias and function for linking Mission Control to any repo
function Link-MissionControl {
    <#
    .SYNOPSIS
        Link Mission Control agents to any repository
    
    .DESCRIPTION
        Automatically creates symbolic links and configuration files in any repository
        to give it access to Mission Control agents via the /agent command.
    
    .PARAMETER TargetRepo
        Path to the target repository (defaults to current directory)
    
    .PARAMETER Force
        Overwrite existing symlinks and configuration files
    
    .EXAMPLE
        # From the repository root
        Link-MissionControl
        
    .EXAMPLE
        # From anywhere, specify target repo
        Link-MissionControl -TargetRepo "C:\projects\MyProject"
        
    .EXAMPLE
        # Overwrite existing links
        Link-MissionControl -Force
    #>
    
    param(
        [Parameter(Mandatory=$false)]
        [string]$TargetRepo = ".",
        
        [Parameter(Mandatory=$false)]
        [switch]$Force
    )
    
    $MissionControl = $env:MISSION_CONTROL_ROOT
    $LinkScript = Join-Path $MissionControl ".github\scripts\link-mission-control.ps1"
    
    if (-not (Test-Path $LinkScript)) {
        Write-Error "link-mission-control.ps1 not found at: $LinkScript"
        return
    }
    
    $Arguments = @{
        TargetRepo = $TargetRepo
    }
    
    if ($Force) { $Arguments['Force'] = $true }
    
    & $LinkScript @Arguments
}

# Create aliases for convenience
Set-Alias -Name LinkMC -Value Link-MissionControl -Scope Global
Set-Alias -Name "link-mission-control" -Value Link-MissionControl -Scope Global

# Export functions
Export-ModuleMember -Function Use-Agent, Show-MissionControlResources, Link-MissionControl
Export-ModuleMember -Alias LinkMC, link-mission-control

Write-Host "✓ Mission Control workspace loaded"
Write-Host "  Use 'Use-Agent -Type explore -Prompt ""your prompt""' to run agents"
Write-Host "  Use 'Show-MissionControlResources' to see available resources"
Write-Host ""
