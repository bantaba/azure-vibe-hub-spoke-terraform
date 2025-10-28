# Integration Test Runner for Security Workflows
# Orchestrates and executes all security workflow integration tests

param(
    [switch]$RunSASTTests = $true,
    [switch]$RunPipelineTests = $true,
    [switch]$RunWorkflowTests = $true,
    [switch]$RunAggregationTests = $true,
    [switch]$GenerateReport = $true,
    [switch]$CleanupAfterTests = $true,
    [switch]$Verbose = $false,
    [string]$TestEnvironment = "integration",
    [string]$ReportFormat = "html"
)

# Initialize script variables
$ErrorActionPreference = "Stop"
Set-StrictMode -Version Latest

$script:TestSuiteResults = @()
$script:TestStartTime = Get-Date
$script:TestReportPath = "security/reports/integration-test-report-$(Get-Date -Format 'yyyy-MM-dd_HH-mm-ss')"

# Function to write colored output
function Write-ColorOutput {
    param(
        [string]$Message,
        [string]$Color = "White"
    )
    
    $colorMap = @{
        "Red" = [ConsoleColor]::Red
        "Green" = [ConsoleColor]::Green
        "Yellow" = [ConsoleColor]::Yellow
        "Blue" = [ConsoleColor]::Blue
        "Cyan" = [ConsoleColor]::Cyan
        "Magenta" = [ConsoleColor]::Magenta
        "Gray" = [ConsoleColor]::Gray
        "White" = [ConsoleColor]::White
    }
    
    Write-Host $Message -ForegroundColor $colorMap[$Color]
}

# Function to record test suite result
function Add-TestSuiteResult {
    param(
        [string]$SuiteName,
        [bool]$Passed,
        [int]$TotalTests,
        [int]$PassedTests,
        [int]$FailedTests,
        [string]$Duration,
        [string]$ReportPath = "",
        [object]$Details = $null
    )
    
    $result = @{
        "suite_name" = $SuiteName
        "passed" = $Passed
        "total_tests" = $TotalTests
        "passed_tests" = $PassedTests
        "failed_tests" = $FailedTests
        "success_rate" = if ($TotalTests -gt 0) { [Math]::Round(($PassedTests / $TotalTests) * 100, 1) } else { 0 }
        "duration" = $Duration
        "timestamp" = Get-Date
        "report_path" = $ReportPath
        "details" = $Details
    }
    
    $script:TestSuiteResults += $result
    
    $status = if ($Passed) { "✅ PASS" } else { "❌ FAIL" }
    $color = if ($Passed) { "Green" } else { "Red" }
    
    Write-ColorOutput "$status - $SuiteName ($PassedTests/$TotalTests tests passed)" $color
    if ($Duration) {
        Write-ColorOutput "    Duration: $Duration" "Gray"
    }
}

