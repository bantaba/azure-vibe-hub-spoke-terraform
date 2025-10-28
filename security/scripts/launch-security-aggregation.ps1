# Security Report Aggregation Launcher
# Orchestrates the complete security report aggregation workflow

param(
    [switch]$RunScansFirst = $false,
    [switch]$GenerateDashboard = $true,
    [switch]$IncludeTrendAnalysis = $true,
    [switch]$UpdateBaseline = $false,
    [switch]$OpenDashboard = $false,
    [string[]]$ReportFormats = @("html", "json", "markdown"),
    [string]$ConfigPath = "security/sast-tools/aggregator-config.json",
    [switch]$Verbose = $false,
    [switch]$h = $false,
    [switch]$help = $false
)

# Initialize script variables
$ErrorActionPreference = "Stop"
Set-StrictMode -Version Latest

$script:StartTime = Get-Date
$script:ScriptPath = Split-Path -Parent $MyInvocation.MyCommand.Path
$script:ProjectRoot = Split-Path -Parent (Split-Path -Parent $script:ScriptPath)

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

# Function to check prerequisites
function Test-Prerequisites {
    Write-ColorOutput "Checking prerequisites..." "Blue"
    
    $issues = @()
    
    # Check if required directories exist
    $requiredDirs = @(
        "security/reports",
        "security/reports/aggregated", 
        "security/reports/baselines",
        "security/reports/dashboard",
        "security/sast-tools"
    )
    
    foreach ($dir in $requiredDirs) {
        if (!(Test-Path $dir)) {
            try {
                New-Item -ItemType Directory -Path $dir -Force | Out-Null
                Write-ColorOutput "  ✓ Created directory: $dir" "Green"
            } catch {
                $issues += "Cannot create directory: $dir"
            }
        } else {
            Write-ColorOutput "  ✓ Directory exists: $dir" "Green"
        }
    }
    
    # Check if configuration file exists
    if (!(Test-Path $ConfigPath)) {
        $issues += "Configuration file not found: $ConfigPath"
    } else {
        Write-ColorOutput "  ✓ Configuration file found: $ConfigPath" "Green"
    }
    
    # Check if aggregator script exists
    $aggregatorScript = "$script:ScriptPath/security-report-aggregator.ps1"
    if (!(Test-Path $aggregatorScript)) {
        $issues += "Aggregator script not found: $aggregatorScript"
    } else {
        Write-ColorOutput "  ✓ Aggregator script found" "Green"
    }
    
    if ($issues.Count -gt 0) {
        Write-ColorOutput "Prerequisites check failed:" "Red"
        foreach ($issue in $issues) {
            Write-ColorOutput "  ✗ $issue" "Red"
        }
        return $false
    }
    
    Write-ColorOutput "All prerequisites satisfied" "Green"
    return $true
}

# Function to run security scans if requested
function Invoke-SecurityScans {
    if (!$RunScansFirst) {
        Write-ColorOutput "Skipping security scans (use -RunScansFirst to include)" "Yellow"
        return $true
    }
    
    Write-ColorOutput "Running security scans first..." "Blue"
    
    $scanScript = "$script:ScriptPath/local-security-scan.ps1"
    if (!(Test-Path $scanScript)) {
        Write-ColorOutput "Local security scan script not found: $scanScript" "Red"
        return $false
    }
    
    try {
        $scanArgs = @()
        if ($Verbose) {
            $scanArgs += "-Verbose"
        }
        
        Write-ColorOutput "Executing: $scanScript $($scanArgs -join ' ')" "Gray"
        & $scanScript @scanArgs
        
        if ($LASTEXITCODE -eq 0) {
            Write-ColorOutput "Security scans completed successfully" "Green"
            return $true
        } else {
            Write-ColorOutput "Security scans completed with issues (exit code: $LASTEXITCODE)" "Yellow"
            return $true  # Continue with aggregation even if scans found issues
        }
    } catch {
        Write-ColorOutput "Error running security scans: $_" "Red"
        return $false
    }
}

