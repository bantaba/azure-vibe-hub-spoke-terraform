# Test Script for Security Report Aggregation
# Validates the security report aggregation functionality with sample data

param(
    [switch]$CreateSampleData = $true,
    [switch]$TestAggregation = $true,
    [switch]$TestDashboard = $true,
    [switch]$TestTrendAnalysis = $true,
    [switch]$CleanupAfterTest = $false,
    [switch]$Verbose = $false
)

# Initialize script variables
$ErrorActionPreference = "Stop"
Set-StrictMode -Version Latest

$script:TestResults = @()
$script:TestStartTime = Get-Date

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

# Function to record test result
function Add-TestResult {
    param(
        [string]$TestName,
        [bool]$Passed,
        [string]$Message = "",
        [object]$Details = $null
    )
    
    $result = @{
        "test_name" = $TestName
        "passed" = $Passed
        "message" = $Message
        "timestamp" = Get-Date
        "details" = $Details
    }
    
    $script:TestResults += $result
    
    $status = if ($Passed) { "✅ PASS" } else { "❌ FAIL" }
    $color = if ($Passed) { "Green" } else { "Red" }
    
    Write-ColorOutput "$status - $TestName" $color
    if ($Message) {
        Write-ColorOutput "    $Message" "Gray"
    }
}

# Function to create sample scan data
function New-SampleScanData {
    Write-ColorOutput "Creating sample scan data..." "Blue"
    
    # Ensure reports directory exists
    $reportsPath = "security/reports"
    if (!(Test-Path $reportsPath)) {
        New-Item -ItemType Directory -Path $reportsPath -Force | Out-Null
    }
    
    # Create sample Checkov report
    $checkovData = @{
        "results" = @{
            "failed_checks" = @(
                @{
                    "check_id" = "CKV_AZURE_33"
                    "severity" = "HIGH"
                    "resource" = "azurerm_storage_account.example"
                    "file_path" = "src/modules/Storage/storage.tf"
                    "check_name" = "Ensure storage account uses HTTPS traffic only"
                },
                @{
                    "check_id" = "CKV_AZURE_35"
                    "severity" = "MEDIUM"
                    "resource" = "azurerm_storage_account.example"
                    "file_path" = "src/modules/Storage/storage.tf"
                    "check_name" = "Ensure default network access rule for Storage Accounts is set to deny"
                },
                @{
                    "check_id" = "CKV_AZURE_40"
                    "severity" = "CRITICAL"
                    "resource" = "azurerm_key_vault.example"
                    "file_path" = "src/modules/Security/keyvault.tf"
                    "check_name" = "Ensure that the expiration date is set on all keys"
                }
            )
        }
    }
    
    $checkovPath = "$reportsPath/checkov-report.json"
    $checkovData | ConvertTo-Json -Depth 10 | Out-File -FilePath $checkovPath -Encoding UTF8
    
    # Create sample TFSec report
    $tfsecData = @{
        "results" = @(
            @{
                "rule_id" = "azure-storage-default-action-deny"
                "severity" = "HIGH"
                "resource" = "azurerm_storage_account.example"
                "location" = @{
                    "filename" = "src/modules/Storage/storage.tf"
                }
                "description" = "Storage account should have default network access rule set to deny"
            },
            @{
                "rule_id" = "azure-network-no-public-ingress"
                "severity" = "MEDIUM"
                "resource" = "azurerm_network_security_group.example"
                "location" = @{
                    "filename" = "src/modules/network/nsg.tf"
                }
                "description" = "Network security group should not allow public ingress"
            }
        )
    }
    
    $tfsecPath = "$reportsPath/tfsec-report.json"
    $tfsecData | ConvertTo-Json -Depth 10 | Out-File -FilePath $tfsecPath -Encoding UTF8
    
    # Create sample Terrascan report
    $terrascanData = @{
        "results" = @{
            "violations" = @(
                @{
                    "rule_id" = "AC_AZURE_0001"
                    "severity" = "HIGH"
                    "resource_name" = "azurerm_storage_account.example"
                    "file" = "src/modules/Storage/storage.tf"
                    "description" = "Ensure that Storage Account access keys are periodically regenerated"
                },
                @{
                    "rule_id" = "CKV_AZURE_109"
                    "severity" = "LOW"
                    "resource_name" = "azurerm_key_vault.example"
                    "file" = "src/modules/Security/keyvault.tf"
                    "description" = "Ensure that key vault allows firewall rules settings"
                }
            )
        }
    }
    
    $terrascanPath = "$reportsPath/results.json"
    $terrascanData | ConvertTo-Json -Depth 10 | Out-File -FilePath $terrascanPath -Encoding UTF8
    
    # Create sample unified report
    $unifiedData = @{
        "timestamp" = Get-Date -Format "yyyy-MM-ddTHH:mm:ssZ"
        "scan_summary" = @{
            "total_tools_run" = 3
            "total_issues" = 6
            "critical_issues" = 1
            "high_issues" = 3
            "medium_issues" = 2
            "low_issues" = 1
        }
        "tool_results" = @{
            "Checkov" = @{
                "Critical" = 1
                "High" = 1
                "Medium" = 1
                "Low" = 0
                "Info" = 0
            }
            "TFSec" = @{
                "Critical" = 0
                "High" = 1
                "Medium" = 1
                "Low" = 0
                "Info" = 0
            }
            "Terrascan" = @{
                "Critical" = 0
                "High" = 1
                "Medium" = 0
                "Low" = 1
                "Info" = 0
            }
        }
    }
    
    $unifiedPath = "$reportsPath/unified-sast-report.json"
    $unifiedData | ConvertTo-Json -Depth 10 | Out-File -FilePath $unifiedPath -Encoding UTF8
    
    Add-TestResult "Create Sample Scan Data" $true "Created sample reports for Checkov, TFSec, Terrascan, and Unified"
}

