# Unified SAST Execution Script
# This script runs all SAST tools (Checkov, TFSec, Terrascan) and aggregates results

param(
    [string]$SourcePath = "src/",
    [string]$ReportsPath = "security/reports/",
    [switch]$FailOnHigh = $true,
    [switch]$FailOnCritical = $true,
    [switch]$Verbose = $false,
    [switch]$SkipCheckov = $false,
    [switch]$SkipTFSec = $false,
    [switch]$SkipTerrascan = $false,
    [string]$OutputFormat = "json"
)

# Initialize variables
$script:ExitCode = 0
$script:TotalIssues = 0
$script:CriticalIssues = 0
$script:HighIssues = 0
$script:MediumIssues = 0
$script:LowIssues = 0
$script:ScanResults = @{}

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
        "magenta" { Write-Host $Message -ForegroundColor Magenta }
        default { Write-Host $Message }
    }
}

# Function to check if a command exists
function Test-CommandExists {
    param([string]$Command)
    
    try {
        Get-Command $Command -ErrorAction Stop | Out-Null
        return $true
    } catch {
        return $false
    }
}

# Function to parse severity counts from JSON report
function Get-SeverityCounts {
    param(
        [string]$JsonPath,
        [string]$Tool
    )
    
    if (!(Test-Path $JsonPath)) {
        Write-ColorOutput "Warning: Report file not found: $JsonPath" "Yellow"
        return @{ Critical = 0; High = 0; Medium = 0; Low = 0; Info = 0 }
    }
    
    try {
        $jsonContent = Get-Content $JsonPath -Raw | ConvertFrom-Json
        $counts = @{ Critical = 0; High = 0; Medium = 0; Low = 0; Info = 0 }
        
        switch ($Tool.ToLower()) {
            "checkov" {
                if ($jsonContent.results -and $jsonContent.results.failed_checks) {
                    foreach ($check in $jsonContent.results.failed_checks) {
                        switch ($check.severity.ToUpper()) {
                            "CRITICAL" { $counts.Critical++ }
                            "HIGH" { $counts.High++ }
                            "MEDIUM" { $counts.Medium++ }
                            "LOW" { $counts.Low++ }
                            "INFO" { $counts.Info++ }
                        }
                    }
                }
            }
            "tfsec" {
                if ($jsonContent.results) {
                    foreach ($result in $jsonContent.results) {
                        switch ($result.severity.ToUpper()) {
                            "CRITICAL" { $counts.Critical++ }
                            "HIGH" { $counts.High++ }
                            "MEDIUM" { $counts.Medium++ }
                            "LOW" { $counts.Low++ }
                            "INFO" { $counts.Info++ }
                        }
                    }
                }
            }
            "terrascan" {
                if ($jsonContent.results -and $jsonContent.results.violations) {
                    foreach ($violation in $jsonContent.results.violations) {
                        switch ($violation.severity.ToUpper()) {
                            "CRITICAL" { $counts.Critical++ }
                            "HIGH" { $counts.High++ }
                            "MEDIUM" { $counts.Medium++ }
                            "LOW" { $counts.Low++ }
                            "INFO" { $counts.Info++ }
                        }
                    }
                }
            }
        }
        
        return $counts
    } catch {
        Write-ColorOutput "Error parsing $Tool report: $_" "Red"
        return @{ Critical = 0; High = 0; Medium = 0; Low = 0; Info = 0 }
    }
}

# Function to run Checkov scan
function Invoke-CheckovScan {
    Write-ColorOutput "`n=== Running Checkov Security Scan ===" "Blue"
    
    if (!(Test-CommandExists "checkov")) {
        Write-ColorOutput "Checkov not found. Please install Checkov first." "Red"
        return $false
    }
    
    $configFile = "security/sast-tools/.checkov.yaml"
    if (!(Test-Path $configFile)) {
        Write-ColorOutput "Checkov config file not found: $configFile" "Red"
        return $false
    }
    
    try {
        $checkovArgs = @(
            "--config-file", $configFile,
            "--directory", $SourcePath,
            "--output", "json",
            "--output-file-path", "$ReportsPath/checkov-report.json"
        )
        
        if ($Verbose) {
            $checkovArgs += "--verbose"
        }
        
        Write-ColorOutput "Running: checkov $($checkovArgs -join ' ')" "Gray"
        $checkovResult = & checkov @checkovArgs 2>&1
        
        if ($LASTEXITCODE -eq 0) {
            Write-ColorOutput "Checkov scan completed successfully" "Green"
        } else {
            Write-ColorOutput "Checkov scan completed with issues (exit code: $LASTEXITCODE)" "Yellow"
        }
        
        # Parse results
        $counts = Get-SeverityCounts "$ReportsPath/checkov-report.json" "checkov"
        $script:ScanResults["Checkov"] = $counts
        
        return $true
    } catch {
        Write-ColorOutput "Error running Checkov: $_" "Red"
        return $false
    }
}

