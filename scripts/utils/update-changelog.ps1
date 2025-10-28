# Update Changelog Script
# This script provides convenient wrapper functions for changelog generation

param(
    [string]$Action = "generate",
    [string]$Version = "",
    [string]$Since = "",
    [string]$OutputFormat = "markdown",
    [switch]$Interactive = $false,
    [switch]$Verbose = $false
)

# Script configuration
$script:ChangelogDir = "docs/changelog"
$script:MainChangelog = "$script:ChangelogDir/CHANGELOG.md"
$script:GeneratorScript = "scripts/utils/generate-changelog.ps1"

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

# Function to get the latest git tag
function Get-LatestTag {
    try {
        $latestTag = & git describe --tags --abbrev=0 2>$null
        if ($LASTEXITCODE -eq 0 -and $latestTag) {
            return $latestTag.Trim()
        }
    } catch {
        # No tags found
    }
    return $null
}

# Function to get version from user input
function Get-VersionInput {
    $currentTag = Get-LatestTag
    $suggestedVersion = if ($currentTag) { 
        # Try to increment patch version
        if ($currentTag -match '^v?(\d+)\.(\d+)\.(\d+)') {
            $major = [int]$Matches[1]
            $minor = [int]$Matches[2]
            $patch = [int]$Matches[3] + 1
            "v$major.$minor.$patch"
        } else {
            "v1.0.1"
        }
    } else { 
        "v1.0.0" 
    }
    
    Write-Host "Current latest tag: $(if ($currentTag) { $currentTag } else { 'None' })" -ForegroundColor Yellow
    Write-Host "Suggested version: $suggestedVersion" -ForegroundColor Green
    
    do {
        $version = Read-Host "Enter version (or press Enter for suggested)"
        if ([string]::IsNullOrWhiteSpace($version)) {
            $version = $suggestedVersion
        }
        
        # Validate version format
        if ($version -match '^v?\d+\.\d+\.\d+') {
            break
        } else {
            Write-Host "Invalid version format. Please use semantic versioning (e.g., v1.0.0)" -ForegroundColor Red
        }
    } while ($true)
    
    return $version
}

# Function to generate changelog
function Invoke-ChangelogGeneration {
    param(
        [string]$Since,
        [string]$OutputPath,
        [string]$Format
    )
    
    Write-ColorOutput "Generating changelog..." "Blue"
    
    if (!(Test-Path $script:GeneratorScript)) {
        Write-ColorOutput "Error: Generator script not found: $script:GeneratorScript" "Red"
        return $false
    }
    
    $args = @(
        "-OutputPath", $OutputPath,
        "-Format", $Format
    )
    
    if ($Since) {
        $args += "-Since", $Since
    }
    
    if ($Verbose) {
        $args += "-Verbose"
    }
    
    try {
        & $script:GeneratorScript @args
        return $LASTEXITCODE -eq 0
    } catch {
        Write-ColorOutput "Error running changelog generator: $_" "Red"
        return $false
    }
}

# Function to create versioned changelog
function New-VersionedChangelog {
    param([string]$Version)
    
    $versionedPath = "$script:ChangelogDir/CHANGELOG-$Version.md"
    $latestTag = Get-LatestTag
    
    Write-ColorOutput "Creating versioned changelog for $Version" "Green"
    
    $success = Invoke-ChangelogGeneration -Since $latestTag -OutputPath $versionedPath -Format $OutputFormat
    
    if ($success) {
        Write-ColorOutput "Versioned changelog created: $versionedPath" "Green"
        
        # Update main changelog with version header
        if (Test-Path $script:MainChangelog) {
            $existingContent = Get-Content $script:MainChangelog -Raw
            $versionContent = Get-Content $versionedPath -Raw
            
            # Insert version section into main changelog
            $versionHeader = "## [$Version] - $(Get-Date -Format 'yyyy-MM-dd')"
            $updatedContent = $existingContent -replace "(# Changelog\s*\n\n)", "`$1$versionHeader`n`n$versionContent`n`n"
            
            $updatedContent | Out-File -FilePath $script:MainChangelog -Encoding UTF8
            Write-ColorOutput "Updated main changelog with version $Version" "Green"
        }
        
        return $true
    }
    
    return $false
}

