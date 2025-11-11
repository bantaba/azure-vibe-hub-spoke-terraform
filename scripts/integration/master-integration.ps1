# Master Integration Script
# Main entry point for all integration workflows
# Provides a unified interface for connecting all components

param(
    [Parameter(Mandatory=$false)]
    [ValidateSet("setup", "task-complete", "security-scan", "validate", "status")]
    [string]$Action = "status",
    
    [Parameter(Mandatory=$false)]
    [string]$TaskName = "",
    
    [Parameter(Mandatory=$false)]
    [string]$TaskId = "",
    
    [Parameter(Mandatory=$false)]
    [ValidateSet("setup", "security", "sast", "cicd", "terraform", "docs", "test", "fix", "refactor")]
    [string]$TaskType = "",
    
    [Parameter(Mandatory=$false)]
    [switch]$SkipCommit = $false,
    
    [Parameter(Mandatory=$false)]
    [switch]$SkipScan = $false,
    
    [Parameter(Mandatory=$false)]
    [switch]$SkipDocs = $false,
    
    [Parameter(Mandatory=$false)]
    [switch]$DryRun = $false,
    
    [Parameter(Mandatory=$false)]
    [switch]$VerboseOutput = $false,
    
    [Parameter(Mandatory=$false)]
    [switch]$Help = $false
)

# Script configuration
$script:ScriptPath = Split-Path -Parent $MyInvocation.MyCommand.Path
$script:RootPath = Split-Path -Parent (Split-Path -Parent $script:ScriptPath)

# Show help
if ($Help) {
    Write-Host @"
Master Integration Script - Terraform Security Enhancement

DESCRIPTION:
    Unified interface for all integration workflows including auto-commit system,
    SAST tools integration, CI/CD pipeline connection, and documentation updates.

USAGE:
    .\master-integration.ps1 -Action <action> [options]

ACTIONS:
    setup           Initialize and validate all integration components
    task-complete   Execute task completion workflow (auto-commit + integrations)
    security-scan   Run security scan and update documentation
    validate        Validate all integration components and configurations
    status          Show current integration status and health

PARAMETERS:
    -TaskName       Task description (required for task-complete action)
    -TaskId         Task identifier (e.g., "9.1", "2.3")
    -TaskType       Type of task (auto-detected if not specified)
    -SkipCommit     Skip auto-commit integration
    -SkipScan       Skip security scan integration
    -SkipDocs       Skip documentation updates
    -DryRun         Show what would be done without executing
    -VerboseOutput  Enable verbose output
    -Help           Show this help message

EXAMPLES:
    # Show integration status
    .\master-integration.ps1 -Action status

    # Complete a task with full integration
    .\master-integration.ps1 -Action task-complete -TaskName "Integrate all components" -TaskId "9.1"

    # Run security scan only
    .\master-integration.ps1 -Action security-scan

    # Validate all integrations
    .\master-integration.ps1 -Action validate

    # Setup integration (dry run)
    .\master-integration.ps1 -Action setup -DryRun

    # Task completion without security scan
    .\master-integration.ps1 -Action task-complete -TaskName "Update docs" -SkipScan

"@ -ForegroundColor Cyan
    exit 0
}