# Function to run TFSec scan
function Invoke-TFSecScan {
    Write-ColorOutput "`n=== Running TFSec Security Scan ===" "Blue"
    
    if (!(Test-CommandExists "tfsec")) {
        Write-ColorOutput "TFSec not found. Please install TFSec first." "Red"
        return $false
    }
    
    $configFile = "security/sast-tools/.tfsec.yml"
    if (!(Test-Path $configFile)) {
        Write-ColorOutput "TFSec config file not found: $configFile" "Red"
        return $false
    }
    
    try {
        $tfsecArgs = @(
            "--config-file", $configFile,
            $SourcePath,
            "--format", "json",
            "--out", "$ReportsPath/tfsec-report.json"
        )
        
        if ($Verbose) {
            $tfsecArgs += "--verbose"
        }
        
        Write-ColorOutput "Running: tfsec $($tfsecArgs -join ' ')" "Gray"
        $tfsecResult = & tfsec @tfsecArgs 2>&1
        
        if ($LASTEXITCODE -eq 0) {
            Write-ColorOutput "TFSec scan completed successfully" "Green"
        } else {
            Write-ColorOutput "TFSec scan completed with issues (exit code: $LASTEXITCODE)" "Yellow"
        }
        
        # Parse results
        $counts = Get-SeverityCounts "$ReportsPath/tfsec-report.json" "tfsec"
        $script:ScanResults["TFSec"] = $counts
        
        return $true
    } catch {
        Write-ColorOutput "Error running TFSec: $_" "Red"
        return $false
    }
}

# Function to run Terrascan
function Invoke-TerrascanScan {
    Write-ColorOutput "`n=== Running Terrascan Security Scan ===" "Blue"
    
    if (!(Test-CommandExists "terrascan")) {
        Write-ColorOutput "Terrascan not found. Please install Terrascan first." "Red"
        return $false
    }
    
    $configFile = "security/sast-tools/.terrascan_config.toml"
    if (!(Test-Path $configFile)) {
        Write-ColorOutput "Terrascan config file not found: $configFile" "Red"
        return $false
    }
    
    try {
        $terrascanArgs = @(
            "scan",
            "--config-path", $configFile,
            "--iac-dir", $SourcePath,
            "--output", "json",
            "--output-dir", $ReportsPath
        )
        
        if ($Verbose) {
            $terrascanArgs += "--verbose"
        }
        
        Write-ColorOutput "Running: terrascan $($terrascanArgs -join ' ')" "Gray"
        $terrascanResult = & terrascan @terrascanArgs 2>&1
        
        if ($LASTEXITCODE -eq 0) {
            Write-ColorOutput "Terrascan scan completed successfully" "Green"
        } else {
            Write-ColorOutput "Terrascan scan completed with issues (exit code: $LASTEXITCODE)" "Yellow"
        }
        
        # Parse results (Terrascan outputs to results.json by default)
        $counts = Get-SeverityCounts "$ReportsPath/results.json" "terrascan"
        $script:ScanResults["Terrascan"] = $counts
        
        return $true
    } catch {
        Write-ColorOutput "Error running Terrascan: $_" "Red"
        return $false
    }
}