# Function to run a test script and capture results
function Invoke-TestScript {
    param(
        [string]$ScriptPath,
        [string]$SuiteName,
        [hashtable]$Parameters = @{}
    )
    
    Write-ColorOutput "`n=== Running $SuiteName ===" "Cyan"
    
    if (!(Test-Path $ScriptPath)) {
        Add-TestSuiteResult -SuiteName $SuiteName -Passed $false -TotalTests 0 -PassedTests 0 -FailedTests 1 -Duration "0s" -Details "Script not found: $ScriptPath"
        return
    }
    
    $suiteStartTime = Get-Date
    
    try {
        # Execute the test script with parameters
        $scriptResult = & $ScriptPath @Parameters 2>&1
        
        $suiteEndTime = Get-Date
        $suiteDuration = $suiteEndTime - $suiteStartTime
        
        # Try to parse the test results from the script output
        $reportPattern = "Test report saved: (.+\.json)"
        $reportMatch = $scriptResult | Select-String -Pattern $reportPattern
        
        if ($reportMatch) {
            $reportPath = $reportMatch.Matches[0].Groups[1].Value
            
            if (Test-Path $reportPath) {
                try {
                    $testReport = Get-Content $reportPath -Raw | ConvertFrom-Json
                    
                    $totalTests = $testReport.summary.total_tests
                    $passedTests = $testReport.summary.passed_tests
                    $failedTests = $testReport.summary.failed_tests
                    $suitePassed = ($failedTests -eq 0)
                    
                    Add-TestSuiteResult -SuiteName $SuiteName -Passed $suitePassed -TotalTests $totalTests -PassedTests $passedTests -FailedTests $failedTests -Duration $suiteDuration.ToString('mm\:ss') -ReportPath $reportPath -Details $testReport
                    
                } catch {
                    Write-ColorOutput "Error parsing test report: $_" "Yellow"
                    Add-TestSuiteResult -SuiteName $SuiteName -Passed $false -TotalTests 0 -PassedTests 0 -FailedTests 1 -Duration $suiteDuration.ToString('mm\:ss') -Details "Error parsing test report"
                }
            } else {
                Add-TestSuiteResult -SuiteName $SuiteName -Passed $false -TotalTests 0 -PassedTests 0 -FailedTests 1 -Duration $suiteDuration.ToString('mm\:ss') -Details "Test report not found"
            }
        } else {
            # Fallback: analyze script output for pass/fail indicators
            $passMatches = $scriptResult | Select-String -Pattern "✅ PASS" -AllMatches
            $failMatches = $scriptResult | Select-String -Pattern "❌ FAIL" -AllMatches
            
            $passCount = if ($passMatches) { $passMatches.Matches.Count } else { 0 }
            $failCount = if ($failMatches) { $failMatches.Matches.Count } else { 0 }
            $totalCount = $passCount + $failCount
            
            if ($totalCount -gt 0) {
                $suitePassed = ($failCount -eq 0)
                Add-TestSuiteResult -SuiteName $SuiteName -Passed $suitePassed -TotalTests $totalCount -PassedTests $passCount -FailedTests $failCount -Duration $suiteDuration.ToString('mm\:ss')
            } else {
                Add-TestSuiteResult -SuiteName $SuiteName -Passed $true -TotalTests 1 -PassedTests 1 -FailedTests 0 -Duration $suiteDuration.ToString('mm\:ss') -Details "Script executed successfully"
            }
        }
        
    } catch {
        $suiteEndTime = Get-Date
        $suiteDuration = $suiteEndTime - $suiteStartTime
        
        Write-ColorOutput "Error running $SuiteName : $_" "Red"
        Add-TestSuiteResult -SuiteName $SuiteName -Passed $false -TotalTests 0 -PassedTests 0 -FailedTests 1 -Duration $suiteDuration.ToString('mm\:ss') -Details "Script execution error: $_"
    }
}

# Function to check prerequisites
function Test-Prerequisites {
    Write-ColorOutput "Checking test prerequisites..." "Blue"
    
    $prerequisites = @{
        "PowerShell Version" = $PSVersionTable.PSVersion.Major -ge 5
        "Security Scripts Directory" = Test-Path "security/scripts"
        "Reports Directory" = Test-Path "security/reports"
        "SAST Tools Config" = Test-Path "security/sast-tools"
    }
    
    $missingPrereqs = @()
    foreach ($prereq in $prerequisites.Keys) {
        if (!$prerequisites[$prereq]) {
            $missingPrereqs += $prereq
        }
    }
    
    if ($missingPrereqs.Count -eq 0) {
        Write-ColorOutput "✅ All prerequisites met" "Green"
        return $true
    } else {
        Write-ColorOutput "❌ Missing prerequisites: $($missingPrereqs -join ', ')" "Red"
        return $false
    }
}

# Function to prepare test environment
function Initialize-TestEnvironment {
    Write-ColorOutput "Initializing test environment..." "Blue"
    
    # Ensure required directories exist
    $requiredDirs = @(
        "security/reports",
        "security/reports/test-data",
        "security/reports/aggregated",
        "security/reports/baselines",
        "security/reports/dashboard"
    )
    
    foreach ($dir in $requiredDirs) {
        if (!(Test-Path $dir)) {
            New-Item -ItemType Directory -Path $dir -Force | Out-Null
            Write-ColorOutput "Created directory: $dir" "Gray"
        }
    }
    
    # Create test environment marker
    $envMarker = @{
        "environment" = $TestEnvironment
        "initialized" = Get-Date -Format "yyyy-MM-ddTHH:mm:ssZ"
        "test_runner_version" = "1.0"
    }
    
    $envMarkerPath = "security/reports/test-environment.json"
    $envMarker | ConvertTo-Json | Out-File -FilePath $envMarkerPath -Encoding UTF8
    
    Write-ColorOutput "Test environment initialized" "Green"
}

