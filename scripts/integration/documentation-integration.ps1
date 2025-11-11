# Documentation Integration Script
# Links documentation system with change tracking and automated updates

param(
    [Parameter(Mandatory=$false)]
    [ValidateSet("security-scan", "task-completion", "git-changes", "full-update")]
    [string]$UpdateTrigger = "full-update",
    
    [Parameter(Mandatory=$false)]
    [string]$TaskName = "",
    
    [Parameter(Mandatory=$false)]
    [string]$TaskId = "",
    
    [Parameter(Mandatory=$false)]
    [switch]$UpdateChangelog = $true,
    
    [Parameter(Mandatory=$false)]
    [switch]$UpdateSecurityDocs = $true,
    
    [Parameter(Mandatory=$false)]
    [switch]$UpdateTaskDocs = $true,
    
    [Parameter(Mandatory=$false)]
    [switch]$DryRun = $false,
    
    [Parameter(Mandatory=$false)]
    [switch]$Verbose = $false
)

# Script configuration
$script:ScriptPath = Split-Path -Parent $MyInvocation.MyCommand.Path
$script:RootPath = Split-Path -Parent (Split-Path -Parent $script:ScriptPath)

# Function to write colored output
function Write-ColorOutput {
    param(
        [string]$Message,
        [string]$Color = "White"
    )
    
    if ($Verbose) {
        $timestamp = Get-Date -Format "HH:mm:ss"
        $Message = "[$timestamp] $Message"
    }
    
    switch ($Color.ToLower()) {
        "red" { Write-Host $Message -ForegroundColor Red }
        "green" { Write-Host $Message -ForegroundColor Green }
        "yellow" { Write-Host $Message -ForegroundColor Yellow }
        "blue" { Write-Host $Message -ForegroundColor Blue }
        "cyan" { Write-Host $Message -ForegroundColor Cyan }
        default { Write-Host $Message }
    }
}

# Function to get git changes since last documentation update
function Get-GitChangesSinceLastUpdate {
    try {
        # Get the last commit that updated documentation
        $lastDocCommit = git log --oneline --grep="docs:" -n 1 --format="%H" 2>$null
        
        if (-not $lastDocCommit) {
            # If no doc commits found, get changes from last 10 commits
            $lastDocCommit = git rev-parse "HEAD~10" 2>$null
        }
        
        if ($lastDocCommit) {
            $changes = git diff --name-status "$lastDocCommit..HEAD" 2>$null
            return $changes
        } else {
            # Fallback to recent changes
            $changes = git diff --name-status "HEAD~5..HEAD" 2>$null
            return $changes
        }
    }
    catch {
        Write-ColorOutput "Warning: Could not retrieve git changes: $($_.Exception.Message)" "Yellow"
        return @()
    }
}

# Function to analyze changes and categorize them
function Get-ChangeAnalysis {
    param([string[]]$Changes)
    
    $analysis = @{
        "security_changes" = @()
        "terraform_changes" = @()
        "script_changes" = @()
        "config_changes" = @()
        "doc_changes" = @()
        "other_changes" = @()
    }
    
    foreach ($change in $Changes) {
        if (-not $change) { continue }
        
        $parts = $change -split "`t"
        if ($parts.Count -lt 2) { continue }
        
        $status = $parts[0]
        $file = $parts[1]
        
        $changeInfo = @{
            "status" = $status
            "file" = $file
        }
        
        # Categorize changes
        if ($file -match "security/|\.checkov|\.tfsec|terrascan") {
            $analysis.security_changes += $changeInfo
        }
        elseif ($file -match "\.tf$|terraform") {
            $analysis.terraform_changes += $changeInfo
        }
        elseif ($file -match "scripts/|\.ps1$|\.sh$") {
            $analysis.script_changes += $changeInfo
        }
        elseif ($file -match "\.yml$|\.yaml$|\.json$|\.toml$") {
            $analysis.config_changes += $changeInfo
        }
        elseif ($file -match "\.md$|docs/") {
            $analysis.doc_changes += $changeInfo
        }
        else {
            $analysis.other_changes += $changeInfo
        }
    }
    
    return $analysis
}

