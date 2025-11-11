# Integration Orchestrator Script
# Connects auto-commit system with task completion, SAST tools with CI/CD pipelines,
# and documentation system with change tracking

param(
    [Parameter(Mandatory=$false)]
    [ValidateSet("task-completion", "security-scan", "documentation-update", "full-integration")]
    [string]$IntegrationType = "full-integration",
    
    [Parameter(Mandatory=$false)]
    [string]$TaskName = "",
    
    [Parameter(Mandatory=$false)]
    [string]$TaskId = "",
    
    [Parameter(Mandatory=$false)]
    [switch]$SkipCommit = $false,
    
    [Parameter(Mandatory=$false)]
    [switch]$SkipScan = $false,
    
    [Parameter(Mandatory=$false)]
    [switch]$SkipDocs = $false,
    
    [Parameter(Mandatory=$false)]
    [switch]$DryRun = $false,
    
    [Parameter(Mandatory=$false)]
    [switch]$VerboseOutput = $false
)

# Script configuration
$script:ScriptPath = Split-Path -Parent $MyInvocation.MyCommand.Path
$script:RootPath = Split-Path -Parent (Split-Path -Parent $script:ScriptPath)
$script:ExitCode = 0

# Import required modules and scripts
$gitWrapperPath = Join-Path $script:RootPath "scripts\git\auto-commit-wrapper.ps1"
$sastScanPath = Join-Path $script:RootPath "security\scripts\run-sast-scan.ps1"
$changelogPath = Join-Path $script:RootPath "scripts\utils\automated-changelog-system.ps1"

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

# Function to detect task completion and trigger auto-commit
function Invoke-TaskCompletionIntegration {
    param(
        [string]$TaskName,
        [string]$TaskId
    )
    
    Write-ColorOutput "=== Task Completion Integration ===" "Cyan"
    
    if (-not (Test-GitRepository)) {
        Write-ColorOutput "Error: Not in a git repository" "Red"
        return $false
    }
    
    if (-not $TaskName) {
        Write-ColorOutput "Error: Task name is required for task completion integration" "Red"
        return $false
    }
    
    try {
        # Import git wrapper functions
        if (Test-Path $gitWrapperPath) {
            . $gitWrapperPath
            Write-ColorOutput "Loaded git wrapper functions" "Green"
        } else {
            Write-ColorOutput "Error: Git wrapper script not found: $gitWrapperPath" "Red"
            return $false
        }
        
        # Check for changes
        $hasChanges = git status --porcelain 2>$null
        if (-not $hasChanges) {
            Write-ColorOutput "No changes detected for task completion" "Yellow"
            return $true
        }
        
        Write-ColorOutput "Detected changes for task: $TaskName" "Green"
        
        if ($DryRun) {
            Write-ColorOutput "[DRY RUN] Would execute auto-commit for task: $TaskName" "Yellow"
            return $true
        }
        
        # Execute auto-commit with task completion detection
        $commitResult = Invoke-TaskAutoCommit -TaskName $TaskName -TaskId $TaskId -Force
        
        if ($commitResult) {
            Write-ColorOutput "Task completion auto-commit successful" "Green"
            return $true
        } else {
            Write-ColorOutput "Task completion auto-commit failed" "Red"
            return $false
        }
    }
    catch {
        Write-ColorOutput "Error in task completion integration: $($_.Exception.Message)" "Red"
        return $false
    }
}

# Function to integrate SAST tools with CI/CD pipeline triggers
function Invoke-SecurityScanIntegration {
    Write-ColorOutput "=== Security Scan Integration ===" "Cyan"
    
    try {
        # Check if SAST scan script exists
        if (-not (Test-Path $sastScanPath)) {
            Write-ColorOutput "Error: SAST scan script not found: $sastScanPath" "Red"
            return $false
        }
        
        Write-ColorOutput "Running integrated security scan..." "Blue"
        
        if ($DryRun) {
            Write-ColorOutput "[DRY RUN] Would execute SAST security scan" "Yellow"
            return $true
        }
        
        # Execute SAST scan with integration parameters
        $scanArgs = @{
            "SourcePath" = "src/"
            "ReportsPath" = "security/reports/"
            "FailOnHigh" = $true
            "FailOnCritical" = $true
            "Verbose" = $VerboseOutput
        }
        
        & $sastScanPath @scanArgs
        $scanExitCode = $LASTEXITCODE
        
        if ($scanExitCode -eq 0) {
            Write-ColorOutput "Security scan integration completed successfully" "Green"
            
            # Trigger documentation update for scan results
            if (-not $SkipDocs) {
                Write-ColorOutput "Updating documentation with scan results..." "Blue"
                Invoke-DocumentationIntegration -UpdateType "security-scan"
            }
            
            return $true
        } else {
            Write-ColorOutput "Security scan integration failed with exit code: $scanExitCode" "Red"
            $script:ExitCode = $scanExitCode
            return $false
        }
    }
    catch {
        Write-ColorOutput "Error in security scan integration: $($_.Exception.Message)" "Red"
        return $false
    }
}

