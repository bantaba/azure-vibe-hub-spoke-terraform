# Automated Changelog System
# This script provides a unified interface for all changelog and release management operations

param(
    [string]$Command = "help",
    [string]$Version = "",
    [string]$Since = "",
    [string]$ReleaseType = "patch",
    [switch]$Interactive = $true,
    [switch]$DryRun = $false,
    [switch]$Verbose = $false
)

# Configuration
$script:ScriptsDir = "scripts/utils"
$script:ChangelogGenerator = "$script:ScriptsDir/generate-changelog.ps1"
$script:ChangelogUpdater = "$script:ScriptsDir/update-changelog.ps1"
$script:ReleaseManager = "$script:ScriptsDir/release-manager.ps1"
$script:ImpactAnalyzer = "$script:ScriptsDir/change-impact-analyzer.ps1"

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
        "gray" { Write-Host $Message -ForegroundColor Gray }
        default { Write-Host $Message }
    }
}

# Function to check script dependencies
function Test-Dependencies {
    $missing = @()
    
    $scripts = @(
        $script:ChangelogGenerator,
        $script:ChangelogUpdater,
        $script:ReleaseManager,
        $script:ImpactAnalyzer
    )
    
    foreach ($script in $scripts) {
        if (!(Test-Path $script)) {
            $missing += $script
        }
    }
    
    if ($missing.Count -gt 0) {
        Write-ColorOutput "Missing required scripts:" "Red"
        foreach ($script in $missing) {
            Write-ColorOutput "  - $script" "Red"
        }
        return $false
    }
    
    return $true
}

# Function to execute script with parameters
function Invoke-Script {
    param(
        [string]$ScriptPath,
        [hashtable]$Parameters = @{}
    )
    
    if (!(Test-Path $ScriptPath)) {
        Write-ColorOutput "Script not found: $ScriptPath" "Red"
        return $false
    }
    
    try {
        $args = @()
        foreach ($key in $Parameters.Keys) {
            $value = $Parameters[$key]
            if ($value -is [switch] -and $value) {
                $args += "-$key"
            } elseif ($value -and $value -ne "") {
                $args += "-$key", $value
            }
        }
        
        if ($Verbose) {
            Write-ColorOutput "Executing: $ScriptPath $($args -join ' ')" "Gray"
        }
        
        & $ScriptPath @args
        return $LASTEXITCODE -eq 0
    } catch {
        Write-ColorOutput "Error executing script: $_" "Red"
        return $false
    }
}

# Function to show help
function Show-Help {
    Write-ColorOutput "Automated Changelog System" "Green"
    Write-ColorOutput "==========================" "Green"
    Write-ColorOutput ""
    Write-ColorOutput "USAGE:" "Cyan"
    Write-ColorOutput "  .\automated-changelog-system.ps1 -Command <command> [options]" "Gray"
    Write-ColorOutput ""
    Write-ColorOutput "COMMANDS:" "Cyan"
    Write-ColorOutput "  generate      Generate changelog from git history" "Gray"
    Write-ColorOutput "  update        Update main changelog" "Gray"
    Write-ColorOutput "  release       Prepare a new release" "Gray"
    Write-ColorOutput "  analyze       Analyze change impact" "Gray"
    Write-ColorOutput "  version       Show current version information" "Gray"
    Write-ColorOutput "  status        Show changelog system status" "Gray"
    Write-ColorOutput "  help          Show this help message" "Gray"
    Write-ColorOutput ""
    Write-ColorOutput "OPTIONS:" "Cyan"
    Write-ColorOutput "  -Version      Specific version for release operations" "Gray"
    Write-ColorOutput "  -Since        Start point for analysis (git ref)" "Gray"
    Write-ColorOutput "  -ReleaseType  Type of release (major|minor|patch)" "Gray"
    Write-ColorOutput "  -Interactive  Enable interactive mode (default: true)" "Gray"
    Write-ColorOutput "  -DryRun       Show what would be done without making changes" "Gray"
    Write-ColorOutput "  -Verbose      Enable verbose output" "Gray"
    Write-ColorOutput ""
    Write-ColorOutput "EXAMPLES:" "Cyan"
    Write-ColorOutput "  # Generate changelog" "Gray"
    Write-ColorOutput "  .\automated-changelog-system.ps1 -Command generate" "Gray"
    Write-ColorOutput ""
    Write-ColorOutput "  # Prepare minor release" "Gray"
    Write-ColorOutput "  .\automated-changelog-system.ps1 -Command release -ReleaseType minor" "Gray"
    Write-ColorOutput ""
    Write-ColorOutput "  # Analyze changes since last tag" "Gray"
    Write-ColorOutput "  .\automated-changelog-system.ps1 -Command analyze" "Gray"
    Write-ColorOutput ""
    Write-ColorOutput "  # Dry run release preparation" "Gray"
    Write-ColorOutput "  .\automated-changelog-system.ps1 -Command release -DryRun" "Gray"
}

