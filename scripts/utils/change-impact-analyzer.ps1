# Change Impact Analyzer Script
# This script analyzes the impact of changes in the Terraform project

param(
    [string]$Since = "",
    [string]$Until = "HEAD",
    [string]$OutputFormat = "markdown",
    [string]$OutputPath = "docs/changelog/impact-analysis.md",
    [switch]$IncludeFileAnalysis = $true,
    [switch]$IncludeSecurityAnalysis = $true,
    [switch]$Verbose = $false
)

# Configuration
$script:SecurityPatterns = @(
    @{ Pattern = "password|secret|key|token"; Category = "Credentials"; Severity = "High" }
    @{ Pattern = "encrypt|decrypt|cipher"; Category = "Encryption"; Severity = "Medium" }
    @{ Pattern = "auth|rbac|permission|role"; Category = "Authentication"; Severity = "Medium" }
    @{ Pattern = "network|firewall|nsg|security_group"; Category = "Network Security"; Severity = "Medium" }
    @{ Pattern = "storage|blob|container"; Category = "Data Storage"; Severity = "Low" }
    @{ Pattern = "monitor|log|audit"; Category = "Monitoring"; Severity = "Low" }
)

$script:ImpactCategories = @{
    "Critical" = @{ Icon = "🚨"; Color = "Red"; Description = "Breaking changes requiring immediate attention" }
    "High" = @{ Icon = "⚠️"; Color = "Yellow"; Description = "Significant changes requiring careful review" }
    "Medium" = @{ Icon = "📋"; Color = "Blue"; Description = "Notable changes with moderate impact" }
    "Low" = @{ Icon = "ℹ️"; Color = "Gray"; Description = "Minor changes with minimal impact" }
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
            "yellow" { Write-Host $Message -ForegroundColor Yellow }
            "blue" { Write-Host $Message -ForegroundColor Blue }
            "green" { Write-Host $Message -ForegroundColor Green }
            "cyan" { Write-Host $Message -ForegroundColor Cyan }
            "gray" { Write-Host $Message -ForegroundColor Gray }
            default { Write-Host $Message }
        }
    }
}

# Function to get file changes
function Get-FileChanges {
    param(
        [string]$Since,
        [string]$Until
    )
    
    Write-ColorOutput "Analyzing file changes..." "Blue"
    
    $gitArgs = @("diff", "--name-status")
    if ($Since) {
        $gitArgs += "$Since..$Until"
    } else {
        $gitArgs += $Until
    }
    
    try {
        $changes = & git @gitArgs 2>&1
        if ($LASTEXITCODE -ne 0) {
            Write-ColorOutput "Error getting file changes: $changes" "Red"
            return @()
        }
        
        $fileChanges = @()
        foreach ($line in $changes) {
            if ($line -match '^([AMD])\s+(.+)$') {
                $status = $Matches[1]
                $file = $Matches[2]
                
                $changeType = switch ($status) {
                    "A" { "Added" }
                    "M" { "Modified" }
                    "D" { "Deleted" }
                    default { "Unknown" }
                }
                
                $fileChanges += @{
                    File = $file
                    Status = $changeType
                    Extension = [System.IO.Path]::GetExtension($file)
                    Directory = [System.IO.Path]::GetDirectoryName($file)
                }
            }
        }
        
        return $fileChanges
    } catch {
        Write-ColorOutput "Error analyzing file changes: $_" "Red"
        return @()
    }
}

