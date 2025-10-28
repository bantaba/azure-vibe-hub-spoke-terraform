# Auto-Update Changelog Script
# This script automatically updates the changelog when triggered by git hooks or CI/CD

param(
    [string]$TriggerEvent = "post-commit",
    [switch]$Force = $false,
    [switch]$Verbose = $false
)

# Configuration
$script:ChangelogPath = "docs/changelog/CHANGELOG.md"
$script:GeneratorScript = "scripts/utils/generate-changelog.ps1"
$script:ConfigPath = "docs/changelog/changelog-config.json"

# Function to write colored output
function Write-ColorOutput {
    param(
        [string]$Message,
        [string]$Color = "White"
    )
    
    if ($Verbose) {
        switch ($Color.ToLower()) {
            "red" { Write-Host $Message -ForegroundColor Red }
            "green" { Write-Host $Message -ForegroundColor Green }
            "yellow" { Write-Host $Message -ForegroundColor Yellow }
            "blue" { Write-Host $Message -ForegroundColor Blue }
            "cyan" { Write-Host $Message -ForegroundColor Cyan }
            default { Write-Host $Message }
        }
    }
}

# Function to check if changelog update is needed
function Test-ChangelogUpdateNeeded {
    if ($Force) {
        return $true
    }
    
    # Check if changelog exists
    if (!(Test-Path $script:ChangelogPath)) {
        Write-ColorOutput "Changelog doesn't exist, update needed" "Yellow"
        return $true
    }
    
    # Check if there are new commits since last changelog update
    try {
        $changelogModified = (Get-Item $script:ChangelogPath).LastWriteTime
        $latestCommit = & git log -1 --format="%cd" --date=local 2>$null
        
        if ($LASTEXITCODE -eq 0 -and $latestCommit) {
            $latestCommitTime = [DateTime]::Parse($latestCommit)
            if ($latestCommitTime -gt $changelogModified) {
                Write-ColorOutput "New commits found since last changelog update" "Yellow"
                return $true
            }
        }
    } catch {
        Write-ColorOutput "Error checking commit dates, forcing update" "Yellow"
        return $true
    }
    
    Write-ColorOutput "Changelog is up to date" "Green"
    return $false
}

# Function to update changelog
function Update-Changelog {
    Write-ColorOutput "Updating changelog..." "Blue"
    
    if (!(Test-Path $script:GeneratorScript)) {
        Write-ColorOutput "Error: Generator script not found: $script:GeneratorScript" "Red"
        return $false
    }
    
    $args = @(
        "-OutputPath", $script:ChangelogPath
    )
    
    if ($Verbose) {
        $args += "-Verbose"
    }
    
    try {
        & $script:GeneratorScript @args
        return $LASTEXITCODE -eq 0
    } catch {
        Write-ColorOutput "Error updating changelog: $_" "Red"
        return $false
    }
}#
 Main execution
Write-ColorOutput "Auto-Update Changelog ($TriggerEvent)" "Green"
Write-ColorOutput "======================================" "Green"

# Validate git repository
if (!(Test-Path ".git")) {
    Write-ColorOutput "Error: Not in a git repository" "Red"
    exit 1
}

# Check if update is needed
if (Test-ChangelogUpdateNeeded) {
    $success = Update-Changelog
    
    if ($success) {
        Write-ColorOutput "Changelog updated successfully!" "Green"
        
        # If this is a post-commit hook, we might want to amend the commit
        if ($TriggerEvent -eq "post-commit" -and (Test-Path $script:ChangelogPath)) {
            Write-ColorOutput "Changelog updated after commit" "Yellow"
            Write-ColorOutput "Consider running: git add $script:ChangelogPath && git commit --amend --no-edit" "Cyan"
        }
        
        exit 0
    } else {
        Write-ColorOutput "Failed to update changelog" "Red"
        exit 1
    }
} else {
    Write-ColorOutput "No changelog update needed" "Green"
    exit 0
}