# Function to show version information
function Show-Version {
    Write-ColorOutput "Version Information" "Cyan"
    Write-ColorOutput "==================" "Cyan"
    
    # Get current version from VERSION file
    $currentVersion = "Unknown"
    if (Test-Path "VERSION") {
        $currentVersion = (Get-Content "VERSION" -Raw).Trim()
    }
    
    # Get latest git tag
    $latestTag = "None"
    try {
        $tag = & git describe --tags --abbrev=0 2>$null
        if ($LASTEXITCODE -eq 0 -and $tag) {
            $latestTag = $tag.Trim()
        }
    } catch {
        # No tags found
    }
    
    # Get commit count since last tag
    $commitsSinceTag = 0
    if ($latestTag -ne "None") {
        try {
            $count = & git rev-list "$latestTag..HEAD" --count 2>$null
            if ($LASTEXITCODE -eq 0) {
                $commitsSinceTag = [int]$count
            }
        } catch {
            # Error counting commits
        }
    }
    
    Write-ColorOutput "Current Version: $currentVersion" "Yellow"
    Write-ColorOutput "Latest Git Tag: $latestTag" "Yellow"
    Write-ColorOutput "Commits Since Tag: $commitsSinceTag" "Yellow"
    
    # Show changelog files
    if (Test-Path "docs/changelog") {
        $changelogFiles = Get-ChildItem -Path "docs/changelog" -Filter "*.md" | Sort-Object Name
        Write-ColorOutput "`nChangelog Files:" "Cyan"
        foreach ($file in $changelogFiles) {
            $size = [math]::Round($file.Length / 1KB, 2)
            Write-ColorOutput "  $($file.Name) ($size KB)" "Gray"
        }
    }
    
    # Show release files
    if (Test-Path "docs/releases") {
        $releaseFiles = Get-ChildItem -Path "docs/releases" -Filter "*.md" | Sort-Object Name
        if ($releaseFiles.Count -gt 0) {
            Write-ColorOutput "`nRelease Files:" "Cyan"
            foreach ($file in $releaseFiles) {
                $size = [math]::Round($file.Length / 1KB, 2)
                Write-ColorOutput "  $($file.Name) ($size KB)" "Gray"
            }
        }
    }
}

