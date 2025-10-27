# Auto-Commit Wrapper Functions
# Task completion detection logic and commit message templates

# Import the main auto-commit script functions
$scriptPath = Split-Path -Parent $MyInvocation.MyCommand.Path
$autoCommitScript = Join-Path $scriptPath "auto-commit.ps1"

# Configuration for task types and templates
$Global:TaskTemplates = @{
    "setup" = @{
        "type" = "feat"
        "description" = "Initial project setup and configuration"
    }
    "security" = @{
        "type" = "security"
        "description" = "Security enhancement implementation"
    }
    "sast" = @{
        "type" = "feat"
        "description" = "SAST tool integration and configuration"
    }
    "cicd" = @{
        "type" = "ci"
        "description" = "CI/CD pipeline implementation"
    }
    "terraform" = @{
        "type" = "feat"
        "description" = "Terraform infrastructure improvements"
    }
    "docs" = @{
        "type" = "docs"
        "description" = "Documentation updates and improvements"
    }
    "test" = @{
        "type" = "test"
        "description" = "Test implementation and validation"
    }
    "fix" = @{
        "type" = "fix"
        "description" = "Bug fixes and issue resolution"
    }
    "refactor" = @{
        "type" = "refactor"
        "description" = "Code refactoring and optimization"
    }
}

# Function to detect task completion based on file changes
function Test-TaskCompletion {
    param(
        [Parameter(Mandatory=$true)]
        [string]$TaskId,
        
        [Parameter(Mandatory=$false)]
        [string[]]$ExpectedFiles = @(),
        
        [Parameter(Mandatory=$false)]
        [string[]]$RequiredPatterns = @()
    )
    
    Write-Host "Checking task completion for: $TaskId"
    
    # Check if we're in a git repository
    try {
        $null = git rev-parse --git-dir 2>$null
    }
    catch {
        Write-Warning "Not in a git repository"
        return $false
    }
    
    # Get current git status
    try {
        $status = git status --porcelain 2>$null
        if (-not $status) {
            Write-Host "No changes detected"
            return $false
        }
        
        Write-Host "Detected changes:"
        $status | ForEach-Object { Write-Host "  $_" }
        
        # Check for expected files if specified
        if ($ExpectedFiles.Count -gt 0) {
            $changedFiles = $status | ForEach-Object { $_.Substring(3) }
            $foundFiles = @()
            
            foreach ($expectedFile in $ExpectedFiles) {
                $found = $changedFiles | Where-Object { $_ -like "*$expectedFile*" }
                if ($found) {
                    $foundFiles += $found
                }
            }
            
            if ($foundFiles.Count -eq 0) {
                Write-Warning "Expected files not found in changes: $($ExpectedFiles -join ', ')"
                return $false
            }
            
            Write-Host "Found expected files: $($foundFiles -join ', ')"
        }
        
        # Check for required patterns in changed files if specified
        if ($RequiredPatterns.Count -gt 0) {
            $changedFiles = git diff --cached --name-only 2>$null
            if (-not $changedFiles) {
                # Stage changes to check content
                git add . 2>$null
                $changedFiles = git diff --cached --name-only 2>$null
            }
            
            $patternMatches = @()
            foreach ($pattern in $RequiredPatterns) {
                $matches = git diff --cached | Select-String -Pattern $pattern -Quiet
                if ($matches) {
                    $patternMatches += $pattern
                }
            }
            
            if ($patternMatches.Count -eq 0) {
                Write-Warning "Required patterns not found in changes: $($RequiredPatterns -join ', ')"
                return $false
            }
            
            Write-Host "Found required patterns: $($patternMatches -join ', ')"
        }
        
        return $true
    }
    catch {
        Write-Error "Failed to check task completion: $($_.Exception.Message)"
        return $false
    }
}

# Function to get task type from task name or ID
function Get-TaskType {
    param(
        [Parameter(Mandatory=$true)]
        [string]$TaskName,
        
        [Parameter(Mandatory=$false)]
        [string]$TaskId = ""
    )
    
    $taskLower = $TaskName.ToLower()
    
    # Check for specific keywords to determine task type
    if ($taskLower -match "setup|initialize|create.*structure") {
        return "setup"
    }
    elseif ($taskLower -match "security|sast|scan|vulnerability") {
        return "security"
    }
    elseif ($taskLower -match "checkov|tfsec|terrascan|compliance") {
        return "sast"
    }
    elseif ($taskLower -match "pipeline|ci.*cd|github.*actions|azure.*devops") {
        return "cicd"
    }
    elseif ($taskLower -match "terraform|infrastructure|module") {
        return "terraform"
    }
    elseif ($taskLower -match "document|readme|changelog") {
        return "docs"
    }
    elseif ($taskLower -match "test|validation|verify") {
        return "test"
    }
    elseif ($taskLower -match "fix|bug|issue|error") {
        return "fix"
    }
    elseif ($taskLower -match "refactor|optimize|improve|enhance") {
        return "refactor"
    }
    else {
        return "feat"  # Default to feature
    }
}

