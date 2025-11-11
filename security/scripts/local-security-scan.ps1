# Local Security Scan Execution Script
# Enhanced script for local SAST tool execution with detailed reporting and remediation guidance

param(
    [string]$SourcePath = "src/",
    [string]$ReportsPath = "security/reports/",
    [string]$Tool = "all",  # Options: all, checkov, tfsec, terrascan
    [switch]$Interactive = $false,
    [switch]$DryRun = $false,
    [switch]$Verbose = $false,
    [switch]$ShowRemediation = $true,
    [switch]$GenerateBaseline = $false,
    [string]$Severity = "all",  # Options: all, critical, high, medium, low
    [string]$OutputFormat = "detailed"  # Options: detailed, summary, json
)

# Import required modules and set error handling
$ErrorActionPreference = "Stop"
Set-StrictMode -Version Latest

# Initialize script variables
$script:ScanResults = @{}
$script:RemediationGuidance = @{}
$script:TotalIssues = 0
$script:ExitCode = 0

# Color output functions
function Write-ColorOutput {
    param(
        [string]$Message,
        [string]$Color = "White",
        [switch]$NoNewline = $false
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
    
    $consoleColor = $colorMap[$Color]
    if ($NoNewline) {
        Write-Host $Message -ForegroundColor $consoleColor -NoNewline
    } else {
        Write-Host $Message -ForegroundColor $consoleColor
    }
}

# Function to display script header
function Show-ScriptHeader {
    Clear-Host
    Write-ColorOutput "╔══════════════════════════════════════════════════════════════╗" "Cyan"
    Write-ColorOutput "║                 Local Security Scan Execution                ║" "Cyan"
    Write-ColorOutput "║              Enhanced SAST Tool Integration                  ║" "Cyan"
    Write-ColorOutput "╚══════════════════════════════════════════════════════════════╝" "Cyan"
    Write-ColorOutput ""
    Write-ColorOutput "Configuration:" "Yellow"
    Write-ColorOutput "  Source Path:      $SourcePath" "Gray"
    Write-ColorOutput "  Reports Path:     $ReportsPath" "Gray"
    Write-ColorOutput "  Tool Selection:   $Tool" "Gray"
    Write-ColorOutput "  Severity Filter:  $Severity" "Gray"
    Write-ColorOutput "  Output Format:    $OutputFormat" "Gray"
    Write-ColorOutput "  Interactive Mode: $Interactive" "Gray"
    Write-ColorOutput "  Dry Run:          $DryRun" "Gray"
    Write-ColorOutput ""
}

# Function to check prerequisites
function Test-Prerequisites {
    Write-ColorOutput "Checking prerequisites..." "Blue"
    
    $missingTools = @()
    $toolsToCheck = @()
    
    switch ($Tool.ToLower()) {
        "all" { $toolsToCheck = @("checkov", "tfsec", "terrascan") }
        "checkov" { $toolsToCheck = @("checkov") }
        "tfsec" { $toolsToCheck = @("tfsec") }
        "terrascan" { $toolsToCheck = @("terrascan") }
        default { 
            Write-ColorOutput "Invalid tool selection: $Tool" "Red"
            return $false
        }
    }
    
    foreach ($toolName in $toolsToCheck) {
        try {
            $null = Get-Command $toolName -ErrorAction Stop
            Write-ColorOutput "  ✓ $toolName found" "Green"
        } catch {
            Write-ColorOutput "  ✗ $toolName not found" "Red"
            $missingTools += $toolName
        }
    }
    
    # Check source directory
    if (!(Test-Path $SourcePath)) {
        Write-ColorOutput "  ✗ Source directory not found: $SourcePath" "Red"
        return $false
    } else {
        Write-ColorOutput "  ✓ Source directory exists" "Green"
    }
    
    # Create reports directory if needed
    if (!(Test-Path $ReportsPath)) {
        if (!$DryRun) {
            New-Item -ItemType Directory -Path $ReportsPath -Force | Out-Null
        }
        Write-ColorOutput "  ✓ Reports directory created: $ReportsPath" "Yellow"
    } else {
        Write-ColorOutput "  ✓ Reports directory exists" "Green"
    }
    
    if ($missingTools.Count -gt 0) {
        Write-ColorOutput "`nMissing tools detected:" "Red"
        foreach ($tool in $missingTools) {
            Write-ColorOutput "  - $tool" "Red"
        }
        Write-ColorOutput "`nPlease install missing tools using:" "Yellow"
        Write-ColorOutput "  .\security\scripts\install-all-sast-tools.ps1" "Cyan"
        return $false
    }
    
    return $true
}

# Function to get remediation guidance for specific issues
function Get-RemediationGuidance {
    param(
        [string]$RuleId,
        [string]$Tool,
        [string]$Resource = "",
        [string]$Description = ""
    )
    
    $guidance = @{
        "checkov" = @{
            "CKV_AZURE_33" = @{
                "title" = "Storage Account TLS Version"
                "description" = "Ensure Storage Account uses the latest TLS version"
                "remediation" = @(
                    "Update the storage account configuration to use TLS 1.2:",
                    '```hcl',
                    'resource "azurerm_storage_account" "example" {',
                    '  min_tls_version = "TLS1_2"',
                    '}',
                    '```'
                )
                "impact" = "Medium - Improves data in transit security"
                "effort" = "Low - Simple configuration change"
            }
            "CKV_AZURE_35" = @{
                "title" = "Storage Account Network Access"
                "description" = "Set default network access rule to deny"
                "remediation" = @(
                    "Configure network rules to deny by default:",
                    '```hcl',
                    'resource "azurerm_storage_account" "example" {',
                    '  network_rules {',
                    '    default_action = "Deny"',
                    '    ip_rules       = ["your.allowed.ip.range"]',
                    '  }',
                    '}',
                    '```'
                )
                "impact" = "High - Prevents unauthorized network access"
                "effort" = "Medium - Requires network planning"
            }
            "CKV_AZURE_40" = @{
                "title" = "Key Vault Key Expiration"
                "description" = "Set expiration dates on Key Vault keys"
                "remediation" = @(
                    "Add expiration date to Key Vault keys:",
                    '```hcl',
                    'resource "azurerm_key_vault_key" "example" {',
                    '  expiration_date = "2025-12-31T23:59:59Z"',
                    '}',
                    '```'
                )
                "impact" = "Medium - Improves key lifecycle management"
                "effort" = "Low - Add expiration parameter"
            }
        }
        "tfsec" = @{
            "azure-storage-default-action-deny" = @{
                "title" = "Storage Default Action"
                "description" = "Storage account should deny access by default"
                "remediation" = @(
                    "Set network rules default action to Deny:",
                    '```hcl',
                    'network_rules {',
                    '  default_action = "Deny"',
                    '}',
                    '```'
                )
                "impact" = "High - Network security improvement"
                "effort" = "Low - Configuration change"
            }
            "azure-keyvault-specify-network-acl" = @{
                "title" = "Key Vault Network ACL"
                "description" = "Key Vault should have network access restrictions"
                "remediation" = @(
                    "Configure Key Vault network ACLs:",
                    '```hcl',
                    'resource "azurerm_key_vault" "example" {',
                    '  network_acls {',
                    '    default_action = "Deny"',
                    '    ip_rules       = ["allowed.ip.range"]',
                    '  }',
                    '}',
                    '```'
                )
                "impact" = "High - Restricts Key Vault access"
                "effort" = "Medium - Network configuration required"
            }
        }
        "terrascan" = @{
            "AC_AZURE_0001" = @{
                "title" = "Storage Account Encryption"
                "description" = "Storage account should use customer-managed keys"
                "remediation" = @(
                    "Configure customer-managed key encryption:",
                    '```hcl',
                    'resource "azurerm_storage_account" "example" {',
                    '  customer_managed_key {',
                    '    key_vault_key_id = azurerm_key_vault_key.example.id',
                    '  }',
                    '}',
                    '```'
                )
                "impact" = "High - Enhanced encryption control"
                "effort" = "High - Requires Key Vault setup"
            }
        }
    }
    
    $toolGuidance = $guidance[$Tool.ToLower()]
    if ($toolGuidance -and $toolGuidance[$RuleId]) {
        return $toolGuidance[$RuleId]
    }
    
    # Generic guidance for unknown rules
    return @{
        "title" = "Security Issue Detected"
        "description" = $Description
        "remediation" = @(
            "Review the security finding and apply appropriate fixes:",
            "1. Analyze the specific resource: $Resource",
            "2. Consult tool documentation for detailed guidance",
            "3. Test changes in a development environment",
            "4. Apply fixes following security best practices"
        )
        "impact" = "Unknown - Review finding details"
        "effort" = "Unknown - Depends on specific issue"
    }
}

# Function to parse and analyze scan results
function Invoke-ResultAnalysis {
    param(
        [string]$Tool,
        [string]$ReportPath
    )
    
    if (!(Test-Path $ReportPath)) {
        Write-ColorOutput "Report file not found: $ReportPath" "Red"
        return @{ Issues = @(); Summary = @{ Total = 0; Critical = 0; High = 0; Medium = 0; Low = 0 } }
    }
    
    try {
        $jsonContent = Get-Content $ReportPath -Raw | ConvertFrom-Json
        $issues = @()
        $summary = @{ Total = 0; Critical = 0; High = 0; Medium = 0; Low = 0; Info = 0 }
        
        switch ($Tool.ToLower()) {
            "checkov" {
                if ($jsonContent.results -and $jsonContent.results.failed_checks) {
                    foreach ($check in $jsonContent.results.failed_checks) {
                        $severity = $check.severity.ToUpper()
                        if ($Severity -eq "all" -or $Severity -eq $severity.ToLower()) {
                            $issue = @{
                                Tool = "Checkov"
                                RuleId = $check.check_id
                                Severity = $severity
                                Resource = $check.resource
                                File = $check.file_path
                                Line = $check.file_line_range[0]
                                Description = $check.check_name
                                Guidance = Get-RemediationGuidance -RuleId $check.check_id -Tool "checkov" -Resource $check.resource -Description $check.check_name
                            }
                            $issues += $issue
                            $summary[$severity]++
                            $summary.Total++
                        }
                    }
                }
            }
            "tfsec" {
                if ($jsonContent.results) {
                    foreach ($result in $jsonContent.results) {
                        $severity = $result.severity.ToUpper()
                        if ($Severity -eq "all" -or $Severity -eq $severity.ToLower()) {
                            $issue = @{
                                Tool = "TFSec"
                                RuleId = $result.rule_id
                                Severity = $severity
                                Resource = $result.resource
                                File = $result.location.filename
                                Line = $result.location.start_line
                                Description = $result.description
                                Guidance = Get-RemediationGuidance -RuleId $result.rule_id -Tool "tfsec" -Resource $result.resource -Description $result.description
                            }
                            $issues += $issue
                            $summary[$severity]++
                            $summary.Total++
                        }
                    }
                }
            }
            "terrascan" {
                if ($jsonContent.results -and $jsonContent.results.violations) {
                    foreach ($violation in $jsonContent.results.violations) {
                        $severity = $violation.severity.ToUpper()
                        if ($Severity -eq "all" -or $Severity -eq $severity.ToLower()) {
                            $issue = @{
                                Tool = "Terrascan"
                                RuleId = $violation.rule_id
                                Severity = $severity
                                Resource = $violation.resource_name
                                File = $violation.file
                                Line = $violation.line
                                Description = $violation.description
                                Guidance = Get-RemediationGuidance -RuleId $violation.rule_id -Tool "terrascan" -Resource $violation.resource_name -Description $violation.description
                            }
                            $issues += $issue
                            $summary[$severity]++
                            $summary.Total++
                        }
                    }
                }
            }
        }
        
        return @{ Issues = $issues; Summary = $summary }
    } catch {
        Write-ColorOutput "Error parsing $Tool report: $_" "Red"
        return @{ Issues = @(); Summary = @{ Total = 0; Critical = 0; High = 0; Medium = 0; Low = 0 } }
    }
}

# Function to display detailed results
function Show-DetailedResults {
    param([hashtable]$Results)
    
    if ($Results.Issues.Count -eq 0) {
        Write-ColorOutput "✓ No security issues found!" "Green"
        return
    }
    
    Write-ColorOutput "`n╔══════════════════════════════════════════════════════════════╗" "Yellow"
    Write-ColorOutput "║                    Security Issues Found                     ║" "Yellow"
    Write-ColorOutput "╚══════════════════════════════════════════════════════════════╝" "Yellow"
    
    # Group issues by severity
    $groupedIssues = $Results.Issues | Group-Object -Property Severity
    
    foreach ($group in ($groupedIssues | Sort-Object { 
        switch ($_.Name) {
            "CRITICAL" { 0 }
            "HIGH" { 1 }
            "MEDIUM" { 2 }
            "LOW" { 3 }
            default { 4 }
        }
    })) {
        $severityColor = switch ($group.Name) {
            "CRITICAL" { "Red" }
            "HIGH" { "Red" }
            "MEDIUM" { "Yellow" }
            "LOW" { "Yellow" }
            default { "Gray" }
        }
        
        Write-ColorOutput "`n$($group.Name) Severity Issues ($($group.Count)):" $severityColor
        Write-ColorOutput ("=" * 50) $severityColor
        
        foreach ($issue in $group.Group) {
            Write-ColorOutput "`n[$($issue.Tool)] $($issue.RuleId)" "Cyan"
            Write-ColorOutput "  Resource: $($issue.Resource)" "Gray"
            Write-ColorOutput "  File: $($issue.File):$($issue.Line)" "Gray"
            Write-ColorOutput "  Description: $($issue.Description)" "White"
            
            if ($ShowRemediation -and $issue.Guidance) {
                Write-ColorOutput "`n  Remediation Guidance:" "Green"
                Write-ColorOutput "  Title: $($issue.Guidance.title)" "Green"
                Write-ColorOutput "  Impact: $($issue.Guidance.impact)" "Yellow"
                Write-ColorOutput "  Effort: $($issue.Guidance.effort)" "Yellow"
                
                Write-ColorOutput "`n  Steps to Fix:" "Green"
                foreach ($step in $issue.Guidance.remediation) {
                    Write-ColorOutput "    $step" "Gray"
                }
            }
            
            Write-ColorOutput ("-" * 60) "Gray"
        }
    }
}

# Function to display summary results
function Show-SummaryResults {
    param([hashtable]$AllResults)
    
    Write-ColorOutput "`n╔══════════════════════════════════════════════════════════════╗" "Cyan"
    Write-ColorOutput "║                      Scan Summary                            ║" "Cyan"
    Write-ColorOutput "╚══════════════════════════════════════════════════════════════╝" "Cyan"
    
    $totalIssues = 0
    $totalCritical = 0
    $totalHigh = 0
    $totalMedium = 0
    $totalLow = 0
    
    foreach ($toolName in $AllResults.Keys) {
        $result = $AllResults[$toolName]
        $summary = $result.Summary
        
        Write-ColorOutput "`n$toolName Results:" "Yellow"
        Write-ColorOutput "  Critical: $($summary.Critical)" $(if ($summary.Critical -gt 0) { "Red" } else { "Green" })
        Write-ColorOutput "  High:     $($summary.High)" $(if ($summary.High -gt 0) { "Red" } else { "Green" })
        Write-ColorOutput "  Medium:   $($summary.Medium)" $(if ($summary.Medium -gt 0) { "Yellow" } else { "Green" })
        Write-ColorOutput "  Low:      $($summary.Low)" $(if ($summary.Low -gt 0) { "Yellow" } else { "Green" })
        Write-ColorOutput "  Total:    $($summary.Total)" "White"
        
        $totalIssues += $summary.Total
        $totalCritical += $summary.Critical
        $totalHigh += $summary.High
        $totalMedium += $summary.Medium
        $totalLow += $summary.Low
    }
    
    Write-ColorOutput "`nOverall Summary:" "Cyan"
    Write-ColorOutput "===============" "Cyan"
    Write-ColorOutput "Critical Issues: $totalCritical" $(if ($totalCritical -gt 0) { "Red" } else { "Green" })
    Write-ColorOutput "High Issues:     $totalHigh" $(if ($totalHigh -gt 0) { "Red" } else { "Green" })
    Write-ColorOutput "Medium Issues:   $totalMedium" $(if ($totalMedium -gt 0) { "Yellow" } else { "Green" })
    Write-ColorOutput "Low Issues:      $totalLow" $(if ($totalLow -gt 0) { "Yellow" } else { "Green" })
    Write-ColorOutput "Total Issues:    $totalIssues" "White"
    
    # Set exit code based on findings
    if ($totalCritical -gt 0 -or $totalHigh -gt 0) {
        $script:ExitCode = 1
        Write-ColorOutput "`n⚠️  Action Required: Critical or High severity issues found!" "Red"
    } elseif ($totalMedium -gt 0) {
        Write-ColorOutput "`n⚠️  Review Recommended: Medium severity issues found" "Yellow"
    } else {
        Write-ColorOutput "`n✅ Security scan passed: No critical issues found!" "Green"
    }
    
    $script:TotalIssues = $totalIssues
}

# Function to run individual tool scan
function Invoke-ToolScan {
    param(
        [string]$ToolName,
        [string]$ConfigFile,
        [array]$Arguments
    )
    
    Write-ColorOutput "`n=== Running $ToolName Security Scan ===" "Blue"
    
    if ($DryRun) {
        Write-ColorOutput "DRY RUN: Would execute: $ToolName $($Arguments -join ' ')" "Yellow"
        return $true
    }
    
    try {
        Write-ColorOutput "Executing: $ToolName $($Arguments -join ' ')" "Gray"
        
        if ($Interactive) {
            Write-ColorOutput "Press Enter to continue or Ctrl+C to skip..." "Yellow"
            Read-Host
        }
        
        $process = Start-Process -FilePath $ToolName -ArgumentList $Arguments -NoNewWindow -Wait -PassThru -RedirectStandardOutput "$ReportsPath/$ToolName-output.log" -RedirectStandardError "$ReportsPath/$ToolName-error.log"
        
        if ($process.ExitCode -eq 0) {
            Write-ColorOutput "$ToolName scan completed successfully" "Green"
        } else {
            Write-ColorOutput "$ToolName scan completed with findings (exit code: $($process.ExitCode))" "Yellow"
        }
        
        return $true
    } catch {
        Write-ColorOutput "Error running $ToolName`: $_" "Red"
        return $false
    }
}

# Main execution function
function Invoke-SecurityScan {
    Show-ScriptHeader
    
    if (!(Test-Prerequisites)) {
        Write-ColorOutput "`nPrerequisites check failed. Exiting." "Red"
        exit 1
    }
    
    Write-ColorOutput "`nStarting security scan..." "Green"
    
    $toolsToRun = @()
    switch ($Tool.ToLower()) {
        "all" { $toolsToRun = @("checkov", "tfsec", "terrascan") }
        default { $toolsToRun = @($Tool.ToLower()) }
    }
    
    $allResults = @{}
    
    foreach ($toolName in $toolsToRun) {
        $success = $false
        $reportFile = ""
        
        switch ($toolName) {
            "checkov" {
                $reportFile = "$ReportsPath/checkov-report.json"
                $args = @(
                    "--config-file", "security/sast-tools/.checkov.yaml",
                    "--directory", $SourcePath,
                    "--output", "json",
                    "--output-file-path", $reportFile
                )
                if ($Verbose) { $args += "--verbose" }
                $success = Invoke-ToolScan -ToolName "checkov" -ConfigFile "security/sast-tools/.checkov.yaml" -Arguments $args
            }
            "tfsec" {
                $reportFile = "$ReportsPath/tfsec-report.json"
                $args = @(
                    "--config-file", "security/sast-tools/.tfsec.yml",
                    $SourcePath,
                    "--format", "json",
                    "--out", $reportFile
                )
                if ($Verbose) { $args += "--verbose" }
                $success = Invoke-ToolScan -ToolName "tfsec" -ConfigFile "security/sast-tools/.tfsec.yml" -Arguments $args
            }
            "terrascan" {
                $reportFile = "$ReportsPath/results.json"
                $args = @(
                    "scan",
                    "--config-path", "security/sast-tools/.terrascan_config.toml",
                    "--iac-dir", $SourcePath,
                    "--output", "json",
                    "--output-dir", $ReportsPath
                )
                if ($Verbose) { $args += "--verbose" }
                $success = Invoke-ToolScan -ToolName "terrascan" -ConfigFile "security/sast-tools/.terrascan_config.toml" -Arguments $args
            }
        }
        
        if ($success -and !$DryRun) {
            $result = Invoke-ResultAnalysis -Tool $toolName -ReportPath $reportFile
            $allResults[$toolName] = $result
        }
    }
    
    if (!$DryRun -and $allResults.Keys.Count -gt 0) {
        switch ($OutputFormat.ToLower()) {
            "detailed" {
                foreach ($toolName in $allResults.Keys) {
                    Write-ColorOutput "`n╔══════════════════════════════════════════════════════════════╗" "Magenta"
                    Write-ColorOutput "║                    $toolName Results                         ║" "Magenta"
                    Write-ColorOutput "╚══════════════════════════════════════════════════════════════╝" "Magenta"
                    Show-DetailedResults -Results $allResults[$toolName]
                }
            }
            "summary" {
                Show-SummaryResults -AllResults $allResults
            }
            "json" {
                $jsonOutput = @{
                    timestamp = Get-Date -Format "yyyy-MM-ddTHH:mm:ssZ"
                    scan_configuration = @{
                        source_path = $SourcePath
                        tools = $toolsToRun
                        severity_filter = $Severity
                    }
                    results = $allResults
                }
                $jsonPath = "$ReportsPath/local-scan-results.json"
                $jsonOutput | ConvertTo-Json -Depth 10 | Out-File -FilePath $jsonPath -Encoding UTF8
                Write-ColorOutput "`nJSON results saved to: $jsonPath" "Green"
            }
        }
        
        Show-SummaryResults -AllResults $allResults
        
        # Generate baseline if requested
        if ($GenerateBaseline) {
            $baselinePath = "$ReportsPath/security-baseline.json"
            $allResults | ConvertTo-Json -Depth 10 | Out-File -FilePath $baselinePath -Encoding UTF8
            Write-ColorOutput "`nBaseline saved to: $baselinePath" "Green"
        }
    }
    
    Write-ColorOutput "`n╔══════════════════════════════════════════════════════════════╗" "Cyan"
    Write-ColorOutput "║                    Scan Complete                             ║" "Cyan"
    Write-ColorOutput "╚══════════════════════════════════════════════════════════════╝" "Cyan"
    
    if ($script:TotalIssues -gt 0) {
        Write-ColorOutput "`nNext Steps:" "Yellow"
        Write-ColorOutput "1. Review the security findings above" "Gray"
        Write-ColorOutput "2. Apply the recommended remediation steps" "Gray"
        Write-ColorOutput "3. Re-run the scan to verify fixes" "Gray"
        Write-ColorOutput "4. Consider integrating scans into your CI/CD pipeline" "Gray"
    }
    
    Write-ColorOutput "`nReports saved to: $ReportsPath" "Cyan"
    
    exit $script:ExitCode
}

# Execute main function
Invoke-SecurityScan