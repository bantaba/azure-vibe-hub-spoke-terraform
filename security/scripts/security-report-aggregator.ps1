# Security Report Aggregation System
# Implements unified security report generation with trend analysis and dashboard components

param(
    [string]$ReportsPath = "security/reports/",
    [string]$OutputPath = "security/reports/aggregated/",
    [string]$BaselinePath = "security/reports/baselines/",
    [string]$DashboardPath = "security/reports/dashboard/",
    [string[]]$ReportFormats = @("html", "json", "markdown"),
    [switch]$GenerateDashboard = $true,
    [switch]$IncludeTrendAnalysis = $true,
    [switch]$UpdateBaseline = $false,
    [switch]$OpenDashboard = $false,
    [int]$HistoryDays = 30,
    [string]$ConfigPath = "security/sast-tools/aggregator-config.json"
)

# Initialize script variables
$ErrorActionPreference = "Stop"
Set-StrictMode -Version Latest

$script:Timestamp = Get-Date -Format "yyyy-MM-dd_HH-mm-ss"
$script:AggregatedData = @{}
$script:TrendData = @{}
$script:SecurityPosture = @{}

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

# Function to load configuration
function Get-AggregatorConfiguration {
    $defaultConfig = @{
        "severity_weights" = @{
            "CRITICAL" = 10
            "HIGH" = 7
            "MEDIUM" = 4
            "LOW" = 1
            "INFO" = 0
        }
        "risk_thresholds" = @{
            "low" = 50
            "medium" = 200
            "high" = 500
        }
        "trend_analysis" = @{
            "enabled" = $true
            "history_days" = 30
            "baseline_update_threshold" = 0.1
        }
        "dashboard" = @{
            "enabled" = $true
            "auto_refresh" = 300
            "chart_types" = @("severity", "trends", "tools", "categories")
        }
        "report_retention" = @{
            "days" = 90
            "max_reports" = 100
        }
    }
    
    if (Test-Path $ConfigPath) {
        try {
            $config = Get-Content $ConfigPath -Raw | ConvertFrom-Json -AsHashtable
            # Merge with defaults
            foreach ($key in $defaultConfig.Keys) {
                if (!$config.ContainsKey($key)) {
                    $config[$key] = $defaultConfig[$key]
                }
            }
            return $config
        } catch {
            Write-ColorOutput "Warning: Error loading config, using defaults: $_" "Yellow"
            return $defaultConfig
        }
    } else {
        # Create default config file
        $defaultConfig | ConvertTo-Json -Depth 10 | Out-File -FilePath $ConfigPath -Encoding UTF8
        Write-ColorOutput "Created default configuration: $ConfigPath" "Green"
        return $defaultConfig
    }
}

# Function to load all available scan results
function Get-AllScanResults {
    Write-ColorOutput "Loading all available scan results..." "Blue"
    
    $results = @{}
    $reportFiles = @{
        "Checkov" = @("checkov-report.json", "checkov-*.json")
        "TFSec" = @("tfsec-report.json", "tfsec-*.json")
        "Terrascan" = @("results.json", "terrascan-*.json")
        "Unified" = @("unified-sast-report.json", "unified-*.json")
        "LocalScan" = @("local-scan-results.json", "local-scan-*.json")
    }
    
    foreach ($tool in $reportFiles.Keys) {
        $toolResults = @()
        foreach ($pattern in $reportFiles[$tool]) {
            $files = Get-ChildItem -Path $ReportsPath -Filter $pattern -ErrorAction SilentlyContinue
            foreach ($file in $files) {
                try {
                    $content = Get-Content $file.FullName -Raw | ConvertFrom-Json
                    $toolResults += @{
                        "file" = $file.Name
                        "timestamp" = $file.LastWriteTime
                        "data" = $content
                    }
                    Write-ColorOutput "  ✓ Loaded $($file.Name)" "Green"
                } catch {
                    Write-ColorOutput "  ✗ Error loading $($file.Name): $_" "Red"
                }
            }
        }
        if ($toolResults.Count -gt 0) {
            $results[$tool] = $toolResults
        }
    }
    
    return $results
}

