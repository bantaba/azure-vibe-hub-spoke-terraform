# Smart Git Commit Script
# Intelligently stages and commits changes based on file patterns and content analysis

param(
    [string]$CommitMessage = "",
    [switch]$DryRun = $false,
    [switch]$Interactive = $false,
    [string]$CommitType = "auto",
    [string[]]$IncludePatterns = @(),
    [string[]]$ExcludePatterns = @("*.log", "*.tmp", ".DS_Store", "Thumbs.db", "node_modules/", ".terraform/")
)

# Function to write colored output
function Write-ColorOutput {
    param(
        [string]$Message,
        [string]$Color = "White"
    )
    
    switch ($Color.ToLower()) {
        "red" { Write-Host $Message -ForegroundColor Red }
        "green" { Write-Host $Message -ForegroundColor Green }
        "yellow" { Write-Host $Message -ForegroundColor Yellow }
        "blue" { Write-Host $Message -ForegroundColor Blue }
        "cyan" { Write-Host $Message -ForegroundColor Cyan }
        "magenta" { Write-Host $Message -ForegroundColor Magenta }
        default { Write-Host $Message }
    }
}

# Function to analyze changes and suggest commit type
function Get-CommitType {
    param([array]$ChangedFiles)
    
    $hasNewFeatures = $false
    $hasBugFixes = $false
    $hasDocChanges = $false
    $hasConfigChanges = $false
    $hasTestChanges = $false
    $hasRefactoring = $false
    
    foreach ($file in $ChangedFiles) {
        $fileName = $file.ToLower()
        
        # Check for new features
        if ($fileName -match "\.(tf|py|ps1|js|ts)$" -and $file -match "new file") {
            $hasNewFeatures = $true
        }
        
        # Check for documentation changes
        if ($fileName -match "\.(md|txt|rst)$") {
            $hasDocChanges = $true
        }
        
        # Check for configuration changes
        if ($fileName -match "\.(yaml|yml|json|toml|ini|conf)$") {
            $hasConfigChanges = $true
        }
        
        # Check for test files
        if ($fileName -match "(test|spec)" -or $fileName -match "tests?/") {
            $hasTestChanges = $true
        }
    }
    
    # Determine primary commit type
    if ($hasNewFeatures) { return "feat" }
    if ($hasBugFixes) { return "fix" }
    if ($hasConfigChanges -and !$hasNewFeatures) { return "config" }
    if ($hasDocChanges -and !$hasNewFeatures -and !$hasConfigChanges) { return "docs" }
    if ($hasTestChanges -and !$hasNewFeatures) { return "test" }
    
    return "chore"
}

