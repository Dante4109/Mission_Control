#!/usr/bin/env pwsh
<#
.SYNOPSIS
    Run an AI agent against a target folder (Claude Code or GitHub Copilot)

.DESCRIPTION
    Execute an agent operation (explore, task, code-review, general-purpose)
    against any folder in the workspace with optional configuration.
    Defaults to Claude Code; pass -Provider Copilot to use GitHub Copilot.

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

.PARAMETER Provider
    AI provider to use: ClaudeCode (default) or Copilot

.EXAMPLE
    .\run-agent.ps1 -TargetPath "C:\projects\MyProject" -AgentType explore

.EXAMPLE
    .\run-agent.ps1 -TargetPath "." -AgentType code-review -Prompt code-review-prompt.md -OutputTemplate json-output

.EXAMPLE
    .\run-agent.ps1 -TargetPath "." -AgentType explore -CustomPrompt "List all API endpoints" -Provider Copilot
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
    [string]$CustomPrompt,

    [Parameter(Mandatory=$false)]
    [ValidateSet('ClaudeCode', 'Copilot')]
    [string]$Provider = 'ClaudeCode'
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
Write-Host "Agent Operation  [$Provider]"
Write-Host "═══════════════════════════════════════════════════════════"
Write-Host "Agent Type:       $AgentType"
Write-Host "Target Path:      $($ResolvedTargetPath.Path)"
Write-Host "Timestamp:        $Timestamp"
Write-Host "Prompt:           $(if ($Prompt) { $Prompt } else { 'none' })"
Write-Host "Output Template:  $(if ($OutputTemplate) { $OutputTemplate } else { 'none' })"
Write-Host "Log File:         $LogFile"
Write-Host "═══════════════════════════════════════════════════════════"
Write-Host ""

$FullPrompt = if ($CustomPrompt) { $CustomPrompt } elseif ($PromptContent) { $PromptContent } else { "Analyze: $($ResolvedTargetPath.Path)" }

switch ($Provider) {
    'ClaudeCode' {
        $ClaudeAgentType = switch ($AgentType) {
            'explore'          { 'Explore' }
            'task'             { 'general-purpose' }
            'code-review'      { 'general-purpose' }
            'general-purpose'  { 'general-purpose' }
        }
        Write-Host "Running Claude Code agent ($ClaudeAgentType)..."
        Write-Host ""
        claude --agent-type $ClaudeAgentType --print $FullPrompt 2>&1 | Tee-Object -FilePath $LogFile
    }
    'Copilot' {
        Write-Host "Running Copilot agent ($AgentType)..."
        Write-Host "⚠ Copilot integration: connect to 'gh copilot' CLI here."
        "Prompt: $FullPrompt" | Add-Content $LogFile
    }
}
Write-Host ""
Write-Host "✓ Results saved to: $LogFile"
Write-Host ""