# Function to analyze security impact
function Get-SecurityImpact {
    param([array]$FileChanges)
    
    Write-ColorOutput "Analyzing security impact..." "Blue"
    
    $securityImpact = @{
        TotalSecurityFiles = 0
        HighRiskChanges = 0
        MediumRiskChanges = 0
        LowRiskChanges = 0
        SecurityCategories = @{}
        AffectedFiles = @()
    }
    
    foreach ($change in $FileChanges) {
        $file = $change.File
        $isSecurityRelated = $false
        
        # Check if file is in security-related directories
        if ($file -match "security|auth|rbac|key|vault|encrypt") {
            $isSecurityRelated = $true
        }
        
        # Check file content patterns (for existing files)
        if ((Test-Path $file) -and ($change.Status -ne "Deleted")) {
            try {
                $content = Get-Content $file -Raw -ErrorAction SilentlyContinue
                if ($content) {
                    foreach ($pattern in $script:SecurityPatterns) {
                        if ($content -match $pattern.Pattern) {
                            $isSecurityRelated = $true
                            
                            if (!$securityImpact.SecurityCategories.ContainsKey($pattern.Category)) {
                                $securityImpact.SecurityCategories[$pattern.Category] = @{
                                    Count = 0
                                    Severity = $pattern.Severity
                                    Files = @()
                                }
                            }
                            
                            $securityImpact.SecurityCategories[$pattern.Category].Count++
                            $securityImpact.SecurityCategories[$pattern.Category].Files += $file
                            
                            switch ($pattern.Severity) {
                                "High" { $securityImpact.HighRiskChanges++ }
                                "Medium" { $securityImpact.MediumRiskChanges++ }
                                "Low" { $securityImpact.LowRiskChanges++ }
                            }
                            
                            break
                        }
                    }
                }
            } catch {
                # Error reading file content
            }
        }
        
        if ($isSecurityRelated) {
            $securityImpact.TotalSecurityFiles++
            $securityImpact.AffectedFiles += $change
        }
    }
    
    return $securityImpact
}

# Function to analyze infrastructure impact
function Get-InfrastructureImpact {
    param([array]$FileChanges)
    
    Write-ColorOutput "Analyzing infrastructure impact..." "Blue"
    
    $infraImpact = @{
        TerraformFiles = 0
        ModuleChanges = 0
        ConfigChanges = 0
        ScriptChanges = 0
        DocumentationChanges = 0
        AffectedModules = @()
        ImpactLevel = "Low"
    }
    
    foreach ($change in $FileChanges) {
        $file = $change.File
        $extension = $change.Extension
        $directory = $change.Directory
        
        # Categorize changes
        if ($extension -eq ".tf" -or $extension -eq ".tfvars") {
            $infraImpact.TerraformFiles++
            
            if ($directory -match "modules") {
                $infraImpact.ModuleChanges++
                $moduleName = ($directory -split "[\\/]" | Where-Object { $_ -ne "modules" })[0]
                if ($moduleName -and $infraImpact.AffectedModules -notcontains $moduleName) {
                    $infraImpact.AffectedModules += $moduleName
                }
            } else {
                $infraImpact.ConfigChanges++
            }
        } elseif ($extension -eq ".ps1" -or $extension -eq ".sh") {
            $infraImpact.ScriptChanges++
        } elseif ($extension -eq ".md" -or $extension -eq ".txt") {
            $infraImpact.DocumentationChanges++
        }
    }
    
    # Determine impact level
    if ($infraImpact.ModuleChanges -gt 0 -or $infraImpact.ConfigChanges -gt 3) {
        $infraImpact.ImpactLevel = "High"
    } elseif ($infraImpact.TerraformFiles -gt 0 -or $infraImpact.ScriptChanges -gt 2) {
        $infraImpact.ImpactLevel = "Medium"
    } else {
        $infraImpact.ImpactLevel = "Low"
    }
    
    return $infraImpact
}