# Function to aggregate security findings across all tools and time periods
function Invoke-SecurityAggregation {
    param([hashtable]$ScanResults, [hashtable]$Config)
    
    Write-ColorOutput "Aggregating security findings..." "Blue"
    
    $aggregation = @{
        "summary" = @{
            "total_scans" = 0
            "total_findings" = 0
            "critical_findings" = 0
            "high_findings" = 0
            "medium_findings" = 0
            "low_findings" = 0
            "info_findings" = 0
            "risk_score" = 0
            "last_scan" = $null
            "scan_frequency" = 0
        }
        "tool_breakdown" = @{}
        "category_analysis" = @{}
        "resource_analysis" = @{}
        "timeline_data" = @()
        "top_issues" = @()
        "security_posture" = @{
            "current_score" = 0
            "trend" = "stable"
            "improvement_areas" = @()
            "compliance_status" = @{}
        }
    }
    
    $allFindings = @()
    $timelineEntries = @()
    
    foreach ($tool in $ScanResults.Keys) {
        $toolData = @{
            "total_scans" = $ScanResults[$tool].Count
            "findings" = @{
                "critical" = 0
                "high" = 0
                "medium" = 0
                "low" = 0
                "info" = 0
            }
            "latest_scan" = $null
            "trend" = "stable"
        }
        
        # Sort by timestamp to get latest first
        $sortedScans = $ScanResults[$tool] | Sort-Object { $_.timestamp } -Descending
        if ($sortedScans.Count -gt 0) {
            $toolData.latest_scan = $sortedScans[0].timestamp
        }
        
        foreach ($scanResult in $ScanResults[$tool]) {
            $aggregation.summary.total_scans++
            
            # Create timeline entry
            $timelineEntry = @{
                "timestamp" = $scanResult.timestamp
                "tool" = $tool
                "file" = $scanResult.file
                "findings" = @{
                    "critical" = 0
                    "high" = 0
                    "medium" = 0
                    "low" = 0
                    "info" = 0
                }
            }
            
            # Parse findings based on tool format
            $findings = Get-FindingsFromScanData -Tool $tool -Data $scanResult.data
            
            foreach ($finding in $findings) {
                $severity = $finding.severity.ToUpper()
                $severityLower = $severity.ToLower()
                $toolData.findings[$severityLower]++
                $aggregation.summary["${severityLower}_findings"]++
                $aggregation.summary.total_findings++
                $timelineEntry.findings[$severityLower]++
                
                # Add to all findings for analysis
                $finding.tool = $tool
                $finding.scan_timestamp = $scanResult.timestamp
                $allFindings += $finding
            }
            
            $timelineEntries += $timelineEntry
        }
        
        $aggregation.tool_breakdown[$tool] = $toolData
    }
    
    # Calculate risk score
    $weights = $Config.severity_weights
    $aggregation.summary.risk_score = 
        ($aggregation.summary.critical_findings * $weights.CRITICAL) +
        ($aggregation.summary.high_findings * $weights.HIGH) +
        ($aggregation.summary.medium_findings * $weights.MEDIUM) +
        ($aggregation.summary.low_findings * $weights.LOW) +
        ($aggregation.summary.info_findings * $weights.INFO)
    
    # Analyze categories and resources
    $aggregation.category_analysis = Get-CategoryAnalysis -Findings $allFindings
    $aggregation.resource_analysis = Get-ResourceAnalysis -Findings $allFindings
    
    # Get top issues
    $aggregation.top_issues = Get-TopSecurityIssues -Findings $allFindings
    
    # Sort timeline data
    $aggregation.timeline_data = $timelineEntries | Sort-Object timestamp -Descending
    
    # Calculate security posture
    $aggregation.security_posture = Get-SecurityPosture -Aggregation $aggregation -Config $Config
    
    return $aggregation
}

# Function to extract findings from scan data based on tool format
function Get-FindingsFromScanData {
    param([string]$Tool, [object]$Data)
    
    $findings = @()
    
    switch ($Tool.ToLower()) {
        "checkov" {
            if ($Data.results -and $Data.results.failed_checks) {
                foreach ($check in $Data.results.failed_checks) {
                    $findings += @{
                        "rule_id" = $check.check_id
                        "severity" = $check.severity
                        "resource" = $check.resource
                        "file" = $check.file_path
                        "description" = $check.check_name
                        "category" = Get-SecurityCategory -RuleId $check.check_id -Tool $Tool
                    }
                }
            }
        }
        "tfsec" {
            if ($Data.results) {
                foreach ($result in $Data.results) {
                    $findings += @{
                        "rule_id" = $result.rule_id
                        "severity" = $result.severity
                        "resource" = $result.resource
                        "file" = $result.location.filename
                        "description" = $result.description
                        "category" = Get-SecurityCategory -RuleId $result.rule_id -Tool $Tool
                    }
                }
            }
        }
        "terrascan" {
            if ($Data.results -and $Data.results.violations) {
                foreach ($violation in $Data.results.violations) {
                    $findings += @{
                        "rule_id" = $violation.rule_id
                        "severity" = $violation.severity
                        "resource" = $violation.resource_name
                        "file" = $violation.file
                        "description" = $violation.description
                        "category" = Get-SecurityCategory -RuleId $violation.rule_id -Tool $Tool
                    }
                }
            }
        }
        "unified" {
            if ($Data.tool_results -and $Data.tool_results -is [hashtable]) {
                foreach ($toolResult in $Data.tool_results.Keys) {
                    $toolFindings = Get-FindingsFromScanData -Tool $toolResult -Data $Data.tool_results[$toolResult]
                    $findings += $toolFindings
                }
            }
        }
        "localscan" {
            if ($Data.detailed_results) {
                foreach ($toolResult in $Data.detailed_results.Keys) {
                    if ($Data.detailed_results[$toolResult].issues) {
                        $findings += $Data.detailed_results[$toolResult].issues
                    }
                }
            }
        }
    }
    
    return $findings
}

# Function to get security category for a rule
function Get-SecurityCategory {
    param([string]$RuleId, [string]$Tool)
    
    $categories = @{
        "STORAGE" = @("CKV_AZURE_33", "CKV_AZURE_35", "CKV_AZURE_36", "azure-storage-default-action-deny", "AC_AZURE_0001")
        "NETWORK" = @("CKV_AZURE_9", "CKV_AZURE_10", "CKV_AZURE_11", "azure-network-no-public-ingress", "CKV_AZURE_12")
        "IDENTITY" = @("CKV_AZURE_40", "CKV_AZURE_41", "CKV_AZURE_42", "azure-keyvault-specify-network-acl", "CKV_AZURE_109")
        "COMPUTE" = @("CKV_AZURE_1", "CKV_AZURE_50", "azure-compute-disable-password-authentication", "CKV_AZURE_149")
        "MONITORING" = @("CKV_AZURE_37", "CKV_AZURE_54", "azure-monitor-log-profile-enabled", "CKV_AZURE_92")
        "ENCRYPTION" = @("CKV_AZURE_92", "CKV_AZURE_93", "CKV_AZURE_94", "CKV_AZURE_95")
        "ACCESS_CONTROL" = @("CKV_AZURE_40", "CKV_AZURE_41", "CKV_AZURE_109", "CKV_AZURE_110")
        "COMPLIANCE" = @("CKV_AZURE_37", "CKV_AZURE_38", "CKV_AZURE_39")
    }
    
    foreach ($category in $categories.Keys) {
        if ($categories[$category] -contains $RuleId) {
            return $category
        }
    }
    
    # Try to categorize by rule ID pattern
    if ($RuleId -match "storage|blob|account") { return "STORAGE" }
    if ($RuleId -match "network|nsg|firewall|subnet") { return "NETWORK" }
    if ($RuleId -match "keyvault|secret|key|identity") { return "IDENTITY" }
    if ($RuleId -match "vm|compute|scale") { return "COMPUTE" }
    if ($RuleId -match "monitor|log|diagnostic") { return "MONITORING" }
    if ($RuleId -match "encrypt|tls|ssl") { return "ENCRYPTION" }
    if ($RuleId -match "rbac|role|access|auth") { return "ACCESS_CONTROL" }
    
    return "OTHER"
}

