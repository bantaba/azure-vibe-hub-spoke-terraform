# Security Report Generation Script
# Generates comprehensive security reports with analysis and remediation guidance

param(
    [string]$ReportsPath = "security/reports/",
    [string]$OutputPath = "security/reports/",
    [string]$ReportFormat = "html",  # Options: html, markdown, pdf, json
    [string]$ReportType = "comprehensive",  # Options: comprehensive, summary, executive
    [switch]$IncludeRemediation = $true,
    [switch]$IncludeTrends = $false,
    [string]$BaselinePath = "",
    [switch]$OpenReport = $false
)

# Initialize script variables
$ErrorActionPreference = "Stop"
Set-StrictMode -Version Latest

$script:ReportData = @{}
$script:Timestamp = Get-Date -Format "yyyy-MM-dd_HH-mm-ss"

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

# Function to load scan results
function Get-ScanResults {
    Write-ColorOutput "Loading scan results..." "Blue"
    
    $results = @{}
    $reportFiles = @{
        "Checkov" = "$ReportsPath/checkov-report.json"
        "TFSec" = "$ReportsPath/tfsec-report.json"
        "Terrascan" = "$ReportsPath/results.json"
        "Unified" = "$ReportsPath/unified-sast-report.json"
    }
    
    foreach ($tool in $reportFiles.Keys) {
        $filePath = $reportFiles[$tool]
        if (Test-Path $filePath) {
            try {
                $content = Get-Content $filePath -Raw | ConvertFrom-Json
                $results[$tool] = $content
                Write-ColorOutput "  ✓ Loaded $tool results" "Green"
            } catch {
                Write-ColorOutput "  ✗ Error loading $tool results: $_" "Red"
            }
        } else {
            Write-ColorOutput "  ⚠ $tool report not found: $filePath" "Yellow"
        }
    }
    
    return $results
}

# Function to analyze security findings
function Invoke-SecurityAnalysis {
    param([hashtable]$ScanResults)
    
    Write-ColorOutput "Analyzing security findings..." "Blue"
    
    $analysis = @{
        TotalFindings = 0
        CriticalFindings = 0
        HighFindings = 0
        MediumFindings = 0
        LowFindings = 0
        ToolBreakdown = @{}
        CategoryBreakdown = @{}
        ResourceBreakdown = @{}
        TopIssues = @()
        RiskScore = 0
    }
    
    foreach ($tool in $ScanResults.Keys) {
        $toolFindings = @{
            Total = 0
            Critical = 0
            High = 0
            Medium = 0
            Low = 0
            Issues = @()
        }
        
        switch ($tool) {
            "Checkov" {
                if ($ScanResults[$tool].results -and $ScanResults[$tool].results.failed_checks) {
                    foreach ($check in $ScanResults[$tool].results.failed_checks) {
                        $severity = $check.severity.ToUpper()
                        $toolFindings[$severity]++
                        $toolFindings.Total++
                        $analysis.TotalFindings++
                        $analysis["${severity}Findings"]++
                        
                        $issue = @{
                            Tool = $tool
                            RuleId = $check.check_id
                            Severity = $severity
                            Resource = $check.resource
                            File = $check.file_path
                            Description = $check.check_name
                            Category = Get-SecurityCategory -RuleId $check.check_id -Tool $tool
                        }
                        $toolFindings.Issues += $issue
                    }
                }
            }
            "TFSec" {
                if ($ScanResults[$tool].results) {
                    foreach ($result in $ScanResults[$tool].results) {
                        $severity = $result.severity.ToUpper()
                        $toolFindings[$severity]++
                        $toolFindings.Total++
                        $analysis.TotalFindings++
                        $analysis["${severity}Findings"]++
                        
                        $issue = @{
                            Tool = $tool
                            RuleId = $result.rule_id
                            Severity = $severity
                            Resource = $result.resource
                            File = $result.location.filename
                            Description = $result.description
                            Category = Get-SecurityCategory -RuleId $result.rule_id -Tool $tool
                        }
                        $toolFindings.Issues += $issue
                    }
                }
            }
            "Terrascan" {
                if ($ScanResults[$tool].results -and $ScanResults[$tool].results.violations) {
                    foreach ($violation in $ScanResults[$tool].results.violations) {
                        $severity = $violation.severity.ToUpper()
                        $toolFindings[$severity]++
                        $toolFindings.Total++
                        $analysis.TotalFindings++
                        $analysis["${severity}Findings"]++
                        
                        $issue = @{
                            Tool = $tool
                            RuleId = $violation.rule_id
                            Severity = $severity
                            Resource = $violation.resource_name
                            File = $violation.file
                            Description = $violation.description
                            Category = Get-SecurityCategory -RuleId $violation.rule_id -Tool $tool
                        }
                        $toolFindings.Issues += $issue
                    }
                }
            }
        }
        
        $analysis.ToolBreakdown[$tool] = $toolFindings
        
        # Categorize issues
        foreach ($issue in $toolFindings.Issues) {
            if (!$analysis.CategoryBreakdown[$issue.Category]) {
                $analysis.CategoryBreakdown[$issue.Category] = 0
            }
            $analysis.CategoryBreakdown[$issue.Category]++
            
            # Resource breakdown
            if (!$analysis.ResourceBreakdown[$issue.Resource]) {
                $analysis.ResourceBreakdown[$issue.Resource] = 0
            }
            $analysis.ResourceBreakdown[$issue.Resource]++
        }
    }
    
    # Calculate risk score (weighted by severity)
    $analysis.RiskScore = ($analysis.CriticalFindings * 10) + 
                         ($analysis.HighFindings * 7) + 
                         ($analysis.MediumFindings * 4) + 
                         ($analysis.LowFindings * 1)
    
    # Identify top issues (most frequent rule violations)
    $allIssues = @()
    foreach ($tool in $analysis.ToolBreakdown.Keys) {
        $allIssues += $analysis.ToolBreakdown[$tool].Issues
    }
    
    $analysis.TopIssues = $allIssues | Group-Object -Property RuleId | 
                         Sort-Object Count -Descending | 
                         Select-Object -First 10 | 
                         ForEach-Object {
                             @{
                                 RuleId = $_.Name
                                 Count = $_.Count
                                 Severity = ($_.Group | Select-Object -First 1).Severity
                                 Description = ($_.Group | Select-Object -First 1).Description
                             }
                         }
    
    return $analysis
}

