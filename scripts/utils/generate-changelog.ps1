# Automated Changelog Generation Script
# This script generates changelogs from git commit history with categorization and impact analysis

param(
    [string]$OutputPath = "docs/changelog/CHANGELOG.md",
    [string]$Since = "",
    [string]$Until = "HEAD",
    [string]$Format = "markdown",
    [switch]$IncludeAll = $false,
    [switch]$GroupByDate = $true,
    [switch]$Verbose = $false
)

# Initialize variables
$script:CommitCategories = @{
    "feat" = @{ Name = "Features"; Icon = "✨"; Color = "Green" }
    "fix" = @{ Name = "Bug Fixes"; Icon = "🐛"; Color = "Red" }
    "docs" = @{ Name = "Documentation"; Icon = "📚"; Color = "Blue" }
    "style" = @{ Name = "Styles"; Icon = "💄"; Color = "Magenta" }
    "refactor" = @{ Name = "Code Refactoring"; Icon = "♻️"; Color = "Yellow" }
    "perf" = @{ Name = "Performance Improvements"; Icon = "⚡"; Color = "Cyan" }
    "test" = @{ Name = "Tests"; Icon = "✅"; Color = "Green" }
    "build" = @{ Name = "Build System"; Icon = "👷"; Color = "Gray" }
    "ci" = @{ Name = "Continuous Integration"; Icon = "🔧"; Color = "Gray" }
    "chore" = @{ Name = "Chores"; Icon = "🔨"; Color = "Gray" }
    "revert" = @{ Name = "Reverts"; Icon = "⏪"; Color = "Red" }
    "security" = @{ Name = "Security"; Icon = "🔒"; Color = "Red" }
    "breaking" = @{ Name = "Breaking Changes"; Icon = "💥"; Color = "Red" }
}

$script:ImpactLevels = @{
    "major" = @{ Name = "Major"; Icon = "🚨"; Description = "Breaking changes or major new features" }
    "minor" = @{ Name = "Minor"; Icon = "📈"; Description = "New features or significant improvements" }
    "patch" = @{ Name = "Patch"; Icon = "🔧"; Description = "Bug fixes or minor improvements" }
}

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
            "magenta" { Write-Host $Message -ForegroundColor Magenta }
            "gray" { Write-Host $Message -ForegroundColor Gray }
            default { Write-Host $Message }
        }
    }
}# Function to parse conventional commit message
function Get-CommitInfo {
    param([string]$CommitMessage)
    
    $commitInfo = @{
        Type = "chore"
        Scope = ""
        Subject = $CommitMessage
        Body = ""
        IsBreaking = $false
        Impact = "patch"
        Category = "Chores"
    }
    
    # Parse conventional commit format: type(scope): subject
    if ($CommitMessage -match '^(\w+)(\([^)]+\))?\s*:\s*(.+)$') {
        $commitInfo.Type = $Matches[1].ToLower()
        $commitInfo.Scope = if ($Matches[2]) { $Matches[2].Trim('()') } else { "" }
        $commitInfo.Subject = $Matches[3]
        
        # Check for breaking change indicators
        if ($CommitMessage -match '!:|BREAKING CHANGE') {
            $commitInfo.IsBreaking = $true
            $commitInfo.Impact = "major"
        }
        
        # Determine impact level based on type
        switch ($commitInfo.Type) {
            "feat" { 
                $commitInfo.Impact = if ($commitInfo.IsBreaking) { "major" } else { "minor" }
            }
            "fix" { 
                $commitInfo.Impact = "patch"
            }
            "perf" { 
                $commitInfo.Impact = "minor"
            }
            "security" { 
                $commitInfo.Impact = "patch"
            }
            default { 
                $commitInfo.Impact = "patch"
            }
        }
        
        # Set category based on type
        if ($script:CommitCategories.ContainsKey($commitInfo.Type)) {
            $commitInfo.Category = $script:CommitCategories[$commitInfo.Type].Name
        }
    }
    
    return $commitInfo
}