# Function to update main changelog
function Update-MainChangelog {
    Write-ColorOutput "Updating main changelog..." "Green"
    
    $success = Invoke-ChangelogGeneration -Since $Since -OutputPath $script:MainChangelog -Format $OutputFormat
    
    if ($success) {
        Write-ColorOutput "Main changelog updated successfully!" "Green"
        return $true
    }
    
    return $false
}

# Function to show changelog statistics
function Show-ChangelogStats {
    Write-ColorOutput "Changelog Statistics" "Cyan"
    Write-ColorOutput "===================" "Cyan"
    
    # Count commits since last tag
    $latestTag = Get-LatestTag
    $commitCount = 0
    
    if ($latestTag) {
        try {
            $commits = & git rev-list "$latestTag..HEAD" --count 2>$null
            if ($LASTEXITCODE -eq 0) {
                $commitCount = [int]$commits
            }
        } catch {
            # Error counting commits
        }
        Write-ColorOutput "Latest tag: $latestTag" "Yellow"
        Write-ColorOutput "Commits since latest tag: $commitCount" "Yellow"
    } else {
        try {
            $commits = & git rev-list HEAD --count 2>$null
            if ($LASTEXITCODE -eq 0) {
                $commitCount = [int]$commits
            }
        } catch {
            # Error counting commits
        }
        Write-ColorOutput "No tags found" "Yellow"
        Write-ColorOutput "Total commits: $commitCount" "Yellow"
    }
    
    # Show existing changelog files
    if (Test-Path $script:ChangelogDir) {
        $changelogFiles = Get-ChildItem -Path $script:ChangelogDir -Filter "*.md" | Sort-Object Name
        Write-ColorOutput "`nExisting changelog files:" "Cyan"
        foreach ($file in $changelogFiles) {
            $size = [math]::Round($file.Length / 1KB, 2)
            Write-ColorOutput "  $($file.Name) ($size KB)" "Gray"
        }
    }
}

# Main execution
Write-ColorOutput "Changelog Update Utility" "Green"
Write-ColorOutput "=======================" "Green"

# Validate git repository
if (!(Test-Path ".git")) {
    Write-ColorOutput "Error: Not in a git repository" "Red"
    exit 1
}

# Create changelog directory if it doesn't exist
if (!(Test-Path $script:ChangelogDir)) {
    New-Item -ItemType Directory -Path $script:ChangelogDir -Force | Out-Null
    Write-ColorOutput "Created changelog directory: $script:ChangelogDir" "Yellow"
}

# Execute based on action
switch ($Action.ToLower()) {
    "generate" {
        if ($Interactive) {
            Show-ChangelogStats
            Write-Host ""
            $choice = Read-Host "Generate changelog? (y/N)"
            if ($choice -notmatch '^[Yy]') {
                Write-ColorOutput "Cancelled by user" "Yellow"
                exit 0
            }
        }
        
        $success = Update-MainChangelog
        exit $(if ($success) { 0 } else { 1 })
    }
    
    "version" {
        if (!$Version) {
            if ($Interactive) {
                $Version = Get-VersionInput
            } else {
                Write-ColorOutput "Error: Version parameter required for version action" "Red"
                exit 1
            }
        }
        
        $success = New-VersionedChangelog -Version $Version
        exit $(if ($success) { 0 } else { 1 })
    }
    
    "stats" {
        Show-ChangelogStats
        exit 0
    }
    
    default {
        Write-ColorOutput "Unknown action: $Action" "Red"
        Write-ColorOutput "Available actions: generate, version, stats" "Yellow"
        exit 1
    }
}