# Function to create historical data for trend analysis
function New-SampleHistoricalData {
    Write-ColorOutput "Creating sample historical data..." "Blue"
    
    $aggregatedPath = "security/reports/aggregated"
    if (!(Test-Path $aggregatedPath)) {
        New-Item -ItemType Directory -Path $aggregatedPath -Force | Out-Null
    }
    
    # Create historical data points (last 7 days)
    for ($i = 7; $i -ge 1; $i--) {
        $date = (Get-Date).AddDays(-$i)
        $timestamp = $date.ToString("yyyy-MM-dd_HH-mm-ss")
        
        # Simulate improving security posture over time
        $baseRisk = 150 + ($i * 10)  # Risk decreases over time
        $criticalFindings = [Math]::Max(0, $i - 4)
        $highFindings = [Math]::Max(1, $i - 2)
        
        $historicalData = @{
            "timestamp" = $date.ToString("yyyy-MM-ddTHH:mm:ssZ")
            "aggregation" = @{
                "summary" = @{
                    "total_findings" = $criticalFindings + $highFindings + 3
                    "critical_findings" = $criticalFindings
                    "high_findings" = $highFindings
                    "medium_findings" = 2
                    "low_findings" = 1
                    "risk_score" = $baseRisk
                }
                "security_posture" = @{
                    "current_score" = [Math]::Min(100, 100 - ($baseRisk / 5))
                    "risk_level" = if ($baseRisk -lt 100) { "low" } elseif ($baseRisk -lt 200) { "medium" } else { "high" }
                }
            }
        }
        
        $filePath = "$aggregatedPath/security-aggregation-$timestamp.json"
        $historicalData | ConvertTo-Json -Depth 10 | Out-File -FilePath $filePath -Encoding UTF8
    }
    
    Add-TestResult "Create Historical Data" $true "Created 7 days of historical aggregation data"
}