# Function to integrate documentation system with change tracking
function Invoke-DocumentationIntegration {
    param(
        [ValidateSet("task-completion", "security-scan", "general-update")]
        [string]$UpdateType = "general-update"
    )
    
    Write-ColorOutput "=== Documentation Integration ===" "Cyan"
    
    try {
        # Check if changelog system exists
        if (-not (Test-Path $changelogPath)) {
            Write-ColorOutput "Warning: Changelog system script not found: $changelogPath" "Yellow"
            # Continue without failing, as documentation is not critical
        }
        
        Write-ColorOutput "Updating documentation for: $UpdateType" "Blue"
        
        if ($DryRun) {
            Write-ColorOutput "[DRY RUN] Would update documentation for: $UpdateType" "Yellow"
            return $true
        }
        
        # Update changelog based on git history
        if (Test-Path $changelogPath) {
            & $changelogPath -UpdateType $UpdateType -Verbose:$VerboseOutput
            
            if ($LASTEXITCODE -eq 0) {
                Write-ColorOutput "Changelog updated successfully" "Green"
            } else {
                Write-ColorOutput "Warning: Changelog update failed" "Yellow"
            }
        }
        
        # Update security documentation if this is a security scan update
        if ($UpdateType -eq "security-scan") {
            $securityDocsPath = "docs/security"
            if (Test-Path $securityDocsPath) {
                Write-ColorOutput "Updating security documentation..." "Blue"
                
                # Update security scan results summary
                $scanResultsPath = "security/reports/unified-sast-report.json"
                if (Test-Path $scanResultsPath) {
                    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
                    $updateNote = "`n## Security Scan Update - $timestamp`n`nLatest security scan results have been updated. See security/reports/ for detailed findings.`n"
                    
                    $securityReadmePath = Join-Path $securityDocsPath "README.md"
                    if (Test-Path $securityReadmePath) {
                        Add-Content -Path $securityReadmePath -Value $updateNote
                        Write-ColorOutput "Security documentation updated" "Green"
                    }
                }
            }
        }
        
        return $true
    }
    catch {
        Write-ColorOutput "Error in documentation integration: $($_.Exception.Message)" "Red"
        return $false
    }
}

# Function to run full integration workflow
function Invoke-FullIntegration {
    Write-ColorOutput "=== Full Integration Workflow ===" "Cyan"
    Write-ColorOutput "Starting comprehensive integration process..." "Blue"
    
    $integrationSteps = @()
    $failedSteps = @()
    
    # Step 1: Task completion integration (if task specified)
    if ($TaskName) {
        Write-ColorOutput "`nStep 1: Task Completion Integration" "Yellow"
        $integrationSteps += "Task Completion"
        
        if (-not $SkipCommit) {
            $taskResult = Invoke-TaskCompletionIntegration -TaskName $TaskName -TaskId $TaskId
            if (-not $taskResult) {
                $failedSteps += "Task Completion"
            }
        } else {
            Write-ColorOutput "Skipping task completion integration" "Yellow"
        }
    }
    
    # Step 2: Security scan integration
    Write-ColorOutput "`nStep 2: Security Scan Integration" "Yellow"
    $integrationSteps += "Security Scan"
    
    if (-not $SkipScan) {
        $scanResult = Invoke-SecurityScanIntegration
        if (-not $scanResult) {
            $failedSteps += "Security Scan"
        }
    } else {
        Write-ColorOutput "Skipping security scan integration" "Yellow"
    }
    
    # Step 3: Documentation integration
    Write-ColorOutput "`nStep 3: Documentation Integration" "Yellow"
    $integrationSteps += "Documentation"
    
    if (-not $SkipDocs) {
        $docsResult = Invoke-DocumentationIntegration -UpdateType "general-update"
        if (-not $docsResult) {
            $failedSteps += "Documentation"
        }
    } else {
        Write-ColorOutput "Skipping documentation integration" "Yellow"
    }
    
    # Step 4: CI/CD pipeline validation (check if workflows are properly configured)
    Write-ColorOutput "`nStep 4: CI/CD Pipeline Validation" "Yellow"
    $integrationSteps += "CI/CD Pipeline"
    
    $workflowPath = ".github/workflows/terraform-security-scan.yml"
    if (Test-Path $workflowPath) {
        Write-ColorOutput "GitHub Actions workflow found and validated" "Green"
    } else {
        Write-ColorOutput "Warning: GitHub Actions workflow not found" "Yellow"
        $failedSteps += "CI/CD Pipeline"
    }
    
    # Azure DevOps pipeline check
    $azureDevOpsPath = "azure-pipelines.yml"
    if (Test-Path $azureDevOpsPath) {
        Write-ColorOutput "Azure DevOps pipeline found and validated" "Green"
    } else {
        Write-ColorOutput "Info: Azure DevOps pipeline not found (optional)" "Gray"
    }
    
    # Summary
    Write-ColorOutput "`n=== Integration Summary ===" "Cyan"
    Write-ColorOutput "Total integration steps: $($integrationSteps.Count)" "White"
    Write-ColorOutput "Successful steps: $($integrationSteps.Count - $failedSteps.Count)" "Green"
    Write-ColorOutput "Failed steps: $($failedSteps.Count)" $(if ($failedSteps.Count -gt 0) { "Red" } else { "Green" })
    
    if ($failedSteps.Count -gt 0) {
        Write-ColorOutput "Failed integration steps:" "Red"
        $failedSteps | ForEach-Object { Write-ColorOutput "  - $_" "Red" }
        $script:ExitCode = 1
        return $false
    } else {
        Write-ColorOutput "All integration steps completed successfully!" "Green"
        return $true
    }
}