# Function to get git commits
function Get-GitCommits {
    param(
        [string]$Since,
        [string]$Until
    )
    
    Write-ColorOutput "Retrieving git commits..." "Blue"
    
    $gitArgs = @("log", "--pretty=format:%H|%ad|%s|%an|%ae", "--date=short")
    
    if ($Since) {
        if ($Until -eq "HEAD") {
            $gitArgs += "$Since..$Until"
        } else {
            $gitArgs += "$Since..$Until"
        }
    } else {
        $gitArgs += $Until
    }
    
    try {
        $gitOutput = & git @gitArgs 2>&1
        
        if ($LASTEXITCODE -ne 0) {
            Write-ColorOutput "Error retrieving git commits: $gitOutput" "Red"
            return @()
        }
        
        $commits = @()
        foreach ($line in $gitOutput) {
            if ($line -and $line.Contains('|')) {
                $parts = $line -split '\|', 5
                if ($parts.Count -ge 4) {
                    $commitInfo = Get-CommitInfo $parts[2]
                    $commits += @{
                        Hash = $parts[0]
                        Date = $parts[1]
                        Message = $parts[2]
                        Author = $parts[3]
                        Email = if ($parts.Count -gt 4) { $parts[4] } else { "" }
                        Info = $commitInfo
                    }
                }
            }
        }
        
        Write-ColorOutput "Retrieved $($commits.Count) commits" "Green"
        return $commits
    } catch {
        Write-ColorOutput "Error executing git command: $_" "Red"
        return @()
    }
}

# Function to group commits by category and date
function Group-Commits {
    param([array]$Commits)
    
    Write-ColorOutput "Grouping commits by category and date..." "Blue"
    
    $groupedCommits = @{}
    
    foreach ($commit in $Commits) {
        $category = $commit.Info.Category
        $date = $commit.Date
        
        if (!$groupedCommits.ContainsKey($category)) {
            $groupedCommits[$category] = @{}
        }
        
        if ($GroupByDate) {
            if (!$groupedCommits[$category].ContainsKey($date)) {
                $groupedCommits[$category][$date] = @()
            }
            $groupedCommits[$category][$date] += $commit
        } else {
            if (!$groupedCommits[$category].ContainsKey("all")) {
                $groupedCommits[$category]["all"] = @()
            }
            $groupedCommits[$category]["all"] += $commit
        }
    }
    
    return $groupedCommits
}