# Function to test the aggregation functionality
function Test-AggregationFunctionality {
    Write-ColorOutput "Testing aggregation functionality..." "Blue"
    
    try {
        # Test if aggregator script exists
        $aggregatorScript = "security/scripts/security-report-aggregator.ps1"
        if (!(Test-Path $aggregatorScript)) {
            Add-TestResult "Aggregator Script Exists" $false "Script not found: $aggregatorScript"
            return
        }
        
        Add-TestResult "Aggregator Script Exists" $true "Found aggregator script"
        
        # Test configuration file
        $configPath = "security/sast-tools/aggregator-config.json"
        if (!(Test-Path $configPath)) {
            Add-TestResult "Configuration File Exists" $false "Config not found: $configPath"
            return
        }
        
        Add-TestResult "Configuration File Exists" $true "Found configuration file"
        
        # Test configuration loading
        try {
            $config = Get-Content $configPath -Raw | ConvertFrom-Json
            $requiredKeys = @("severity_weights", "risk_thresholds", "trend_analysis", "dashboard")
            $missingKeys = @()
            
            foreach ($key in $requiredKeys) {
                if (!$config.PSObject.Properties.Name.Contains($key)) {
                    $missingKeys += $key
                }
            }
            
            if ($missingKeys.Count -eq 0) {
                Add-TestResult "Configuration Validation" $true "All required configuration keys present"
            } else {
                Add-TestResult "Configuration Validation" $false "Missing keys: $($missingKeys -join ', ')"
            }
        } catch {
            Add-TestResult "Configuration Validation" $false "Error parsing configuration: $_"
        }
        
        # Test directory structure
        $requiredDirs = @(
            "security/reports",
            "security/reports/aggregated",
            "security/reports/baselines",
            "security/reports/dashboard"
        )
        
        $missingDirs = @()
        foreach ($dir in $requiredDirs) {
            if (!(Test-Path $dir)) {
                $missingDirs += $dir
            }
        }
        
        if ($missingDirs.Count -eq 0) {
            Add-TestResult "Directory Structure" $true "All required directories exist"
        } else {
            Add-TestResult "Directory Structure" $false "Missing directories: $($missingDirs -join ', ')"
        }
        
    } catch {
        Add-TestResult "Aggregation Functionality Test" $false "Error during testing: $_"
    }
}

# Function to test dashboard generation
function Test-DashboardGeneration {
    Write-ColorOutput "Testing dashboard generation..." "Blue"
    
    try {
        # Run the aggregator with dashboard generation
        $aggregatorScript = "security/scripts/security-report-aggregator.ps1"
        
        $aggregatorArgs = @{
            "GenerateDashboard" = $true
            "IncludeTrendAnalysis" = $true
            "ReportFormats" = @("json", "html")
        }
        
        if ($Verbose) {
            Write-ColorOutput "Running aggregator with dashboard generation..." "Gray"
        }
        
        & $aggregatorScript @aggregatorArgs
        
        # Check if dashboard was created
        $dashboardPath = "security/reports/dashboard/security-dashboard.html"
        if (Test-Path $dashboardPath) {
            Add-TestResult "Dashboard Generation" $true "Dashboard created successfully"
            
            # Validate dashboard content
            $dashboardContent = Get-Content $dashboardPath -Raw
            $requiredElements = @("Security Dashboard", "chart.js", "trendChart", "toolChart", "categoryChart")
            $missingElements = @()
            
            foreach ($element in $requiredElements) {
                if ($dashboardContent -notmatch [regex]::Escape($element)) {
                    $missingElements += $element
                }
            }
            
            if ($missingElements.Count -eq 0) {
                Add-TestResult "Dashboard Content Validation" $true "All required elements present in dashboard"
            } else {
                Add-TestResult "Dashboard Content Validation" $false "Missing elements: $($missingElements -join ', ')"
            }
        } else {
            Add-TestResult "Dashboard Generation" $false "Dashboard file not created"
        }
        
        # Check for dashboard data file
        $dashboardDataPath = "security/reports/dashboard/dashboard-data.json"
        if (Test-Path $dashboardDataPath) {
            Add-TestResult "Dashboard Data Generation" $true "Dashboard data file created"
        } else {
            Add-TestResult "Dashboard Data Generation" $false "Dashboard data file not created"
        }
        
    } catch {
        Add-TestResult "Dashboard Generation Test" $false "Error during dashboard testing: $_"
    }
}