# Function to show system status
function Show-Status {
    Write-ColorOutput "Changelog System Status" "Cyan"
    Write-ColorOutput "=======================" "Cyan"
    
    # Check git repository
    $gitStatus = if (Test-Path ".git") { "✅ Available" } else { "❌ Not a git repository" }
    Write-ColorOutput "Git Repository: $gitStatus" "Gray"
    
    # Check required directories
    $directories = @("docs/changelog", "docs/releases", "scripts/utils")
    foreach ($dir in $directories) {
        $status = if (Test-Path $dir) { "✅ Exists" } else { "❌ Missing" }
        Write-ColorOutput "${dir}: $status" "Gray"
    }
    
    # Check required scripts
    Write-ColorOutput "`nScript Dependencies:" "Cyan"
    $scripts = @{
        "Changelog Generator" = $script:ChangelogGenerator
        "Changelog Updater" = $script:ChangelogUpdater
        "Release Manager" = $script:ReleaseManager
        "Impact Analyzer" = $script:ImpactAnalyzer
    }
    
    foreach ($name in $scripts.Keys) {
        $path = $scripts[$name]
        $status = if (Test-Path $path) { "✅ Available" } else { "❌ Missing" }
        Write-ColorOutput "${name}: $status" "Gray"
    }
    
    # Check configuration files
    Write-ColorOutput "`nConfiguration Files:" "Cyan"
    $configs = @{
        "VERSION file" = "VERSION"
        "Changelog Config" = "docs/changelog/changelog-config.json"
        "Main Changelog" = "docs/changelog/CHANGELOG.md"
    }
    
    foreach ($name in $configs.Keys) {
        $path = $configs[$name]
        $status = if (Test-Path $path) { "✅ Available" } else { "❌ Missing" }
        Write-ColorOutput "${name}: $status" "Gray"
    }
    
    # Show recent activity
    Write-ColorOutput "`nRecent Activity:" "Cyan"
    try {
        $recentCommits = & git log --oneline -5 2>$null
        if ($LASTEXITCODE -eq 0 -and $recentCommits) {
            foreach ($commit in $recentCommits) {
                Write-ColorOutput "  $commit" "Gray"
            }
        } else {
            Write-ColorOutput "  No recent commits found" "Gray"
        }
    } catch {
        Write-ColorOutput "  Error retrieving recent commits" "Red"
    }
}

# Main execution
Write-ColorOutput "Automated Changelog System" "Green"
Write-ColorOutput "==========================" "Green"

# Validate dependencies
if (!(Test-Dependencies)) {
    Write-ColorOutput "Please ensure all required scripts are available" "Red"
    exit 1
}

# Execute command
switch ($Command.ToLower()) {
    "generate" {
        Write-ColorOutput "Generating changelog..." "Blue"
        $params = @{
            Verbose = $Verbose
        }
        if ($Since) { $params.Since = $Since }
        
        $success = Invoke-Script -ScriptPath $script:ChangelogGenerator -Parameters $params
        exit $(if ($success) { 0 } else { 1 })
    }
    
    "update" {
        Write-ColorOutput "Updating changelog..." "Blue"
        $params = @{
            Action = "generate"
            Interactive = $Interactive
            Verbose = $Verbose
        }
        if ($Since) { $params.Since = $Since }
        
        $success = Invoke-Script -ScriptPath $script:ChangelogUpdater -Parameters $params
        exit $(if ($success) { 0 } else { 1 })
    }
    
    "release" {
        Write-ColorOutput "Preparing release..." "Blue"
        $params = @{
            Action = "prepare"
            ReleaseType = $ReleaseType
            Interactive = $Interactive
            DryRun = $DryRun
            Verbose = $Verbose
        }
        if ($Version) { $params.Version = $Version }
        
        $success = Invoke-Script -ScriptPath $script:ReleaseManager -Parameters $params
        exit $(if ($success) { 0 } else { 1 })
    }
    
    "analyze" {
        Write-ColorOutput "Analyzing change impact..." "Blue"
        $params = @{
            IncludeFileAnalysis = $true
            IncludeSecurityAnalysis = $true
            Verbose = $Verbose
        }
        if ($Since) { $params.Since = $Since }
        
        $success = Invoke-Script -ScriptPath $script:ImpactAnalyzer -Parameters $params
        exit $(if ($success) { 0 } else { 1 })
    }
    
    "version" {
        Show-Version
        exit 0
    }
    
    "status" {
        Show-Status
        exit 0
    }
    
    "help" {
        Show-Help
        exit 0
    }
    
    default {
        Write-ColorOutput "Unknown command: $Command" "Red"
        Write-ColorOutput "Use -Command help for available commands" "Yellow"
        exit 1
    }
}