# Function to get commit analysis
function Get-CommitAnalysis {
    param(
        [string]$Since,
        [string]$Until
    )
    
    Write-ColorOutput "Analyzing commits..." "Blue"
    
    $gitArgs = @("log", "--pretty=format:%H|%s|%an|%ad|%B", "--date=short")
    if ($Since) {
        $gitArgs += "$Since..$Until"
    } else {
        $gitArgs += $Until
    }
    
    try {
        $output = & git @gitArgs 2>&1
        if ($LASTEXITCODE -ne 0) {
            Write-ColorOutput "Error getting commits: $output" "Red"
            return @{}
        }
        
        $commits = @()
        $currentCommit = @{}
        
        foreach ($line in $output) {
            if ($line -match '^([a-f0-9]+)\|(.+)\|(.+)\|(.+)\|(.*)$') {
                # New commit
                if ($currentCommit.Count -gt 0) {
                    $commits += $currentCommit
                }
                
                $currentCommit = @{
                    Hash = $Matches[1]
                    Subject = $Matches[2]
                    Author = $Matches[3]
                    Date = $Matches[4]
                    Body = $Matches[5]
                    Type = "other"
                    Scope = ""
                    IsBreaking = $false
                    SecurityRelated = $false
                }
                
                # Parse conventional commit
                if ($currentCommit.Subject -match '^(\w+)(\([^)]+\))?\s*:\s*(.+)') {
                    $currentCommit.Type = $Matches[1].ToLower()
                    $currentCommit.Scope = if ($Matches[2]) { $Matches[2].Trim('()') } else { "" }
                    $currentCommit.Subject = $Matches[3]
                }
                
                # Check for breaking changes
                if ($currentCommit.Subject -match '!:' -or $currentCommit.Body -match 'BREAKING CHANGE') {
                    $currentCommit.IsBreaking = $true
                }
                
                # Check for security-related changes
                if ($currentCommit.Subject -match 'security|auth|encrypt|rbac|vulnerability' -or 
                    $currentCommit.Body -match 'security|auth|encrypt|rbac|vulnerability') {
                    $currentCommit.SecurityRelated = $true
                }
            } else {
                # Continuation of commit body
                if ($currentCommit.Count -gt 0) {
                    $currentCommit.Body += "`n$line"
                }
            }
        }
        
        # Add last commit
        if ($currentCommit.Count -gt 0) {
            $commits += $currentCommit
        }
        
        return $commits
    } catch {
        Write-ColorOutput "Error analyzing commits: $_" "Red"
        return @()
    }
}