# Function to aggregate and display results
function Show-AggregatedResults {
    Write-ColorOutput "`n=== SAST Scan Results Summary ===" "Cyan"
    Write-ColorOutput "=================================" "Cyan"
    
    $totalCritical = 0
    $totalHigh = 0
    $totalMedium = 0
    $totalLow = 0
    $totalInfo = 0
    
    foreach ($tool in $script:ScanResults.Keys) {
        $counts = $script:ScanResults[$tool]
        $toolTotal = $counts.Critical + $counts.High + $counts.Medium + $counts.Low + $counts.Info
        
        Write-ColorOutput "`n$tool Results:" "Yellow"
        Write-ColorOutput "  Critical: $($counts.Critical)" $(if ($counts.Critical -gt 0) { "Red" } else { "Green" })
        Write-ColorOutput "  High:     $($counts.High)" $(if ($counts.High -gt 0) { "Red" } else { "Green" })
        Write-ColorOutput "  Medium:   $($counts.Medium)" $(if ($counts.Medium -gt 0) { "Yellow" } else { "Green" })
        Write-ColorOutput "  Low:      $($counts.Low)" $(if ($counts.Low -gt 0) { "Yellow" } else { "Green" })
        Write-ColorOutput "  Info:     $($counts.Info)" "Gray"
        Write-ColorOutput "  Total:    $toolTotal" "White"
        
        $totalCritical += $counts.Critical
        $totalHigh += $counts.High
        $totalMedium += $counts.Medium
        $totalLow += $counts.Low
        $totalInfo += $counts.Info
    }
    
    $grandTotal = $totalCritical + $totalHigh + $totalMedium + $totalLow + $totalInfo
    
    Write-ColorOutput "`nOverall Summary:" "Cyan"
    Write-ColorOutput "===============" "Cyan"
    Write-ColorOutput "Critical Issues: $totalCritical" $(if ($totalCritical -gt 0) { "Red" } else { "Green" })
    Write-ColorOutput "High Issues:     $totalHigh" $(if ($totalHigh -gt 0) { "Red" } else { "Green" })
    Write-ColorOutput "Medium Issues:   $totalMedium" $(if ($totalMedium -gt 0) { "Yellow" } else { "Green" })
    Write-ColorOutput "Low Issues:      $totalLow" $(if ($totalLow -gt 0) { "Yellow" } else { "Green" })
    Write-ColorOutput "Info Issues:     $totalInfo" "Gray"
    Write-ColorOutput "Total Issues:    $grandTotal" "White"
    
    # Set script-level variables for exit code determination
    $script:CriticalIssues = $totalCritical
    $script:HighIssues = $totalHigh
    $script:TotalIssues = $grandTotal
    
    # Determine exit code based on severity
    if ($FailOnCritical -and $totalCritical -gt 0) {
        $script:ExitCode = 1
        Write-ColorOutput "`nBuild FAILED: Critical security issues found!" "Red"
    } elseif ($FailOnHigh -and $totalHigh -gt 0) {
        $script:ExitCode = 1
        Write-ColorOutput "`nBuild FAILED: High severity security issues found!" "Red"
    } elseif ($grandTotal -eq 0) {
        Write-ColorOutput "`nBuild PASSED: No security issues found!" "Green"
    } else {
        Write-ColorOutput "`nBuild PASSED: Only low/medium severity issues found." "Yellow"
    }
}

# Function to generate unified report
function New-UnifiedReport {
    $timestamp = Get-Date -Format "yyyy-MM-ddTHH:mm:ssZ"
    $unifiedReport = @{
        timestamp = $timestamp
        scan_summary = @{
            total_tools_run = $script:ScanResults.Keys.Count
            total_issues = $script:TotalIssues
            critical_issues = $script:CriticalIssues
            high_issues = $script:HighIssues
            medium_issues = $script:MediumIssues
            low_issues = $script:LowIssues
        }
        tool_results = $script:ScanResults
        configuration = @{
            source_path = $SourcePath
            reports_path = $ReportsPath
            fail_on_critical = $FailOnCritical
            fail_on_high = $FailOnHigh
        }
    }
    
    $reportPath = "$ReportsPath/unified-sast-report.json"
    $unifiedReport | ConvertTo-Json -Depth 10 | Out-File -FilePath $reportPath -Encoding UTF8
    Write-ColorOutput "`nUnified report saved to: $reportPath" "Green"
}

# Main execution
Write-ColorOutput "Starting Unified SAST Security Scan" "Green"
Write-ColorOutput "====================================" "Green"
Write-ColorOutput "Source Path: $SourcePath" "Gray"
Write-ColorOutput "Reports Path: $ReportsPath" "Gray"
Write-ColorOutput "Fail on Critical: $FailOnCritical" "Gray"
Write-ColorOutput "Fail on High: $FailOnHigh" "Gray"

# Create reports directory if it doesn't exist
if (!(Test-Path $ReportsPath)) {
    New-Item -ItemType Directory -Path $ReportsPath -Force | Out-Null
    Write-ColorOutput "Created reports directory: $ReportsPath" "Yellow"
}

# Run scans
$scanSuccess = $true

if (!$SkipCheckov) {
    $scanSuccess = (Invoke-CheckovScan) -and $scanSuccess
}

if (!$SkipTFSec) {
    $scanSuccess = (Invoke-TFSecScan) -and $scanSuccess
}

if (!$SkipTerrascan) {
    $scanSuccess = (Invoke-TerrascanScan) -and $scanSuccess
}

# Show results and generate unified report
if ($script:ScanResults.Keys.Count -gt 0) {
    Show-AggregatedResults
    New-UnifiedReport
} else {
    Write-ColorOutput "`nNo scans were executed successfully!" "Red"
    $script:ExitCode = 1
}

Write-ColorOutput "`nScan completed. Check the reports directory for detailed results." "Cyan"
exit $script:ExitCode