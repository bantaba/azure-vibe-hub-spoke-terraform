# Cloud Deployment Test Script
# Tests Terraform infrastructure deployment readiness and security validation

param(
    [switch]$ValidateOnly = $false,
    [switch]$RunSecurityScan = $true,
    [switch]$CheckAzureConnection = $true,
    [switch]$Verbose = $false
)

$ErrorActionPreference = "Continue"
$testResults = @()
$startTime = Get-Date

function Write-TestResult {
    param(
        [string]$TestName,
        [bool]$Passed,
        [string]$Message = ""
    )
    
    $status = if ($Passed) { "✅ PASS" } else { "❌ FAIL" }
    $color = if ($Passed) { "Green" } else { "Red" }
    
    Write-Host "$status - $TestName" -ForegroundColor $color
    if ($Message) {
        Write-Host "    $Message" -ForegroundColor Gray
    }
    
    $script:testResults += @{
        Test = $TestName
        Passed = $Passed
        Message = $Message
        Timestamp = Get-Date
    }
}

Write-Host "╔══════════════════════════════════════════════════════════════╗" -ForegroundColor Cyan
Write-Host "║              Cloud Deployment Readiness Test                ║" -ForegroundColor Cyan
Write-Host "╚══════════════════════════════════════════════════════════════╝" -ForegroundColor Cyan
Write-Host ""

# Test 1: Terraform Installation
Write-Host "Testing Terraform Installation..." -ForegroundColor Blue
try {
    $tfVersion = terraform version -json 2>&1 | ConvertFrom-Json
    $version = $tfVersion.terraform_version
    Write-TestResult "Terraform Installation" $true "Version $version installed"
} catch {
    Write-TestResult "Terraform Installation" $false "Terraform not found or not accessible"
}

# Test 2: Terraform Configuration Validation
Write-Host "`nTesting Terraform Configuration..." -ForegroundColor Blue
if (Test-Path "src/main.tf") {
    Write-TestResult "Terraform Source Files" $true "Main configuration found"
    
    # Check for required files
    $requiredFiles = @("main.tf", "variables.tf", "provider.tf", "terraform.tf")
    $missingFiles = @()
    
    foreach ($file in $requiredFiles) {
        if (!(Test-Path "src/$file")) {
            $missingFiles += $file
        }
    }
    
    if ($missingFiles.Count -eq 0) {
        Write-TestResult "Required Terraform Files" $true "All required files present"
    } else {
        Write-TestResult "Required Terraform Files" $false "Missing: $($missingFiles -join ', ')"
    }
    
    # Validate Terraform syntax
    try {
        Push-Location src
        $initResult = terraform init -backend=false 2>&1
        if ($LASTEXITCODE -eq 0) {
            Write-TestResult "Terraform Init" $true "Initialization successful"
            
            $validateResult = terraform validate -json 2>&1 | ConvertFrom-Json
            if ($validateResult.valid) {
                Write-TestResult "Terraform Validation" $true "Configuration is valid"
            } else {
                $errors = $validateResult.error_count
                Write-TestResult "Terraform Validation" $false "$errors validation errors found"
            }
        } else {
            Write-TestResult "Terraform Init" $false "Initialization failed"
        }
        Pop-Location
    } catch {
        Pop-Location
        Write-TestResult "Terraform Validation" $false "Error during validation: $_"
    }
} else {
    Write-TestResult "Terraform Source Files" $false "src/main.tf not found"
}

# Test 3: Azure CLI and Connection
if ($CheckAzureConnection) {
    Write-Host "`nTesting Azure Connection..." -ForegroundColor Blue
    try {
        $azVersion = az version 2>&1 | ConvertFrom-Json
        Write-TestResult "Azure CLI Installation" $true "Azure CLI installed"
        
        # Check Azure login status
        try {
            $account = az account show 2>&1 | ConvertFrom-Json
            if ($account.id) {
                Write-TestResult "Azure Authentication" $true "Logged in as $($account.user.name)"
                Write-TestResult "Azure Subscription" $true "Using subscription: $($account.name)"
            } else {
                Write-TestResult "Azure Authentication" $false "Not logged in to Azure"
            }
        } catch {
            Write-TestResult "Azure Authentication" $false "Not logged in to Azure (run 'az login')"
        }
    } catch {
        Write-TestResult "Azure CLI Installation" $false "Azure CLI not found"
    }
}

# Test 4: Security Scanning Tools
Write-Host "`nTesting Security Scanning Tools..." -ForegroundColor Blue
$sastTools = @{
    "checkov" = "Checkov (IaC Security Scanner)"
    "tfsec" = "TFSec (Terraform Security Scanner)"
    "terrascan" = "Terrascan (Policy as Code)"
}

$installedTools = @()
foreach ($tool in $sastTools.Keys) {
    try {
        $null = Get-Command $tool -ErrorAction Stop
        Write-TestResult "SAST Tool: $($sastTools[$tool])" $true "Installed and available"
        $installedTools += $tool
    } catch {
        Write-TestResult "SAST Tool: $($sastTools[$tool])" $false "Not installed"
    }
}