# Function to update changelog with recent changes
function Update-ChangelogWithChanges {
    param([hashtable]$ChangeAnalysis)
    
    Write-ColorOutput "Updating changelog with recent changes..." "Blue"
    
    $changelogPath = "CHANGELOG.md"
    $timestamp = Get-Date -Format "yyyy-MM-dd"
    
    # Create changelog if it doesn't exist
    if (-not (Test-Path $changelogPath)) {
        $initialContent = @"
# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

"@
        if (-not $DryRun) {
            $initialContent | Out-File -FilePath $changelogPath -Encoding UTF8
        }
        Write-ColorOutput "Created new changelog file" "Green"
    }
    
    # Generate changelog entry
    $changelogEntry = "`n## [$timestamp] - Automated Update`n"
    
    # Add security changes
    if ($ChangeAnalysis.security_changes.Count -gt 0) {
        $changelogEntry += "`n### Security`n"
        foreach ($change in $ChangeAnalysis.security_changes) {
            $action = switch ($change.status) {
                "A" { "Added" }
                "M" { "Modified" }
                "D" { "Removed" }
                default { "Changed" }
            }
            $changelogEntry += "- $action security configuration: $($change.file)`n"
        }
    }
    
    # Add Terraform changes
    if ($ChangeAnalysis.terraform_changes.Count -gt 0) {
        $changelogEntry += "`n### Infrastructure`n"
        foreach ($change in $ChangeAnalysis.terraform_changes) {
            $action = switch ($change.status) {
                "A" { "Added" }
                "M" { "Updated" }
                "D" { "Removed" }
                default { "Changed" }
            }
            $changelogEntry += "- $action Terraform module: $($change.file)`n"
        }
    }
    
    # Add script changes
    if ($ChangeAnalysis.script_changes.Count -gt 0) {
        $changelogEntry += "`n### Automation`n"
        foreach ($change in $ChangeAnalysis.script_changes) {
            $action = switch ($change.status) {
                "A" { "Added" }
                "M" { "Updated" }
                "D" { "Removed" }
                default { "Changed" }
            }
            $changelogEntry += "- $action automation script: $($change.file)`n"
        }
    }
    
    # Add configuration changes
    if ($ChangeAnalysis.config_changes.Count -gt 0) {
        $changelogEntry += "`n### Configuration`n"
        foreach ($change in $ChangeAnalysis.config_changes) {
            $action = switch ($change.status) {
                "A" { "Added" }
                "M" { "Updated" }
                "D" { "Removed" }
                default { "Changed" }
            }
            $changelogEntry += "- $action configuration file: $($change.file)`n"
        }
    }
    
    if (-not $DryRun) {
        # Insert the new entry after the header
        $existingContent = Get-Content $changelogPath -Raw
        $headerEnd = $existingContent.IndexOf("`n`n") + 2
        
        if ($headerEnd -gt 1) {
            $newContent = $existingContent.Substring(0, $headerEnd) + $changelogEntry + $existingContent.Substring($headerEnd)
        } else {
            $newContent = $existingContent + $changelogEntry
        }
        
        $newContent | Out-File -FilePath $changelogPath -Encoding UTF8
        Write-ColorOutput "Changelog updated successfully" "Green"
    } else {
        Write-ColorOutput "[DRY RUN] Would add changelog entry:`n$changelogEntry" "Yellow"
    }
}

# Function to update security documentation
function Update-SecurityDocumentation {
    Write-ColorOutput "Updating security documentation..." "Blue"
    
    $securityDocsPath = "docs/security"
    $securityReadmePath = Join-Path $securityDocsPath "README.md"
    
    # Create security docs directory if it doesn't exist
    if (-not (Test-Path $securityDocsPath)) {
        if (-not $DryRun) {
            New-Item -ItemType Directory -Path $securityDocsPath -Force | Out-Null
        }
        Write-ColorOutput "Created security documentation directory" "Green"
    }
    
    # Check for recent security scan results
    $scanResultsPath = "security/reports/unified-sast-report.json"
    if (Test-Path $scanResultsPath) {
        try {
            $scanResults = Get-Content $scanResultsPath -Raw | ConvertFrom-Json
            $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
            
            $securityUpdate = @"

## Security Scan Update - $timestamp

### Latest Scan Results Summary
- **Total Issues**: $($scanResults.scan_summary.total_issues)
- **Critical Issues**: $($scanResults.scan_summary.critical_issues)
- **High Issues**: $($scanResults.scan_summary.high_issues)
- **Medium Issues**: $($scanResults.scan_summary.medium_issues)
- **Low Issues**: $($scanResults.scan_summary.low_issues)

### Tools Used
"@
            
            foreach ($tool in $scanResults.tool_results.PSObject.Properties.Name) {
                $toolResults = $scanResults.tool_results.$tool
                $toolTotal = $toolResults.Critical + $toolResults.High + $toolResults.Medium + $toolResults.Low + $toolResults.Info
                $securityUpdate += "`n- **$tool**: $toolTotal issues found"
            }
            
            $securityUpdate += "`n`nFor detailed results, see the security/reports/ directory.`n"
            
            if (-not $DryRun) {
                if (Test-Path $securityReadmePath) {
                    Add-Content -Path $securityReadmePath -Value $securityUpdate
                } else {
                    $initialSecurityDoc = @"
# Security Documentation

This document tracks security improvements and scan results for the Terraform Security Enhancement project.

$securityUpdate
"@
                    $initialSecurityDoc | Out-File -FilePath $securityReadmePath -Encoding UTF8
                }
            }
            
            Write-ColorOutput "Security documentation updated with scan results" "Green"
        }
        catch {
            Write-ColorOutput "Warning: Could not parse security scan results: $($_.Exception.Message)" "Yellow"
        }
    }
}

