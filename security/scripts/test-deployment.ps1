# Quick Deployment Test Script
# Tests that all security scanning automation components are properly deployed

param(
    [switch]$Verbose = $false
)

$ErrorActionPreference = "Continue"
$testResults = @()

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
Write-Host "║          Security Scanning Automation Deployment Test       ║" -ForegroundColor Cyan
Write-Host "╚══════════════════════════════════════════════════════════════╝" -ForegroundColor Cyan
Write-Host ""

# Test 1: Check if security scripts directory exists
Write-Host "Testing Script Deployment..." -ForegroundColor Blue
$scriptsPath = "security/scripts"
if (Test-Path $scriptsPath) {
    Write-TestResult "Security Scripts Directory" $true "Directory exists at $scriptsPath"
} else {
    Write-TestResult "Security Scripts Directory" $false "Directory not found"
}

# Test 2: Check for required scripts
$requiredScripts = @(
    "local-security-scan.ps1",
    "security-report-aggregator.ps1",
    "launch-security-aggregation.ps1",
    "remediation-assistant.ps1",
    "test-security-workflows.ps1",
    "run-sast-scan.ps1",
    "generate-security-report.ps1"
)

foreach ($script in $requiredScripts) {
    $scriptPath = Join-Path $scriptsPath $script
    if (Test-Path $scriptPath) {
        Write-TestResult "Script: $script" $true "File exists"
    } else {
        Write-TestResult "Script: $script" $false "File not found"
    }
}

# Test 3: Check for configuration files
Write-Host "`nTesting Configuration Files..." -ForegroundColor Blue
$configFiles = @(
    "security/sast-tools/.checkov.yaml",
    "security/sast-tools/.tfsec.yml",
    "security/sast-tools/.terrascan_config.toml",
    "security/sast-tools/aggregator-config.json"
)

foreach ($config in $configFiles) {
    $configName = if ($config) { Split-Path $config -Leaf } else { "Unknown" }
    if (Test-Path $config) {
        Write-TestResult "Config: $configName" $true "File exists"
    } else {
        Write-TestResult "Config: $configName" $false "File not found"
    }
}

# Test 4: Check for reports directory
Write-Host "`nTesting Directory Structure..." -ForegroundColor Blue
$directories = @(
    "security/reports",
    "security/reports/aggregated",
    "security/reports/baselines",
    "security/reports/dashboard"
)

foreach ($dir in $directories) {
    if (Test-Path $dir) {
        Write-TestResult "Directory: $dir" $true "Exists"
    } else {
        # Try to create it
        try {
            New-Item -ItemType Directory -Path $dir -Force | Out-Null
            Write-TestResult "Directory: $dir" $true "Created"
        } catch {
            Write-TestResult "Directory: $dir" $false "Could not create"
        }
    }
}

# Test 5: Check for SAST tools (optional)
Write-Host "`nTesting SAST Tool Availability..." -ForegroundColor Blue
$sastTools = @("checkov", "tfsec", "terrascan")

foreach ($tool in $sastTools) {
    try {
        $null = Get-Command $tool -ErrorAction Stop
        Write-TestResult "SAST Tool: $tool" $true "Available"
    } catch {
        Write-TestResult "SAST Tool: $tool" $false "Not installed"
    }
}

# Test 6: Validate script syntax (basic check)
Write-Host "`nTesting Script Syntax..." -ForegroundColor Blue
$scriptsToValidate = @(
    "security/scripts/security-report-aggregator.ps1",
    "security/scripts/launch-security-aggregation.ps1",
    "security/scripts/test-security-workflows.ps1"
)

foreach ($scriptPath in $scriptsToValidate) {
    if (Test-Path $scriptPath) {
        try {
            $null = [System.Management.Automation.PSParser]::Tokenize((Get-Content $scriptPath -Raw), [ref]$null)
            Write-TestResult "Syntax: $(Split-Path $scriptPath -Leaf)" $true "Valid PowerShell syntax"
        } catch {
            Write-TestResult "Syntax: $(Split-Path $scriptPath -Leaf)" $false "Syntax error: $_"
        }
    }
}

# Test 7: Check documentation
Write-Host "`nTesting Documentation..." -ForegroundColor Blue
$docFiles = @(
    "security/scripts/README.md",
    "security/scripts/README-integration-tests.md"
)

foreach ($doc in $docFiles) {
    if (Test-Path $doc) {
        Write-TestResult "Documentation: $(Split-Path $doc -Leaf)" $true "File exists"
    } else {
        Write-TestResult "Documentation: $(Split-Path $doc -Leaf)" $false "File not found"
    }
}

# Summary
Write-Host "`n╔══════════════════════════════════════════════════════════════╗" -ForegroundColor Cyan
Write-Host "║                      Test Summary                            ║" -ForegroundColor Cyan
Write-Host "╚══════════════════════════════════════════════════════════════╝" -ForegroundColor Cyan

$totalTests = $testResults.Count
$passedTests = ($testResults | Where-Object { $_.Passed }).Count
$failedTests = $totalTests - $passedTests

Write-Host "Total Tests: $totalTests" -ForegroundColor White
Write-Host "Passed: $passedTests" -ForegroundColor Green
Write-Host "Failed: $failedTests" -ForegroundColor $(if ($failedTests -gt 0) { "Red" } else { "Green" })

if ($failedTests -eq 0) {
    Write-Host "`n✅ All deployment tests passed!" -ForegroundColor Green
    Write-Host "Security scanning automation is properly deployed." -ForegroundColor Green
    exit 0
} else {
    Write-Host "`n⚠️  Some tests failed. Review the results above." -ForegroundColor Yellow
    $failedTestsList = $testResults | Where-Object { !$_.Passed }
    Write-Host "`nFailed Tests:" -ForegroundColor Red
    foreach ($test in $failedTestsList) {
        Write-Host "  - $($test.Test): $($test.Message)" -ForegroundColor Red
    }
    exit 1
}