# Function to generate impact analysis report
function New-ImpactAnalysisReport {
    param(
        [array]$FileChanges,
        [array]$Commits,
        [hashtable]$SecurityImpact,
        [hashtable]$InfraImpact
    )
    
    Write-ColorOutput "Generating impact analysis report..." "Blue"
    
    $report = @()
    $report += "# Change Impact Analysis"
    $report += ""
    $report += "**Analysis Date:** $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')"
    $report += "**Analysis Period:** $(if ($Since) { $Since } else { 'Beginning' }) to $Until"
    $report += "**Total Commits:** $($Commits.Count)"
    $report += "**Total Files Changed:** $($FileChanges.Count)"
    $report += ""
    
    # Overall impact assessment
    $overallImpact = "Low"
    if ($SecurityImpact.HighRiskChanges -gt 0 -or $InfraImpact.ImpactLevel -eq "High") {
        $overallImpact = "Critical"
    } elseif ($SecurityImpact.MediumRiskChanges -gt 0 -or $InfraImpact.ImpactLevel -eq "Medium") {
        $overallImpact = "High"
    } elseif ($SecurityImpact.LowRiskChanges -gt 0 -or $InfraImpact.ImpactLevel -eq "Low") {
        $overallImpact = "Medium"
    }
    
    $impactInfo = $script:ImpactCategories[$overallImpact]
    $report += "## Overall Impact: $($impactInfo.Icon) $overallImpact"
    $report += ""
    $report += $impactInfo.Description
    $report += ""
    
    # Security impact section
    $report += "## Security Impact Analysis"
    $report += ""
    
    if ($SecurityImpact.TotalSecurityFiles -gt 0) {
        $report += "### Security Risk Assessment"
        $report += ""
        $report += "- **High Risk Changes:** $($SecurityImpact.HighRiskChanges)"
        $report += "- **Medium Risk Changes:** $($SecurityImpact.MediumRiskChanges)"
        $report += "- **Low Risk Changes:** $($SecurityImpact.LowRiskChanges)"
        $report += "- **Total Security-Related Files:** $($SecurityImpact.TotalSecurityFiles)"
        $report += ""
        
        if ($SecurityImpact.SecurityCategories.Count -gt 0) {
            $report += "### Security Categories Affected"
            $report += ""
            foreach ($category in $SecurityImpact.SecurityCategories.Keys) {
                $categoryData = $SecurityImpact.SecurityCategories[$category]
                $severityIcon = switch ($categoryData.Severity) {
                    "High" { "🔴" }
                    "Medium" { "🟡" }
                    "Low" { "🟢" }
                    default { "⚪" }
                }
                $report += "- $severityIcon **$category** ($($categoryData.Severity) Risk): $($categoryData.Count) changes"
            }
            $report += ""
        }
        
        if ($SecurityImpact.AffectedFiles.Count -gt 0) {
            $report += "### Security-Related Files Changed"
            $report += ""
            foreach ($file in $SecurityImpact.AffectedFiles) {
                $statusIcon = switch ($file.Status) {
                    "Added" { "➕" }
                    "Modified" { "📝" }
                    "Deleted" { "❌" }
                    default { "📄" }
                }
                $report += "- $statusIcon ``$($file.File)`` ($($file.Status))"
            }
            $report += ""
        }
    } else {
        $report += "No security-related changes detected in this analysis period."
        $report += ""
    }
    
    # Infrastructure impact section
    $report += "## Infrastructure Impact Analysis"
    $report += ""
    $report += "### Change Summary"
    $report += ""
    $report += "- **Terraform Files:** $($InfraImpact.TerraformFiles)"
    $report += "- **Module Changes:** $($InfraImpact.ModuleChanges)"
    $report += "- **Configuration Changes:** $($InfraImpact.ConfigChanges)"
    $report += "- **Script Changes:** $($InfraImpact.ScriptChanges)"
    $report += "- **Documentation Changes:** $($InfraImpact.DocumentationChanges)"
    $report += "- **Impact Level:** $($InfraImpact.ImpactLevel)"
    $report += ""
    
    if ($InfraImpact.AffectedModules.Count -gt 0) {
        $report += "### Affected Modules"
        $report += ""
        foreach ($module in $InfraImpact.AffectedModules) {
            $report += "- 📦 ``$module``"
        }
        $report += ""
    }
    
    # Commit analysis section
    $report += "## Commit Analysis"
    $report += ""
    
    $commitTypes = @{}
    $breakingChanges = 0
    $securityCommits = 0
    
    foreach ($commit in $Commits) {
        if (!$commitTypes.ContainsKey($commit.Type)) {
            $commitTypes[$commit.Type] = 0
        }
        $commitTypes[$commit.Type]++
        
        if ($commit.IsBreaking) {
            $breakingChanges++
        }
        
        if ($commit.SecurityRelated) {
            $securityCommits++
        }
    }
    
    $report += "### Commit Type Distribution"
    $report += ""
    foreach ($type in $commitTypes.Keys | Sort-Object) {
        $count = $commitTypes[$type]
        $typeIcon = switch ($type) {
            "feat" { "✨" }
            "fix" { "🐛" }
            "docs" { "📚" }
            "security" { "🔒" }
            "refactor" { "♻️" }
            "test" { "✅" }
            "chore" { "🔧" }
            default { "📝" }
        }
        $report += "- $typeIcon **$type**: $count commits"
    }
    $report += ""
    
    if ($breakingChanges -gt 0) {
        $report += "### ⚠️ Breaking Changes"
        $report += ""
        $report += "This analysis period includes **$breakingChanges breaking changes** that may require:"
        $report += ""
        $report += "- Configuration updates"
        $report += "- Migration procedures"
        $report += "- Testing and validation"
        $report += "- Documentation updates"
        $report += ""
    }
    
    if ($securityCommits -gt 0) {
        $report += "### 🔒 Security-Related Commits"
        $report += ""
        $report += "Found **$securityCommits security-related commits** that should be:"
        $report += ""
        $report += "- Reviewed by security team"
        $report += "- Tested thoroughly"
        $report += "- Documented appropriately"
        $report += "- Monitored post-deployment"
        $report += ""
    }
    
    # Recommendations section
    $report += "## Recommendations"
    $report += ""
    
    if ($overallImpact -eq "Critical") {
        $report += "### 🚨 Critical Impact - Immediate Action Required"
        $report += ""
        $report += "1. **Security Review**: Conduct thorough security review of all changes"
        $report += "2. **Testing**: Perform comprehensive testing in staging environment"
        $report += "3. **Rollback Plan**: Prepare detailed rollback procedures"
        $report += "4. **Monitoring**: Implement enhanced monitoring during deployment"
        $report += "5. **Communication**: Notify all stakeholders of potential impact"
    } elseif ($overallImpact -eq "High") {
        $report += "### ⚠️ High Impact - Careful Review Required"
        $report += ""
        $report += "1. **Code Review**: Ensure thorough code review by senior team members"
        $report += "2. **Testing**: Test all affected modules and configurations"
        $report += "3. **Documentation**: Update relevant documentation"
        $report += "4. **Staged Deployment**: Consider phased deployment approach"
    } else {
        $report += "### ℹ️ Standard Deployment Process"
        $report += ""
        $report += "1. **Standard Review**: Follow normal code review process"
        $report += "2. **Basic Testing**: Run standard test suite"
        $report += "3. **Documentation**: Update documentation as needed"
        $report += "4. **Deploy**: Proceed with standard deployment process"
    }
    
    $report += ""
    
    # File changes section
    if ($FileChanges.Count -gt 0) {
        $report += "## Detailed File Changes"
        $report += ""
        
        $changesByType = @{}
        foreach ($change in $FileChanges) {
            if (!$changesByType.ContainsKey($change.Status)) {
                $changesByType[$change.Status] = @()
            }
            $changesByType[$change.Status] += $change
        }
        
        foreach ($status in @("Added", "Modified", "Deleted")) {
            if ($changesByType.ContainsKey($status)) {
                $statusIcon = switch ($status) {
                    "Added" { "➕" }
                    "Modified" { "📝" }
                    "Deleted" { "❌" }
                }
                
                $report += "### $statusIcon $status Files ($($changesByType[$status].Count))"
                $report += ""
                
                foreach ($change in $changesByType[$status]) {
                    $report += "- ``$($change.File)``"
                }
                $report += ""
            }
        }
    }
    
    # Metadata
    $report += "---"
    $report += ""
    $report += "*This impact analysis was automatically generated on $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss') UTC*"
    $report += ""
    $report += "**Analysis Parameters:**"
    $report += "- Since: $(if ($Since) { $Since } else { 'Beginning of history' })"
    $report += "- Until: $Until"
    $report += "- Include File Analysis: $IncludeFileAnalysis"
    $report += "- Include Security Analysis: $IncludeSecurityAnalysis"
    
    return $report -join "`n"
}