# Function to generate markdown changelog
function New-MarkdownChangelog {
    param(
        [hashtable]$GroupedCommits,
        [array]$AllCommits
    )
    
    Write-ColorOutput "Generating markdown changelog..." "Blue"
    
    $changelog = @()
    $changelog += "# Changelog"
    $changelog += ""
    $changelog += "All notable changes to this project will be documented in this file."
    $changelog += ""
    $changelog += "The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),"
    $changelog += "and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html)."
    $changelog += ""
    
    # Generate summary statistics
    $totalCommits = $AllCommits.Count
    $impactCounts = @{}
    $typeCounts = @{}
    
    foreach ($commit in $AllCommits) {
        $impact = $commit.Info.Impact
        $type = $commit.Info.Type
        
        if (!$impactCounts.ContainsKey($impact)) { $impactCounts[$impact] = 0 }
        if (!$typeCounts.ContainsKey($type)) { $typeCounts[$type] = 0 }
        
        $impactCounts[$impact]++
        $typeCounts[$type]++
    }
    
    $changelog += "## Summary"
    $changelog += ""
    $changelog += "**Total Changes**: $totalCommits"
    $changelog += ""
    
    # Impact breakdown
    $changelog += "### Impact Analysis"
    $changelog += ""
    foreach ($impact in @("major", "minor", "patch")) {
        if ($impactCounts.ContainsKey($impact)) {
            $count = $impactCounts[$impact]
            $icon = $script:ImpactLevels[$impact].Icon
            $name = $script:ImpactLevels[$impact].Name
            $description = $script:ImpactLevels[$impact].Description
            $changelog += "- $icon **$name**: $count changes - $description"
        }
    }
    $changelog += ""
    
    # Type breakdown
    $changelog += "### Change Types"
    $changelog += ""
    foreach ($type in $typeCounts.Keys | Sort-Object) {
        $count = $typeCounts[$type]
        if ($script:CommitCategories.ContainsKey($type)) {
            $icon = $script:CommitCategories[$type].Icon
            $name = $script:CommitCategories[$type].Name
            $changelog += "- $icon **$name**: $count changes"
        } else {
            $changelog += "- **$type**: $count changes"
        }
    }
    $changelog += ""
    
    # Generate detailed changes by category
    $changelog += "## Detailed Changes"
    $changelog += ""
    
    # Sort categories by importance
    $categoryOrder = @("Breaking Changes", "Security", "Features", "Bug Fixes", "Performance Improvements", 
                      "Code Refactoring", "Documentation", "Tests", "Build System", "Continuous Integration", 
                      "Styles", "Chores", "Reverts")
    
    foreach ($categoryName in $categoryOrder) {
        if ($GroupedCommits.ContainsKey($categoryName)) {
            $categoryData = $GroupedCommits[$categoryName]
            
            # Find the icon for this category
            $categoryIcon = "📝"
            foreach ($type in $script:CommitCategories.Keys) {
                if ($script:CommitCategories[$type].Name -eq $categoryName) {
                    $categoryIcon = $script:CommitCategories[$type].Icon
                    break
                }
            }
            
            $changelog += "### $categoryIcon $categoryName"
            $changelog += ""
            
            if ($GroupByDate) {
                # Group by date
                $dates = $categoryData.Keys | Sort-Object -Descending
                foreach ($date in $dates) {
                    $commits = $categoryData[$date]
                    $changelog += "#### $date"
                    $changelog += ""
                    
                    foreach ($commit in $commits) {
                        $scope = if ($commit.Info.Scope) { "**$($commit.Info.Scope)**: " } else { "" }
                        $breaking = if ($commit.Info.IsBreaking) { " 💥" } else { "" }
                        $changelog += "- $scope$($commit.Info.Subject)$breaking ([``$($commit.Hash.Substring(0,7))``](../../commit/$($commit.Hash)))"
                    }
                    $changelog += ""
                }
            } else {
                # List all commits in category
                $commits = $categoryData["all"]
                foreach ($commit in $commits) {
                    $scope = if ($commit.Info.Scope) { "**$($commit.Info.Scope)**: " } else { "" }
                    $breaking = if ($commit.Info.IsBreaking) { " 💥" } else { "" }
                    $date = $commit.Date
                    $changelog += "- $scope$($commit.Info.Subject)$breaking - $date ([``$($commit.Hash.Substring(0,7))``](../../commit/$($commit.Hash)))"
                }
                $changelog += ""
            }
        }
    }
    
    # Add generation metadata
    $changelog += "---"
    $changelog += ""
    $changelog += "*This changelog was automatically generated on $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss') UTC*"
    $changelog += ""
    $changelog += "**Generation Parameters:**"
    $changelog += "- Since: $(if ($Since) { $Since } else { 'Beginning of history' })"
    $changelog += "- Until: $Until"
    $changelog += "- Total commits analyzed: $totalCommits"
    $changelog += "- Group by date: $GroupByDate"
    
    return $changelog -join "`n"
}# Function to generate JSON changelog
function New-JsonChangelog {
    param(
        [hashtable]$GroupedCommits,
        [array]$AllCommits
    )
    
    Write-ColorOutput "Generating JSON changelog..." "Blue"
    
    $changelogData = @{
        metadata = @{
            generated_at = (Get-Date -Format "yyyy-MM-ddTHH:mm:ssZ")
            total_commits = $AllCommits.Count
            since = if ($Since) { $Since } else { $null }
            until = $Until
            group_by_date = $GroupByDate
        }
        summary = @{
            impact_analysis = @{}
            change_types = @{}
        }
        changes = @{}
        commits = @()
    }
    
    # Calculate summary statistics
    foreach ($commit in $AllCommits) {
        $impact = $commit.Info.Impact
        $type = $commit.Info.Type
        
        if (!$changelogData.summary.impact_analysis.ContainsKey($impact)) {
            $changelogData.summary.impact_analysis[$impact] = 0
        }
        if (!$changelogData.summary.change_types.ContainsKey($type)) {
            $changelogData.summary.change_types[$type] = 0
        }
        
        $changelogData.summary.impact_analysis[$impact]++
        $changelogData.summary.change_types[$type]++
        
        # Add commit to commits array
        $changelogData.commits += @{
            hash = $commit.Hash
            short_hash = $commit.Hash.Substring(0, 7)
            date = $commit.Date
            message = $commit.Message
            author = $commit.Author
            email = $commit.Email
            type = $commit.Info.Type
            scope = $commit.Info.Scope
            subject = $commit.Info.Subject
            is_breaking = $commit.Info.IsBreaking
            impact = $commit.Info.Impact
            category = $commit.Info.Category
        }
    }
    
    # Add grouped changes
    foreach ($category in $GroupedCommits.Keys) {
        $changelogData.changes[$category] = @{}
        
        foreach ($dateOrAll in $GroupedCommits[$category].Keys) {
            $changelogData.changes[$category][$dateOrAll] = @()
            
            foreach ($commit in $GroupedCommits[$category][$dateOrAll]) {
                $changelogData.changes[$category][$dateOrAll] += @{
                    hash = $commit.Hash
                    short_hash = $commit.Hash.Substring(0, 7)
                    date = $commit.Date
                    subject = $commit.Info.Subject
                    scope = $commit.Info.Scope
                    is_breaking = $commit.Info.IsBreaking
                    impact = $commit.Info.Impact
                    author = $commit.Author
                }
            }
        }
    }
    
    return $changelogData | ConvertTo-Json -Depth 10
}