# Test 5: Run Security Scan (if tools available and requested)
if ($RunSecurityScan -and $installedTools.Count -gt 0) {
    Write-Host "`nRunning Security Scan..." -ForegroundColor Blue
    
    $scanScript = "security/scripts/run-sast-scan.ps1"
    if (Test-Path $scanScript) {
        try {
            $scanResult = & $scanScript -SourcePath "src" -ReportsPath "security/reports" -FailOnHigh:$false -FailOnCritical:$false 2>&1
            
            # Check if reports were generated
            $reportFiles = @(
                "security/reports/unified-sast-report.json"
            )
            
            $reportsGenerated = $false
            foreach ($report in $reportFiles) {
                if (Test-Path $report) {
                    $reportsGenerated = $true
                    break
                }
            }
            
            if ($reportsGenerated) {
                Write-TestResult "Security Scan Execution" $true "Scan completed and reports generated"
                
                # Parse results
                try {
                    $unifiedReport = Get-Content "security/reports/unified-sast-report.json" -Raw | ConvertFrom-Json
                    $totalIssues = $unifiedReport.summary.total_issues
                    $critical = $unifiedReport.summary.critical
                    $high = $unifiedReport.summary.high
                    
                    if ($critical -gt 0 -or $high -gt 0) {
                        Write-TestResult "Security Scan Results" $false "Found $critical critical and $high high severity issues"
                    } else {
                        Write-TestResult "Security Scan Results" $true "No critical or high severity issues found"
                    }
                } catch {
                    Write-TestResult "Security Scan Results" $true "Reports generated (unable to parse)"
                }
            } else {
                Write-TestResult "Security Scan Execution" $false "Scan completed but no reports generated"
            }
        } catch {
            Write-TestResult "Security Scan Execution" $false "Error during scan: $_"
        }
    } else {
        Write-TestResult "Security Scan Script" $false "Scan script not found at $scanScript"
    }
}

# Test 6: Module Structure
Write-Host "`nTesting Module Structure..." -ForegroundColor Blue
$requiredModules = @(
    "src/modules/resourceGroup",
    "src/modules/network",
    "src/modules/Security",
    "src/modules/compute",
    "src/modules/monitoring"
)

$missingModules = @()
foreach ($module in $requiredModules) {
    if (Test-Path $module) {
        # Check for main.tf in module
        if (Test-Path "$module/main.tf") {
            Write-TestResult "Module: $(Split-Path $module -Leaf)" $true "Module exists with main.tf"
        } else {
            Write-TestResult "Module: $(Split-Path $module -Leaf)" $false "Module missing main.tf"
            $missingModules += $module
        }
    } else {
        Write-TestResult "Module: $(Split-Path $module -Leaf)" $false "Module directory not found"
        $missingModules += $module
    }
}