# Function to generate intelligent commit message
function New-CommitMessage {
    param(
        [array]$ChangedFiles,
        [string]$CommitType
    )
    
    $taskPattern = "tasks\.md"
    $specPattern = "\.kiro/specs/"
    $securityPattern = "security/"
    $scriptPattern = "scripts/"
    
    # Check for task-related changes
    $taskFiles = $ChangedFiles | Where-Object { $_ -match $taskPattern }
    $specFiles = $ChangedFiles | Where-Object { $_ -match $specPattern }
    $securityFiles = $ChangedFiles | Where-Object { $_ -match $securityPattern }
    $scriptFiles = $ChangedFiles | Where-Object { $_ -match $scriptPattern }
    
    $subject = ""
    $body = @()
    
    # Generate subject line based on changes
    if ($taskFiles) {
        $subject = "$CommitType`: update task completion status"
        $body += "- Updated task status in specification files"
    }
    
    if ($securityFiles) {
        if ($subject) {
            $subject = "$CommitType`: implement security enhancements and update tasks"
        } else {
            $subject = "$CommitType`: implement security configuration and tools"
        }
        $body += "- Added security tools configuration and policies"
        $body += "- Implemented SAST tools integration"
    }
    
    if ($scriptFiles) {
        if (!$subject) {
            $subject = "$CommitType`: add automation scripts and tools"
        }
        $body += "- Added PowerShell automation scripts"
        $body += "- Implemented installation and execution utilities"
    }
    
    # Default subject if none matched
    if (!$subject) {
        $subject = "$CommitType`: update project files and configuration"
        $body += "- Updated project files and configuration"
    }
    
    # Add file summary to body
    $newFiles = $ChangedFiles | Where-Object { $_ -match "new file:" }
    $modifiedFiles = $ChangedFiles | Where-Object { $_ -match "modified:" }
    
    if ($newFiles.Count -gt 0) {
        $body += ""
        $body += "New files:"
        $newFiles | ForEach-Object {
            $fileName = ($_ -split "new file:\s+")[1]
            $body += "- $fileName"
        }
    }
    
    if ($modifiedFiles.Count -gt 0 -and $modifiedFiles.Count -le 5) {
        $body += ""
        $body += "Modified files:"
        $modifiedFiles | ForEach-Object {
            $fileName = ($_ -split "modified:\s+")[1]
            $body += "- $fileName"
        }
    }
    
    # Combine subject and body
    if ($body.Count -gt 0) {
        return "$subject`n`n$($body -join "`n")"
    } else {
        return $subject
    }
}

# Main execution
Write-ColorOutput "Smart Git Commit Tool" "Green"
Write-ColorOutput "====================" "Green"

# Check if we're in a git repository
try {
    $gitStatus = git status --porcelain 2>&1
    if ($LASTEXITCODE -ne 0) {
        Write-ColorOutput "Error: Not in a git repository or git not available" "Red"
        exit 1
    }
} catch {
    Write-ColorOutput "Error: Git command failed: $_" "Red"
    exit 1
}

# Check if there are changes to commit
if (!$gitStatus) {
    Write-ColorOutput "No changes to commit" "Yellow"
    exit 0
}

Write-ColorOutput "Analyzing changes..." "Blue"

# Get detailed status
$statusOutput = git status --porcelain
$changedFiles = $statusOutput -split "`n" | Where-Object { $_ -ne "" }

Write-ColorOutput "Found $($changedFiles.Count) changed files:" "Yellow"
$changedFiles | ForEach-Object { Write-ColorOutput "  $_" "Gray" }

# Filter files based on patterns
$filesToStage = @()
foreach ($file in $changedFiles) {
    $fileName = ($file -split "\s+", 2)[1]
    $shouldInclude = $true
    
    # Check exclude patterns
    foreach ($pattern in $ExcludePatterns) {
        if ($fileName -like $pattern) {
            $shouldInclude = $false
            Write-ColorOutput "Excluding: $fileName (matches $pattern)" "Gray"
            break
        }
    }
    
    # Check include patterns (if specified)
    if ($IncludePatterns.Count -gt 0 -and $shouldInclude) {
        $shouldInclude = $false
        foreach ($pattern in $IncludePatterns) {
            if ($fileName -like $pattern) {
                $shouldInclude = $true
                break
            }
        }
    }
    
    if ($shouldInclude) {
        $filesToStage += $fileName
    }
}

if ($filesToStage.Count -eq 0) {
    Write-ColorOutput "No files to stage after filtering" "Yellow"
    exit 0
}

Write-ColorOutput "`nFiles to stage:" "Green"
$filesToStage | ForEach-Object { Write-ColorOutput "  $_" "Green" }

# Generate commit message if not provided
if (!$CommitMessage) {
    $detectedType = Get-CommitType $changedFiles
    $CommitMessage = New-CommitMessage $changedFiles $detectedType
    Write-ColorOutput "`nGenerated commit message:" "Cyan"
    Write-ColorOutput $CommitMessage "White"
}

# Interactive confirmation
if ($Interactive) {
    Write-ColorOutput "`nProceed with commit? (y/N): " "Yellow" -NoNewline
    $response = Read-Host
    if ($response -notmatch "^[Yy]") {
        Write-ColorOutput "Commit cancelled" "Yellow"
        exit 0
    }
}

# Dry run mode
if ($DryRun) {
    Write-ColorOutput "`n[DRY RUN] Would stage and commit the following:" "Magenta"
    Write-ColorOutput "Files: $($filesToStage -join ', ')" "Gray"
    Write-ColorOutput "Message: $CommitMessage" "Gray"
    exit 0
}

# Stage files
Write-ColorOutput "`nStaging files..." "Blue"
try {
    foreach ($file in $filesToStage) {
        git add $file
        if ($LASTEXITCODE -ne 0) {
            Write-ColorOutput "Error staging file: $file" "Red"
            exit 1
        }
    }
    Write-ColorOutput "Files staged successfully" "Green"
} catch {
    Write-ColorOutput "Error staging files: $_" "Red"
    exit 1
}

# Commit changes
Write-ColorOutput "Committing changes..." "Blue"
try {
    git commit -m $CommitMessage
    if ($LASTEXITCODE -eq 0) {
        Write-ColorOutput "Commit successful!" "Green"
        
        # Show commit info
        $commitHash = git rev-parse --short HEAD
        Write-ColorOutput "Commit hash: $commitHash" "Cyan"
        
        # Show commit details
        git show --stat HEAD
    } else {
        Write-ColorOutput "Commit failed" "Red"
        exit 1
    }
} catch {
    Write-ColorOutput "Error committing changes: $_" "Red"
    exit 1
}