# Function to analyze findings by category
function Get-CategoryAnalysis {
    param([array]$Findings)
    
    $analysis = @{}
    
    foreach ($finding in $Findings) {
        $category = $finding.category
        if (!$analysis.ContainsKey($category)) {
            $analysis[$category] = @{
                "total" = 0
                "critical" = 0
                "high" = 0
                "medium" = 0
                "low" = 0
                "info" = 0
                "top_rules" = @{}
            }
        }
        
        $severityLower = $finding.severity.ToLower()
        $analysis[$category].total++
        $analysis[$category][$severityLower]++
        
        # Track top rules in category
        $ruleId = $finding.rule_id
        if (!$analysis[$category].top_rules.ContainsKey($ruleId)) {
            $analysis[$category].top_rules[$ruleId] = 0
        }
        $analysis[$category].top_rules[$ruleId]++
    }
    
    # Sort top rules for each category
    foreach ($category in $analysis.Keys) {
        $sortedRules = $analysis[$category].top_rules.GetEnumerator() | 
                      Sort-Object Value -Descending | 
                      Select-Object -First 5
        $analysis[$category].top_rules = @{}
        foreach ($rule in $sortedRules) {
            $analysis[$category].top_rules[$rule.Name] = $rule.Value
        }
    }
    
    return $analysis
}

# Function to analyze findings by resource
function Get-ResourceAnalysis {
    param([array]$Findings)
    
    $analysis = @{}
    
    foreach ($finding in $Findings) {
        $resource = $finding.resource
        if (!$analysis.ContainsKey($resource)) {
            $analysis[$resource] = @{
                "total" = 0
                "critical" = 0
                "high" = 0
                "medium" = 0
                "low" = 0
                "info" = 0
                "categories" = @{}
                "files" = @{}
            }
        }
        
        $severityLower = $finding.severity.ToLower()
        $analysis[$resource].total++
        $analysis[$resource][$severityLower]++
        
        # Track categories for resource
        $category = $finding.category
        if (!$analysis[$resource].categories.ContainsKey($category)) {
            $analysis[$resource].categories[$category] = 0
        }
        $analysis[$resource].categories[$category]++
        
        # Track files for resource
        $file = $finding.file
        if (!$analysis[$resource].files.ContainsKey($file)) {
            $analysis[$resource].files[$file] = 0
        }
        $analysis[$resource].files[$file]++
    }
    
    return $analysis
}

# Function to get top security issues
function Get-TopSecurityIssues {
    param([array]$Findings)
    
    $issueGroups = $Findings | Group-Object -Property rule_id | 
                   Sort-Object Count -Descending | 
                   Select-Object -First 15
    
    $topIssues = @()
    foreach ($group in $issueGroups) {
        $sample = $group.Group[0]
        $topIssues += @{
            "rule_id" = $group.Name
            "count" = $group.Count
            "severity" = $sample.severity
            "description" = $sample.description
            "category" = $sample.category
            "affected_resources" = ($group.Group | Select-Object -ExpandProperty resource -Unique).Count
            "affected_files" = ($group.Group | Select-Object -ExpandProperty file -Unique).Count
        }
    }
    
    return $topIssues
}

# Function to calculate security posture
function Get-SecurityPosture {
    param([hashtable]$Aggregation, [hashtable]$Config)
    
    $posture = @{
        "current_score" = 0
        "risk_level" = "unknown"
        "trend" = "stable"
        "improvement_areas" = @()
        "compliance_status" = @{}
        "recommendations" = @()
    }
    
    # Calculate normalized security score (0-100, higher is better)
    $totalFindings = $Aggregation.summary.total_findings
    $riskScore = $Aggregation.summary.risk_score
    
    if ($totalFindings -eq 0) {
        $posture.current_score = 100
        $posture.risk_level = "low"
    } else {
        # Normalize score based on risk thresholds
        $maxRisk = $Config.risk_thresholds.high
        $normalizedRisk = [Math]::Min($riskScore / $maxRisk, 1.0)
        $posture.current_score = [Math]::Max(0, 100 - ($normalizedRisk * 100))
        
        if ($riskScore -lt $Config.risk_thresholds.low) {
            $posture.risk_level = "low"
        } elseif ($riskScore -lt $Config.risk_thresholds.medium) {
            $posture.risk_level = "medium"
        } else {
            $posture.risk_level = "high"
        }
    }
    
    # Identify improvement areas
    $categoryTotals = @{}
    foreach ($category in $Aggregation.category_analysis.Keys) {
        $categoryData = $Aggregation.category_analysis[$category]
        $categoryRisk = ($categoryData.critical * 10) + ($categoryData.high * 7) + 
                       ($categoryData.medium * 4) + ($categoryData.low * 1)
        $categoryTotals[$category] = $categoryRisk
    }
    
    $topCategories = $categoryTotals.GetEnumerator() | 
                    Sort-Object Value -Descending | 
                    Select-Object -First 3
    
    foreach ($category in $topCategories) {
        if ($category.Value -gt 0) {
            $posture.improvement_areas += $category.Name
        }
    }
    
    # Generate recommendations
    $posture.recommendations = Get-SecurityRecommendations -Aggregation $Aggregation -Posture $posture
    
    return $posture
}