# Function to run SAST integration tests
function Invoke-SASTIntegrationTests {
    if (!$RunSASTTests) {
        Write-ColorOutput "Skipping SAST integration tests" "Yellow"
        return
    }
    
    $sastTestScript = "security/scripts/test-security-workflows.ps1"
    $sastParameters = @{
        "TestSASTIntegration" = $true
        "TestCIPipeline" = $false
        "TestEndToEnd" = $false
        "CreateTestData" = $true
        "CleanupAfterTest" = $false
        "Verbose" = $Verbose
        "TestEnvironment" = $TestEnvironment
    }
    
    Invoke-TestScript -ScriptPath $sastTestScript -SuiteName "SAST Tool Integration Tests" -Parameters $sastParameters
}

# Function to run CI/CD pipeline tests
function Invoke-PipelineTests {
    if (!$RunPipelineTests) {
        Write-ColorOutput "Skipping CI/CD pipeline tests" "Yellow"
        return
    }
    
    $pipelineTestScript = "security/scripts/test-security-workflows.ps1"
    $pipelineParameters = @{
        "TestSASTIntegration" = $false
        "TestCIPipeline" = $true
        "TestEndToEnd" = $false
        "CreateTestData" = $false
        "CleanupAfterTest" = $false
        "Verbose" = $Verbose
        "TestEnvironment" = $TestEnvironment
    }
    
    Invoke-TestScript -ScriptPath $pipelineTestScript -SuiteName "CI/CD Pipeline Security Tests" -Parameters $pipelineParameters
}

# Function to run end-to-end workflow tests
function Invoke-WorkflowTests {
    if (!$RunWorkflowTests) {
        Write-ColorOutput "Skipping end-to-end workflow tests" "Yellow"
        return
    }
    
    $workflowTestScript = "security/scripts/test-security-workflows.ps1"
    $workflowParameters = @{
        "TestSASTIntegration" = $false
        "TestCIPipeline" = $false
        "TestEndToEnd" = $true
        "CreateTestData" = $true
        "CleanupAfterTest" = $false
        "Verbose" = $Verbose
        "TestEnvironment" = $TestEnvironment
    }
    
    Invoke-TestScript -ScriptPath $workflowTestScript -SuiteName "End-to-End Workflow Tests" -Parameters $workflowParameters
}

# Function to run aggregation tests
function Invoke-AggregationTests {
    if (!$RunAggregationTests) {
        Write-ColorOutput "Skipping aggregation tests" "Yellow"
        return
    }
    
    $aggregationTestScript = "security/scripts/test-security-aggregation.ps1"
    $aggregationParameters = @{
        "CreateSampleData" = $true
        "TestAggregation" = $true
        "TestDashboard" = $true
        "TestTrendAnalysis" = $true
        "CleanupAfterTest" = $false
        "Verbose" = $Verbose
    }
    
    Invoke-TestScript -ScriptPath $aggregationTestScript -SuiteName "Security Report Aggregation Tests" -Parameters $aggregationParameters
}

# Function to cleanup test environment
function Clear-TestEnvironment {
    if (!$CleanupAfterTests) {
        Write-ColorOutput "Skipping test environment cleanup" "Yellow"
        return
    }
    
    Write-ColorOutput "Cleaning up test environment..." "Blue"
    
    try {
        # Clean up test data directories
        $testDataDirs = @(
            "security/reports/test-data"
        )
        
        foreach ($dir in $testDataDirs) {
            if (Test-Path $dir) {
                Remove-Item $dir -Recurse -Force
                Write-ColorOutput "Removed test data directory: $dir" "Gray"
            }
        }
        
        # Clean up temporary test files
        $tempFiles = Get-ChildItem -Path "security/reports" -Filter "*test*" -File -ErrorAction SilentlyContinue
        foreach ($file in $tempFiles) {
            if ($file.Name -notmatch "integration-test-report") {
                Remove-Item $file.FullName -Force
                Write-ColorOutput "Removed temporary file: $($file.Name)" "Gray"
            }
        }
        
        # Remove environment marker
        $envMarkerPath = "security/reports/test-environment.json"
        if (Test-Path $envMarkerPath) {
            Remove-Item $envMarkerPath -Force
        }
        
        Write-ColorOutput "Test environment cleanup completed" "Green"
        
    } catch {
        Write-ColorOutput "Error during cleanup: $_" "Yellow"
    }
}