# Function to check for existing scan results
function Test-ScanResults {
    Write-ColorOutput "Checking for existing scan results..." "Blue"
    
    $reportsPath = "security/reports"
    $expectedFiles = @(
        "checkov-report.json",
        "tfsec-report.json", 
        "results.json",
        "unified-sast-report.json"
    )
    
    $foundFiles = @()
    foreach ($file in $expectedFiles) {
        $filePath = "$reportsPath/$file"
        if (Test-Path $filePath) {
            $fileInfo = Get-Item $filePath
            $age = (Get-Date) - $fileInfo.LastWriteTime
            $foundFiles += @{
                "name" = $file
                "path" = $filePath
                "age_hours" = [Math]::Round($age.TotalHours, 1)
                "size_kb" = [Math]::Round($fileInfo.Length / 1KB, 1)
            }
            Write-ColorOutput "  ✓ Found: $file (age: $([Math]::Round($age.TotalHours, 1))h, size: $([Math]::Round($fileInfo.Length / 1KB, 1))KB)" "Green"
        }
    }
    
    if ($foundFiles.Count -eq 0) {
        Write-ColorOutput "No scan results found. Please run security scans first." "Yellow"
        Write-ColorOutput "Use: .\security\scripts\local-security-scan.ps1" "Yellow"
        return $false
    }
    
    # Check if results are recent (less than 24 hours old)
    $oldFiles = $foundFiles | Where-Object { $_.age_hours -gt 24 }
    if ($oldFiles.Count -gt 0) {
        Write-ColorOutput "Warning: Some scan results are older than 24 hours:" "Yellow"
        foreach ($file in $oldFiles) {
            Write-ColorOutput "  ⚠ $($file.name) - $($file.age_hours) hours old" "Yellow"
        }
        Write-ColorOutput "Consider running fresh scans with -RunScansFirst" "Yellow"
    }
    
    return $true
}

# Function to run the aggregation
function Invoke-ReportAggregation {
    Write-ColorOutput "Starting security report aggregation..." "Blue"
    
    $aggregatorScript = "$script:ScriptPath/security-report-aggregator.ps1"
    
    try {
        $aggregatorArgs = @{
            "ReportFormats" = $ReportFormats
            "GenerateDashboard" = $GenerateDashboard
            "IncludeTrendAnalysis" = $IncludeTrendAnalysis
            "UpdateBaseline" = $UpdateBaseline
            "OpenDashboard" = $OpenDashboard
            "ConfigPath" = $ConfigPath
        }
        
        if ($Verbose) {
            Write-ColorOutput "Aggregator arguments:" "Gray"
            foreach ($key in $aggregatorArgs.Keys) {
                Write-ColorOutput "  $key = $($aggregatorArgs[$key])" "Gray"
            }
        }
        
        Write-ColorOutput "Executing aggregator script..." "Gray"
        & $aggregatorScript @aggregatorArgs
        
        if ($LASTEXITCODE -eq 0 -or $null -eq $LASTEXITCODE) {
            Write-ColorOutput "Report aggregation completed successfully" "Green"
            return $true
        } else {
            Write-ColorOutput "Report aggregation completed with issues (exit code: $LASTEXITCODE)" "Yellow"
            return $false
        }
    } catch {
        Write-ColorOutput "Error running report aggregation: $_" "Red"
        Write-ColorOutput "Stack trace: $($_.ScriptStackTrace)" "Red"
        return $false
    }
}

# Function to display summary
function Show-ExecutionSummary {
    $endTime = Get-Date
    $duration = $endTime - $script:StartTime
    
    Write-ColorOutput "`n╔══════════════════════════════════════════════════════════════╗" "Cyan"
    Write-ColorOutput "║                    Execution Summary                         ║" "Cyan"
    Write-ColorOutput "╚══════════════════════════════════════════════════════════════╝" "Cyan"
    
    Write-ColorOutput "Start Time: $($script:StartTime.ToString('yyyy-MM-dd HH:mm:ss'))" "Gray"
    Write-ColorOutput "End Time: $($endTime.ToString('yyyy-MM-dd HH:mm:ss'))" "Gray"
    Write-ColorOutput "Duration: $($duration.ToString('mm\:ss'))" "Gray"
    
    # Check for generated reports
    $aggregatedPath = "security/reports/aggregated"
    if (Test-Path $aggregatedPath) {
        $recentReports = Get-ChildItem -Path $aggregatedPath -Filter "*$(Get-Date -Format 'yyyy-MM-dd')*" | 
                        Sort-Object LastWriteTime -Descending
        
        if ($recentReports.Count -gt 0) {
            Write-ColorOutput "`nGenerated Reports:" "Green"
            foreach ($report in $recentReports) {
                Write-ColorOutput "  📄 $($report.Name)" "Cyan"
            }
        }
    }
    
    # Check for dashboard
    $dashboardPath = "security/reports/dashboard/security-dashboard.html"
    if (Test-Path $dashboardPath) {
        Write-ColorOutput "`n🌐 Dashboard available at: $dashboardPath" "Green"
        if (!$OpenDashboard) {
            Write-ColorOutput "   Use -OpenDashboard to open automatically" "Gray"
        }
    }
    
    Write-ColorOutput "`n✅ Security report aggregation workflow completed!" "Green"
}