# Function to update task documentation
function Update-TaskDocumentation {
    param([string]$TaskName, [string]$TaskId)
    
    if (-not $TaskName) {
        Write-ColorOutput "Skipping task documentation update (no task specified)" "Yellow"
        return
    }
    
    Write-ColorOutput "Updating task documentation..." "Blue"
    
    $taskDocsPath = "docs/tasks"
    $taskLogPath = Join-Path $taskDocsPath "task-completion-log.md"
    
    # Create task docs directory if it doesn't exist
    if (-not (Test-Path $taskDocsPath)) {
        if (-not $DryRun) {
            New-Item -ItemType Directory -Path $taskDocsPath -Force | Out-Null
        }
        Write-ColorOutput "Created task documentation directory" "Green"
    }
    
    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    $taskEntry = @"

## Task Completed - $timestamp

**Task**: $TaskName
$(if ($TaskId) { "**Task ID**: $TaskId" })
**Completion Time**: $timestamp
**Integration Trigger**: $UpdateTrigger

### Changes Made
"@
    
    # Get recent git changes for this task
    try {
        $recentChanges = git diff --name-only HEAD~1..HEAD 2>$null
        if ($recentChanges) {
            foreach ($change in $recentChanges) {
                $taskEntry += "`n- Modified: $change"
            }
        } else {
            $taskEntry += "`n- No file changes detected"
        }
    }
    catch {
        $taskEntry += "`n- Could not retrieve change information"
    }
    
    $taskEntry += "`n"
    
    if (-not $DryRun) {
        if (Test-Path $taskLogPath) {
            Add-Content -Path $taskLogPath -Value $taskEntry
        } else {
            $initialTaskDoc = @"
# Task Completion Log

This document tracks completed tasks and their associated changes.

$taskEntry
"@
            $initialTaskDoc | Out-File -FilePath $taskLogPath -Encoding UTF8
        }
    }
    
    Write-ColorOutput "Task documentation updated" "Green"
}

# Function to update project overview documentation
function Update-ProjectOverview {
    Write-ColorOutput "Updating project overview documentation..." "Blue"
    
    $overviewPath = "docs/PROJECT_OVERVIEW.md"
    
    if (-not (Test-Path $overviewPath)) {
        $overviewContent = @"
# Terraform Security Enhancement Project Overview

## Project Status
Last Updated: $(Get-Date -Format "yyyy-MM-dd HH:mm:ss")

## Integration Status
- **Auto-Commit System**: Integrated with task completion
- **SAST Tools**: Integrated with CI/CD pipelines
- **Documentation System**: Linked with change tracking
- **Security Scanning**: Automated with reporting

## Key Components

### Security Tools
- Checkov: Infrastructure security scanning
- TFSec: Terraform-specific security analysis
- Terrascan: Policy-as-code validation

### Automation Scripts
- Auto-commit system for task completion
- Integrated security scanning
- Automated documentation updates
- CI/CD pipeline integration

### Documentation System
- Automated changelog generation
- Security scan result tracking
- Task completion logging
- Integration status monitoring

## Recent Activity
This section is automatically updated with recent project changes.

"@
        
        if (-not $DryRun) {
            $overviewContent | Out-File -FilePath $overviewPath -Encoding UTF8
        }
        Write-ColorOutput "Created project overview documentation" "Green"
    } else {
        # Update the last updated timestamp
        if (-not $DryRun) {
            $content = Get-Content $overviewPath -Raw
            $updatedContent = $content -replace "Last Updated: .*", "Last Updated: $(Get-Date -Format "yyyy-MM-dd HH:mm:ss")"
            $updatedContent | Out-File -FilePath $overviewPath -Encoding UTF8
        }
        Write-ColorOutput "Updated project overview timestamp" "Green"
    }
}

