# Comprehensive Security Validation Report
# Validates all security configurations against best practices

param(
    [Parameter(Mandatory=$false)]
    [switch]$DetailedReport = $false,
    
    [Parameter(Mandatory=$false)]
    [switch]$ExportJson = $true,
    
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

# Function to validate Terraform configuration
function Test-TerraformConfiguration {
    Write-ColorOutput "Validating Terraform Configuration..." "Blue"
    
    $validation = @{
        "terraform_format" = $false
        "terraform_validate" = $false
        "security_modules" = @{}
        "issues" = @()
    }
    
    try {
        # Check Terraform formatting
        Push-Location "src"
        $formatResult = terraform fmt -check -recursive 2>&1
        if ($LASTEXITCODE -eq 0) {
            $validation.terraform_format = $true
            Write-ColorOutput "✓ Terraform formatting is correct" "Green"
        } else {
            $validation.issues += "Terraform files need formatting"
            Write-ColorOutput "⚠ Terraform files need formatting" "Yellow"
        }
        
        # Validate Terraform configuration
        $validateResult = terraform validate 2>&1
        if ($LASTEXITCODE -eq 0) {
            $validation.terraform_validate = $true
            Write-ColorOutput "✓ Terraform configuration is valid" "Green"
        } else {
            $validation.issues += "Terraform validation failed: $validateResult"
            Write-ColorOutput "✗ Terraform validation failed" "Red"
        }
        
        Pop-Location
    }
    catch {
        $validation.issues += "Error during Terraform validation: $($_.Exception.Message)"
        Write-ColorOutput "Error during Terraform validation: $($_.Exception.Message)" "Red"
        Pop-Location
    }
    
    return $validation
}

# Function to validate security module configurations
function Test-SecurityModuleConfigurations {
    Write-ColorOutput "Validating Security Module Configurations..." "Blue"
    
    $securityModules = @{
        "key_vault" = @{
            "path" = "src/modules/Security/kvault"
            "required_files" = @("vault/keyVault.tf", "secret/secret.tf")
            "security_features" = @()
        }
        "storage_account" = @{
            "path" = "src/modules/Storage/stgAccount"
            "required_files" = @("sa.tf", "variables_sa.tf")
            "security_features" = @()
        }
        "user_assigned_identity" = @{
            "path" = "src/modules/Security/uami"
            "required_files" = @("uami.tf", "uami_variables.tf")
            "security_features" = @()
        }
        "network_security" = @{
            "path" = "src/modules/network/nsg"
            "required_files" = @("nsg.tf", "variables_nsg.tf")
            "security_features" = @()
        }
    }
    
    foreach ($module in $securityModules.GetEnumerator()) {
        $moduleName = $module.Key
        $moduleConfig = $module.Value
        
        Write-ColorOutput "Checking $moduleName module..." "Yellow"
        
        # Check if module directory exists
        if (Test-Path $moduleConfig.path) {
            Write-ColorOutput "  ✓ Module directory exists" "Green"
            
            # Check required files
            $missingFiles = @()
            foreach ($file in $moduleConfig.required_files) {
                $filePath = Join-Path $moduleConfig.path $file
                if (Test-Path $filePath) {
                    Write-ColorOutput "  ✓ $file exists" "Green"
                } else {
                    $missingFiles += $file
                    Write-ColorOutput "  ✗ $file missing" "Red"
                }
            }
            
            if ($missingFiles.Count -eq 0) {
                $securityModules[$moduleName]["status"] = "valid"
            } else {
                $securityModules[$moduleName]["status"] = "incomplete"
                $securityModules[$moduleName]["missing_files"] = $missingFiles
            }
        } else {
            Write-ColorOutput "  ✗ Module directory missing" "Red"
            $securityModules[$moduleName]["status"] = "missing"
        }
    }
    
    return $securityModules
}

# Function to validate SAST tool configurations
function Test-SASTToolConfigurations {
    Write-ColorOutput "Validating SAST Tool Configurations..." "Blue"
    
    $sastTools = @{
        "checkov" = @{
            "config_file" = "security/sast-tools/.checkov.yaml"
            "status" = "unknown"
        }
        "tfsec" = @{
            "config_file" = "security/sast-tools/.tfsec.yml"
            "status" = "unknown"
        }
        "terrascan" = @{
            "config_file" = "security/sast-tools/.terrascan_config.toml"
            "status" = "unknown"
        }
    }
    
    foreach ($tool in $sastTools.GetEnumerator()) {
        $toolName = $tool.Key
        $configFile = $tool.Value.config_file
        
        if (Test-Path $configFile) {
            $sastTools[$toolName]["status"] = "configured"
            Write-ColorOutput "  ✓ $toolName configuration found" "Green"
            
            # Validate configuration content
            try {
                $configContent = Get-Content $configFile -Raw
                if ($configContent.Length -gt 0) {
                    $sastTools[$toolName]["has_content"] = $true
                    Write-ColorOutput "  ✓ $toolName configuration has content" "Green"
                } else {
                    $sastTools[$toolName]["has_content"] = $false
                    Write-ColorOutput "  ⚠ $toolName configuration is empty" "Yellow"
                }
            }
            catch {
                $sastTools[$toolName]["has_content"] = $false
                Write-ColorOutput "  ⚠ Could not read $toolName configuration" "Yellow"
            }
        } else {
            $sastTools[$toolName]["status"] = "missing"
            Write-ColorOutput "  ✗ $toolName configuration missing" "Red"
        }
    }
    
    return $sastTools
}

# Function to validate CI/CD pipeline configurations
function Test-CICDPipelineConfigurations {
    Write-ColorOutput "Validating CI/CD Pipeline Configurations..." "Blue"
    
    $pipelines = @{
        "github_actions" = @{
            "file" = ".github/workflows/terraform-security-scan.yml"
            "status" = "unknown"
            "security_features" = @()
        }
        "azure_devops" = @{
            "file" = "azure-pipelines.yml"
            "status" = "unknown"
            "security_features" = @()
        }
    }
    
    foreach ($pipeline in $pipelines.GetEnumerator()) {
        $pipelineName = $pipeline.Key
        $pipelineFile = $pipeline.Value.file
        
        if (Test-Path $pipelineFile) {
            $pipelines[$pipelineName]["status"] = "configured"
            Write-ColorOutput "  ✓ $pipelineName pipeline found" "Green"
            
            try {
                $pipelineContent = Get-Content $pipelineFile -Raw
                
                # Check for security features
                $securityFeatures = @()
                
                if ($pipelineContent -match "checkov|tfsec|terrascan") {
                    $securityFeatures += "SAST Tools"
                }
                
                if ($pipelineContent -match "security.*scan|security.*gate") {
                    $securityFeatures += "Security Gates"
                }
                
                if ($pipelineContent -match "sarif|security.*report") {
                    $securityFeatures += "Security Reporting"
                }
                
                if ($pipelineContent -match "terraform.*validate|terraform.*plan") {
                    $securityFeatures += "Terraform Validation"
                }
                
                $pipelines[$pipelineName]["security_features"] = $securityFeatures
                
                if ($securityFeatures.Count -gt 0) {
                    Write-ColorOutput "  ✓ Security features: $($securityFeatures -join ', ')" "Green"
                } else {
                    Write-ColorOutput "  ⚠ No security features detected" "Yellow"
                }
            }
            catch {
                Write-ColorOutput "  ⚠ Could not analyze pipeline content" "Yellow"
            }
        } else {
            $pipelines[$pipelineName]["status"] = "missing"
            Write-ColorOutput "  ✗ $pipelineName pipeline missing" "Red"
        }
    }
    
    return $pipelines
}

# Function to validate integration system
function Test-IntegrationSystem {
    Write-ColorOutput "Validating Integration System..." "Blue"
    
    $integrationComponents = @{
        "auto_commit_system" = @{
            "files" = @(
                "scripts/git/auto-commit.ps1",
                "scripts/git/auto-commit-wrapper.ps1",
                "scripts/git/commit-task.ps1"
            )
            "status" = "unknown"
        }
        "integration_orchestrator" = @{
            "files" = @(
                "scripts/integration/integration-orchestrator.ps1",
                "scripts/integration/task-completion-hook.ps1",
                "scripts/integration/master-integration.ps1"
            )
            "status" = "unknown"
        }
        "documentation_system" = @{
            "files" = @(
                "scripts/integration/documentation-integration.ps1",
                "scripts/utils/automated-changelog-system.ps1"
            )
            "status" = "unknown"
        }
    }
    
    foreach ($component in $integrationComponents.GetEnumerator()) {
        $componentName = $component.Key
        $componentFiles = $component.Value.files
        
        $missingFiles = @()
        $existingFiles = @()
        
        foreach ($file in $componentFiles) {
            if (Test-Path $file) {
                $existingFiles += $file
            } else {
                $missingFiles += $file
            }
        }
        
        if ($missingFiles.Count -eq 0) {
            $integrationComponents[$componentName]["status"] = "complete"
            Write-ColorOutput "  ✓ $componentName is complete" "Green"
        } elseif ($existingFiles.Count -gt 0) {
            $integrationComponents[$componentName]["status"] = "partial"
            $integrationComponents[$componentName]["missing_files"] = $missingFiles
            Write-ColorOutput "  ⚠ $componentName is partially configured" "Yellow"
        } else {
            $integrationComponents[$componentName]["status"] = "missing"
            Write-ColorOutput "  ✗ $componentName is missing" "Red"
        }
    }
    
    return $integrationComponents
}

# Function to generate security score
function Get-SecurityScore {
    param(
        [hashtable]$TerraformValidation,
        [hashtable]$SecurityModules,
        [hashtable]$SASTTools,
        [hashtable]$CICDPipelines,
        [hashtable]$IntegrationSystem
    )
    
    $scores = @{
        "terraform_config" = 0
        "security_modules" = 0
        "sast_tools" = 0
        "cicd_pipelines" = 0
        "integration_system" = 0
        "overall" = 0
    }
    
    # Terraform configuration score (20 points)
    if ($TerraformValidation.terraform_format) { $scores.terraform_config += 10 }
    if ($TerraformValidation.terraform_validate) { $scores.terraform_config += 10 }
    
    # Security modules score (25 points)
    $validModules = ($SecurityModules.Values | Where-Object { $_.status -eq "valid" }).Count
    $totalModules = $SecurityModules.Count
    $scores.security_modules = [math]::Round(($validModules / $totalModules) * 25)
    
    # SAST tools score (20 points)
    $configuredTools = ($SASTTools.Values | Where-Object { $_.status -eq "configured" }).Count
    $totalTools = $SASTTools.Count
    $scores.sast_tools = [math]::Round(($configuredTools / $totalTools) * 20)
    
    # CI/CD pipelines score (20 points)
    $configuredPipelines = ($CICDPipelines.Values | Where-Object { $_.status -eq "configured" }).Count
    $totalPipelines = $CICDPipelines.Count
    $scores.cicd_pipelines = [math]::Round(($configuredPipelines / $totalPipelines) * 20)
    
    # Integration system score (15 points)
    $completeComponents = ($IntegrationSystem.Values | Where-Object { $_.status -eq "complete" }).Count
    $totalComponents = $IntegrationSystem.Count
    $scores.integration_system = [math]::Round(($completeComponents / $totalComponents) * 15)
    
    # Overall score
    $scores.overall = $scores.terraform_config + $scores.security_modules + $scores.sast_tools + $scores.cicd_pipelines + $scores.integration_system
    
    return $scores
}

# Main execution
Write-ColorOutput "Comprehensive Security Validation Report" "Green"
Write-ColorOutput "=========================================" "Green"

$timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
Write-ColorOutput "Report generated: $timestamp" "Gray"

# Run all validations
$terraformValidation = Test-TerraformConfiguration
$securityModules = Test-SecurityModuleConfigurations
$sastTools = Test-SASTToolConfigurations
$cicdPipelines = Test-CICDPipelineConfigurations
$integrationSystem = Test-IntegrationSystem

# Calculate security score
$securityScore = Get-SecurityScore -TerraformValidation $terraformValidation -SecurityModules $securityModules -SASTTools $sastTools -CICDPipelines $cicdPipelines -IntegrationSystem $integrationSystem

# Display summary
Write-ColorOutput "`n=== Security Validation Summary ===" "Cyan"
Write-ColorOutput "Terraform Configuration: $($securityScore.terraform_config)/20" $(if ($securityScore.terraform_config -ge 15) { "Green" } elseif ($securityScore.terraform_config -ge 10) { "Yellow" } else { "Red" })
Write-ColorOutput "Security Modules: $($securityScore.security_modules)/25" $(if ($securityScore.security_modules -ge 20) { "Green" } elseif ($securityScore.security_modules -ge 15) { "Yellow" } else { "Red" })
Write-ColorOutput "SAST Tools: $($securityScore.sast_tools)/20" $(if ($securityScore.sast_tools -ge 15) { "Green" } elseif ($securityScore.sast_tools -ge 10) { "Yellow" } else { "Red" })
Write-ColorOutput "CI/CD Pipelines: $($securityScore.cicd_pipelines)/20" $(if ($securityScore.cicd_pipelines -ge 15) { "Green" } elseif ($securityScore.cicd_pipelines -ge 10) { "Yellow" } else { "Red" })
Write-ColorOutput "Integration System: $($securityScore.integration_system)/15" $(if ($securityScore.integration_system -ge 12) { "Green" } elseif ($securityScore.integration_system -ge 8) { "Yellow" } else { "Red" })

Write-ColorOutput "`nOverall Security Score: $($securityScore.overall)/100" $(
    if ($securityScore.overall -ge 80) { "Green" }
    elseif ($securityScore.overall -ge 60) { "Yellow" }
    else { "Red" }
)

# Generate detailed report
$detailedReport = @{
    "timestamp" = $timestamp
    "security_score" = $securityScore
    "terraform_validation" = $terraformValidation
    "security_modules" = $securityModules
    "sast_tools" = $sastTools
    "cicd_pipelines" = $cicdPipelines
    "integration_system" = $integrationSystem
    "recommendations" = @()
}

# Generate recommendations
if ($securityScore.terraform_config -lt 20) {
    $detailedReport.recommendations += "Fix Terraform configuration issues and ensure proper formatting"
}
if ($securityScore.security_modules -lt 25) {
    $detailedReport.recommendations += "Complete implementation of all security modules"
}
if ($securityScore.sast_tools -lt 20) {
    $detailedReport.recommendations += "Configure all SAST tools (Checkov, TFSec, Terrascan)"
}
if ($securityScore.cicd_pipelines -lt 20) {
    $detailedReport.recommendations += "Implement CI/CD pipelines with security gates"
}
if ($securityScore.integration_system -lt 15) {
    $detailedReport.recommendations += "Complete integration system setup"
}

# Display recommendations
if ($detailedReport.recommendations.Count -gt 0) {
    Write-ColorOutput "`n=== Recommendations ===" "Yellow"
    $detailedReport.recommendations | ForEach-Object { Write-ColorOutput "- $_" "Yellow" }
}

# Export report
if ($ExportJson) {
    $reportPath = "security/reports/security-validation-report.json"
    $detailedReport | ConvertTo-Json -Depth 10 | Out-File -FilePath $reportPath -Encoding UTF8
    Write-ColorOutput "`nDetailed report saved to: $reportPath" "Green"
}

# Determine exit code
if ($securityScore.overall -ge 80) {
    Write-ColorOutput "`nSecurity validation PASSED!" "Green"
    exit 0
} elseif ($securityScore.overall -ge 60) {
    Write-ColorOutput "`nSecurity validation completed with warnings." "Yellow"
    exit 0
} else {
    Write-ColorOutput "`nSecurity validation FAILED!" "Red"
    exit 1
}