# Function to show usage information
function Show-Usage {
    Write-ColorOutput "Security Report Aggregation Launcher" "Cyan"
    Write-ColorOutput "====================================" "Cyan"
    Write-ColorOutput ""
    Write-ColorOutput "USAGE:" "Yellow"
    Write-ColorOutput "  .\launch-security-aggregation.ps1 [OPTIONS]" "White"
    Write-ColorOutput ""
    Write-ColorOutput "OPTIONS:" "Yellow"
    Write-ColorOutput "  -RunScansFirst          Run security scans before aggregation" "White"
    Write-ColorOutput "  -GenerateDashboard      Generate interactive dashboard (default: true)" "White"
    Write-ColorOutput "  -IncludeTrendAnalysis   Include trend analysis (default: true)" "White"
    Write-ColorOutput "  -UpdateBaseline         Update security baseline" "White"
    Write-ColorOutput "  -OpenDashboard          Open dashboard in browser after generation" "White"
    Write-ColorOutput "  -ReportFormats          Report formats to generate (default: html,json,markdown)" "White"
    Write-ColorOutput "  -ConfigPath             Path to aggregator configuration file" "White"
    Write-ColorOutput "  -Verbose                Enable verbose output" "White"
    Write-ColorOutput ""
    Write-ColorOutput "EXAMPLES:" "Yellow"
    Write-ColorOutput "  # Basic aggregation with existing scan results" "Gray"
    Write-ColorOutput "  .\launch-security-aggregation.ps1" "White"
    Write-ColorOutput ""
    Write-ColorOutput "  # Run scans first, then aggregate with dashboard" "Gray"
    Write-ColorOutput "  .\launch-security-aggregation.ps1 -RunScansFirst -OpenDashboard" "White"
    Write-ColorOutput ""
    Write-ColorOutput "  # Update baseline and generate only JSON reports" "Gray"
    Write-ColorOutput "  .\launch-security-aggregation.ps1 -UpdateBaseline -ReportFormats @('json')" "White"
}

# Main execution function
function Start-AggregationWorkflow {
    Write-ColorOutput "╔══════════════════════════════════════════════════════════════╗" "Cyan"
    Write-ColorOutput "║        Security Report Aggregation Launcher v1.0            ║" "Cyan"
    Write-ColorOutput "╚══════════════════════════════════════════════════════════════╝" "Cyan"
    Write-ColorOutput ""
    
    # Check prerequisites
    if (!(Test-Prerequisites)) {
        Write-ColorOutput "Prerequisites check failed. Exiting." "Red"
        exit 1
    }
    
    # Run security scans if requested
    if (!(Invoke-SecurityScans)) {
        Write-ColorOutput "Security scans failed. Exiting." "Red"
        exit 1
    }
    
    # Check for existing scan results
    if (!(Test-ScanResults)) {
        Write-ColorOutput "No scan results available for aggregation." "Red"
        Write-ColorOutput "Use -RunScansFirst to run scans automatically, or run them manually first." "Yellow"
        exit 1
    }
    
    # Run the aggregation
    if (!(Invoke-ReportAggregation)) {
        Write-ColorOutput "Report aggregation failed. Check the logs above for details." "Red"
        exit 1
    }
    
    # Show summary
    Show-ExecutionSummary
}

# Handle help parameter
if ($h -or $help -or $args -contains "-h" -or $args -contains "--help" -or $args -contains "/?") {
    Show-Usage
    exit 0
}

# Execute main workflow
try {
    Start-AggregationWorkflow
} catch {
    Write-ColorOutput "Unexpected error: $_" "Red"
    Write-ColorOutput "Stack trace: $($_.ScriptStackTrace)" "Red"
    exit 1
}