# Function to create enhanced commit message with task context
function New-TaskCommitMessage {
    param(
        [Parameter(Mandatory=$true)]
        [string]$TaskName,
        
        [Parameter(Mandatory=$false)]
        [string]$TaskId = "",
        
        [Parameter(Mandatory=$false)]
        [string]$TaskType = "",
        
        [Parameter(Mandatory=$false)]
        [string]$AdditionalDescription = ""
    )
    
    # Determine task type if not provided
    if (-not $TaskType) {
        $TaskType = Get-TaskType -TaskName $TaskName -TaskId $TaskId
    }
    
    # Get template for task type
    $template = $Global:TaskTemplates[$TaskType]
    if (-not $template) {
        $template = $Global:TaskTemplates["feat"]
    }
    
    # Build commit message
    $scope = if ($TaskId) { $TaskId } else { "terraform-security" }
    $commitType = $template.type
    $baseDescription = $template.description
    
    # Create main commit message
    $message = "$commitType($scope): $TaskName"
    
    # Add detailed description
    $description = $baseDescription
    if ($AdditionalDescription) {
        $description += "`n`n$AdditionalDescription"
    }
    
    # Add metadata
    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    $description += "`n`nTask completed: $timestamp"
    
    if ($TaskId) {
        $description += "`nTask ID: $TaskId"
    }
    
    $description += "`nTask Type: $TaskType"
    
    # Add changed files summary
    try {
        $changedFiles = git status --porcelain 2>$null
        if ($changedFiles) {
            $fileCount = ($changedFiles | Measure-Object).Count
            $description += "`nFiles changed: $fileCount"
            
            # Add file list if not too many
            if ($fileCount -le 10) {
                $description += "`nChanged files:"
                $changedFiles | ForEach-Object { 
                    $status = $_.Substring(0, 2)
                    $file = $_.Substring(3)
                    $description += "`n  $status $file"
                }
            }
        }
    }
    catch {
        # Ignore errors in file summary
    }
    
    return @{
        "message" = $message
        "description" = $description
        "type" = $commitType
    }
}

# Function to execute auto-commit with task completion detection
function Invoke-TaskAutoCommit {
    param(
        [Parameter(Mandatory=$true)]
        [string]$TaskName,
        
        [Parameter(Mandatory=$false)]
        [string]$TaskId = "",
        
        [Parameter(Mandatory=$false)]
        [string]$TaskType = "",
        
        [Parameter(Mandatory=$false)]
        [string[]]$ExpectedFiles = @(),
        
        [Parameter(Mandatory=$false)]
        [string[]]$RequiredPatterns = @(),
        
        [Parameter(Mandatory=$false)]
        [string]$AdditionalDescription = "",
        
        [Parameter(Mandatory=$false)]
        [switch]$Force,
        
        [Parameter(Mandatory=$false)]
        [switch]$DryRun
    )
    
    Write-Host "=== Task Auto-Commit Process ===" -ForegroundColor Cyan
    Write-Host "Task: $TaskName" -ForegroundColor Yellow
    if ($TaskId) { Write-Host "Task ID: $TaskId" -ForegroundColor Yellow }
    
    # Check task completion unless forced
    if (-not $Force) {
        $isComplete = Test-TaskCompletion -TaskId $TaskId -ExpectedFiles $ExpectedFiles -RequiredPatterns $RequiredPatterns
        if (-not $isComplete) {
            Write-Warning "Task completion check failed. Use -Force to override."
            return $false
        }
    }
    
    # Generate commit message
    $commitInfo = New-TaskCommitMessage -TaskName $TaskName -TaskId $TaskId -TaskType $TaskType -AdditionalDescription $AdditionalDescription
    
    Write-Host "Commit Type: $($commitInfo.type)" -ForegroundColor Green
    Write-Host "Commit Message: $($commitInfo.message)" -ForegroundColor Green
    
    # Execute auto-commit script
    try {
        $params = @{
            "TaskName" = $TaskName
            "CommitType" = $commitInfo.type
            "Description" = $commitInfo.description
        }
        
        if ($TaskId) { $params["TaskId"] = $TaskId }
        if ($DryRun) { $params["DryRun"] = $true }
        
        # Call the main auto-commit script
        & $autoCommitScript @params
        
        if ($LASTEXITCODE -eq 0) {
            Write-Host "Task auto-commit completed successfully!" -ForegroundColor Green
            return $true
        } else {
            Write-Error "Auto-commit script failed with exit code: $LASTEXITCODE"
            return $false
        }
    }
    catch {
        Write-Error "Failed to execute auto-commit: $($_.Exception.Message)"
        return $false
    }
}