# Function to write colored output
function Write-ColorOutput {
    param(
        [string]$Message,
        [string]$Color = "White"
    )
    
    if ($VerboseOutput) {
        $timestamp = Get-Date -Format "HH:mm:ss"
        $Message = "[$timestamp] $Message"
    }
    
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

# Function to check if required scripts exist
function Test-IntegrationScripts {
    $requiredScripts = @{
        "Integration Orchestrator" = "scripts/integration/integration-orchestrator.ps1"
        "Task Completion Hook" = "scripts/integration/task-completion-hook.ps1"
        "CI/CD Integration Config" = "scripts/integration/cicd-integration-config.ps1"
        "Documentation Integration" = "scripts/integration/documentation-integration.ps1"
        "Auto-Commit Wrapper" = "scripts/git/auto-commit-wrapper.ps1"
        "SAST Scanner" = "security/scripts/run-sast-scan.ps1"
    }
    
    $missingScripts = @()
    
    foreach ($script in $requiredScripts.GetEnumerator()) {
        if (-not (Test-Path $script.Value)) {
            $missingScripts += $script.Key
        }
    }
    
    return @{
        "total" = $requiredScripts.Count
        "missing" = $missingScripts
        "available" = $requiredScripts.Count - $missingScripts.Count
    }
}

# Function to setup integration environment
function Invoke-IntegrationSetup {
    Write-ColorOutput "=== Integration Setup ===" "Cyan"
    
    # Check git repository
    try {
        $null = git rev-parse --git-dir 2>$null
        Write-ColorOutput "✓ Git repository detected" "Green"
    }
    catch {
        Write-ColorOutput "✗ Not in a git repository" "Red"
        return $false
    }
    
    # Create required directories
    $requiredDirs = @(
        "scripts/integration",
        "security/reports", 
        "docs/security",
        "docs/tasks"
    )
    
    foreach ($dir in $requiredDirs) {
        if (-not (Test-Path $dir)) {
            if (-not $DryRun) {
                New-Item -ItemType Directory -Path $dir -Force | Out-Null
            }
            Write-ColorOutput "✓ Created directory: $dir" "Green"
        } else {
            Write-ColorOutput "✓ Directory exists: $dir" "Green"
        }
    }
    
    # Validate integration scripts
    $scriptStatus = Test-IntegrationScripts
    Write-ColorOutput "Integration scripts: $($scriptStatus.available)/$($scriptStatus.total) available" $(if ($scriptStatus.missing.Count -eq 0) { "Green" } else { "Yellow" })
    
    if ($scriptStatus.missing.Count -gt 0) {
        Write-ColorOutput "Missing scripts:" "Yellow"
        $scriptStatus.missing | ForEach-Object { Write-ColorOutput "  - $_" "Yellow" }
    }
    
    # Test CI/CD integration
    $cicdConfigPath = "scripts/integration/cicd-integration-config.ps1"
    if (Test-Path $cicdConfigPath) {
        Write-ColorOutput "Validating CI/CD integration..." "Blue"
        if (-not $DryRun) {
            & $cicdConfigPath -Platform "validate" -ValidateOnly
            $cicdResult = $LASTEXITCODE
            if ($cicdResult -eq 0) {
                Write-ColorOutput "✓ CI/CD integration validated" "Green"
            } else {
                Write-ColorOutput "⚠ CI/CD integration needs improvement" "Yellow"
            }
        }
    }
    
    Write-ColorOutput "Integration setup completed" "Green"
    return $true
}

# Function to execute task completion workflow
function Invoke-TaskCompletionWorkflow {
    param([string]$TaskName, [string]$TaskId, [string]$TaskType)
    
    Write-ColorOutput "=== Task Completion Workflow ===" "Cyan"
    Write-ColorOutput "Task: $TaskName" "Yellow"
    
    if (-not $TaskName) {
        Write-ColorOutput "Error: Task name is required for task completion workflow" "Red"
        return $false
    }
    
    $hookPath = "scripts/integration/task-completion-hook.ps1"
    if (-not (Test-Path $hookPath)) {
        Write-ColorOutput "Error: Task completion hook not found: $hookPath" "Red"
        return $false
    }
    
    # Build arguments for task completion hook
    $hookArgs = @{
        "TaskName" = $TaskName
        "DryRun" = $DryRun
        "Verbose" = $VerboseOutput
    }
    
    if ($TaskId) { $hookArgs["TaskId"] = $TaskId }
    if ($TaskType) { $hookArgs["TaskType"] = $TaskType }
    if ($SkipScan) { $hookArgs["SkipSecurityScan"] = $true }
    if ($SkipDocs) { $hookArgs["SkipDocumentationUpdate"] = $true }
    
    # Execute task completion hook
    & $hookPath @hookArgs
    $hookResult = $LASTEXITCODE
    
    if ($hookResult -eq 0) {
        Write-ColorOutput "Task completion workflow executed successfully" "Green"
        return $true
    } else {
        Write-ColorOutput "Task completion workflow failed" "Red"
        return $false
    }
}

# Function to execute security scan workflow
function Invoke-SecurityScanWorkflow {
    Write-ColorOutput "=== Security Scan Workflow ===" "Cyan"
    
    $orchestratorPath = "scripts/integration/integration-orchestrator.ps1"
    if (-not (Test-Path $orchestratorPath)) {
        Write-ColorOutput "Error: Integration orchestrator not found: $orchestratorPath" "Red"
        return $false
    }
    
    # Execute security scan integration
    $scanArgs = @{
        "IntegrationType" = "security-scan"
        "DryRun" = $DryRun
        "Verbose" = $VerboseOutput
    }
    
    & $orchestratorPath @scanArgs
    $scanResult = $LASTEXITCODE
    
    if ($scanResult -eq 0) {
        Write-ColorOutput "Security scan workflow executed successfully" "Green"
        return $true
    } else {
        Write-ColorOutput "Security scan workflow failed" "Red"
        return $false
    }
}

# Function to validate all integrations
function Invoke-IntegrationValidation {
    Write-ColorOutput "=== Integration Validation ===" "Cyan"
    
    $validationResults = @{
        "scripts" = $false
        "cicd" = $false
        "git" = $false
        "security" = $false
    }
    
    # Validate integration scripts
    $scriptStatus = Test-IntegrationScripts
    $validationResults.scripts = ($scriptStatus.missing.Count -eq 0)
    Write-ColorOutput "Integration Scripts: $(if ($validationResults.scripts) { 'PASS' } else { 'FAIL' })" $(if ($validationResults.scripts) { "Green" } else { "Red" })
    
    # Validate CI/CD integration
    $cicdConfigPath = "scripts/integration/cicd-integration-config.ps1"
    if (Test-Path $cicdConfigPath) {
        & $cicdConfigPath -Platform "validate" -ValidateOnly
        $validationResults.cicd = ($LASTEXITCODE -eq 0)
    }
    Write-ColorOutput "CI/CD Integration: $(if ($validationResults.cicd) { 'PASS' } else { 'FAIL' })" $(if ($validationResults.cicd) { "Green" } else { "Red" })
    
    # Validate git repository
    try {
        $null = git rev-parse --git-dir 2>$null
        $validationResults.git = $true
    }
    catch {
        $validationResults.git = $false
    }
    Write-ColorOutput "Git Repository: $(if ($validationResults.git) { 'PASS' } else { 'FAIL' })" $(if ($validationResults.git) { "Green" } else { "Red" })
    
    # Validate security tools
    $sastScanPath = "security/scripts/run-sast-scan.ps1"
    $validationResults.security = (Test-Path $sastScanPath)
    Write-ColorOutput "Security Tools: $(if ($validationResults.security) { 'PASS' } else { 'FAIL' })" $(if ($validationResults.security) { "Green" } else { "Red" })
    
    # Overall validation result
    $overallPass = $validationResults.Values | ForEach-Object { $_ } | Where-Object { $_ -eq $true }
    $passCount = $overallPass.Count
    $totalCount = $validationResults.Count
    
    Write-ColorOutput "`nValidation Summary: $passCount/$totalCount components passed" $(if ($passCount -eq $totalCount) { "Green" } else { "Yellow" })
    
    return ($passCount -eq $totalCount)
}

# Function to show integration status
function Show-IntegrationStatus {
    Write-ColorOutput "=== Integration Status ===" "Cyan"
    
    # Check integration components
    $components = @{
        "Auto-Commit System" = @{
            "path" = "scripts/git/auto-commit-wrapper.ps1"
            "description" = "Automated git commits on task completion"
        }
        "SAST Integration" = @{
            "path" = "security/scripts/run-sast-scan.ps1"
            "description" = "Security scanning with Checkov, TFSec, Terrascan"
        }
        "CI/CD Pipeline" = @{
            "path" = ".github/workflows/terraform-security-scan.yml"
            "description" = "GitHub Actions workflow for security validation"
        }
        "Documentation System" = @{
            "path" = "scripts/integration/documentation-integration.ps1"
            "description" = "Automated documentation updates and change tracking"
        }
        "Integration Orchestrator" = @{
            "path" = "scripts/integration/integration-orchestrator.ps1"
            "description" = "Main integration workflow coordinator"
        }
    }
    
    Write-ColorOutput "`nComponent Status:" "Yellow"
    foreach ($component in $components.GetEnumerator()) {
        $status = if (Test-Path $component.Value.path) { "✓ ACTIVE" } else { "✗ MISSING" }
        $color = if (Test-Path $component.Value.path) { "Green" } else { "Red" }
        
        Write-ColorOutput "  $($component.Key): $status" $color
        if ($VerboseOutput) {
            Write-ColorOutput "    $($component.Value.description)" "Gray"
            Write-ColorOutput "    Path: $($component.Value.path)" "Gray"
        }
    }
    
    # Check recent activity
    Write-ColorOutput "`nRecent Integration Activity:" "Yellow"
    try {
        $recentCommits = git log --oneline --grep="feat\|security\|ci\|docs" -n 5 --format="%h %s" 2>$null
        if ($recentCommits) {
            $recentCommits | ForEach-Object { Write-ColorOutput "  $_" "Gray" }
        } else {
            Write-ColorOutput "  No recent integration activity found" "Gray"
        }
    }
    catch {
        Write-ColorOutput "  Could not retrieve git history" "Gray"
    }
    
    # Check security scan results
    $scanResultsPath = "security/reports/unified-sast-report.json"
    if (Test-Path $scanResultsPath) {
        try {
            $scanResults = Get-Content $scanResultsPath -Raw | ConvertFrom-Json
            Write-ColorOutput "`nLatest Security Scan:" "Yellow"
            Write-ColorOutput "  Timestamp: $($scanResults.timestamp)" "Gray"
            Write-ColorOutput "  Total Issues: $($scanResults.scan_summary.total_issues)" "Gray"
            Write-ColorOutput "  Critical: $($scanResults.scan_summary.critical_issues)" $(if ($scanResults.scan_summary.critical_issues -gt 0) { "Red" } else { "Green" })
            Write-ColorOutput "  High: $($scanResults.scan_summary.high_issues)" $(if ($scanResults.scan_summary.high_issues -gt 0) { "Red" } else { "Green" })
        }
        catch {
            Write-ColorOutput "  Could not parse security scan results" "Gray"
        }
    } else {
        Write-ColorOutput "`nLatest Security Scan: No results found" "Yellow"
    }
}

# Main execution
Write-ColorOutput "Master Integration Script - Terraform Security Enhancement" "Green"
Write-ColorOutput "==========================================================" "Green"
Write-ColorOutput "Action: $Action" "Gray"
Write-ColorOutput "Dry Run: $DryRun" "Gray"

$actionResult = $false

try {
    switch ($Action) {
        "setup" {
            $actionResult = Invoke-IntegrationSetup
        }
        "task-complete" {
            $actionResult = Invoke-TaskCompletionWorkflow -TaskName $TaskName -TaskId $TaskId -TaskType $TaskType
        }
        "security-scan" {
            $actionResult = Invoke-SecurityScanWorkflow
        }
        "validate" {
            $actionResult = Invoke-IntegrationValidation
        }
        "status" {
            Show-IntegrationStatus
            $actionResult = $true
        }
        default {
            Write-ColorOutput "Error: Unknown action: $Action" "Red"
            Write-ColorOutput "Use -Help for usage information" "Yellow"
            exit 1
        }
    }
    
    if ($actionResult) {
        Write-ColorOutput "`nMaster integration action '$Action' completed successfully!" "Green"
        exit 0
    } else {
        Write-ColorOutput "`nMaster integration action '$Action' failed!" "Red"
        exit 1
    }
}
catch {
    Write-ColorOutput "Critical error in master integration: $($_.Exception.Message)" "Red"
    exit 1
}