# Function to get security category for a rule
function Get-SecurityCategory {
    param(
        [string]$RuleId,
        [string]$Tool
    )
    
    $categories = @{
        "storage" = @("CKV_AZURE_33", "CKV_AZURE_35", "CKV_AZURE_36", "azure-storage-default-action-deny")
        "network" = @("CKV_AZURE_9", "CKV_AZURE_10", "CKV_AZURE_11", "azure-network-no-public-ingress")
        "identity" = @("CKV_AZURE_40", "CKV_AZURE_41", "CKV_AZURE_42", "azure-keyvault-specify-network-acl")
        "compute" = @("CKV_AZURE_1", "CKV_AZURE_50", "azure-compute-disable-password-authentication")
        "monitoring" = @("CKV_AZURE_37", "CKV_AZURE_54", "azure-monitor-log-profile-enabled")
        "encryption" = @("AC_AZURE_0001", "CKV_AZURE_92")
    }
    
    foreach ($category in $categories.Keys) {
        if ($categories[$category] -contains $RuleId) {
            return $category.ToUpper()
        }
    }
    
    return "OTHER"
}

# Function to generate HTML report
function New-HtmlReport {
    param(
        [hashtable]$Analysis,
        [hashtable]$ScanResults
    )
    
    $htmlContent = @"
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Security Scan Report - $script:Timestamp</title>
    <style>
        body { font-family: 'Segoe UI', Tahoma, Geneva, Verdana, sans-serif; margin: 0; padding: 20px; background-color: #f5f5f5; }
        .container { max-width: 1200px; margin: 0 auto; background-color: white; padding: 30px; border-radius: 10px; box-shadow: 0 0 20px rgba(0,0,0,0.1); }
        .header { text-align: center; margin-bottom: 30px; padding-bottom: 20px; border-bottom: 3px solid #007acc; }
        .header h1 { color: #007acc; margin: 0; font-size: 2.5em; }
        .header .subtitle { color: #666; font-size: 1.2em; margin-top: 10px; }
        .summary-grid { display: grid; grid-template-columns: repeat(auto-fit, minmax(200px, 1fr)); gap: 20px; margin-bottom: 30px; }
        .summary-card { background: linear-gradient(135deg, #667eea 0%, #764ba2 100%); color: white; padding: 20px; border-radius: 10px; text-align: center; }
        .summary-card.critical { background: linear-gradient(135deg, #ff6b6b 0%, #ee5a24 100%); }
        .summary-card.high { background: linear-gradient(135deg, #ffa726 0%, #ff7043 100%); }
        .summary-card.medium { background: linear-gradient(135deg, #ffca28 0%, #ffa000 100%); }
        .summary-card.low { background: linear-gradient(135deg, #66bb6a 0%, #43a047 100%); }
        .summary-card h3 { margin: 0 0 10px 0; font-size: 2em; }
        .summary-card p { margin: 0; font-size: 1.1em; }
        .section { margin-bottom: 30px; }
        .section h2 { color: #333; border-bottom: 2px solid #007acc; padding-bottom: 10px; }
        .chart-container { background: white; padding: 20px; border-radius: 8px; margin-bottom: 20px; }
        .issue-list { background: #f9f9f9; border-radius: 8px; padding: 20px; }
        .issue-item { background: white; margin-bottom: 15px; padding: 15px; border-radius: 5px; border-left: 4px solid #007acc; }
        .issue-item.critical { border-left-color: #e74c3c; }
        .issue-item.high { border-left-color: #f39c12; }
        .issue-item.medium { border-left-color: #f1c40f; }
        .issue-item.low { border-left-color: #27ae60; }
        .issue-header { display: flex; justify-content: space-between; align-items: center; margin-bottom: 10px; }
        .issue-title { font-weight: bold; color: #333; }
        .severity-badge { padding: 4px 12px; border-radius: 20px; color: white; font-size: 0.9em; font-weight: bold; }
        .severity-badge.critical { background-color: #e74c3c; }
        .severity-badge.high { background-color: #f39c12; }
        .severity-badge.medium { background-color: #f1c40f; color: #333; }
        .severity-badge.low { background-color: #27ae60; }
        .issue-details { color: #666; font-size: 0.95em; }
        .remediation { background: #e8f5e8; padding: 15px; border-radius: 5px; margin-top: 10px; }
        .remediation h4 { color: #27ae60; margin: 0 0 10px 0; }
        .code-block { background: #2d3748; color: #e2e8f0; padding: 15px; border-radius: 5px; font-family: 'Courier New', monospace; font-size: 0.9em; overflow-x: auto; }
        .footer { text-align: center; margin-top: 40px; padding-top: 20px; border-top: 1px solid #ddd; color: #666; }
        .risk-meter { width: 100%; height: 20px; background: #ddd; border-radius: 10px; overflow: hidden; margin: 10px 0; }
        .risk-fill { height: 100%; transition: width 0.3s ease; }
        .risk-low { background: linear-gradient(90deg, #27ae60, #2ecc71); }
        .risk-medium { background: linear-gradient(90deg, #f39c12, #f1c40f); }
        .risk-high { background: linear-gradient(90deg, #e74c3c, #c0392b); }
    </style>
</head>
<body>
    <div class="container">
        <div class="header">
            <h1>🛡️ Security Scan Report</h1>
            <div class="subtitle">Generated on $(Get-Date -Format "MMMM dd, yyyy 'at' HH:mm:ss")</div>
        </div>

        <div class="summary-grid">
            <div class="summary-card">
                <h3>$($Analysis.TotalFindings)</h3>
                <p>Total Findings</p>
            </div>
            <div class="summary-card critical">
                <h3>$($Analysis.CriticalFindings)</h3>
                <p>Critical Issues</p>
            </div>
            <div class="summary-card high">
                <h3>$($Analysis.HighFindings)</h3>
                <p>High Severity</p>
            </div>
            <div class="summary-card medium">
                <h3>$($Analysis.MediumFindings)</h3>
                <p>Medium Severity</p>
            </div>
            <div class="summary-card low">
                <h3>$($Analysis.LowFindings)</h3>
                <p>Low Severity</p>
            </div>
        </div>

        <div class="section">
            <h2>📊 Risk Assessment</h2>
            <div class="chart-container">
                <h3>Overall Risk Score: $($Analysis.RiskScore)</h3>
                <div class="risk-meter">
"@

    # Calculate risk level and percentage
    $maxRisk = 1000  # Theoretical maximum
    $riskPercentage = [Math]::Min(($Analysis.RiskScore / $maxRisk) * 100, 100)
    $riskClass = if ($Analysis.RiskScore -lt 50) { "risk-low" } elseif ($Analysis.RiskScore -lt 200) { "risk-medium" } else { "risk-high" }
    
    $htmlContent += @"
                    <div class="risk-fill $riskClass" style="width: $riskPercentage%"></div>
                </div>
                <p><strong>Risk Level:</strong> $(if ($Analysis.RiskScore -lt 50) { "Low" } elseif ($Analysis.RiskScore -lt 200) { "Medium" } else { "High" })</p>
            </div>
        </div>

        <div class="section">
            <h2>🔍 Top Security Issues</h2>
            <div class="issue-list">
"@

    foreach ($issue in $Analysis.TopIssues) {
        $severityClass = $issue.Severity.ToLower()
        $htmlContent += @"
                <div class="issue-item $severityClass">
                    <div class="issue-header">
                        <div class="issue-title">$($issue.RuleId): $($issue.Description)</div>
                        <div class="severity-badge $severityClass">$($issue.Severity)</div>
                    </div>
                    <div class="issue-details">
                        <strong>Occurrences:</strong> $($issue.Count) | 
                        <strong>Impact:</strong> Multiple resources affected
                    </div>
                </div>
"@
    }

    $htmlContent += @"
            </div>
        </div>

        <div class="section">
            <h2>📈 Tool Breakdown</h2>
            <div class="chart-container">
"@

    foreach ($tool in $Analysis.ToolBreakdown.Keys) {
        $toolData = $Analysis.ToolBreakdown[$tool]
        $htmlContent += @"
                <h3>$tool Results</h3>
                <p><strong>Total Issues:</strong> $($toolData.Total) | 
                   <strong>Critical:</strong> $($toolData.Critical) | 
                   <strong>High:</strong> $($toolData.High) | 
                   <strong>Medium:</strong> $($toolData.Medium) | 
                   <strong>Low:</strong> $($toolData.Low)</p>
"@
    }

    if ($IncludeRemediation) {
        $htmlContent += @"
        </div>
        </div>

        <div class="section">
            <h2>🔧 Remediation Guidance</h2>
            <div class="issue-list">
"@

        # Add detailed remediation for top issues
        foreach ($issue in ($Analysis.TopIssues | Select-Object -First 5)) {
            $guidance = Get-RemediationGuidance -RuleId $issue.RuleId -Tool "generic" -Description $issue.Description
            $severityClass = $issue.Severity.ToLower()
            
            $htmlContent += @"
                <div class="issue-item $severityClass">
                    <div class="issue-header">
                        <div class="issue-title">$($issue.RuleId)</div>
                        <div class="severity-badge $severityClass">$($issue.Severity)</div>
                    </div>
                    <div class="remediation">
                        <h4>🛠️ How to Fix</h4>
                        <p><strong>Impact:</strong> $($guidance.impact)</p>
                        <p><strong>Effort:</strong> $($guidance.effort)</p>
                        <div class="code-block">
$($guidance.remediation -join "`n")
                        </div>
                    </div>
                </div>
"@
        }
        
        $htmlContent += @"
            </div>
"@
    }

    $htmlContent += @"
        </div>

        <div class="footer">
            <p>Report generated by Terraform Security Enhancement Suite</p>
            <p>For more information, visit the project documentation</p>
        </div>
    </div>
</body>
</html>
"@

    return $htmlContent
}

# Function to generate Markdown report
function New-MarkdownReport {
    param(
        [hashtable]$Analysis,
        [hashtable]$ScanResults
    )
    
    $mdContent = @"
# 🛡️ Security Scan Report

**Generated:** $(Get-Date -Format "MMMM dd, yyyy 'at' HH:mm:ss")

## 📊 Executive Summary

| Metric | Count |
|--------|-------|
| Total Findings | $($Analysis.TotalFindings) |
| Critical Issues | $($Analysis.CriticalFindings) |
| High Severity | $($Analysis.HighFindings) |
| Medium Severity | $($Analysis.MediumFindings) |
| Low Severity | $($Analysis.LowFindings) |
| **Risk Score** | **$($Analysis.RiskScore)** |

## 🎯 Risk Assessment

**Overall Risk Level:** $(if ($Analysis.RiskScore -lt 50) { "🟢 Low" } elseif ($Analysis.RiskScore -lt 200) { "🟡 Medium" } else { "🔴 High" })

Risk Score Calculation:
- Critical Issues: $($Analysis.CriticalFindings) × 10 = $($Analysis.CriticalFindings * 10)
- High Issues: $($Analysis.HighFindings) × 7 = $($Analysis.HighFindings * 7)
- Medium Issues: $($Analysis.MediumFindings) × 4 = $($Analysis.MediumFindings * 4)
- Low Issues: $($Analysis.LowFindings) × 1 = $($Analysis.LowFindings * 1)

## 🔍 Top Security Issues

"@

    foreach ($issue in $Analysis.TopIssues) {
        $severityEmoji = switch ($issue.Severity) {
            "CRITICAL" { "🔴" }
            "HIGH" { "🟠" }
            "MEDIUM" { "🟡" }
            "LOW" { "🟢" }
            default { "⚪" }
        }
        
        $mdContent += @"
### $severityEmoji $($issue.RuleId)

**Description:** $($issue.Description)
**Severity:** $($issue.Severity)
**Occurrences:** $($issue.Count)

"@
    }

    $mdContent += @"

## 📈 Tool Breakdown

"@

    foreach ($tool in $Analysis.ToolBreakdown.Keys) {
        $toolData = $Analysis.ToolBreakdown[$tool]
        $mdContent += @"
### $tool

| Severity | Count |
|----------|-------|
| Critical | $($toolData.Critical) |
| High | $($toolData.High) |
| Medium | $($toolData.Medium) |
| Low | $($toolData.Low) |
| **Total** | **$($toolData.Total)** |

"@
    }

    if ($IncludeRemediation) {
        $mdContent += @"

## 🔧 Remediation Guidance

"@

        foreach ($issue in ($Analysis.TopIssues | Select-Object -First 5)) {
            $guidance = Get-RemediationGuidance -RuleId $issue.RuleId -Tool "generic" -Description $issue.Description
            
            $mdContent += @"
### $($issue.RuleId) - $($guidance.title)

**Impact:** $($guidance.impact)
**Effort:** $($guidance.effort)

**Steps to Fix:**
``````hcl
$($guidance.remediation -join "`n")
``````

"@
        }
    }

    $mdContent += @"

---
*Report generated by Terraform Security Enhancement Suite*
"@

    return $mdContent
}

# Function to get remediation guidance (simplified version for report generation)
function Get-RemediationGuidance {
    param(
        [string]$RuleId,
        [string]$Tool,
        [string]$Description = ""
    )
    
    # Simplified guidance for report generation
    return @{
        "title" = "Security Configuration Issue"
        "impact" = "Potential security vulnerability"
        "effort" = "Review required"
        "remediation" = @(
            "# Review the security finding",
            "# Apply appropriate security controls",
            "# Test changes in development environment",
            "# Re-run security scan to verify fix"
        )
    }
}

# Main execution
function New-SecurityReport {
    Write-ColorOutput "╔══════════════════════════════════════════════════════════════╗" "Cyan"
    Write-ColorOutput "║              Security Report Generation                      ║" "Cyan"
    Write-ColorOutput "╚══════════════════════════════════════════════════════════════╝" "Cyan"
    
    # Load scan results
    $scanResults = Get-ScanResults
    
    if ($scanResults.Keys.Count -eq 0) {
        Write-ColorOutput "No scan results found. Please run security scans first." "Red"
        Write-ColorOutput "Use: .\security\scripts\local-security-scan.ps1" "Yellow"
        exit 1
    }
    
    # Analyze results
    $analysis = Invoke-SecurityAnalysis -ScanResults $scanResults
    
    # Generate report based on format
    $reportContent = ""
    $reportExtension = ""
    
    switch ($ReportFormat.ToLower()) {
        "html" {
            $reportContent = New-HtmlReport -Analysis $analysis -ScanResults $scanResults
            $reportExtension = "html"
        }
        "markdown" {
            $reportContent = New-MarkdownReport -Analysis $analysis -ScanResults $scanResults
            $reportExtension = "md"
        }
        "json" {
            $reportData = @{
                timestamp = Get-Date -Format "yyyy-MM-ddTHH:mm:ssZ"
                analysis = $analysis
                scan_results = $scanResults
            }
            $reportContent = $reportData | ConvertTo-Json -Depth 10
            $reportExtension = "json"
        }
        default {
            Write-ColorOutput "Unsupported report format: $ReportFormat" "Red"
            exit 1
        }
    }
    
    # Save report
    $reportFileName = "security-report-$script:Timestamp.$reportExtension"
    $reportPath = Join-Path $OutputPath $reportFileName
    
    $reportContent | Out-File -FilePath $reportPath -Encoding UTF8
    
    Write-ColorOutput "`n✅ Security report generated successfully!" "Green"
    Write-ColorOutput "📄 Report saved to: $reportPath" "Cyan"
    Write-ColorOutput "📊 Total findings: $($analysis.TotalFindings)" "Yellow"
    Write-ColorOutput "🎯 Risk score: $($analysis.RiskScore)" "Yellow"
    
    # Open report if requested
    if ($OpenReport -and $ReportFormat -eq "html") {
        try {
            Start-Process $reportPath
            Write-ColorOutput "🌐 Report opened in default browser" "Green"
        } catch {
            Write-ColorOutput "Could not open report automatically: $_" "Yellow"
        }
    }
    
    return $reportPath
}

# Execute main function
New-SecurityReport