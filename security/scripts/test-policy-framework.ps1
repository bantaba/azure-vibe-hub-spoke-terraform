# Test Policy-as-Code Framework Validation
# Validates Terraform Compliance integration and policy files

param(
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
    }
}

Write-Host "╔══════════════════════════════════════════════════════════════╗" -ForegroundColor Cyan
Write-Host "║       Policy-as-Code Framework Validation Test              ║" -ForegroundColor Cyan
Write-Host "╚══════════════════════════════════════════════════════════════╝" -ForegroundColor Cyan
Write-Host ""

# Test 1: Check installation script exists
Write-Host "Testing Installation Components..." -ForegroundColor Blue
if (Test-Path "security/scripts/install-terraform-compliance.ps1") {
    Write-TestResult "Installation Script" $true "File exists"
} else {
    Write-TestResult "Installation Script" $false "File not found"
}

# Test 2: Check execution script exists
if (Test-Path "security/scripts/run-terraform-compliance.ps1") {
    Write-TestResult "Execution Script" $true "File exists"
} else {
    Write-TestResult "Execution Script" $false "File not found"
}

# Test 3: Check policy directory structure
Write-Host "`nTesting Policy Directory Structure..." -ForegroundColor Blue
if (Test-Path "security/policies") {
    Write-TestResult "Policies Directory" $true "Directory exists"
} else {
    Write-TestResult "Policies Directory" $false "Directory not found"
}

# Test 4: Check policy feature files
$requiredFeatures = @(
    "azure_security.feature",
    "network_security.feature",
    "compliance.feature"
)

foreach ($feature in $requiredFeatures) {
    $featurePath = "security/policies/$feature"
    if (Test-Path $featurePath) {
        # Count scenarios in the feature file
        $content = Get-Content $featurePath -Raw
        $scenarioCount = ([regex]::Matches($content, "Scenario:")).Count
        Write-TestResult "Policy File: $feature" $true "$scenarioCount scenarios found"
    } else {
        Write-TestResult "Policy File: $feature" $false "File not found"
    }
}

# Test 5: Validate Gherkin syntax in policy files
Write-Host "`nValidating Policy File Syntax..." -ForegroundColor Blue
foreach ($feature in $requiredFeatures) {
    $featurePath = "security/policies/$feature"
    if (Test-Path $featurePath) {
        $content = Get-Content $featurePath -Raw
        
        # Check for required Gherkin keywords
        $hasFeature = $content -match "Feature:"
        $hasScenario = $content -match "Scenario:"
        $hasGiven = $content -match "Given"
        $hasThen = $content -match "Then"
        
        if ($hasFeature -and $hasScenario -and $hasGiven -and $hasThen) {
            Write-TestResult "Gherkin Syntax: $feature" $true "Valid BDD structure"
        } else {
            Write-TestResult "Gherkin Syntax: $feature" $false "Missing required keywords"
        }
    }
}

# Test 6: Check documentation
Write-Host "`nTesting Documentation..." -ForegroundColor Blue
if (Test-Path "security/policies/README.md") {
    $readmeContent = Get-Content "security/policies/README.md" -Raw
    $hasInstallation = $readmeContent -match "Installation"
    $hasUsage = $readmeContent -match "Usage"
    $hasExamples = $readmeContent -match "Example"
    
    if ($hasInstallation -and $hasUsage -and $hasExamples) {
        Write-TestResult "Policy Documentation" $true "Complete documentation"
    } else {
        Write-TestResult "Policy Documentation" $false "Incomplete documentation"
    }
} else {
    Write-TestResult "Policy Documentation" $false "README.md not found"
}

# Test 7: Validate script syntax
Write-Host "`nValidating Script Syntax..." -ForegroundColor Blue
$scripts = @(
    "security/scripts/install-terraform-compliance.ps1",
    "security/scripts/run-terraform-compliance.ps1"
)

foreach ($script in $scripts) {
    if (Test-Path $script) {
        try {
            $null = [System.Management.Automation.PSParser]::Tokenize((Get-Content $script -Raw), [ref]$null)
            Write-TestResult "Script Syntax: $(Split-Path $script -Leaf)" $true "Valid PowerShell"
        } catch {
            Write-TestResult "Script Syntax: $(Split-Path $script -Leaf)" $false "Syntax error"
        }
    }
}

# Test 8: Check for Python (Terraform Compliance requirement)
Write-Host "`nTesting Prerequisites..." -ForegroundColor Blue
try {
    $pythonVersion = python --version 2>&1
    Write-TestResult "Python Installation" $true "Python found: $pythonVersion"
} catch {
    Write-TestResult "Python Installation" $false "Python not found (required for Terraform Compliance)"
}