# Function to save changelog to file
function Save-Changelog {
    param(
        [string]$Content,
        [string]$FilePath
    )
    
    Write-ColorOutput "Saving changelog to: $FilePath" "Blue"
    
    try {
        # Create directory if it doesn't exist
        $directory = Split-Path -Parent $FilePath
        if ($directory -and !(Test-Path $directory)) {
            New-Item -ItemType Directory -Path $directory -Force | Out-Null
            Write-ColorOutput "Created directory: $directory" "Yellow"
        }
        
        # Save content to file
        $Content | Out-File -FilePath $FilePath -Encoding UTF8
        Write-ColorOutput "Changelog saved successfully!" "Green"
        
        return $true
    } catch {
        Write-ColorOutput "Error saving changelog: $_" "Red"
        return $false
    }
}

# Main execution
Write-ColorOutput "Starting Automated Changelog Generation" "Green"
Write-ColorOutput "=======================================" "Green"

# Validate git repository
if (!(Test-Path ".git")) {
    Write-ColorOutput "Error: Not in a git repository" "Red"
    exit 1
}

# Get git commits
$commits = Get-GitCommits -Since $Since -Until $Until

if ($commits.Count -eq 0) {
    Write-ColorOutput "No commits found in the specified range" "Yellow"
    exit 0
}

# Filter commits if not including all
if (!$IncludeAll) {
    # Exclude merge commits and commits with certain patterns
    $commits = $commits | Where-Object { 
        $_.Message -notmatch '^Merge ' -and 
        $_.Message -notmatch '^Revert ' -and
        $_.Message.Trim() -ne ''
    }
    Write-ColorOutput "Filtered to $($commits.Count) commits (excluding merges and reverts)" "Yellow"
}

# Group commits
$groupedCommits = Group-Commits -Commits $commits

# Generate changelog based on format
switch ($Format.ToLower()) {
    "json" {
        $changelogContent = New-JsonChangelog -GroupedCommits $groupedCommits -AllCommits $commits
        if ($OutputPath -notmatch '\.json$') {
            $OutputPath = $OutputPath -replace '\.[^.]+$', '.json'
        }
    }
    default {
        $changelogContent = New-MarkdownChangelog -GroupedCommits $groupedCommits -AllCommits $commits
        if ($OutputPath -notmatch '\.md$') {
            $OutputPath = $OutputPath -replace '\.[^.]+$', '.md'
        }
    }
}

# Save changelog
$success = Save-Changelog -Content $changelogContent -FilePath $OutputPath

if ($success) {
    Write-ColorOutput "`nChangelog generation completed successfully!" "Green"
    Write-ColorOutput "Output file: $OutputPath" "Cyan"
    Write-ColorOutput "Total commits processed: $($commits.Count)" "Cyan"
    exit 0
} else {
    Write-ColorOutput "`nChangelog generation failed!" "Red"
    exit 1
}