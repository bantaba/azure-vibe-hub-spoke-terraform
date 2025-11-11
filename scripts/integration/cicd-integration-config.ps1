# CI/CD Integration Configuration
# Configures and validates CI/CD pipeline integration with SAST tools and automation

param(
    [Parameter(Mandatory=$false)]
    [ValidateSet("github-actions", "azure-devops", "both", "validate")]
    [string]$Platform = "both",
    
    [Parameter(Mandatory=$false)]
    [switch]$UpdateWorkflows = $false,
    
    [Parameter(Mandatory=$false)]
    [switch]$ValidateOnly = $false,
    
    [Parameter(Mandatory=$false)]
    [switch]$VerboseOutput = $false
)

# Script configuration
$script:ScriptPath = Split-Path -Parent $MyInvocation.MyCommand.Path
$script:RootPath = Split-Path -Parent (Split-Path -Parent $script:ScriptPath)

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
        default { Write-Host $Message }
    }
}

# Function to validate GitHub Actions workflow
function Test-GitHubActionsIntegration {
    Write-ColorOutput "Validating GitHub Actions integration..." "Blue"
    
    $workflowPath = ".github/workflows/terraform-security-scan.yml"
    $validationResults = @{
        "workflow_exists" = $false
        "sast_tools_configured" = $false
        "security_gates_configured" = $false
        "reporting_configured" = $false
        "integration_score" = 0
    }
    
    if (Test-Path $workflowPath) {
        $validationResults.workflow_exists = $true
        Write-ColorOutput "✓ GitHub Actions workflow found" "Green"
        
        try {
            $workflowContent = Get-Content $workflowPath -Raw
            
            # Check for SAST tools configuration
            $sastTools = @("checkov", "tfsec", "terrascan")
            $configuredTools = @()
            
            foreach ($tool in $sastTools) {
                if ($workflowContent -match $tool) {
                    $configuredTools += $tool
                }
            }
            
            if ($configuredTools.Count -eq $sastTools.Count) {
                $validationResults.sast_tools_configured = $true
                Write-ColorOutput "✓ All SAST tools configured in workflow" "Green"
            } else {
                Write-ColorOutput "⚠ Missing SAST tools: $($sastTools | Where-Object { $_ -notin $configuredTools })" "Yellow"
            }
            
            # Check for security gates
            if ($workflowContent -match "fail.*on.*critical|fail.*on.*high") {
                $validationResults.security_gates_configured = $true
                Write-ColorOutput "✓ Security gates configured" "Green"
            } else {
                Write-ColorOutput "⚠ Security gates not properly configured" "Yellow"
            }
            
            # Check for reporting
            if ($workflowContent -match "upload.*artifact|sarif|security.*report") {
                $validationResults.reporting_configured = $true
                Write-ColorOutput "✓ Security reporting configured" "Green"
            } else {
                Write-ColorOutput "⚠ Security reporting not configured" "Yellow"
            }
            
        } catch {
            Write-ColorOutput "Error reading workflow file: $($_.Exception.Message)" "Red"
        }
    } else {
        Write-ColorOutput "✗ GitHub Actions workflow not found" "Red"
    }
    
    # Calculate integration score
    $score = 0
    if ($validationResults.workflow_exists) { $score += 25 }
    if ($validationResults.sast_tools_configured) { $score += 25 }
    if ($validationResults.security_gates_configured) { $score += 25 }
    if ($validationResults.reporting_configured) { $score += 25 }
    
    $validationResults.integration_score = $score
    
    Write-ColorOutput "GitHub Actions Integration Score: $score/100" $(if ($score -ge 75) { "Green" } elseif ($score -ge 50) { "Yellow" } else { "Red" })
    
    return $validationResults
}