# Convenience functions for common task types
function Invoke-SecurityTaskCommit {
    param(
        [Parameter(Mandatory=$true)]
        [string]$TaskName,
        
        [Parameter(Mandatory=$false)]
        [string]$TaskId = "",
        
        [Parameter(Mandatory=$false)]
        [string]$AdditionalDescription = "",
        
        [Parameter(Mandatory=$false)]
        [switch]$DryRun
    )
    
    return Invoke-TaskAutoCommit -TaskName $TaskName -TaskId $TaskId -TaskType "security" -AdditionalDescription $AdditionalDescription -DryRun:$DryRun
}

function Invoke-SASTTaskCommit {
    param(
        [Parameter(Mandatory=$true)]
        [string]$TaskName,
        
        [Parameter(Mandatory=$false)]
        [string]$TaskId = "",
        
        [Parameter(Mandatory=$false)]
        [string]$AdditionalDescription = "",
        
        [Parameter(Mandatory=$false)]
        [switch]$DryRun
    )
    
    $expectedFiles = @("checkov", "tfsec", "terrascan", ".yml", ".yaml", "config")
    return Invoke-TaskAutoCommit -TaskName $TaskName -TaskId $TaskId -TaskType "sast" -ExpectedFiles $expectedFiles -AdditionalDescription $AdditionalDescription -DryRun:$DryRun
}

function Invoke-TerraformTaskCommit {
    param(
        [Parameter(Mandatory=$true)]
        [string]$TaskName,
        
        [Parameter(Mandatory=$false)]
        [string]$TaskId = "",
        
        [Parameter(Mandatory=$false)]
        [string]$AdditionalDescription = "",
        
        [Parameter(Mandatory=$false)]
        [switch]$DryRun
    )
    
    $expectedFiles = @(".tf", "terraform")
    $requiredPatterns = @("resource\s+\"", "variable\s+\"", "output\s+\"")
    return Invoke-TaskAutoCommit -TaskName $TaskName -TaskId $TaskId -TaskType "terraform" -ExpectedFiles $expectedFiles -RequiredPatterns $requiredPatterns -AdditionalDescription $AdditionalDescription -DryRun:$DryRun
}

function Invoke-CICDTaskCommit {
    param(
        [Parameter(Mandatory=$true)]
        [string]$TaskName,
        
        [Parameter(Mandatory=$false)]
        [string]$TaskId = "",
        
        [Parameter(Mandatory=$false)]
        [string]$AdditionalDescription = "",
        
        [Parameter(Mandatory=$false)]
        [switch]$DryRun
    )
    
    $expectedFiles = @(".yml", ".yaml", "pipeline", "workflow", "action")
    return Invoke-TaskAutoCommit -TaskName $TaskName -TaskId $TaskId -TaskType "cicd" -ExpectedFiles $expectedFiles -AdditionalDescription $AdditionalDescription -DryRun:$DryRun
}

function Invoke-DocsTaskCommit {
    param(
        [Parameter(Mandatory=$true)]
        [string]$TaskName,
        
        [Parameter(Mandatory=$false)]
        [string]$TaskId = "",
        
        [Parameter(Mandatory=$false)]
        [string]$AdditionalDescription = "",
        
        [Parameter(Mandatory=$false)]
        [switch]$DryRun
    )
    
    $expectedFiles = @(".md", "README", "CHANGELOG", "docs/")
    return Invoke-TaskAutoCommit -TaskName $TaskName -TaskId $TaskId -TaskType "docs" -ExpectedFiles $expectedFiles -AdditionalDescription $AdditionalDescription -DryRun:$DryRun
}

# Export functions for use in other scripts
Export-ModuleMember -Function @(
    'Test-TaskCompletion',
    'Get-TaskType', 
    'New-TaskCommitMessage',
    'Invoke-TaskAutoCommit',
    'Invoke-SecurityTaskCommit',
    'Invoke-SASTTaskCommit', 
    'Invoke-TerraformTaskCommit',
    'Invoke-CICDTaskCommit',
    'Invoke-DocsTaskCommit'
)