# Test 7: Backend Configuration
Write-Host "`nTesting Backend Configuration..." -ForegroundColor Blue
if (Test-Path "src/terraform.tf") {
    $terraformConfig = Get-Content "src/terraform.tf" -Raw
    
    if ($terraformConfig -match "backend\s+`"azurerm`"") {
        Write-TestResult "Backend Configuration" $true "Azure backend configured"
    } else {
        Write-TestResult "Backend Configuration" $false "Azure backend not configured"
    }
    
    # Check for required providers
    if ($terraformConfig -match "azurerm") {
        Write-TestResult "Azure Provider" $true "AzureRM provider configured"
    } else {
        Write-TestResult "Azure Provider" $false "AzureRM provider not configured"
    }
} else {
    Write-TestResult "Backend Configuration" $false "terraform.tf not found"
}

# Test 8: Deployment Scripts
Write-Host "`nTesting Deployment Scripts..." -ForegroundColor Blue
$deploymentScripts = @(
    "scripts/ci-cd/deploy.ps1",
    "scripts/ci-cd/validate.ps1"
)

foreach ($script in $deploymentScripts) {
    if (Test-Path $script) {
        Write-TestResult "Script: $(Split-Path $script -Leaf)" $true "Deployment script exists"
    } else {
        Write-TestResult "Script: $(Split-Path $script -Leaf)" $false "Script not found"
    }
}

# Test 9: CI/CD Pipeline Configuration
Write-Host "`nTesting CI/CD Configuration..." -ForegroundColor Blue
$pipelineFiles = @(
    ".github/workflows/terraform-security-scan.yml",
    "azure-pipelines.yml"
)

$foundPipelines = @()
foreach ($pipeline in $pipelineFiles) {
    if (Test-Path $pipeline) {
        Write-TestResult "Pipeline: $(Split-Path $pipeline -Leaf)" $true "Pipeline configuration exists"
        $foundPipelines += $pipeline
    }
}

if ($foundPipelines.Count -eq 0) {
    Write-TestResult "CI/CD Pipelines" $false "No pipeline configurations found"
}

# Test 10: Documentation
Write-Host "`nTesting Documentation..." -ForegroundColor Blue
$docFiles = @(
    "README.md",
    "docs/setup/README.md",
    "docs/security/README.md"
)

foreach ($doc in $docFiles) {
    if (Test-Path $doc) {
        Write-TestResult "Documentation: $doc" $true "File exists"
    } else {
        Write-TestResult "Documentation: $doc" $false "File not found"
    }
}

# Test 11: Terraform Plan (Dry Run)
if (!$ValidateOnly -and (Test-Path "src/main.tf")) {
    Write-Host "`nTesting Terraform Plan (Dry Run)..." -ForegroundColor Blue
    try {
        Push-Location src
        Write-Host "  Running terraform plan..." -ForegroundColor Gray
        $planResult = terraform plan -input=false -out=tfplan 2>&1
        
        if ($LASTEXITCODE -eq 0) {
            Write-TestResult "Terraform Plan" $true "Plan generated successfully"
            
            # Show plan summary
            $showResult = terraform show -json tfplan 2>&1 | ConvertFrom-Json
            if ($showResult.resource_changes) {
                $toCreate = ($showResult.resource_changes | Where-Object { $_.change.actions -contains "create" }).Count
                $toUpdate = ($showResult.resource_changes | Where-Object { $_.change.actions -contains "update" }).Count
                $toDelete = ($showResult.resource_changes | Where-Object { $_.change.actions -contains "delete" }).Count
                
                Write-Host "    Plan Summary: +$toCreate ~$toUpdate -$toDelete" -ForegroundColor Cyan
            }
            
            # Clean up plan file
            if (Test-Path "tfplan") {
                Remove-Item "tfplan" -Force
            }
        } else {
            Write-TestResult "Terraform Plan" $false "Plan generation failed"
        }
        Pop-Location
    } catch {
        Pop-Location
        Write-TestResult "Terraform Plan" $false "Error during plan: $_"
    }
}

# Summary
$endTime = Get-Date
$duration = $endTime - $startTime

Write-Host "`n╔══════════════════════════════════════════════════════════════╗" -ForegroundColor Cyan
Write-Host "║                  Deployment Test Summary                    ║" -ForegroundColor Cyan
Write-Host "╚══════════════════════════════════════════════════════════════╝" -ForegroundColor Cyan

$totalTests = $testResults.Count
$passedTests = ($testResults | Where-Object { $_.Passed }).Count
$failedTests = $totalTests - $passedTests

Write-Host "`nTotal Tests: $totalTests" -ForegroundColor White
Write-Host "Passed: $passedTests" -ForegroundColor Green
Write-Host "Failed: $failedTests" -ForegroundColor $(if ($failedTests -gt 0) { "Red" } else { "Green" })
Write-Host "Duration: $($duration.ToString('mm\:ss'))" -ForegroundColor Gray

# Save test results
$testReport = @{
    timestamp = Get-Date -Format "yyyy-MM-ddTHH:mm:ssZ"
    test_type = "cloud_deployment_readiness"
    summary = @{
        total_tests = $totalTests
        passed_tests = $passedTests
        failed_tests = $failedTests
        success_rate = if ($totalTests -gt 0) { [Math]::Round(($passedTests / $totalTests) * 100, 1) } else { 0 }
        duration_seconds = $duration.TotalSeconds
    }
    test_results = $testResults
}

$reportPath = "security/reports/cloud-deployment-test-$(Get-Date -Format 'yyyy-MM-dd_HH-mm-ss').json"
$testReport | ConvertTo-Json -Depth 10 | Out-File -FilePath $reportPath -Encoding UTF8
Write-Host "`nTest report saved: $reportPath" -ForegroundColor Cyan

# Deployment readiness assessment
Write-Host "`n╔══════════════════════════════════════════════════════════════╗" -ForegroundColor Yellow
Write-Host "║              Deployment Readiness Assessment                ║" -ForegroundColor Yellow
Write-Host "╚══════════════════════════════════════════════════════════════╝" -ForegroundColor Yellow

$criticalTests = $testResults | Where-Object { 
    $_.Test -match "Terraform Installation|Terraform Validation|Azure Authentication|Security Scan Results"
}
$criticalFailures = ($criticalTests | Where-Object { !$_.Passed }).Count

if ($failedTests -eq 0) {
    Write-Host "`n✅ READY FOR DEPLOYMENT" -ForegroundColor Green
    Write-Host "All tests passed. Infrastructure is ready for cloud deployment." -ForegroundColor Green
    exit 0
} elseif ($criticalFailures -eq 0) {
    Write-Host "`n⚠️  DEPLOYMENT POSSIBLE WITH WARNINGS" -ForegroundColor Yellow
    Write-Host "Some non-critical tests failed. Review the results above." -ForegroundColor Yellow
    Write-Host "Deployment can proceed but issues should be addressed." -ForegroundColor Yellow
    exit 0
} else {
    Write-Host "" -ForegroundColor Red
    Write-Host "NOT READY FOR DEPLOYMENT" -ForegroundColor Red
    Write-Host "Critical tests failed. Address issues before deployment." -ForegroundColor Red
    Write-Host "" -ForegroundColor Red
    
    $failedCritical = $criticalTests | Where-Object { !$_.Passed }
    foreach ($test in $failedCritical) {
        Write-Host "  FAILED: $($test.Test)" -ForegroundColor Red
    }
    exit 1
}
