# Auto-Commit PowerShell Script
# Automated git operations with commit message standardization and error handling

param(
    [Parameter(Mandatory=$true)]
    [string]$TaskName,
    
    [Parameter(Mandatory=$false)]
    [string]$TaskId = "",
    
    [Parameter(Mandatory=$false)]
    [string]$CommitType = "feat",
    
    [Parameter(Mandatory=$false)]
    [string]$Description = "",
    
    [Parameter(Mandatory=$false)]
    [int]$MaxRetries = 3,
    
    [Parameter(Mandatory=$false)]
    [switch]$DryRun
)

# Configuration
$ErrorActionPreference = "Stop"
$ProgressPreference = "SilentlyContinue"

# Logging function
function Write-Log {
    param(
        [string]$Message,
        [string]$Level = "INFO"
    )
    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    $logMessage = "[$timestamp] [$Level] $Message"
    Write-Host $logMessage
    
    # Also log to file if logs directory exists
    $logDir = "logs"
    if (Test-Path $logDir) {
        $logFile = Join-Path $logDir "auto-commit.log"
        Add-Content -Path $logFile -Value $logMessage
    }
}

# Function to check if we're in a git repository
function Test-GitRepository {
    try {
        $null = git rev-parse --git-dir 2>$null
        return $true
    }
    catch {
        return $false
    }
}

# Function to get git status
function Get-GitStatus {
    try {
        $status = git status --porcelain 2>$null
        return $status
    }
    catch {
        Write-Log "Failed to get git status: $($_.Exception.Message)" "ERROR"
        return $null
    }
}

# Function to stage all changes
function Invoke-GitAdd {
    param([int]$RetryCount = 0)
    
    try {
        Write-Log "Staging all changes..."
        git add . 2>$null
        
        # Verify staging worked
        $staged = git diff --cached --name-only 2>$null
        if ($staged) {
            Write-Log "Successfully staged $($staged.Count) files"
            return $true
        } else {
            Write-Log "No files were staged" "WARN"
            return $false
        }
    }
    catch {
        if ($RetryCount -lt $MaxRetries) {
            Write-Log "Git add failed, retrying... (attempt $($RetryCount + 1)/$MaxRetries)" "WARN"
            Start-Sleep -Seconds (2 * ($RetryCount + 1))
            return Invoke-GitAdd -RetryCount ($RetryCount + 1)
        } else {
            Write-Log "Git add failed after $MaxRetries attempts: $($_.Exception.Message)" "ERROR"
            return $false
        }
    }
}

# Function to create standardized commit message
function New-CommitMessage {
    param(
        [string]$Type,
        [string]$Task,
        [string]$TaskId,
        [string]$Description
    )
    
    # Standardized commit message format: type(scope): description
    $scope = if ($TaskId) { $TaskId } else { "security" }
    $message = "$Type($scope): $Task"
    
    if ($Description) {
        $message += "`n`n$Description"
    }
    
    # Add timestamp and metadata
    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    $message += "`n`nTimestamp: $timestamp"
    
    if ($TaskId) {
        $message += "`nTask-ID: $TaskId"
    }
    
    return $message
}

# Function to perform git commit
function Invoke-GitCommit {
    param(
        [string]$Message,
        [int]$RetryCount = 0
    )
    
    try {
        Write-Log "Creating commit with message: $($Message.Split("`n")[0])"
        
        if ($DryRun) {
            Write-Log "DRY RUN: Would commit with message: $Message" "INFO"
            return $true
        }
        
        # Create temporary file for commit message to handle multi-line messages
        $tempFile = [System.IO.Path]::GetTempFileName()
        Set-Content -Path $tempFile -Value $Message -Encoding UTF8
        
        try {
            git commit -F $tempFile 2>$null
            Write-Log "Commit created successfully"
            return $true
        }
        finally {
            Remove-Item -Path $tempFile -Force -ErrorAction SilentlyContinue
        }
    }
    catch {
        if ($RetryCount -lt $MaxRetries) {
            Write-Log "Git commit failed, retrying... (attempt $($RetryCount + 1)/$MaxRetries)" "WARN"
            Start-Sleep -Seconds (2 * ($RetryCount + 1))
            return Invoke-GitCommit -Message $Message -RetryCount ($RetryCount + 1)
        } else {
            Write-Log "Git commit failed after $MaxRetries attempts: $($_.Exception.Message)" "ERROR"
            return $false
        }
    }
}

# Function to get current branch name
function Get-CurrentBranch {
    try {
        $branch = git branch --show-current 2>$null
        return $branch.Trim()
    }
    catch {
        Write-Log "Failed to get current branch: $($_.Exception.Message)" "WARN"
        return "unknown"
    }
}

# Main execution function
function Invoke-AutoCommit {
    Write-Log "Starting auto-commit process for task: $TaskName"
    
    # Validate we're in a git repository
    if (-not (Test-GitRepository)) {
        Write-Log "Not in a git repository. Please run this script from the project root." "ERROR"
        exit 1
    }
    
    # Get current branch
    $currentBranch = Get-CurrentBranch
    Write-Log "Current branch: $currentBranch"
    
    # Check for changes
    $status = Get-GitStatus
    if (-not $status) {
        Write-Log "No changes detected in the repository" "INFO"
        return $true
    }
    
    Write-Log "Detected changes in the following files:"
    $status | ForEach-Object { Write-Log "  $_" }
    
    # Stage changes
    $stageResult = Invoke-GitAdd
    if (-not $stageResult) {
        Write-Log "Failed to stage changes" "ERROR"
        exit 1
    }
    
    # Create commit message
    $commitMessage = New-CommitMessage -Type $CommitType -Task $TaskName -TaskId $TaskId -Description $Description
    
    # Perform commit
    $commitResult = Invoke-GitCommit -Message $commitMessage
    if (-not $commitResult) {
        Write-Log "Failed to create commit" "ERROR"
        exit 1
    }
    
    Write-Log "Auto-commit completed successfully for task: $TaskName"
    return $true
}

# Script entry point
try {
    $result = Invoke-AutoCommit
    if ($result) {
        Write-Log "Auto-commit process completed successfully" "SUCCESS"
        exit 0
    } else {
        Write-Log "Auto-commit process failed" "ERROR"
        exit 1
    }
}
catch {
    Write-Log "Unexpected error during auto-commit: $($_.Exception.Message)" "ERROR"
    Write-Log "Stack trace: $($_.ScriptStackTrace)" "ERROR"
    exit 1
}