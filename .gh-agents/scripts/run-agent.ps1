#!/usr/bin/env pwsh
<#
.SYNOPSIS
    Run a GitHub Copilot agent against a target folder

.DESCRIPTION
    Execute an agent operation (explore, task, code-review, general-purpose) 
    against any folder in the workspace with optional configuration.

.PARAMETER TargetPath
    Full or relative path to the target folder to analyze/process

.PARAMETER AgentType
    Type of agent: explore, task, code-review, or general-purpose

.PARAMETER Config
    Configuration file from config/ folder (optional)

.PARAMETER Prompt
    Prompt file from prompts/ folder (optional)

.PARAMETER OutputTemplate
    Output template file from templates/ folder (optional)

.PARAMETER CustomPrompt
    Custom instruction/prompt for the agent (optional)

.EXAMPLE
    .\run-agent.ps1 -TargetPath "C:\projects\MyProject" -AgentType explore
    
.EXAMPLE
    .\run-agent.ps1 -TargetPath "." -AgentType code-review -Prompt code-review-prompt.md -OutputTemplate json-output
#>

param(
    [Parameter(Mandatory=$true)]
    [string]$TargetPath,
    
    [Parameter(Mandatory=$true)]
    [ValidateSet('explore', 'task', 'code-review', 'general-purpose')]
    [string]$AgentType,
    
    [Parameter(Mandatory=$false)]
    [string]$Config,
    
    [Parameter(Mandatory=$false)]
    [string]$Prompt,
    
    [Parameter(Mandatory=$false)]
    [string]$OutputTemplate,
    
    [Parameter(Mandatory=$false)]
    [string]$CustomPrompt
)

$ErrorActionPreference = "Stop"

# Resolve paths
$ResolvedTargetPath = Resolve-Path $TargetPath -ErrorAction Stop
$ScriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$AgentDir = Split-Path -Parent $ScriptDir
$ConfigDir = Join-Path $AgentDir "config"
$PromptDir = Join-Path $AgentDir "prompts"
$TemplateDir = Join-Path $AgentDir "templates"
$OutputDir = Join-Path $AgentDir "outputs" $AgentType
$Timestamp = Get-Date -Format "yyyyMMdd_HHmmss"

# Create output directory
if (-not (Test-Path $OutputDir)) {
    New-Item -ItemType Directory -Path $OutputDir -Force | Out-Null
}

# Load configuration if provided
$ConfigData = $null
if ($Config) {
    $ConfigPath = Join-Path $ConfigDir $Config
    if (Test-Path $ConfigPath) {
        $ConfigData = Get-Content $ConfigPath -Raw | ConvertFrom-Json
        Write-Host "✓ Loaded configuration: $Config"
    } else {
        Write-Warning "Configuration not found: $ConfigPath"
    }
}

# Load prompt if provided
$PromptContent = $null
if ($Prompt) {
    $PromptPath = Join-Path $PromptDir $Prompt
    if (Test-Path $PromptPath) {
        $PromptContent = Get-Content $PromptPath -Raw
        Write-Host "✓ Loaded prompt: $Prompt"
    } else {
        Write-Warning "Prompt not found: $PromptPath"
    }
}

# Load output template if provided
$TemplateContent = $null
if ($OutputTemplate) {
    $TemplatePath = Join-Path $TemplateDir $OutputTemplate
    if (Test-Path $TemplatePath) {
        $TemplateContent = Get-Content $TemplatePath -Raw
        Write-Host "✓ Loaded output template: $OutputTemplate"
    } else {
        Write-Warning "Output template not found: $TemplatePath"
    }
}

# Prepare execution context
$ExecutionContext = @{
    TargetPath = $ResolvedTargetPath.Path
    AgentType = $AgentType
    Timestamp = $Timestamp
    Config = $ConfigData
    Prompt = $PromptContent
    OutputTemplate = $TemplateContent
    CustomPrompt = $CustomPrompt
}

# Log execution start
$LogFile = Join-Path $OutputDir "${AgentType}_${Timestamp}.log"
$ExecutionSummary = @{
    AgentType = $AgentType
    TargetPath = $ResolvedTargetPath.Path
    StartTime = Get-Date -Format "o"
    Config = if ($Config) { $Config } else { "none" }
    Prompt = if ($Prompt) { $Prompt } else { "none" }
    OutputTemplate = if ($OutputTemplate) { $OutputTemplate } else { "none" }
} | ConvertTo-Json

$ExecutionSummary | Add-Content $LogFile

Write-Host ""
Write-Host "═══════════════════════════════════════════════════════════"
Write-Host "GitHub Copilot Agent Operation"
Write-Host "═══════════════════════════════════════════════════════════"
Write-Host "Agent Type:       $AgentType"
Write-Host "Target Path:      $($ResolvedTargetPath.Path)"
Write-Host "Timestamp:        $Timestamp"
Write-Host "Prompt:           $(if ($Prompt) { $Prompt } else { 'none' })"
Write-Host "Output Template:  $(if ($OutputTemplate) { $OutputTemplate } else { 'none' })"
Write-Host "Log File:         $LogFile"
Write-Host "═══════════════════════════════════════════════════════════"
Write-Host ""

# TODO: Integration with actual Copilot API
Write-Host "⚠ Note: This script is a template for agent execution."
Write-Host "   To use with actual Copilot agents, integrate with your Copilot CLI setup."
Write-Host ""
Write-Host "Next Steps:"
Write-Host "  1. Create prompts in: $PromptDir"
Write-Host "  2. Define output templates in: $TemplateDir"
Write-Host "  3. Configure settings in: $ConfigDir"
Write-Host "  4. Results will be saved to: $OutputDir"
Write-Host ""