# Function to test trend analysis
function Test-TrendAnalysisFunctionality {
    Write-ColorOutput "Testing trend analysis functionality..." "Blue"
    
    try {
        # Import the security posture module
        $modulePath = Join-Path $PWD "security/scripts/SecurityPostureModule.psm1"
        if (Test-Path $modulePath) {
            Import-Module $modulePath -Force
            Add-TestResult "Security Posture Module Import" $true "Module imported successfully"
        } else {
            Add-TestResult "Security Posture Module Import" $false "Module not found: $modulePath"
            return
        }
        
        # Test security posture calculation
        $postureScore = Get-SecurityPostureScore -CriticalFindings 1 -HighFindings 2 -MediumFindings 3 -LowFindings 1
        
        if ($postureScore -and $postureScore.ContainsKey("security_score")) {
            Add-TestResult "Security Posture Calculation" $true "Posture score calculated: $($postureScore.security_score)"
        } else {
            Add-TestResult "Security Posture Calculation" $false "Failed to calculate security posture"
        }
        
        # Test trend analysis with sample data
        $sampleTrendData = @(
            @{ "timestamp" = (Get-Date).AddDays(-3); "risk_score" = 200 },
            @{ "timestamp" = (Get-Date).AddDays(-2); "risk_score" = 180 },
            @{ "timestamp" = (Get-Date).AddDays(-1); "risk_score" = 160 },
            @{ "timestamp" = Get-Date; "risk_score" = 140 }
        )
        
        $trends = Get-SecurityTrends -HistoricalData $sampleTrendData
        
        if ($trends -and $trends.trend_available) {
            Add-TestResult "Trend Analysis" $true "Trend analysis completed: $($trends.short_term.direction)"
        } else {
            Add-TestResult "Trend Analysis" $false "Failed to perform trend analysis"
        }
        
        # Test recommendations generation
        $recommendations = Get-SecurityRecommendations -PostureData $postureScore -TrendData $trends
        
        if ($recommendations -and $recommendations.Count -gt 0) {
            Add-TestResult "Recommendations Generation" $true "Generated $($recommendations.Count) recommendations"
        } else {
            Add-TestResult "Recommendations Generation" $false "Failed to generate recommendations"
        }
        
    } catch {
        Add-TestResult "Trend Analysis Test" $false "Error during trend analysis testing: $_"
    }
}

# Function to test launcher script
function Test-LauncherScript {
    Write-ColorOutput "Testing launcher script..." "Blue"
    
    try {
        $launcherScript = "security/scripts/launch-security-aggregation.ps1"
        
        if (Test-Path $launcherScript) {
            Add-TestResult "Launcher Script Exists" $true "Launcher script found"
            
            # Test help functionality
            try {
                $helpOutput = & $launcherScript -help 2>&1 | Out-String
                if ($helpOutput -and $helpOutput -match "Security Report Aggregation Launcher") {
                    Add-TestResult "Launcher Help Function" $true "Help function works correctly"
                } else {
                    Add-TestResult "Launcher Help Function" $false "Help output not as expected"
                }
            } catch {
                Add-TestResult "Launcher Help Function" $false "Error testing help: $_"
            }
        } else {
            Add-TestResult "Launcher Script Exists" $false "Launcher script not found"
        }
        
    } catch {
        Add-TestResult "Launcher Script Test" $false "Error testing launcher script: $_"
    }
}