# Function to generate comprehensive test report
function New-IntegrationTestReport {
    if (!$GenerateReport) {
        Write-ColorOutput "Skipping test report generation" "Yellow"
        return
    }
    
    Write-ColorOutput "Generating integration test report..." "Blue"
    
    $endTime = Get-Date
    $totalDuration = $endTime - $script:TestStartTime
    
    # Calculate overall statistics
    $totalSuites = $script:TestSuiteResults.Count
    $passedSuites = ($script:TestSuiteResults | Where-Object { $_.passed }).Count
    $failedSuites = $totalSuites - $passedSuites
    
    $totalTests = if ($script:TestSuiteResults.Count -gt 0) { ($script:TestSuiteResults | Measure-Object -Property total_tests -Sum).Sum } else { 0 }
    $totalPassedTests = if ($script:TestSuiteResults.Count -gt 0) { ($script:TestSuiteResults | Measure-Object -Property passed_tests -Sum).Sum } else { 0 }
    $totalFailedTests = if ($script:TestSuiteResults.Count -gt 0) { ($script:TestSuiteResults | Measure-Object -Property failed_tests -Sum).Sum } else { 0 }
    
    $overallSuccessRate = if ($totalTests -gt 0) { [Math]::Round(($totalPassedTests / $totalTests) * 100, 1) } else { 0 }
    
    # Create comprehensive report
    $integrationReport = @{
        "timestamp" = Get-Date -Format "yyyy-MM-ddTHH:mm:ssZ"
        "test_environment" = $TestEnvironment
        "summary" = @{
            "total_suites" = $totalSuites
            "passed_suites" = $passedSuites
            "failed_suites" = $failedSuites
            "total_tests" = $totalTests
            "passed_tests" = $totalPassedTests
            "failed_tests" = $totalFailedTests
            "overall_success_rate" = $overallSuccessRate
            "total_duration" = $totalDuration.ToString()
            "duration_seconds" = $totalDuration.TotalSeconds
        }
        "test_suites" = $script:TestSuiteResults
        "configuration" = @{
            "sast_tests_enabled" = $RunSASTTests
            "pipeline_tests_enabled" = $RunPipelineTests
            "workflow_tests_enabled" = $RunWorkflowTests
            "aggregation_tests_enabled" = $RunAggregationTests
            "cleanup_enabled" = $CleanupAfterTests
            "verbose_mode" = $Verbose
        }
        "environment_info" = @{
            "powershell_version" = $PSVersionTable.PSVersion.ToString()
            "os_version" = [System.Environment]::OSVersion.ToString()
            "machine_name" = [System.Environment]::MachineName
            "user_name" = [System.Environment]::UserName
        }
    }
    
    # Save JSON report
    $jsonReportPath = "$script:TestReportPath.json"
    $integrationReport | ConvertTo-Json -Depth 10 | Out-File -FilePath $jsonReportPath -Encoding UTF8
    Write-ColorOutput "JSON report saved: $jsonReportPath" "Green"
    
    # Generate HTML report if requested
    if ($ReportFormat -eq "html" -or $ReportFormat -eq "both") {
        $htmlReport = New-HTMLTestReport -ReportData $integrationReport
        $htmlReportPath = "$script:TestReportPath.html"
        $htmlReport | Out-File -FilePath $htmlReportPath -Encoding UTF8
        Write-ColorOutput "HTML report saved: $htmlReportPath" "Green"
    }
    
    return $jsonReportPath
}

