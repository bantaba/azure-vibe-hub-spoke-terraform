# Release Manager Script
# This script manages version tracking and release documentation generation

param(
    [string]$Action = "prepare",
    [string]$Version = "",
    [string]$ReleaseType = "patch", # major, minor, patch
    [switch]$DryRun = $false,
    [switch]$Interactive = $true,
    [switch]$Verbose = $false
)

# Configuration
$script:ChangelogDir = "docs/changelog"
$script:ReleasesDir = "docs/releases"
$script:MainChangelog = "$script:ChangelogDir/CHANGELOG.md"
$script:VersionFile = "VERSION"
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

# Function to get current version
function Get-CurrentVersion {
    # Try to get version from VERSION file
    if (Test-Path $script:VersionFile) {
        $version = Get-Content $script:VersionFile -Raw
        if ($version) {
            return $version.Trim()
        }
    }
    
    # Try to get latest git tag
    try {
        $latestTag = & git describe --tags --abbrev=0 2>$null
        if ($LASTEXITCODE -eq 0 -and $latestTag) {
            return $latestTag.Trim()
        }
    } catch {
        # No tags found
    }
    
    # Default version
    return "v0.1.0"
}

# Function to increment version
function Get-NextVersion {
    param(
        [string]$CurrentVersion,
        [string]$ReleaseType
    )
    
    # Parse semantic version
    if ($CurrentVersion -match '^v?(\d+)\.(\d+)\.(\d+)') {
        $major = [int]$Matches[1]
        $minor = [int]$Matches[2]
        $patch = [int]$Matches[3]
        
        switch ($ReleaseType.ToLower()) {
            "major" {
                $major++
                $minor = 0
                $patch = 0
            }
            "minor" {
                $minor++
                $patch = 0
            }
            "patch" {
                $patch++
            }
            default {
                Write-ColorOutput "Invalid release type: $ReleaseType" "Red"
                return $null
            }
        }
        
        return "v$major.$minor.$patch"
    } else {
        Write-ColorOutput "Invalid version format: $CurrentVersion" "Red"
        return $null
    }
}

# Function to analyze changes since last release
function Get-ChangeAnalysis {
    param([string]$Since)
    
    Write-ColorOutput "Analyzing changes since $Since..." "Blue"
    
    try {
        # Get commits since last release
        $gitArgs = @("log", "--pretty=format:%H|%s|%an|%ad", "--date=short")
        if ($Since) {
            $gitArgs += "$Since..HEAD"
        }
        
        $commits = & git @gitArgs 2>&1
        if ($LASTEXITCODE -ne 0) {
            Write-ColorOutput "Error getting git commits: $commits" "Red"
            return @{}
        }
        
        $analysis = @{
            TotalCommits = 0
            BreakingChanges = 0
            Features = 0
            Fixes = 0
            Security = 0
            Documentation = 0
            Other = 0
            SuggestedReleaseType = "patch"
            CommitsByType = @{}
        }
        
        foreach ($line in $commits) {
            if ($line -and $line.Contains('|')) {
                $analysis.TotalCommits++
                $parts = $line -split '\|', 4
                $message = $parts[1]
                
                # Categorize commit
                if ($message -match '^(feat|feature)(\(.*\))?!?:' -or $message -match 'BREAKING CHANGE') {
                    if ($message -match '!:' -or $message -match 'BREAKING CHANGE') {
                        $analysis.BreakingChanges++
                        $analysis.SuggestedReleaseType = "major"
                    } else {
                        $analysis.Features++
                        if ($analysis.SuggestedReleaseType -eq "patch") {
                            $analysis.SuggestedReleaseType = "minor"
                        }
                    }
                } elseif ($message -match '^(fix|bugfix)(\(.*\))?:') {
                    $analysis.Fixes++
                } elseif ($message -match '^(security|sec)(\(.*\))?:') {
                    $analysis.Security++
                } elseif ($message -match '^(docs|doc)(\(.*\))?:') {
                    $analysis.Documentation++
                } else {
                    $analysis.Other++
                }
            }
        }
        
        return $analysis
    } catch {
        Write-ColorOutput "Error analyzing changes: $_" "Red"
        return @{}
    }
}

