# Task Completion Hook
# Automatically triggers integration workflow when tasks are completed
# This script can be called by task management systems or manually

param(
    [Parameter(Mandatory=$true)]
    [string]$TaskName,
    
    [Parameter(Mandatory=$false)]
    [string]$TaskId = "",
    
    [Parameter(Mandatory=$false)]
    [ValidateSet("setup", "security", "sast", "cicd", "terraform", "docs", "test", "fix", "refactor")]
    [string]$TaskType = "",
    
    [Parameter(Mandatory=$false)]
    [switch]$SkipSecurityScan = $false,
    
    [Parameter(Mandatory=$false)]
    [switch]$SkipDocumentationUpdate = $false,
    
    [Parameter(Mandatory=$false)]
    [switch]$DryRun = $false,
    
    [Parameter(Mandatory=$false)]
    [switch]$Verbose = $false
)

# Script configuration
$script:ScriptPath = Split-Path -Parent $MyInvocation.MyCommand.Path
$script:RootPath = Split-Path -Parent (Split-Path -Parent $script:ScriptPath)
$orchestratorPath = Join-Path $script:ScriptPath "integration-orchestrator.ps1"

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

# Function to determine if security scan should be triggered
function Test-ShouldTriggerSecurityScan {
    param([string]$TaskType, [string]$TaskName)
    
    # Always trigger for security-related tasks
    if ($TaskType -in @("security", "sast", "terraform")) {
        return $true
    }
    
    # Check task name for security-related keywords
    $securityKeywords = @("security", "sast", "scan", "checkov", "tfsec", "terrascan", "vulnerability", "compliance")
    $taskLower = $TaskName.ToLower()
    
    foreach ($keyword in $securityKeywords) {
        if ($taskLower -contains $keyword) {
            return $true
        }
    }
    
    return $false
}

# Function to determine if documentation update should be triggered
function Test-ShouldTriggerDocumentationUpdate {
    param([string]$TaskType, [string]$TaskName)
    
    # Always trigger for documentation tasks
    if ($TaskType -eq "docs") {
        return $true
    }
    
    # Trigger for major implementation tasks
    if ($TaskType -in @("security", "sast", "cicd", "terraform")) {
        return $true
    }
    
    return $false
}

Write-ColorOutput "=== Task Completion Hook ===" "Cyan"
Write-ColorOutput "Task: $TaskName" "Yellow"
if ($TaskId) { Write-ColorOutput "Task ID: $TaskId" "Yellow" }
if ($TaskType) { Write-ColorOutput "Task Type: $TaskType" "Yellow" }

# Check if orchestrator exists
if (-not (Test-Path $orchestratorPath)) {
    Write-ColorOutput "Error: Integration orchestrator not found: $orchestratorPath" "Red"
    exit 1
}

try {
    # Step 1: Always execute task completion integration (auto-commit)
    Write-ColorOutput "`nStep 1: Executing task completion integration..." "Blue"
    
    $taskCompletionArgs = @{
        "IntegrationType" = "task-completion"
        "TaskName" = $TaskName
        "DryRun" = $DryRun
        "Verbose" = $Verbose
    }
    
    if ($TaskId) {
        $taskCompletionArgs["TaskId"] = $TaskId
    }
    
    & $orchestratorPath @taskCompletionArgs
    $taskCompletionResult = $LASTEXITCODE
    
    if ($taskCompletionResult -eq 0) {
        Write-ColorOutput "Task completion integration successful" "Green"
    } else {
        Write-ColorOutput "Task completion integration failed" "Red"
        # Continue with other integrations even if commit fails
    }
    
    # Step 2: Conditionally execute security scan integration
    if (-not $SkipSecurityScan -and (Test-ShouldTriggerSecurityScan -TaskType $TaskType -TaskName $TaskName)) {
        Write-ColorOutput "`nStep 2: Executing security scan integration..." "Blue"
        
        $securityScanArgs = @{
            "IntegrationType" = "security-scan"
            "DryRun" = $DryRun
            "Verbose" = $Verbose
        }
        
        & $orchestratorPath @securityScanArgs
        $securityScanResult = $LASTEXITCODE
        
        if ($securityScanResult -eq 0) {
            Write-ColorOutput "Security scan integration successful" "Green"
        } else {
            Write-ColorOutput "Security scan integration failed" "Red"
        }
    } else {
        Write-ColorOutput "`nStep 2: Skipping security scan integration (not required for this task type)" "Yellow"
        $securityScanResult = 0
    }
    
    # Step 3: Conditionally execute documentation update
    if (-not $SkipDocumentationUpdate -and (Test-ShouldTriggerDocumentationUpdate -TaskType $TaskType -TaskName $TaskName)) {
        Write-ColorOutput "`nStep 3: Executing documentation update..." "Blue"
        
        $docsUpdateArgs = @{
            "IntegrationType" = "documentation-update"
            "DryRun" = $DryRun
            "Verbose" = $Verbose
        }
        
        & $orchestratorPath @docsUpdateArgs
        $docsUpdateResult = $LASTEXITCODE
        
        if ($docsUpdateResult -eq 0) {
            Write-ColorOutput "Documentation update successful" "Green"
        } else {
            Write-ColorOutput "Documentation update failed" "Red"
        }
    } else {
        Write-ColorOutput "`nStep 3: Skipping documentation update (not required for this task type)" "Yellow"
        $docsUpdateResult = 0
    }
    
    # Summary
    Write-ColorOutput "`n=== Task Completion Hook Summary ===" "Cyan"
    Write-ColorOutput "Task Completion: $(if ($taskCompletionResult -eq 0) { 'SUCCESS' } else { 'FAILED' })" $(if ($taskCompletionResult -eq 0) { "Green" } else { "Red" })
    Write-ColorOutput "Security Scan: $(if ($securityScanResult -eq 0) { 'SUCCESS' } else { 'FAILED' })" $(if ($securityScanResult -eq 0) { "Green" } else { "Red" })
    Write-ColorOutput "Documentation: $(if ($docsUpdateResult -eq 0) { 'SUCCESS' } else { 'FAILED' })" $(if ($docsUpdateResult -eq 0) { "Green" } else { "Red" })
    
    # Determine overall result
    $overallResult = $taskCompletionResult + $securityScanResult + $docsUpdateResult
    
    if ($overallResult -eq 0) {
        Write-ColorOutput "`nTask completion hook executed successfully!" "Green"
        exit 0
    } else {
        Write-ColorOutput "`nTask completion hook completed with errors!" "Red"
        exit 1
    }
}
catch {
    Write-ColorOutput "Critical error in task completion hook: $($_.Exception.Message)" "Red"
    exit 1
}