# Task Commit Helper Script
# Simple interface for committing completed tasks

param(
    [Parameter(Mandatory=$true)]
    [string]$TaskName,
    
    [Parameter(Mandatory=$false)]
    [string]$TaskId = "",
    
    [Parameter(Mandatory=$false)]
    [ValidateSet("setup", "security", "sast", "cicd", "terraform", "docs", "test", "fix", "refactor", "auto")]
    [string]$TaskType = "auto",
    
    [Parameter(Mandatory=$false)]
    [string]$Description = "",
    
    [Parameter(Mandatory=$false)]
    [switch]$Force,
    
    [Parameter(Mandatory=$false)]
    [switch]$DryRun,
    
    [Parameter(Mandatory=$false)]
    [switch]$Help
)

# Show help
if ($Help) {
    Write-Host @"
Task Commit Helper Script

USAGE:
    .\commit-task.ps1 -TaskName "Task description" [-TaskId "2.1"] [-TaskType "security"] [-Description "Additional details"] [-Force] [-DryRun]

PARAMETERS:
    -TaskName       (Required) Description of the completed task
    -TaskId         (Optional) Task identifier (e.g., "2.1", "3.2")
    -TaskType       (Optional) Type of task: setup, security, sast, cicd, terraform, docs, test, fix, refactor, auto
                    Default: "auto" (automatically detects type from task name)
    -Description    (Optional) Additional description for the commit
    -Force          (Optional) Skip task completion validation
    -DryRun         (Optional) Show what would be committed without actually committing
    -Help           Show this help message

EXAMPLES:
    # Auto-detect task type and commit
    .\commit-task.ps1 -TaskName "Create auto-commit PowerShell script" -TaskId "2.1"
    
    # Specify task type explicitly
    .\commit-task.ps1 -TaskName "Configure Checkov for Azure" -TaskId "3.1" -TaskType "sast"
    
    # Dry run to see what would be committed
    .\commit-task.ps1 -TaskName "Update Terraform modules" -DryRun
    
    # Force commit without validation
    .\commit-task.ps1 -TaskName "Fix configuration issue" -TaskType "fix" -Force

"@ -ForegroundColor Cyan
    exit 0
}

# Import wrapper functions
$scriptPath = Split-Path -Parent $MyInvocation.MyCommand.Path
$wrapperScript = Join-Path $scriptPath "auto-commit-wrapper.ps1"

if (-not (Test-Path $wrapperScript)) {
    Write-Error "Wrapper script not found: $wrapperScript"
    exit 1
}

# Import the wrapper functions
. $wrapperScript

Write-Host "=== Task Commit Helper ===" -ForegroundColor Cyan
Write-Host "Task: $TaskName" -ForegroundColor Yellow
if ($TaskId) { Write-Host "Task ID: $TaskId" -ForegroundColor Yellow }
Write-Host "Task Type: $TaskType" -ForegroundColor Yellow

try {
    $result = $false
    
    # Use specific function based on task type or auto-detect
    switch ($TaskType) {
        "security" {
            $result = Invoke-SecurityTaskCommit -TaskName $TaskName -TaskId $TaskId -AdditionalDescription $Description -DryRun:$DryRun
        }
        "sast" {
            $result = Invoke-SASTTaskCommit -TaskName $TaskName -TaskId $TaskId -AdditionalDescription $Description -DryRun:$DryRun
        }
        "terraform" {
            $result = Invoke-TerraformTaskCommit -TaskName $TaskName -TaskId $TaskId -AdditionalDescription $Description -DryRun:$DryRun
        }
        "cicd" {
            $result = Invoke-CICDTaskCommit -TaskName $TaskName -TaskId $TaskId -AdditionalDescription $Description -DryRun:$DryRun
        }
        "docs" {
            $result = Invoke-DocsTaskCommit -TaskName $TaskName -TaskId $TaskId -AdditionalDescription $Description -DryRun:$DryRun
        }
        default {
            # Auto-detect or use generic function
            $detectedType = if ($TaskType -eq "auto") { Get-TaskType -TaskName $TaskName -TaskId $TaskId } else { $TaskType }
            $result = Invoke-TaskAutoCommit -TaskName $TaskName -TaskId $TaskId -TaskType $detectedType -AdditionalDescription $Description -Force:$Force -DryRun:$DryRun
        }
    }
    
    if ($result) {
        Write-Host "`nTask commit completed successfully!" -ForegroundColor Green
        exit 0
    } else {
        Write-Host "`nTask commit failed!" -ForegroundColor Red
        exit 1
    }
}
catch {
    Write-Error "Error executing task commit: $($_.Exception.Message)"
    exit 1
}