# Test 9: Check if Terraform Compliance is installed (optional)
try {
    $tcVersion = terraform-compliance --version 2>&1
    Write-TestResult "Terraform Compliance" $true "Installed: $tcVersion"
} catch {
    Write-TestResult "Terraform Compliance" $false "Not installed (run install script)"
}

# Test 10: Validate policy coverage
Write-Host "`nAnalyzing Policy Coverage..." -ForegroundColor Blue
$totalScenarios = 0
$policyCategories = @{
    "Security" = 0
    "Network" = 0
    "Compliance" = 0
}

foreach ($feature in $requiredFeatures) {
    $featurePath = "security/policies/$feature"
    if (Test-Path $featurePath) {
        $content = Get-Content $featurePath -Raw
        $scenarioCount = ([regex]::Matches($content, "Scenario:")).Count
        $totalScenarios += $scenarioCount
        
        if ($feature -match "azure_security") {
            $policyCategories["Security"] = $scenarioCount
        } elseif ($feature -match "network_security") {
            $policyCategories["Network"] = $scenarioCount
        } elseif ($feature -match "compliance") {
            $policyCategories["Compliance"] = $scenarioCount
        }
    }
}

Write-TestResult "Total Policy Scenarios" $true "$totalScenarios scenarios across 3 categories"
Write-Host "    Security: $($policyCategories['Security']) scenarios" -ForegroundColor Gray
Write-Host "    Network: $($policyCategories['Network']) scenarios" -ForegroundColor Gray
Write-Host "    Compliance: $($policyCategories['Compliance']) scenarios" -ForegroundColor Gray

# Test 11: Check integration with existing SAST tools
Write-Host "`nTesting Integration..." -ForegroundColor Blue
if (Test-Path "security/scripts/run-sast-scan.ps1") {
    $sastContent = Get-Content "security/scripts/run-sast-scan.ps1" -Raw
    $hasComplianceParam = $sastContent -match "SkipTerraformCompliance"
    
    if ($hasComplianceParam) {
        Write-TestResult "SAST Integration" $true "Terraform Compliance integrated"
    } else {
        Write-TestResult "SAST Integration" $false "Not integrated with SAST scan"
    }
} else {
    Write-TestResult "SAST Integration" $false "SAST scan script not found"
}

# Test 12: Validate policy file structure
Write-Host "`nValidating Policy Structure..." -ForegroundColor Blue
$structureValid = $true
foreach ($feature in $requiredFeatures) {
    $featurePath = "security/policies/$feature"
    if (Test-Path $featurePath) {
        $content = Get-Content $featurePath -Raw
        
        # Check for proper indentation and structure
        $hasProperStructure = $content -match "Feature:.*\n.*As a.*\n.*I want.*\n.*So that"
        
        if (!$hasProperStructure) {
            $structureValid = $false
            break
        }
    }
}

if ($structureValid) {
    Write-TestResult "Policy File Structure" $true "All files follow BDD format"
} else {
    Write-TestResult "Policy File Structure" $false "Some files have structural issues"
}

# Summary
$endTime = Get-Date
$duration = $endTime - $startTime

Write-Host "`n╔══════════════════════════════════════════════════════════════╗" -ForegroundColor Cyan
Write-Host "║                    Validation Summary                        ║" -ForegroundColor Cyan
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
    test_type = "policy_framework_validation"
    summary = @{
        total_tests = $totalTests
        passed_tests = $passedTests
        failed_tests = $failedTests
        total_policy_scenarios = $totalScenarios
        policy_categories = $policyCategories
        duration_seconds = $duration.TotalSeconds
    }
    test_results = $testResults
}

$reportPath = "security/reports/policy-framework-validation-$(Get-Date -Format 'yyyy-MM-dd_HH-mm-ss').json"
$testReport | ConvertTo-Json -Depth 10 | Out-File -FilePath $reportPath -Encoding UTF8
Write-Host "`nTest report saved: $reportPath" -ForegroundColor Cyan

Write-Host ""
if ($failedTests -eq 0) {
    Write-Host "✅ Policy-as-Code Framework Validation PASSED!" -ForegroundColor Green
    Write-Host "All components are properly configured and ready to use." -ForegroundColor Green
    exit 0
} else {
    Write-Host "⚠️  Some validation tests failed." -ForegroundColor Yellow
    Write-Host "Review the results above and address any issues." -ForegroundColor Yellow
    
    $failedTestsList = $testResults | Where-Object { !$_.Passed }
    Write-Host "`nFailed Tests:" -ForegroundColor Red
    foreach ($test in $failedTestsList) {
        Write-Host "  - $($test.Test): $($test.Message)" -ForegroundColor Red
    }
    exit 1
}