# Function to generate release notes
function New-ReleaseNotes {
    param(
        [string]$Version,
        [string]$Since,
        [hashtable]$Analysis
    )
    
    Write-ColorOutput "Generating release notes for $Version..." "Blue"
    
    $releaseNotes = @()
    $releaseNotes += "# Release $Version"
    $releaseNotes += ""
    $releaseNotes += "**Release Date:** $(Get-Date -Format 'yyyy-MM-dd')"
    $releaseNotes += "**Previous Version:** $Since"
    $releaseNotes += ""
    
    # Release summary
    $releaseNotes += "## Summary"
    $releaseNotes += ""
    $releaseNotes += "This release includes $($Analysis.TotalCommits) commits with the following changes:"
    $releaseNotes += ""
    
    if ($Analysis.BreakingChanges -gt 0) {
        $releaseNotes += "- 💥 **$($Analysis.BreakingChanges) Breaking Changes** - Major version update required"
    }
    if ($Analysis.Features -gt 0) {
        $releaseNotes += "- ✨ **$($Analysis.Features) New Features** - Enhanced functionality"
    }
    if ($Analysis.Fixes -gt 0) {
        $releaseNotes += "- 🐛 **$($Analysis.Fixes) Bug Fixes** - Stability improvements"
    }
    if ($Analysis.Security -gt 0) {
        $releaseNotes += "- 🔒 **$($Analysis.Security) Security Updates** - Security enhancements"
    }
    if ($Analysis.Documentation -gt 0) {
        $releaseNotes += "- 📚 **$($Analysis.Documentation) Documentation Updates** - Improved documentation"
    }
    if ($Analysis.Other -gt 0) {
        $releaseNotes += "- 🔧 **$($Analysis.Other) Other Changes** - Maintenance and improvements"
    }
    
    $releaseNotes += ""
    
    # Impact assessment
    $releaseNotes += "## Impact Assessment"
    $releaseNotes += ""
    
    if ($Analysis.BreakingChanges -gt 0) {
        $releaseNotes += "⚠️ **High Impact**: This release contains breaking changes that may require updates to existing configurations or workflows."
        $releaseNotes += ""
    } elseif ($Analysis.Features -gt 0) {
        $releaseNotes += "📈 **Medium Impact**: This release adds new features that enhance functionality without breaking existing implementations."
        $releaseNotes += ""
    } else {
        $releaseNotes += "🔧 **Low Impact**: This release contains bug fixes and improvements that should not affect existing functionality."
        $releaseNotes += ""
    }
    
    # Migration guide placeholder
    if ($Analysis.BreakingChanges -gt 0) {
        $releaseNotes += "## Migration Guide"
        $releaseNotes += ""
        $releaseNotes += "### Breaking Changes"
        $releaseNotes += ""
        $releaseNotes += "Please review the detailed changelog below for specific breaking changes and required actions."
        $releaseNotes += ""
    }
    
    # Detailed changelog reference
    $releaseNotes += "## Detailed Changes"
    $releaseNotes += ""
    $releaseNotes += "For a complete list of changes, see the [detailed changelog](../changelog/CHANGELOG-$Version.md)."
    $releaseNotes += ""
    
    # Installation/upgrade instructions
    $releaseNotes += "## Installation & Upgrade"
    $releaseNotes += ""
    $releaseNotes += "### Prerequisites"
    $releaseNotes += ""
    $releaseNotes += "- Terraform >= 1.0"
    $releaseNotes += "- Azure CLI >= 2.0"
    $releaseNotes += "- PowerShell >= 5.1"
    $releaseNotes += ""
    $releaseNotes += "### Upgrade Steps"
    $releaseNotes += ""
    $releaseNotes += "1. Backup your current Terraform state"
    $releaseNotes += "2. Update to version $Version"
    $releaseNotes += "3. Run ``terraform plan`` to review changes"
    $releaseNotes += "4. Apply changes with ``terraform apply``"
    $releaseNotes += ""
    
    # Verification steps
    $releaseNotes += "## Verification"
    $releaseNotes += ""
    $releaseNotes += "After upgrading, verify the installation by running:"
    $releaseNotes += ""
    $releaseNotes += "```bash"
    $releaseNotes += "# Validate Terraform configuration"
    $releaseNotes += "terraform validate"
    $releaseNotes += ""
    $releaseNotes += "# Run security scans"
    $releaseNotes += "scripts/security/run-security-scan.ps1"
    $releaseNotes += "```"
    $releaseNotes += ""
    
    # Support information
    $releaseNotes += "## Support"
    $releaseNotes += ""
    $releaseNotes += "If you encounter issues with this release:"
    $releaseNotes += ""
    $releaseNotes += "1. Check the [troubleshooting guide](../operations/)"
    $releaseNotes += "2. Review the [security documentation](../security/)"
    $releaseNotes += "3. Consult the [setup guides](../setup/)"
    $releaseNotes += ""
    
    return $releaseNotes -join "`n"
}

# Function to create release
function New-Release {
    param(
        [string]$Version,
        [string]$PreviousVersion
    )
    
    Write-ColorOutput "Creating release $Version..." "Green"
    
    # Create releases directory if it doesn't exist
    if (!(Test-Path $script:ReleasesDir)) {
        New-Item -ItemType Directory -Path $script:ReleasesDir -Force | Out-Null
        Write-ColorOutput "Created releases directory: $script:ReleasesDir" "Yellow"
    }
    
    # Analyze changes
    $analysis = Get-ChangeAnalysis -Since $PreviousVersion
    
    # Generate versioned changelog
    $versionedChangelog = "$script:ChangelogDir/CHANGELOG-$Version.md"
    Write-ColorOutput "Generating versioned changelog: $versionedChangelog" "Blue"
    
    if (Test-Path $script:GeneratorScript) {
        $args = @(
            "-OutputPath", $versionedChangelog,
            "-Since", $PreviousVersion,
            "-Until", "HEAD"
        )
        
        if ($Verbose) {
            $args += "-Verbose"
        }
        
        & $script:GeneratorScript @args
        
        if ($LASTEXITCODE -ne 0) {
            Write-ColorOutput "Error generating versioned changelog" "Red"
            return $false
        }
    }
    
    # Generate release notes
    $releaseNotes = New-ReleaseNotes -Version $Version -Since $PreviousVersion -Analysis $analysis
    $releaseNotesPath = "$script:ReleasesDir/RELEASE-$Version.md"
    
    $releaseNotes | Out-File -FilePath $releaseNotesPath -Encoding UTF8
    Write-ColorOutput "Generated release notes: $releaseNotesPath" "Green"
    
    # Update VERSION file
    $Version | Out-File -FilePath $script:VersionFile -Encoding UTF8 -NoNewline
    Write-ColorOutput "Updated VERSION file: $script:VersionFile" "Green"
    
    # Update main changelog
    if (Test-Path $script:MainChangelog) {
        Write-ColorOutput "Updating main changelog..." "Blue"
        & $script:GeneratorScript -OutputPath $script:MainChangelog
    }
    
    return $true
}