# Function to validate Azure DevOps pipeline
function Test-AzureDevOpsIntegration {
    Write-ColorOutput "Validating Azure DevOps integration..." "Blue"
    
    $pipelinePaths = @("azure-pipelines.yml", "azure-pipelines-security.yml")
    $validationResults = @{
        "pipeline_exists" = $false
        "sast_tools_configured" = $false
        "security_gates_configured" = $false
        "reporting_configured" = $false
        "integration_score" = 0
    }
    
    $pipelineFound = $false
    $pipelineContent = ""
    
    foreach ($pipelinePath in $pipelinePaths) {
        if (Test-Path $pipelinePath) {
            $pipelineFound = $true
            $pipelineContent = Get-Content $pipelinePath -Raw
            Write-ColorOutput "✓ Azure DevOps pipeline found: $pipelinePath" "Green"
            break
        }
    }
    
    if ($pipelineFound) {
        $validationResults.pipeline_exists = $true
        
        try {
            # Check for SAST tools configuration
            $sastTools = @("checkov", "tfsec", "terrascan")
            $configuredTools = @()
            
            foreach ($tool in $sastTools) {
                if ($pipelineContent -match $tool) {
                    $configuredTools += $tool
                }
            }
            
            if ($configuredTools.Count -eq $sastTools.Count) {
                $validationResults.sast_tools_configured = $true
                Write-ColorOutput "✓ All SAST tools configured in pipeline" "Green"
            } else {
                Write-ColorOutput "⚠ Missing SAST tools: $($sastTools | Where-Object { $_ -notin $configuredTools })" "Yellow"
            }
            
            # Check for security gates
            if ($pipelineContent -match "condition.*failed|continueOnError.*false") {
                $validationResults.security_gates_configured = $true
                Write-ColorOutput "✓ Security gates configured" "Green"
            } else {
                Write-ColorOutput "⚠ Security gates not properly configured" "Yellow"
            }
            
            # Check for reporting
            if ($pipelineContent -match "PublishTestResults|PublishBuildArtifacts|security.*report") {
                $validationResults.reporting_configured = $true
                Write-ColorOutput "✓ Security reporting configured" "Green"
            } else {
                Write-ColorOutput "⚠ Security reporting not configured" "Yellow"
            }
            
        } catch {
            Write-ColorOutput "Error reading pipeline file: $($_.Exception.Message)" "Red"
        }
    } else {
        Write-ColorOutput "✗ Azure DevOps pipeline not found" "Red"
    }
    
    # Calculate integration score
    $score = 0
    if ($validationResults.pipeline_exists) { $score += 25 }
    if ($validationResults.sast_tools_configured) { $score += 25 }
    if ($validationResults.security_gates_configured) { $score += 25 }
    if ($validationResults.reporting_configured) { $score += 25 }
    
    $validationResults.integration_score = $score
    
    Write-ColorOutput "Azure DevOps Integration Score: $score/100" $(if ($score -ge 75) { "Green" } elseif ($score -ge 50) { "Yellow" } else { "Red" })
    
    return $validationResults
}

# Function to validate local integration components
function Test-LocalIntegrationComponents {
    Write-ColorOutput "Validating local integration components..." "Blue"
    
    $components = @{
        "SAST Configuration Files" = @(
            "security/sast-tools/.checkov.yaml",
            "security/sast-tools/.tfsec.yml", 
            "security/sast-tools/.terrascan_config.toml"
        )
        "Integration Scripts" = @(
            "scripts/integration/integration-orchestrator.ps1",
            "scripts/integration/task-completion-hook.ps1",
            "security/scripts/run-sast-scan.ps1"
        )
        "Git Automation" = @(
            "scripts/git/auto-commit.ps1",
            "scripts/git/auto-commit-wrapper.ps1",
            "scripts/git/commit-task.ps1"
        )
        "Documentation System" = @(
            "scripts/utils/automated-changelog-system.ps1",
            "docs/security/README.md"
        )
    }
    
    $validationResults = @{
        "total_components" = 0
        "valid_components" = 0
        "missing_components" = @()
        "integration_score" = 0
    }
    
    foreach ($category in $components.GetEnumerator()) {
        Write-ColorOutput "`nChecking $($category.Key):" "Yellow"
        
        foreach ($component in $category.Value) {
            $validationResults.total_components++
            
            if (Test-Path $component) {
                $validationResults.valid_components++
                Write-ColorOutput "  ✓ $component" "Green"
            } else {
                $validationResults.missing_components += $component
                Write-ColorOutput "  ✗ $component" "Red"
            }
        }
    }
    
    # Calculate integration score
    if ($validationResults.total_components -gt 0) {
        $validationResults.integration_score = [math]::Round(($validationResults.valid_components / $validationResults.total_components) * 100)
    }
    
    Write-ColorOutput "`nLocal Integration Score: $($validationResults.integration_score)/100" $(if ($validationResults.integration_score -ge 75) { "Green" } elseif ($validationResults.integration_score -ge 50) { "Yellow" } else { "Red" })
    
    return $validationResults
}