# Function to create HTML test report
function New-HTMLTestReport {
    param([hashtable]$ReportData)
    
    $html = @"
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Security Workflow Integration Test Report</title>
    <style>
        * { margin: 0; padding: 0; box-sizing: border-box; }
        body { font-family: 'Segoe UI', Tahoma, Geneva, Verdana, sans-serif; background: #f5f7fa; padding: 20px; }
        .container { max-width: 1200px; margin: 0 auto; }
        .header { background: linear-gradient(135deg, #667eea 0%, #764ba2 100%); color: white; padding: 30px; border-radius: 10px; margin-bottom: 20px; text-align: center; }
        .header h1 { font-size: 2.5em; margin-bottom: 10px; }
        .header .subtitle { font-size: 1.2em; opacity: 0.9; }
        .summary { display: grid; grid-template-columns: repeat(auto-fit, minmax(200px, 1fr)); gap: 20px; margin-bottom: 30px; }
        .metric-card { background: white; padding: 20px; border-radius: 10px; box-shadow: 0 4px 6px rgba(0,0,0,0.1); text-align: center; }
        .metric-card.success { border-left: 5px solid #27ae60; }
        .metric-card.warning { border-left: 5px solid #f39c12; }
        .metric-card.error { border-left: 5px solid #e74c3c; }
        .metric-value { font-size: 2.5em; font-weight: bold; margin-bottom: 5px; }
        .metric-label { color: #666; font-size: 0.9em; }
        .suite-results { background: white; border-radius: 10px; padding: 20px; box-shadow: 0 4px 6px rgba(0,0,0,0.1); margin-bottom: 20px; }
        .suite-header { display: flex; justify-content: space-between; align-items: center; margin-bottom: 15px; padding-bottom: 10px; border-bottom: 1px solid #eee; }
        .suite-name { font-size: 1.3em; font-weight: bold; }
        .suite-status { padding: 5px 15px; border-radius: 20px; font-size: 0.9em; font-weight: bold; }
        .suite-status.passed { background: #27ae60; color: white; }
        .suite-status.failed { background: #e74c3c; color: white; }
        .suite-details { display: grid; grid-template-columns: repeat(auto-fit, minmax(150px, 1fr)); gap: 15px; }
        .suite-metric { text-align: center; }
        .suite-metric-value { font-size: 1.5em; font-weight: bold; }
        .suite-metric-label { color: #666; font-size: 0.8em; }
        .footer { text-align: center; color: #666; margin-top: 30px; padding: 20px; }
    </style>
</head>
<body>
    <div class="container">
        <div class="header">
            <h1>🛡️ Security Workflow Integration Test Report</h1>
            <div class="subtitle">Generated: $($ReportData.timestamp)</div>
            <div class="subtitle">Environment: $($ReportData.test_environment)</div>
        </div>
        
        <div class="summary">
            <div class="metric-card $(if($ReportData.summary.failed_suites -eq 0){'success'}else{'error'})">
                <div class="metric-value">$($ReportData.summary.passed_suites)/$($ReportData.summary.total_suites)</div>
                <div class="metric-label">Test Suites Passed</div>
            </div>
            <div class="metric-card $(if($ReportData.summary.failed_tests -eq 0){'success'}elseif($ReportData.summary.failed_tests -lt 5){'warning'}else{'error'})">
                <div class="metric-value">$($ReportData.summary.passed_tests)/$($ReportData.summary.total_tests)</div>
                <div class="metric-label">Individual Tests Passed</div>
            </div>
            <div class="metric-card $(if($ReportData.summary.overall_success_rate -ge 90){'success'}elseif($ReportData.summary.overall_success_rate -ge 70){'warning'}else{'error'})">
                <div class="metric-value">$($ReportData.summary.overall_success_rate)%</div>
                <div class="metric-label">Success Rate</div>
            </div>
            <div class="metric-card">
                <div class="metric-value">$($ReportData.summary.total_duration)</div>
                <div class="metric-label">Total Duration</div>
            </div>
        </div>
        
        <h2 style="margin-bottom: 20px;">Test Suite Results</h2>
"@

    foreach ($suite in $ReportData.test_suites) {
        $statusClass = if ($suite.passed) { "passed" } else { "failed" }
        $statusText = if ($suite.passed) { "PASSED" } else { "FAILED" }
        
        $html += @"
        <div class="suite-results">
            <div class="suite-header">
                <div class="suite-name">$($suite.suite_name)</div>
                <div class="suite-status $statusClass">$statusText</div>
            </div>
            <div class="suite-details">
                <div class="suite-metric">
                    <div class="suite-metric-value">$($suite.total_tests)</div>
                    <div class="suite-metric-label">Total Tests</div>
                </div>
                <div class="suite-metric">
                    <div class="suite-metric-value">$($suite.passed_tests)</div>
                    <div class="suite-metric-label">Passed</div>
                </div>
                <div class="suite-metric">
                    <div class="suite-metric-value">$($suite.failed_tests)</div>
                    <div class="suite-metric-label">Failed</div>
                </div>
                <div class="suite-metric">
                    <div class="suite-metric-value">$($suite.success_rate)%</div>
                    <div class="suite-metric-label">Success Rate</div>
                </div>
                <div class="suite-metric">
                    <div class="suite-metric-value">$($suite.duration)</div>
                    <div class="suite-metric-label">Duration</div>
                </div>
            </div>
        </div>
"@
    }

    $html += @"
        
        <div class="footer">
            <p>Report generated by Security Workflow Integration Test Runner v1.0</p>
            <p>PowerShell Version: $($ReportData.environment_info.powershell_version) | OS: $($ReportData.environment_info.os_version)</p>
        </div>
    </div>
</body>
</html>
"@

    return $html
}

# Function to display final summary
function Show-FinalSummary {
    $endTime = Get-Date
    $totalDuration = $endTime - $script:TestStartTime
    
    Write-ColorOutput "`n╔══════════════════════════════════════════════════════════════╗" "Cyan"
    Write-ColorOutput "║          Security Workflow Integration Test Summary          ║" "Cyan"
    Write-ColorOutput "╚══════════════════════════════════════════════════════════════╝" "Cyan"
    
    $totalSuites = $script:TestSuiteResults.Count
    $passedSuites = ($script:TestSuiteResults | Where-Object { $_.passed }).Count
    $failedSuites = $totalSuites - $passedSuites
    
    $totalTests = if ($script:TestSuiteResults.Count -gt 0) { ($script:TestSuiteResults | Measure-Object -Property total_tests -Sum).Sum } else { 0 }
    $totalPassedTests = if ($script:TestSuiteResults.Count -gt 0) { ($script:TestSuiteResults | Measure-Object -Property passed_tests -Sum).Sum } else { 0 }
    $totalFailedTests = if ($script:TestSuiteResults.Count -gt 0) { ($script:TestSuiteResults | Measure-Object -Property failed_tests -Sum).Sum } else { 0 }
    
    Write-ColorOutput "Test Suites: $totalSuites" "White"
    Write-ColorOutput "  Passed: $passedSuites" "Green"
    Write-ColorOutput "  Failed: $failedSuites" $(if ($failedSuites -gt 0) { "Red" } else { "Green" })
    
    Write-ColorOutput "`nIndividual Tests: $totalTests" "White"
    Write-ColorOutput "  Passed: $totalPassedTests" "Green"
    Write-ColorOutput "  Failed: $totalFailedTests" $(if ($totalFailedTests -gt 0) { "Red" } else { "Green" })
    
    $overallSuccessRate = if ($totalTests -gt 0) { [Math]::Round(($totalPassedTests / $totalTests) * 100, 1) } else { 0 }
    Write-ColorOutput "`nOverall Success Rate: $overallSuccessRate%" $(if ($overallSuccessRate -ge 90) { "Green" } elseif ($overallSuccessRate -ge 70) { "Yellow" } else { "Red" })
    Write-ColorOutput "Total Duration: $($totalDuration.ToString('hh\:mm\:ss'))" "Gray"
    
    if ($failedSuites -gt 0) {
        Write-ColorOutput "`nFailed Test Suites:" "Red"
        $failedSuiteResults = $script:TestSuiteResults | Where-Object { !$_.passed }
        foreach ($suite in $failedSuiteResults) {
            Write-ColorOutput "  ❌ $($suite.suite_name) ($($suite.failed_tests) failed tests)" "Red"
        }
    }
    
    if ($totalFailedTests -eq 0) {
        Write-ColorOutput "`n🎉 All integration tests passed! Security workflows are functioning correctly." "Green"
    } elseif ($overallSuccessRate -ge 90) {
        Write-ColorOutput "`n✅ Integration tests mostly successful with minor issues." "Yellow"
    } else {
        Write-ColorOutput "`n❌ Integration tests failed. Please review the issues above." "Red"
    }
}

# Main execution
Write-ColorOutput "╔══════════════════════════════════════════════════════════════╗" "Cyan"
Write-ColorOutput "║        Security Workflow Integration Test Runner             ║" "Cyan"
Write-ColorOutput "╚══════════════════════════════════════════════════════════════╝" "Cyan"

try {
    # Check prerequisites
    if (!(Test-Prerequisites)) {
        Write-ColorOutput "Prerequisites not met. Exiting." "Red"
        exit 1
    }
    
    # Initialize test environment
    Initialize-TestEnvironment
    
    # Run test suites
    Invoke-SASTIntegrationTests
    Invoke-PipelineTests
    Invoke-WorkflowTests
    Invoke-AggregationTests
    
    # Generate comprehensive report
    $reportPath = New-IntegrationTestReport
    
    # Cleanup test environment
    Clear-TestEnvironment
    
    # Display final summary
    Show-FinalSummary
    
    if ($reportPath) {
        Write-ColorOutput "`nDetailed test report available at: $reportPath" "Cyan"
    }
    
} catch {
    Write-ColorOutput "Unexpected error during integration testing: $_" "Red"
    Write-ColorOutput "Stack trace: $($_.ScriptStackTrace)" "Red"
    exit 1
}