# Main execution
Write-ColorOutput "Documentation Integration System" "Green"
Write-ColorOutput "===============================" "Green"
Write-ColorOutput "Update Trigger: $UpdateTrigger" "Gray"
Write-ColorOutput "Dry Run: $DryRun" "Gray"

try {
    # Create docs directory if it doesn't exist
    if (-not (Test-Path "docs")) {
        if (-not $DryRun) {
            New-Item -ItemType Directory -Path "docs" -Force | Out-Null
        }
        Write-ColorOutput "Created docs directory" "Green"
    }
    
    # Get and analyze recent changes
    $gitChanges = Get-GitChangesSinceLastUpdate
    $changeAnalysis = Get-ChangeAnalysis -Changes $gitChanges
    
    Write-ColorOutput "Analyzed $($gitChanges.Count) recent changes" "Blue"
    
    # Update documentation based on trigger and flags
    $updateResults = @{
        "changelog" = $false
        "security_docs" = $false
        "task_docs" = $false
        "project_overview" = $false
    }
    
    # Update changelog
    if ($UpdateChangelog -and $gitChanges.Count -gt 0) {
        try {
            Update-ChangelogWithChanges -ChangeAnalysis $changeAnalysis
            $updateResults.changelog = $true
        }
        catch {
            Write-ColorOutput "Error updating changelog: $($_.Exception.Message)" "Red"
        }
    }
    
    # Update security documentation
    if ($UpdateSecurityDocs -and ($UpdateTrigger -eq "security-scan" -or $UpdateTrigger -eq "full-update")) {
        try {
            Update-SecurityDocumentation
            $updateResults.security_docs = $true
        }
        catch {
            Write-ColorOutput "Error updating security documentation: $($_.Exception.Message)" "Red"
        }
    }
    
    # Update task documentation
    if ($UpdateTaskDocs -and ($UpdateTrigger -eq "task-completion" -or $UpdateTrigger -eq "full-update")) {
        try {
            Update-TaskDocumentation -TaskName $TaskName -TaskId $TaskId
            $updateResults.task_docs = $true
        }
        catch {
            Write-ColorOutput "Error updating task documentation: $($_.Exception.Message)" "Red"
        }
    }
    
    # Update project overview
    if ($UpdateTrigger -eq "full-update") {
        try {
            Update-ProjectOverview
            $updateResults.project_overview = $true
        }
        catch {
            Write-ColorOutput "Error updating project overview: $($_.Exception.Message)" "Red"
        }
    }
    
    # Summary
    Write-ColorOutput "`n=== Documentation Integration Summary ===" "Cyan"
    Write-ColorOutput "Changelog Updated: $(if ($updateResults.changelog) { 'YES' } else { 'NO' })" $(if ($updateResults.changelog) { "Green" } else { "Yellow" })
    Write-ColorOutput "Security Docs Updated: $(if ($updateResults.security_docs) { 'YES' } else { 'NO' })" $(if ($updateResults.security_docs) { "Green" } else { "Yellow" })
    Write-ColorOutput "Task Docs Updated: $(if ($updateResults.task_docs) { 'YES' } else { 'NO' })" $(if ($updateResults.task_docs) { "Green" } else { "Yellow" })
    Write-ColorOutput "Project Overview Updated: $(if ($updateResults.project_overview) { 'YES' } else { 'NO' })" $(if ($updateResults.project_overview) { "Green" } else { "Yellow" })
    
    $successCount = ($updateResults.Values | Where-Object { $_ -eq $true }).Count
    
    if ($successCount -gt 0) {
        Write-ColorOutput "`nDocumentation integration completed successfully!" "Green"
        exit 0
    } else {
        Write-ColorOutput "`nNo documentation updates were performed." "Yellow"
        exit 0
    }
}
catch {
    Write-ColorOutput "Critical error in documentation integration: $($_.Exception.Message)" "Red"
    exit 1
}