# Function to create integration status report
function New-IntegrationStatusReport {
    param(
        [hashtable]$GitHubResults,
        [hashtable]$AzureDevOpsResults,
        [hashtable]$LocalResults
    )
    
    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    $report = @{
        "timestamp" = $timestamp
        "overall_status" = "unknown"
        "integration_scores" = @{
            "github_actions" = $GitHubResults.integration_score
            "azure_devops" = $AzureDevOpsResults.integration_score
            "local_components" = $LocalResults.integration_score
        }
        "component_status" = @{
            "github_actions" = $GitHubResults
            "azure_devops" = $AzureDevOpsResults
            "local_components" = $LocalResults
        }
        "recommendations" = @()
    }
    
    # Calculate overall score
    $overallScore = [math]::Round(($GitHubResults.integration_score + $AzureDevOpsResults.integration_score + $LocalResults.integration_score) / 3)
    
    if ($overallScore -ge 75) {
        $report.overall_status = "excellent"
    } elseif ($overallScore -ge 50) {
        $report.overall_status = "good"
    } elseif ($overallScore -ge 25) {
        $report.overall_status = "needs_improvement"
    } else {
        $report.overall_status = "poor"
    }
    
    # Generate recommendations
    if ($GitHubResults.integration_score -lt 75) {
        $report.recommendations += "Improve GitHub Actions workflow configuration"
    }
    if ($AzureDevOpsResults.integration_score -lt 75) {
        $report.recommendations += "Enhance Azure DevOps pipeline integration"
    }
    if ($LocalResults.integration_score -lt 75) {
        $report.recommendations += "Complete local integration component setup"
    }
    
    # Save report
    $reportPath = "security/reports/integration-status-report.json"
    $report | ConvertTo-Json -Depth 10 | Out-File -FilePath $reportPath -Encoding UTF8
    
    Write-ColorOutput "`nIntegration Status Report saved to: $reportPath" "Green"
    
    return $report
}

# Main execution
Write-ColorOutput "CI/CD Integration Configuration" "Green"
Write-ColorOutput "===============================" "Green"
Write-ColorOutput "Platform: $Platform" "Gray"
Write-ColorOutput "Validate Only: $ValidateOnly" "Gray"

# Create reports directory if it doesn't exist
$reportsDir = "security/reports"
if (-not (Test-Path $reportsDir)) {
    New-Item -ItemType Directory -Path $reportsDir -Force | Out-Null
}

try {
    $githubResults = @{ "integration_score" = 0 }
    $azureDevOpsResults = @{ "integration_score" = 0 }
    $localResults = @{ "integration_score" = 0 }
    
    # Validate GitHub Actions integration
    if ($Platform -in @("github-actions", "both", "validate")) {
        $githubResults = Test-GitHubActionsIntegration
    }
    
    # Validate Azure DevOps integration
    if ($Platform -in @("azure-devops", "both", "validate")) {
        $azureDevOpsResults = Test-AzureDevOpsIntegration
    }
    
    # Always validate local components
    $localResults = Test-LocalIntegrationComponents
    
    # Generate integration status report
    $statusReport = New-IntegrationStatusReport -GitHubResults $githubResults -AzureDevOpsResults $azureDevOpsResults -LocalResults $localResults
    
    # Display summary
    Write-ColorOutput "`n=== Integration Summary ===" "Cyan"
    Write-ColorOutput "Overall Status: $($statusReport.overall_status.ToUpper())" $(
        switch ($statusReport.overall_status) {
            "excellent" { "Green" }
            "good" { "Green" }
            "needs_improvement" { "Yellow" }
            "poor" { "Red" }
            default { "White" }
        }
    )
    
    Write-ColorOutput "GitHub Actions Score: $($githubResults.integration_score)/100" $(if ($githubResults.integration_score -ge 75) { "Green" } else { "Yellow" })
    Write-ColorOutput "Azure DevOps Score: $($azureDevOpsResults.integration_score)/100" $(if ($azureDevOpsResults.integration_score -ge 75) { "Green" } else { "Yellow" })
    Write-ColorOutput "Local Components Score: $($localResults.integration_score)/100" $(if ($localResults.integration_score -ge 75) { "Green" } else { "Yellow" })
    
    if ($statusReport.recommendations.Count -gt 0) {
        Write-ColorOutput "`nRecommendations:" "Yellow"
        $statusReport.recommendations | ForEach-Object { Write-ColorOutput "  - $_" "Yellow" }
    }
    
    # Determine exit code based on overall status
    if ($statusReport.overall_status -in @("excellent", "good")) {
        Write-ColorOutput "`nCI/CD integration validation completed successfully!" "Green"
        exit 0
    } else {
        Write-ColorOutput "`nCI/CD integration needs improvement!" "Yellow"
        exit 1
    }
}
catch {
    Write-ColorOutput "Error during CI/CD integration validation: $($_.Exception.Message)" "Red"
    exit 1
}