# Function to generate security recommendations
function Get-SecurityRecommendations {
    param([hashtable]$Aggregation, [hashtable]$Posture)
    
    $recommendations = @()
    
    # Critical findings recommendations
    if ($Aggregation.summary.critical_findings -gt 0) {
        $recommendations += "Immediately address $($Aggregation.summary.critical_findings) critical security findings"
    }
    
    # High findings recommendations
    if ($Aggregation.summary.high_findings -gt 5) {
        $recommendations += "Prioritize remediation of $($Aggregation.summary.high_findings) high-severity issues"
    }
    
    # Category-specific recommendations
    foreach ($area in $Posture.improvement_areas) {
        switch ($area) {
            "STORAGE" { $recommendations += "Review storage account security configurations and encryption settings" }
            "NETWORK" { $recommendations += "Strengthen network security groups and access controls" }
            "IDENTITY" { $recommendations += "Enhance identity and access management policies" }
            "ENCRYPTION" { $recommendations += "Implement encryption at rest and in transit for all resources" }
            "MONITORING" { $recommendations += "Improve monitoring and logging configurations" }
        }
    }
    
    # General recommendations based on risk level
    switch ($Posture.risk_level) {
        "high" {
            $recommendations += "Conduct immediate security review and implement emergency fixes"
            $recommendations += "Consider implementing additional security controls and monitoring"
        }
        "medium" {
            $recommendations += "Schedule regular security reviews and implement preventive measures"
            $recommendations += "Enhance security scanning frequency and coverage"
        }
        "low" {
            $recommendations += "Maintain current security practices and monitor for new threats"
            $recommendations += "Consider implementing advanced security features for defense in depth"
        }
    }
    
    return $recommendations
}
# Function to perform trend analysis
function Invoke-TrendAnalysis {
    param([hashtable]$Aggregation, [hashtable]$Config)
    
    Write-ColorOutput "Performing trend analysis..." "Blue"
    
    $trendAnalysis = @{
        "enabled" = $Config.trend_analysis.enabled
        "baseline_comparison" = @{}
        "historical_data" = @()
        "trend_direction" = "stable"
        "improvement_rate" = 0
        "regression_indicators" = @()
        "recommendations" = @()
    }
    
    if (!$Config.trend_analysis.enabled) {
        Write-ColorOutput "Trend analysis disabled in configuration" "Yellow"
        return $trendAnalysis
    }
    
    # Load historical data
    $historyPattern = "$ReportsPath/aggregated/security-aggregation-*.json"
    $historicalFiles = Get-ChildItem -Path $historyPattern -ErrorAction SilentlyContinue | 
                      Sort-Object LastWriteTime -Descending |
                      Select-Object -First $Config.trend_analysis.history_days
    
    if ($historicalFiles.Count -lt 2) {
        Write-ColorOutput "Insufficient historical data for trend analysis (need at least 2 data points)" "Yellow"
        $trendAnalysis.enabled = $false
        return $trendAnalysis
    }
    
    # Parse historical data
    foreach ($file in $historicalFiles) {
        try {
            $historicalData = Get-Content $file.FullName -Raw | ConvertFrom-Json
            $trendAnalysis.historical_data += @{
                "timestamp" = $file.LastWriteTime
                "risk_score" = $historicalData.summary.risk_score
                "total_findings" = $historicalData.summary.total_findings
                "critical_findings" = $historicalData.summary.critical_findings
                "high_findings" = $historicalData.summary.high_findings
            }
        } catch {
            Write-ColorOutput "Error parsing historical file $($file.Name): $_" "Yellow"
        }
    }
    
    # Calculate trends
    if ($trendAnalysis.historical_data.Count -ge 2) {
        $latest = $trendAnalysis.historical_data[0]
        $previous = $trendAnalysis.historical_data[1]
        
        # Risk score trend
        $riskChange = $latest.risk_score - $previous.risk_score
        $riskChangePercent = if ($previous.risk_score -gt 0) { 
            ($riskChange / $previous.risk_score) * 100 
        } else { 0 }
        
        # Determine trend direction
        if ($riskChangePercent -lt -5) {
            $trendAnalysis.trend_direction = "improving"
        } elseif ($riskChangePercent -gt 5) {
            $trendAnalysis.trend_direction = "degrading"
        } else {
            $trendAnalysis.trend_direction = "stable"
        }
        
        $trendAnalysis.improvement_rate = -$riskChangePercent
        
        # Baseline comparison
        if (Test-Path $BaselinePath) {
            $baseline = Get-BaselineData -BaselinePath $BaselinePath
            $trendAnalysis.baseline_comparison = Compare-WithBaseline -Current $Aggregation -Baseline $baseline
        }
        
        # Generate trend recommendations
        $trendAnalysis.recommendations = Get-TrendRecommendations -TrendData $trendAnalysis
    }
    
    return $trendAnalysis
}