# Function to cleanup test data
function Remove-TestData {
    Write-ColorOutput "Cleaning up test data..." "Blue"
    
    try {
        $testFiles = @(
            "security/reports/checkov-report.json",
            "security/reports/tfsec-report.json",
            "security/reports/results.json",
            "security/reports/unified-sast-report.json"
        )
        
        foreach ($file in $testFiles) {
            if (Test-Path $file) {
                Remove-Item $file -Force
            }
        }
        
        # Clean up historical data
        $historicalFiles = Get-ChildItem -Path "security/reports/aggregated" -Filter "security-aggregation-*.json" -ErrorAction SilentlyContinue
        foreach ($file in $historicalFiles) {
            Remove-Item $file.FullName -Force
        }
        
        # Clean up dashboard files
        $dashboardFiles = @(
            "security/reports/dashboard/security-dashboard.html",
            "security/reports/dashboard/dashboard-data.json"
        )
        
        foreach ($file in $dashboardFiles) {
            if (Test-Path $file) {
                Remove-Item $file -Force
            }
        }
        
        Add-TestResult "Cleanup Test Data" $true "Test data cleaned up successfully"
        
    } catch {
        Add-TestResult "Cleanup Test Data" $false "Error during cleanup: $_"
    }
}

# Function to display test summary
function Show-TestSummary {
    $endTime = Get-Date
    $duration = $endTime - $script:TestStartTime
    
    Write-ColorOutput "`n╔══════════════════════════════════════════════════════════════╗" "Cyan"
    Write-ColorOutput "║                    Test Summary                              ║" "Cyan"
    Write-ColorOutput "╚══════════════════════════════════════════════════════════════╝" "Cyan"
    
    $totalTests = $script:TestResults.Count
    $passedTests = ($script:TestResults | Where-Object { $_.passed }).Count
    $failedTests = $totalTests - $passedTests
    
    Write-ColorOutput "Total Tests: $totalTests" "White"
    Write-ColorOutput "Passed: $passedTests" "Green"
    Write-ColorOutput "Failed: $failedTests" $(if ($failedTests -gt 0) { "Red" } else { "Green" })
    Write-ColorOutput "Duration: $($duration.ToString('mm\:ss'))" "Gray"
    
    if ($failedTests -gt 0) {
        Write-ColorOutput "`nFailed Tests:" "Red"
        $failedTestResults = $script:TestResults | Where-Object { !$_.passed }
        foreach ($test in $failedTestResults) {
            Write-ColorOutput "  ❌ $($test.test_name): $($test.message)" "Red"
        }
    }
    
    # Save test results
    $testReport = @{
        "timestamp" = Get-Date -Format "yyyy-MM-ddTHH:mm:ssZ"
        "summary" = @{
            "total_tests" = $totalTests
            "passed_tests" = $passedTests
            "failed_tests" = $failedTests
            "success_rate" = if ($totalTests -gt 0) { [Math]::Round(($passedTests / $totalTests) * 100, 1) } else { 0 }
            "duration_seconds" = $duration.TotalSeconds
        }
        "test_results" = $script:TestResults
    }
    
    $reportPath = "security/reports/test-results-$(Get-Date -Format 'yyyy-MM-dd_HH-mm-ss').json"
    $testReport | ConvertTo-Json -Depth 10 | Out-File -FilePath $reportPath -Encoding UTF8
    Write-ColorOutput "`nTest report saved: $reportPath" "Cyan"
    
    if ($failedTests -eq 0) {
        Write-ColorOutput "`n✅ All tests passed! Security report aggregation is working correctly." "Green"
    } else {
        Write-ColorOutput "`n❌ Some tests failed. Please review the issues above." "Red"
    }
}

# Main execution
Write-ColorOutput "╔══════════════════════════════════════════════════════════════╗" "Cyan"
Write-ColorOutput "║         Security Report Aggregation Test Suite              ║" "Cyan"
Write-ColorOutput "╚══════════════════════════════════════════════════════════════╝" "Cyan"

try {
    if ($CreateSampleData) {
        New-SampleScanData
        New-SampleHistoricalData
    }
    
    if ($TestAggregation) {
        Test-AggregationFunctionality
    }
    
    if ($TestDashboard) {
        Test-DashboardGeneration
    }
    
    if ($TestTrendAnalysis) {
        Test-TrendAnalysisFunctionality
    }
    
    Test-LauncherScript
    
    if ($CleanupAfterTest) {
        Remove-TestData
    }
    
} catch {
    Write-ColorOutput "Unexpected error during testing: $_" "Red"
    Add-TestResult "Test Execution" $false "Unexpected error: $_"
} finally {
    Show-TestSummary
}