# Function to show release preview
function Show-ReleasePreview {
    param(
        [string]$Version,
        [string]$PreviousVersion
    )
    
    Write-ColorOutput "Release Preview for $Version" "Cyan"
    Write-ColorOutput "==============================" "Cyan"
    
    $analysis = Get-ChangeAnalysis -Since $PreviousVersion
    
    Write-ColorOutput "Previous Version: $PreviousVersion" "Yellow"
    Write-ColorOutput "New Version: $Version" "Green"
    Write-ColorOutput "Suggested Release Type: $($analysis.SuggestedReleaseType)" "Cyan"
    Write-ColorOutput ""
    
    Write-ColorOutput "Change Summary:" "Cyan"
    Write-ColorOutput "- Total Commits: $($analysis.TotalCommits)" "Gray"
    Write-ColorOutput "- Breaking Changes: $($analysis.BreakingChanges)" "Red"
    Write-ColorOutput "- New Features: $($analysis.Features)" "Green"
    Write-ColorOutput "- Bug Fixes: $($analysis.Fixes)" "Yellow"
    Write-ColorOutput "- Security Updates: $($analysis.Security)" "Red"
    Write-ColorOutput "- Documentation: $($analysis.Documentation)" "Blue"
    Write-ColorOutput "- Other Changes: $($analysis.Other)" "Gray"
    Write-ColorOutput ""
    
    if ($analysis.BreakingChanges -gt 0) {
        Write-ColorOutput "⚠️  WARNING: This release contains breaking changes!" "Red"
    }
}

# Main execution
Write-ColorOutput "Release Manager" "Green"
Write-ColorOutput "===============" "Green"

# Validate git repository
if (!(Test-Path ".git")) {
    Write-ColorOutput "Error: Not in a git repository" "Red"
    exit 1
}

# Get current version
$currentVersion = Get-CurrentVersion
Write-ColorOutput "Current Version: $currentVersion" "Yellow"

# Execute based on action
switch ($Action.ToLower()) {
    "prepare" {
        if (!$Version) {
            $nextVersion = Get-NextVersion -CurrentVersion $currentVersion -ReleaseType $ReleaseType
            if (!$nextVersion) {
                exit 1
            }
            
            if ($Interactive) {
                Show-ReleasePreview -Version $nextVersion -PreviousVersion $currentVersion
                Write-Host ""
                $confirm = Read-Host "Proceed with release $nextVersion? (y/N)"
                if ($confirm -notmatch '^[Yy]') {
                    Write-ColorOutput "Release cancelled by user" "Yellow"
                    exit 0
                }
            }
            
            $Version = $nextVersion
        }
        
        if ($DryRun) {
            Show-ReleasePreview -Version $Version -PreviousVersion $currentVersion
            Write-ColorOutput "DRY RUN: No changes made" "Yellow"
            exit 0
        }
        
        $success = New-Release -Version $Version -PreviousVersion $currentVersion
        exit $(if ($success) { 0 } else { 1 })
    }
    
    "preview" {
        $nextVersion = if ($Version) { $Version } else { Get-NextVersion -CurrentVersion $currentVersion -ReleaseType $ReleaseType }
        Show-ReleasePreview -Version $nextVersion -PreviousVersion $currentVersion
        exit 0
    }
    
    "tag" {
        if (!$Version) {
            $Version = Get-CurrentVersion
        }
        
        Write-ColorOutput "Creating git tag for $Version..." "Blue"
        
        try {
            & git tag -a $Version -m "Release $Version"
            if ($LASTEXITCODE -eq 0) {
                Write-ColorOutput "Git tag created: $Version" "Green"
                Write-ColorOutput "Push with: git push origin $Version" "Cyan"
            } else {
                Write-ColorOutput "Error creating git tag" "Red"
                exit 1
            }
        } catch {
            Write-ColorOutput "Error creating git tag: $_" "Red"
            exit 1
        }
        
        exit 0
    }
    
    default {
        Write-ColorOutput "Unknown action: $Action" "Red"
        Write-ColorOutput "Available actions: prepare, preview, tag" "Yellow"
        exit 1
    }
}