# Function to get baseline data
function Get-BaselineData {
    param([string]$BaselinePath)
    
    $baselineFile = "$BaselinePath/security-baseline.json"
    if (Test-Path $baselineFile) {
        try {
            return Get-Content $baselineFile -Raw | ConvertFrom-Json
        } catch {
            Write-ColorOutput "Error loading baseline data: $_" "Yellow"
            return $null
        }
    }
    return $null
}

# Function to compare current data with baseline
function Compare-WithBaseline {
    param([hashtable]$Current, [object]$Baseline)
    
    if (!$Baseline) {
        return @{ "available" = $false }
    }
    
    return @{
        "available" = $true
        "risk_score_change" = $Current.summary.risk_score - $Baseline.summary.risk_score
        "findings_change" = $Current.summary.total_findings - $Baseline.summary.total_findings
        "critical_change" = $Current.summary.critical_findings - $Baseline.summary.critical_findings
        "high_change" = $Current.summary.high_findings - $Baseline.summary.high_findings
        "baseline_date" = $Baseline.timestamp
        "compliance_status" = Get-ComplianceStatus -Current $Current -Baseline $Baseline
    }
}

# Function to get compliance status
function Get-ComplianceStatus {
    param([hashtable]$Current, [object]$Baseline)
    
    $compliance = @{
        "meets_baseline" = $true
        "violations" = @()
        "improvements" = @()
    }
    
    # Check if current state meets baseline requirements
    if ($Current.summary.critical_findings -gt $Baseline.summary.critical_findings) {
        $compliance.meets_baseline = $false
        $compliance.violations += "Critical findings increased from baseline"
    }
    
    if ($Current.summary.risk_score -gt ($Baseline.summary.risk_score * 1.1)) {
        $compliance.meets_baseline = $false
        $compliance.violations += "Risk score exceeded baseline threshold"
    }
    
    # Identify improvements
    if ($Current.summary.total_findings -lt $Baseline.summary.total_findings) {
        $compliance.improvements += "Total findings reduced from baseline"
    }
    
    if ($Current.summary.risk_score -lt $Baseline.summary.risk_score) {
        $compliance.improvements += "Risk score improved from baseline"
    }
    
    return $compliance
}

# Function to get trend recommendations
function Get-TrendRecommendations {
    param([hashtable]$TrendData)
    
    $recommendations = @()
    
    switch ($TrendData.trend_direction) {
        "improving" {
            $recommendations += "Security posture is improving - maintain current practices"
            $recommendations += "Consider documenting successful security measures for replication"
        }
        "degrading" {
            $recommendations += "Security posture is declining - immediate review required"
            $recommendations += "Investigate recent changes that may have introduced vulnerabilities"
            $recommendations += "Consider implementing additional security controls"
        }
        "stable" {
            $recommendations += "Security posture is stable - continue monitoring"
            $recommendations += "Look for opportunities to proactively improve security"
        }
    }
    
    return $recommendations
}

# Function to create dashboard components
function New-SecurityDashboard {
    param([hashtable]$Aggregation, [hashtable]$TrendData, [hashtable]$Config)
    
    Write-ColorOutput "Creating security dashboard..." "Blue"
    
    # Create dashboard directory
    if (!(Test-Path $DashboardPath)) {
        New-Item -ItemType Directory -Path $DashboardPath -Force | Out-Null
    }
    
    # Generate dashboard HTML
    $dashboardHtml = New-DashboardHtml -Aggregation $Aggregation -TrendData $TrendData -Config $Config
    $dashboardPath = "$DashboardPath/security-dashboard.html"
    $dashboardHtml | Out-File -FilePath $dashboardPath -Encoding UTF8
    
    # Generate dashboard data JSON for dynamic updates
    $dashboardData = @{
        "timestamp" = Get-Date -Format "yyyy-MM-ddTHH:mm:ssZ"
        "aggregation" = $Aggregation
        "trends" = $TrendData
        "config" = $Config
    }
    $dataPath = "$DashboardPath/dashboard-data.json"
    $dashboardData | ConvertTo-Json -Depth 10 | Out-File -FilePath $dataPath -Encoding UTF8
    
    Write-ColorOutput "Dashboard created: $dashboardPath" "Green"
    return $dashboardPath
}