# Main execution
Write-ColorOutput "Change Impact Analyzer" "Green"
Write-ColorOutput "=====================" "Green"

# Validate git repository
if (!(Test-Path ".git")) {
    Write-ColorOutput "Error: Not in a git repository" "Red"
    exit 1
}

# Get file changes
$fileChanges = @()
if ($IncludeFileAnalysis) {
    $fileChanges = Get-FileChanges -Since $Since -Until $Until
}

# Get commit analysis
$commits = Get-CommitAnalysis -Since $Since -Until $Until

# Analyze security impact
$securityImpact = @{}
if ($IncludeSecurityAnalysis -and $fileChanges.Count -gt 0) {
    $securityImpact = Get-SecurityImpact -FileChanges $fileChanges
}

# Analyze infrastructure impact
$infraImpact = @{}
if ($fileChanges.Count -gt 0) {
    $infraImpact = Get-InfrastructureImpact -FileChanges $fileChanges
}

# Generate report
$report = New-ImpactAnalysisReport -FileChanges $fileChanges -Commits $commits -SecurityImpact $securityImpact -InfraImpact $infraImpact

# Save report
try {
    $directory = Split-Path -Parent $OutputPath
    if ($directory -and !(Test-Path $directory)) {
        New-Item -ItemType Directory -Path $directory -Force | Out-Null
        Write-ColorOutput "Created directory: $directory" "Yellow"
    }
    
    $report | Out-File -FilePath $OutputPath -Encoding UTF8
    Write-ColorOutput "Impact analysis report saved: $OutputPath" "Green"
    
    # Display summary
    Write-ColorOutput "`nAnalysis Summary:" "Cyan"
    Write-ColorOutput "- Total Commits: $($commits.Count)" "Gray"
    Write-ColorOutput "- Total Files Changed: $($fileChanges.Count)" "Gray"
    if ($securityImpact.Count -gt 0) {
        Write-ColorOutput "- Security-Related Files: $($securityImpact.TotalSecurityFiles)" "Yellow"
    }
    if ($infraImpact.Count -gt 0) {
        Write-ColorOutput "- Infrastructure Impact: $($infraImpact.ImpactLevel)" "Cyan"
    }
    
    exit 0
} catch {
    Write-ColorOutput "Error saving report: $_" "Red"
    exit 1
}