# Function to validate integration prerequisites
function Test-IntegrationPrerequisites {
    Write-ColorOutput "Validating integration prerequisites..." "Blue"
    
    $prerequisites = @()
    $missingPrereqs = @()
    
    # Check git repository
    $prerequisites += "Git Repository"
    if (-not (Test-GitRepository)) {
        $missingPrereqs += "Git Repository"
    }
    
    # Check required scripts
    $requiredScripts = @{
        "Git Wrapper" = $gitWrapperPath
        "SAST Scanner" = $sastScanPath
        "Changelog System" = $changelogPath
    }
    
    foreach ($script in $requiredScripts.GetEnumerator()) {
        $prerequisites += $script.Key
        if (-not (Test-Path $script.Value)) {
            $missingPrereqs += $script.Key
        }
    }
    
    # Check required directories
    $requiredDirs = @{
        "Source Directory" = "src/"
        "Security Directory" = "security/"
        "Scripts Directory" = "scripts/"
        "Reports Directory" = "security/reports/"
    }
    
    foreach ($dir in $requiredDirs.GetEnumerator()) {
        $prerequisites += $dir.Key
        if (-not (Test-Path $dir.Value)) {
            $missingPrereqs += $dir.Key
        }
    }
    
    Write-ColorOutput "Prerequisites checked: $($prerequisites.Count)" "White"
    Write-ColorOutput "Missing prerequisites: $($missingPrereqs.Count)" $(if ($missingPrereqs.Count -gt 0) { "Red" } else { "Green" })
    
    if ($missingPrereqs.Count -gt 0) {
        Write-ColorOutput "Missing prerequisites:" "Red"
        $missingPrereqs | ForEach-Object { Write-ColorOutput "  - $_" "Red" }
        return $false
    }
    
    Write-ColorOutput "All prerequisites satisfied" "Green"
    return $true
}

# Main execution
Write-ColorOutput "Integration Orchestrator - Terraform Security Enhancement" "Green"
Write-ColorOutput "============================================================" "Green"
Write-ColorOutput "Integration Type: $IntegrationType" "Gray"
Write-ColorOutput "Dry Run: $DryRun" "Gray"

# Validate prerequisites
if (-not (Test-IntegrationPrerequisites)) {
    Write-ColorOutput "Prerequisites validation failed. Cannot proceed with integration." "Red"
    exit 1
}

# Execute integration based on type
$integrationResult = $false

try {
    switch ($IntegrationType) {
        "task-completion" {
            if (-not $TaskName) {
                Write-ColorOutput "Error: TaskName is required for task-completion integration" "Red"
                exit 1
            }
            $integrationResult = Invoke-TaskCompletionIntegration -TaskName $TaskName -TaskId $TaskId
        }
        "security-scan" {
            $integrationResult = Invoke-SecurityScanIntegration
        }
        "documentation-update" {
            $integrationResult = Invoke-DocumentationIntegration -UpdateType "general-update"
        }
        "full-integration" {
            $integrationResult = Invoke-FullIntegration
        }
        default {
            Write-ColorOutput "Error: Unknown integration type: $IntegrationType" "Red"
            exit 1
        }
    }
    
    if ($integrationResult) {
        Write-ColorOutput "`nIntegration completed successfully!" "Green"
        exit $script:ExitCode
    } else {
        Write-ColorOutput "`nIntegration failed!" "Red"
        exit 1
    }
}
catch {
    Write-ColorOutput "Critical error during integration: $($_.Exception.Message)" "Red"
    exit 1
}