# Function to create dashboard HTML
function New-DashboardHtml {
    param([hashtable]$Aggregation, [hashtable]$TrendData, [hashtable]$Config)
    
    $html = @"
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Security Dashboard - Terraform Security Enhancement</title>
    <script src="https://cdn.jsdelivr.net/npm/chart.js"></script>
    <style>
        * { margin: 0; padding: 0; box-sizing: border-box; }
        body { font-family: 'Segoe UI', Tahoma, Geneva, Verdana, sans-serif; background: #f5f7fa; }
        .dashboard { display: grid; grid-template-columns: 1fr 1fr; gap: 20px; padding: 20px; max-width: 1400px; margin: 0 auto; }
        .header { grid-column: 1 / -1; background: linear-gradient(135deg, #667eea 0%, #764ba2 100%); color: white; padding: 30px; border-radius: 10px; text-align: center; }
        .header h1 { font-size: 2.5em; margin-bottom: 10px; }
        .header .subtitle { font-size: 1.2em; opacity: 0.9; }
        .card { background: white; border-radius: 10px; padding: 20px; box-shadow: 0 4px 6px rgba(0,0,0,0.1); }
        .card h2 { color: #333; margin-bottom: 15px; font-size: 1.4em; }
        .metrics-grid { display: grid; grid-template-columns: repeat(auto-fit, minmax(120px, 1fr)); gap: 15px; }
        .metric { text-align: center; padding: 15px; border-radius: 8px; }
        .metric.critical { background: linear-gradient(135deg, #ff6b6b, #ee5a24); color: white; }
        .metric.high { background: linear-gradient(135deg, #ffa726, #ff7043); color: white; }
        .metric.medium { background: linear-gradient(135deg, #ffca28, #ffa000); color: white; }
        .metric.low { background: linear-gradient(135deg, #66bb6a, #43a047); color: white; }
        .metric.total { background: linear-gradient(135deg, #42a5f5, #1e88e5); color: white; }
        .metric-value { font-size: 2em; font-weight: bold; }
        .metric-label { font-size: 0.9em; margin-top: 5px; }
        .chart-container { height: 300px; position: relative; }
        .trend-indicator { display: flex; align-items: center; gap: 10px; padding: 10px; border-radius: 5px; margin: 10px 0; }
        .trend-indicator.improving { background: #e8f5e8; color: #2e7d32; }
        .trend-indicator.degrading { background: #ffebee; color: #c62828; }
        .trend-indicator.stable { background: #e3f2fd; color: #1565c0; }
        .recommendations { background: #f8f9fa; border-left: 4px solid #007acc; padding: 15px; margin: 15px 0; }
        .recommendations ul { margin-left: 20px; }
        .recommendations li { margin: 5px 0; }
        .status-badge { padding: 4px 12px; border-radius: 20px; font-size: 0.8em; font-weight: bold; }
        .status-badge.good { background: #4caf50; color: white; }
        .status-badge.warning { background: #ff9800; color: white; }
        .status-badge.critical { background: #f44336; color: white; }
        .refresh-info { text-align: center; color: #666; font-size: 0.9em; margin-top: 20px; }
    </style>
</head>
<body>
    <div class="dashboard">
        <div class="header">
            <h1>🛡️ Security Dashboard</h1>
            <div class="subtitle">Real-time Security Posture Monitoring</div>
            <div class="subtitle">Last Updated: $(Get-Date -Format "MMMM dd, yyyy 'at' HH:mm:ss")</div>
        </div>
        
        <div class="card">
            <h2>📊 Current Security Metrics</h2>
            <div class="metrics-grid">
                <div class="metric total">
                    <div class="metric-value">$($Aggregation.summary.total_findings)</div>
                    <div class="metric-label">Total Findings</div>
                </div>
                <div class="metric critical">
                    <div class="metric-value">$($Aggregation.summary.critical_findings)</div>
                    <div class="metric-label">Critical</div>
                </div>
                <div class="metric high">
                    <div class="metric-value">$($Aggregation.summary.high_findings)</div>
                    <div class="metric-label">High</div>
                </div>
                <div class="metric medium">
                    <div class="metric-value">$($Aggregation.summary.medium_findings)</div>
                    <div class="metric-label">Medium</div>
                </div>
                <div class="metric low">
                    <div class="metric-value">$($Aggregation.summary.low_findings)</div>
                    <div class="metric-label">Low</div>
                </div>
            </div>
            
            <div class="trend-indicator $($TrendData.trend_direction)">
                <span>📈 Trend: $($TrendData.trend_direction.ToUpper())</span>
                <span class="status-badge $(if($Aggregation.summary.risk_score -lt 50){'good'}elseif($Aggregation.summary.risk_score -lt 200){'warning'}else{'critical'})">
                    Risk Score: $($Aggregation.summary.risk_score)
                </span>
            </div>
        </div>
        
        <div class="card">
            <h2>📈 Security Trends</h2>
            <div class="chart-container">
                <canvas id="trendChart"></canvas>
            </div>
        </div>
        
        <div class="card">
            <h2>🔧 Tool Breakdown</h2>
            <div class="chart-container">
                <canvas id="toolChart"></canvas>
            </div>
        </div>
        
        <div class="card">
            <h2>📋 Category Analysis</h2>
            <div class="chart-container">
                <canvas id="categoryChart"></canvas>
            </div>
        </div>
        
        <div class="card" style="grid-column: 1 / -1;">
            <h2>💡 Recommendations</h2>
            <div class="recommendations">
                <h4>Security Posture Recommendations:</h4>
                <ul>
"@

    foreach ($recommendation in $Aggregation.security_posture.recommendations) {
        $html += "                    <li>$recommendation</li>`n"
    }

    if ($TrendData.enabled -and $TrendData.recommendations.Count -gt 0) {
        $html += @"
                </ul>
                <h4>Trend Analysis Recommendations:</h4>
                <ul>
"@
        foreach ($recommendation in $TrendData.recommendations) {
            $html += "                    <li>$recommendation</li>`n"
        }
    }

    $html += @"
                </ul>
            </div>
        </div>
    </div>
    
    <div class="refresh-info">
        Dashboard auto-refreshes every $($Config.dashboard.auto_refresh) seconds
    </div>

    <script>
        // Trend Chart
        const trendCtx = document.getElementById('trendChart').getContext('2d');
        const trendChart = new Chart(trendCtx, {
            type: 'line',
            data: {
                labels: [$(($TrendData.historical_data | ForEach-Object { "'$($_.timestamp.ToString("MM/dd"))'" }) -join ',')],
                datasets: [{
                    label: 'Risk Score',
                    data: [$(($TrendData.historical_data | ForEach-Object { $_.risk_score }) -join ',')],
                    borderColor: '#007acc',
                    backgroundColor: 'rgba(0, 122, 204, 0.1)',
                    tension: 0.4
                }]
            },
            options: {
                responsive: true,
                maintainAspectRatio: false,
                scales: {
                    y: { beginAtZero: true }
                }
            }
        });

        // Tool Chart
        const toolCtx = document.getElementById('toolChart').getContext('2d');
        const toolChart = new Chart(toolCtx, {
            type: 'doughnut',
            data: {
                labels: [$(($Aggregation.tool_breakdown.Keys | ForEach-Object { "'$_'" }) -join ',')],
                datasets: [{
                    data: [$(($Aggregation.tool_breakdown.Keys | ForEach-Object { $Aggregation.tool_breakdown[$_].total }) -join ',')],
                    backgroundColor: ['#ff6b6b', '#4ecdc4', '#45b7d1', '#96ceb4', '#feca57']
                }]
            },
            options: {
                responsive: true,
                maintainAspectRatio: false
            }
        });

        // Category Chart
        const categoryCtx = document.getElementById('categoryChart').getContext('2d');
        const categoryChart = new Chart(categoryCtx, {
            type: 'bar',
            data: {
                labels: [$(($Aggregation.category_analysis.Keys | ForEach-Object { "'$_'" }) -join ',')],
                datasets: [{
                    label: 'Issues',
                    data: [$(($Aggregation.category_analysis.Keys | ForEach-Object { $Aggregation.category_analysis[$_].total }) -join ',')],
                    backgroundColor: '#007acc'
                }]
            },
            options: {
                responsive: true,
                maintainAspectRatio: false,
                scales: {
                    y: { beginAtZero: true }
                }
            }
        });

        // Auto-refresh functionality
        setTimeout(() => {
            location.reload();
        }, $($Config.dashboard.auto_refresh * 1000));
    </script>
</body>
</html>
"@

    return $html
}

# Function to save aggregated data
function Save-AggregatedData {
    param([hashtable]$Aggregation, [hashtable]$TrendData)
    
    # Create aggregated directory
    if (!(Test-Path $OutputPath)) {
        New-Item -ItemType Directory -Path $OutputPath -Force | Out-Null
    }
    
    # Save aggregated data with timestamp
    $aggregatedData = @{
        "timestamp" = Get-Date -Format "yyyy-MM-ddTHH:mm:ssZ"
        "aggregation" = $Aggregation
        "trends" = $TrendData
        "metadata" = @{
            "version" = "1.0"
            "generator" = "Security Report Aggregator"
            "config_used" = $ConfigPath
        }
    }
    
    # Save in multiple formats
    foreach ($format in $ReportFormats) {
        switch ($format.ToLower()) {
            "json" {
                $jsonPath = "$OutputPath/security-aggregation-$script:Timestamp.json"
                $aggregatedData | ConvertTo-Json -Depth 10 | Out-File -FilePath $jsonPath -Encoding UTF8
                Write-ColorOutput "JSON report saved: $jsonPath" "Green"
            }
            "html" {
                $htmlReport = New-AggregatedHtmlReport -Data $aggregatedData
                $htmlPath = "$OutputPath/security-aggregation-$script:Timestamp.html"
                $htmlReport | Out-File -FilePath $htmlPath -Encoding UTF8
                Write-ColorOutput "HTML report saved: $htmlPath" "Green"
            }
            "markdown" {
                $mdReport = New-AggregatedMarkdownReport -Data $aggregatedData
                $mdPath = "$OutputPath/security-aggregation-$script:Timestamp.md"
                $mdReport | Out-File -FilePath $mdPath -Encoding UTF8
                Write-ColorOutput "Markdown report saved: $mdPath" "Green"
            }
        }
    }
    
    # Update baseline if requested
    if ($UpdateBaseline) {
        Update-SecurityBaseline -Aggregation $Aggregation
    }
}

# Function to create aggregated HTML report
function New-AggregatedHtmlReport {
    param([hashtable]$Data)
    
    $aggregation = $Data.aggregation
    $trends = $Data.trends
    
    return @"
<!DOCTYPE html>
<html>
<head>
    <title>Security Aggregation Report - $($Data.timestamp)</title>
    <style>
        body { font-family: Arial, sans-serif; margin: 40px; }
        .header { text-align: center; margin-bottom: 30px; }
        .summary { background: #f5f5f5; padding: 20px; border-radius: 5px; margin: 20px 0; }
        .metric { display: inline-block; margin: 10px; padding: 15px; background: white; border-radius: 5px; text-align: center; }
        .critical { border-left: 5px solid #e74c3c; }
        .high { border-left: 5px solid #f39c12; }
        .medium { border-left: 5px solid #f1c40f; }
        .low { border-left: 5px solid #27ae60; }
        .section { margin: 30px 0; }
        .trend-improving { color: #27ae60; }
        .trend-degrading { color: #e74c3c; }
        .trend-stable { color: #3498db; }
    </style>
</head>
<body>
    <div class="header">
        <h1>🛡️ Security Aggregation Report</h1>
        <p>Generated: $($Data.timestamp)</p>
    </div>
    
    <div class="summary">
        <h2>Executive Summary</h2>
        <div class="metric critical">
            <h3>$($aggregation.summary.critical_findings)</h3>
            <p>Critical Issues</p>
        </div>
        <div class="metric high">
            <h3>$($aggregation.summary.high_findings)</h3>
            <p>High Severity</p>
        </div>
        <div class="metric medium">
            <h3>$($aggregation.summary.medium_findings)</h3>
            <p>Medium Severity</p>
        </div>
        <div class="metric low">
            <h3>$($aggregation.summary.low_findings)</h3>
            <p>Low Severity</p>
        </div>
        <div class="metric">
            <h3>$($aggregation.summary.risk_score)</h3>
            <p>Risk Score</p>
        </div>
    </div>
    
    <div class="section">
        <h2>Security Posture</h2>
        <p><strong>Current Score:</strong> $($aggregation.security_posture.current_score)/100</p>
        <p><strong>Risk Level:</strong> $($aggregation.security_posture.risk_level)</p>
        <p class="trend-$($trends.trend_direction)"><strong>Trend:</strong> $($trends.trend_direction)</p>
    </div>
    
    <div class="section">
        <h2>Recommendations</h2>
        <ul>
$(($aggregation.security_posture.recommendations | ForEach-Object { "            <li>$_</li>" }) -join "`n")
        </ul>
    </div>
</body>
</html>
"@
}

# Function to create aggregated markdown report
function New-AggregatedMarkdownReport {
    param([hashtable]$Data)
    
    $aggregation = $Data.aggregation
    $trends = $Data.trends
    
    return @"
# 🛡️ Security Aggregation Report

**Generated:** $($Data.timestamp)

## Executive Summary

| Metric | Count |
|--------|-------|
| Total Findings | $($aggregation.summary.total_findings) |
| Critical Issues | $($aggregation.summary.critical_findings) |
| High Severity | $($aggregation.summary.high_findings) |
| Medium Severity | $($aggregation.summary.medium_findings) |
| Low Severity | $($aggregation.summary.low_findings) |
| Risk Score | $($aggregation.summary.risk_score) |

## Security Posture

- **Current Score:** $($aggregation.security_posture.current_score)/100
- **Risk Level:** $($aggregation.security_posture.risk_level)
- **Trend:** $($trends.trend_direction)

## Recommendations

$(($aggregation.security_posture.recommendations | ForEach-Object { "- $_" }) -join "`n")

## Tool Breakdown

$(foreach ($tool in $aggregation.tool_breakdown.Keys) {
    $toolData = $aggregation.tool_breakdown[$tool]
    "### $tool`n`n- Total Scans: $($toolData.total_scans)`n- Latest Scan: $($toolData.latest_scan)`n- Findings: Critical($($toolData.findings.critical)), High($($toolData.findings.high)), Medium($($toolData.findings.medium)), Low($($toolData.findings.low))`n"
})

---
*Report generated by Security Report Aggregator*
"@
}

# Function to update security baseline
function Update-SecurityBaseline {
    param([hashtable]$Aggregation)
    
    if (!(Test-Path $BaselinePath)) {
        New-Item -ItemType Directory -Path $BaselinePath -Force | Out-Null
    }
    
    $baseline = @{
        "timestamp" = Get-Date -Format "yyyy-MM-ddTHH:mm:ssZ"
        "summary" = $Aggregation.summary
        "security_posture" = $Aggregation.security_posture
        "version" = "1.0"
    }
    
    $baselinePath = "$BaselinePath/security-baseline.json"
    $baseline | ConvertTo-Json -Depth 10 | Out-File -FilePath $baselinePath -Encoding UTF8
    Write-ColorOutput "Security baseline updated: $baselinePath" "Green"
}

# Main execution function
function Start-SecurityReportAggregation {
    Write-ColorOutput "╔══════════════════════════════════════════════════════════════╗" "Cyan"
    Write-ColorOutput "║           Security Report Aggregation System                ║" "Cyan"
    Write-ColorOutput "╚══════════════════════════════════════════════════════════════╝" "Cyan"
    
    try {
        # Load configuration
        $config = Get-AggregatorConfiguration
        Write-ColorOutput "Configuration loaded from: $ConfigPath" "Green"
        
        # Load scan results
        $scanResults = Get-AllScanResults
        if ($scanResults.Keys.Count -eq 0) {
            Write-ColorOutput "No scan results found for aggregation" "Yellow"
            Write-ColorOutput "Please run security scans first using: .\security\scripts\local-security-scan.ps1" "Yellow"
            return
        }
        
        Write-ColorOutput "Loaded results from $($scanResults.Keys.Count) tool(s)" "Green"
        
        # Perform aggregation
        $aggregation = Invoke-SecurityAggregation -ScanResults $scanResults -Config $config
        Write-ColorOutput "Security aggregation completed" "Green"
        
        # Perform trend analysis
        $trendData = @{}
        if ($IncludeTrendAnalysis) {
            $trendData = Invoke-TrendAnalysis -Aggregation $aggregation -Config $config
            Write-ColorOutput "Trend analysis completed" "Green"
        }
        
        # Generate dashboard
        $dashboardPath = ""
        if ($GenerateDashboard) {
            $dashboardPath = New-SecurityDashboard -Aggregation $aggregation -TrendData $trendData -Config $config
        }
        
        # Save aggregated data
        Save-AggregatedData -Aggregation $aggregation -TrendData $trendData
        
        # Display summary
        Write-ColorOutput "`n✅ Security report aggregation completed successfully!" "Green"
        Write-ColorOutput "📊 Total findings processed: $($aggregation.summary.total_findings)" "Cyan"
        Write-ColorOutput "🎯 Current risk score: $($aggregation.summary.risk_score)" "Cyan"
        Write-ColorOutput "📈 Security posture: $($aggregation.security_posture.current_score)/100" "Cyan"
        
        if ($GenerateDashboard -and $dashboardPath) {
            Write-ColorOutput "🌐 Dashboard available at: $dashboardPath" "Green"
            
            if ($OpenDashboard) {
                try {
                    Start-Process $dashboardPath
                    Write-ColorOutput "Dashboard opened in default browser" "Green"
                } catch {
                    Write-ColorOutput "Could not open dashboard automatically: $_" "Yellow"
                }
            }
        }
        
    } catch {
        Write-ColorOutput "Error during aggregation: $_" "Red"
        Write-ColorOutput "Stack trace: $($_.ScriptStackTrace)" "Red"
        exit 1
    }
}

# Execute main function
Start-SecurityReportAggregation