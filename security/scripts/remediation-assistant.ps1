# Security Remediation Assistant
# Provides detailed remediation guidance and automated fix suggestions for security findings

param(
    [string]$ReportsPath = "security/reports/",
    [string]$SourcePath = "src/",
    [string]$RuleId = "",
    [string]$Tool = "",
    [switch]$Interactive = $true,
    [switch]$ApplyFixes = $false,
    [switch]$DryRun = $true,
    [string]$Severity = "all"  # Options: all, critical, high, medium, low
)

# Initialize script variables
$ErrorActionPreference = "Stop"
Set-StrictMode -Version Latest

$script:RemediationDatabase = @{}
$script:FixesApplied = @()

# Function to write colored output
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
    
    if ($NoNewline) {
        Write-Host $Message -ForegroundColor $colorMap[$Color] -NoNewline
    } else {
        Write-Host $Message -ForegroundColor $colorMap[$Color]
    }
}

# Function to initialize remediation database
function Initialize-RemediationDatabase {
    $script:RemediationDatabase = @{
        "checkov" = @{
            "CKV_AZURE_33" = @{
                "title" = "Storage Account TLS Version"
                "description" = "Ensure Storage Account uses the latest TLS version (1.2)"
                "category" = "Data Protection"
                "impact" = "HIGH - Prevents use of insecure TLS versions"
                "effort" = "LOW - Simple configuration change"
                "cis_control" = "14.4 - Encrypt All Sensitive Information in Transit"
                "remediation_steps" = @(
                    "1. Locate the azurerm_storage_account resource",
                    "2. Add or update the min_tls_version parameter",
                    "3. Set the value to 'TLS1_2'",
                    "4. Apply the Terraform configuration"
                )
                "code_fix" = @{
                    "pattern" = 'resource\s+"azurerm_storage_account"\s+"[^"]+"\s*\{'
                    "replacement" = @'
resource "azurerm_storage_account" "$1" {
  # ... existing configuration ...
  min_tls_version = "TLS1_2"
'@
                    "search_files" = @("*.tf")
                }
                "validation" = @{
                    "command" = "az storage account show --name {storage_account_name} --resource-group {resource_group} --query minimumTlsVersion"
                    "expected" = "TLS1_2"
                }
                "references" = @(
                    "https://docs.microsoft.com/en-us/azure/storage/common/transport-layer-security-configure-minimum-version",
                    "https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/storage_account#min_tls_version"
                )
            }
            "CKV_AZURE_35" = @{
                "title" = "Storage Account Network Access"
                "description" = "Set default network access rule for Storage Accounts to deny"
                "category" = "Network Security"
                "impact" = "HIGH - Prevents unauthorized network access to storage"
                "effort" = "MEDIUM - Requires network planning and IP whitelisting"
                "cis_control" = "12.3 - Deny Communications with Known Malicious IP Addresses"
                "remediation_steps" = @(
                    "1. Identify legitimate IP ranges that need access",
                    "2. Add network_rules block to storage account",
                    "3. Set default_action to 'Deny'",
                    "4. Add allowed IP ranges to ip_rules",
                    "5. Test access from allowed locations"
                )
                "code_fix" = @{
                    "pattern" = '(resource\s+"azurerm_storage_account"\s+"[^"]+"\s*\{[^}]*)'
                    "replacement" = @'
$1
  
  network_rules {
    default_action             = "Deny"
    ip_rules                   = ["YOUR_ALLOWED_IP_RANGE"]
    virtual_network_subnet_ids = []
    bypass                     = ["AzureServices"]
  }
'@
                    "search_files" = @("*.tf")
                }
                "validation" = @{
                    "command" = "az storage account show --name {storage_account_name} --resource-group {resource_group} --query networkRuleSet.defaultAction"
                    "expected" = "Deny"
                }
                "references" = @(
                    "https://docs.microsoft.com/en-us/azure/storage/common/storage-network-security",
                    "https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/storage_account#network_rules"
                )
            }
            "CKV_AZURE_40" = @{
                "title" = "Key Vault Key Expiration"
                "description" = "Set expiration date on all Key Vault keys"
                "category" = "Identity and Access Management"
                "impact" = "MEDIUM - Improves key lifecycle management and security"
                "effort" = "LOW - Add expiration parameter to key resources"
                "cis_control" = "16.1 - Maintain an Inventory of Authentication Systems"
                "remediation_steps" = @(
                    "1. Review all azurerm_key_vault_key resources",
                    "2. Add expiration_date parameter",
                    "3. Set appropriate expiration date (typically 1-2 years)",
                    "4. Implement key rotation process",
                    "5. Set up monitoring for key expiration"
                )
                "code_fix" = @{
                    "pattern" = '(resource\s+"azurerm_key_vault_key"\s+"[^"]+"\s*\{[^}]*)'
                    "replacement" = @'
$1
  expiration_date = "2025-12-31T23:59:59Z"
'@
                    "search_files" = @("*.tf")
                }
                "validation" = @{
                    "command" = "az keyvault key show --vault-name {vault_name} --name {key_name} --query attributes.expires"
                    "expected" = "not null"
                }
                "references" = @(
                    "https://docs.microsoft.com/en-us/azure/key-vault/keys/about-keys",
                    "https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/key_vault_key#expiration_date"
                )
            }
            "CKV_AZURE_41" = @{
                "title" = "Key Vault Secret Expiration"
                "description" = "Set expiration date on all Key Vault secrets"
                "category" = "Identity and Access Management"
                "impact" = "MEDIUM - Improves secret lifecycle management"
                "effort" = "LOW - Add expiration parameter to secret resources"
                "cis_control" = "16.1 - Maintain an Inventory of Authentication Systems"
                "remediation_steps" = @(
                    "1. Review all azurerm_key_vault_secret resources",
                    "2. Add expiration_date parameter",
                    "3. Set appropriate expiration date",
                    "4. Implement secret rotation process"
                )
                "code_fix" = @{
                    "pattern" = '(resource\s+"azurerm_key_vault_secret"\s+"[^"]+"\s*\{[^}]*)'
                    "replacement" = @'
$1
  expiration_date = "2025-12-31T23:59:59Z"
'@
                    "search_files" = @("*.tf")
                }
                "validation" = @{
                    "command" = "az keyvault secret show --vault-name {vault_name} --name {secret_name} --query attributes.expires"
                    "expected" = "not null"
                }
                "references" = @(
                    "https://docs.microsoft.com/en-us/azure/key-vault/secrets/about-secrets"
                )
            }
        }
        "tfsec" = @{
            "azure-storage-default-action-deny" = @{
                "title" = "Storage Account Default Network Action"
                "description" = "Storage account should deny access by default"
                "category" = "Network Security"
                "impact" = "HIGH - Network security improvement"
                "effort" = "MEDIUM - Network configuration required"
                "cis_control" = "12.3 - Deny Communications with Known Malicious IP Addresses"
                "remediation_steps" = @(
                    "1. Add network_rules block to storage account",
                    "2. Set default_action to 'Deny'",
                    "3. Configure allowed IP ranges or virtual networks"
                )
                "code_fix" = @{
                    "pattern" = '(resource\s+"azurerm_storage_account"\s+"[^"]+"\s*\{[^}]*)'
                    "replacement" = @'
$1
  
  network_rules {
    default_action = "Deny"
    ip_rules       = ["YOUR_ALLOWED_IP_RANGE"]
    bypass         = ["AzureServices"]
  }
'@
                    "search_files" = @("*.tf")
                }
                "validation" = @{
                    "command" = "tfsec --checks azure-storage-default-action-deny ."
                    "expected" = "No issues found"
                }
                "references" = @(
                    "https://aquasecurity.github.io/tfsec/v1.28.1/checks/azure/storage/default-action-deny/"
                )
            }
            "azure-keyvault-specify-network-acl" = @{
                "title" = "Key Vault Network ACL"
                "description" = "Key Vault should have network access restrictions"
                "category" = "Network Security"
                "impact" = "HIGH - Restricts Key Vault access to authorized networks"
                "effort" = "MEDIUM - Network configuration required"
                "cis_control" = "12.3 - Deny Communications with Known Malicious IP Addresses"
                "remediation_steps" = @(
                    "1. Add network_acls block to Key Vault resource",
                    "2. Set default_action to 'Deny'",
                    "3. Configure allowed IP ranges",
                    "4. Add virtual network subnet IDs if needed"
                )
                "code_fix" = @{
                    "pattern" = '(resource\s+"azurerm_key_vault"\s+"[^"]+"\s*\{[^}]*)'
                    "replacement" = @'
$1
  
  network_acls {
    default_action = "Deny"
    ip_rules       = ["YOUR_ALLOWED_IP_RANGE"]
    bypass         = "AzureServices"
  }
'@
                    "search_files" = @("*.tf")
                }
                "validation" = @{
                    "command" = "tfsec --checks azure-keyvault-specify-network-acl ."
                    "expected" = "No issues found"
                }
                "references" = @(
                    "https://aquasecurity.github.io/tfsec/v1.28.1/checks/azure/keyvault/specify-network-acl/"
                )
            }
        }
        "terrascan" = @{
            "AC_AZURE_0001" = @{
                "title" = "Storage Account Customer-Managed Keys"
                "description" = "Storage account should use customer-managed keys for encryption"
                "category" = "Data Protection"
                "impact" = "HIGH - Enhanced encryption control and compliance"
                "effort" = "HIGH - Requires Key Vault setup and key management"
                "cis_control" = "14.8 - Encrypt Sensitive Data at Rest"
                "remediation_steps" = @(
                    "1. Create or identify existing Key Vault",
                    "2. Create encryption key in Key Vault",
                    "3. Grant storage account access to Key Vault",
                    "4. Configure customer_managed_key in storage account",
                    "5. Test encryption functionality"
                )
                "code_fix" = @{
                    "pattern" = '(resource\s+"azurerm_storage_account"\s+"[^"]+"\s*\{[^}]*)'
                    "replacement" = @'
$1
  
  customer_managed_key {
    key_vault_key_id          = azurerm_key_vault_key.storage_key.id
    user_assigned_identity_id = azurerm_user_assigned_identity.storage_identity.id
  }
'@
                    "search_files" = @("*.tf")
                }
                "validation" = @{
                    "command" = "az storage account show --name {storage_account_name} --resource-group {resource_group} --query encryption.keySource"
                    "expected" = "Microsoft.Keyvault"
                }
                "references" = @(
                    "https://docs.microsoft.com/en-us/azure/storage/common/customer-managed-keys-overview"
                )
            }
        }
    }
}

# Function to load security findings
function Get-SecurityFindings {
    Write-ColorOutput "Loading security findings..." "Blue"
    
    $findings = @()
    $reportFiles = @{
        "checkov" = "$ReportsPath/checkov-report.json"
        "tfsec" = "$ReportsPath/tfsec-report.json"
        "terrascan" = "$ReportsPath/results.json"
    }
    
    foreach ($tool in $reportFiles.Keys) {
        $filePath = $reportFiles[$tool]
        if (Test-Path $filePath) {
            try {
                $content = Get-Content $filePath -Raw | ConvertFrom-Json
                
                switch ($tool) {
                    "checkov" {
                        if ($content.results -and $content.results.failed_checks) {
                            foreach ($check in $content.results.failed_checks) {
                                if ($Severity -eq "all" -or $Severity -eq $check.severity.ToLower()) {
                                    $findings += @{
                                        Tool = $tool
                                        RuleId = $check.check_id
                                        Severity = $check.severity.ToUpper()
                                        Resource = $check.resource
                                        File = $check.file_path
                                        Line = $check.file_line_range[0]
                                        Description = $check.check_name
                                    }
                                }
                            }
                        }
                    }
                    "tfsec" {
                        if ($content.results) {
                            foreach ($result in $content.results) {
                                if ($Severity -eq "all" -or $Severity -eq $result.severity.ToLower()) {
                                    $findings += @{
                                        Tool = $tool
                                        RuleId = $result.rule_id
                                        Severity = $result.severity.ToUpper()
                                        Resource = $result.resource
                                        File = $result.location.filename
                                        Line = $result.location.start_line
                                        Description = $result.description
                                    }
                                }
                            }
                        }
                    }
                    "terrascan" {
                        if ($content.results -and $content.results.violations) {
                            foreach ($violation in $content.results.violations) {
                                if ($Severity -eq "all" -or $Severity -eq $violation.severity.ToLower()) {
                                    $findings += @{
                                        Tool = $tool
                                        RuleId = $violation.rule_id
                                        Severity = $violation.severity.ToUpper()
                                        Resource = $violation.resource_name
                                        File = $violation.file
                                        Line = $violation.line
                                        Description = $violation.description
                                    }
                                }
                            }
                        }
                    }
                }
                
                Write-ColorOutput "  ✓ Loaded $tool findings" "Green"
            } catch {
                Write-ColorOutput "  ✗ Error loading $tool findings: $_" "Red"
            }
        } else {
            Write-ColorOutput "  ⚠ $tool report not found: $filePath" "Yellow"
        }
    }
    
    return $findings
}

# Function to display remediation guidance
function Show-RemediationGuidance {
    param([hashtable]$Finding)
    
    $guidance = $script:RemediationDatabase[$Finding.Tool][$Finding.RuleId]
    
    if (!$guidance) {
        Write-ColorOutput "No specific guidance available for $($Finding.RuleId)" "Yellow"
        return
    }
    
    Write-ColorOutput "`n╔══════════════════════════════════════════════════════════════╗" "Cyan"
    Write-ColorOutput "║                    Remediation Guidance                      ║" "Cyan"
    Write-ColorOutput "╚══════════════════════════════════════════════════════════════╝" "Cyan"
    
    Write-ColorOutput "`n🎯 Issue: $($guidance.title)" "Yellow"
    Write-ColorOutput "📝 Description: $($guidance.description)" "White"
    Write-ColorOutput "📂 Category: $($guidance.category)" "Gray"
    Write-ColorOutput "⚠️  Impact: $($guidance.impact)" "Red"
    Write-ColorOutput "🔧 Effort: $($guidance.effort)" "Green"
    Write-ColorOutput "📋 CIS Control: $($guidance.cis_control)" "Blue"
    
    Write-ColorOutput "`n📋 Remediation Steps:" "Green"
    foreach ($step in $guidance.remediation_steps) {
        Write-ColorOutput "   $step" "Gray"
    }
    
    if ($guidance.code_fix) {
        Write-ColorOutput "`n💻 Code Fix Example:" "Cyan"
        Write-ColorOutput $guidance.code_fix.replacement "Gray"
    }
    
    if ($guidance.validation) {
        Write-ColorOutput "`n✅ Validation:" "Green"
        Write-ColorOutput "Command: $($guidance.validation.command)" "Gray"
        Write-ColorOutput "Expected: $($guidance.validation.expected)" "Gray"
    }
    
    Write-ColorOutput "`n📚 References:" "Blue"
    foreach ($ref in $guidance.references) {
        Write-ColorOutput "   • $ref" "Gray"
    }
}

# Function to apply automated fixes
function Invoke-AutomatedFix {
    param([hashtable]$Finding)
    
    $guidance = $script:RemediationDatabase[$Finding.Tool][$Finding.RuleId]
    
    if (!$guidance -or !$guidance.code_fix) {
        Write-ColorOutput "No automated fix available for $($Finding.RuleId)" "Yellow"
        return $false
    }
    
    Write-ColorOutput "`n🔧 Applying automated fix for $($Finding.RuleId)..." "Blue"
    
    if ($DryRun) {
        Write-ColorOutput "DRY RUN: Would apply the following fix:" "Yellow"
        Write-ColorOutput $guidance.code_fix.replacement "Gray"
        return $true
    }
    
    try {
        $filesToSearch = @()
        foreach ($pattern in $guidance.code_fix.search_files) {
            $filesToSearch += Get-ChildItem -Path $SourcePath -Filter $pattern -Recurse
        }
        
        $fixApplied = $false
        foreach ($file in $filesToSearch) {
            $content = Get-Content $file.FullName -Raw
            
            if ($content -match $guidance.code_fix.pattern) {
                Write-ColorOutput "  Updating file: $($file.Name)" "Yellow"
                
                if ($Interactive) {
                    Write-ColorOutput "Apply fix to this file? (y/n): " "Cyan" -NoNewline
                    $response = Read-Host
                    if ($response -ne "y" -and $response -ne "yes") {
                        Write-ColorOutput "  Skipped by user" "Gray"
                        continue
                    }
                }
                
                # Create backup
                $backupPath = "$($file.FullName).backup-$(Get-Date -Format 'yyyyMMdd-HHmmss')"
                Copy-Item $file.FullName $backupPath
                Write-ColorOutput "  Backup created: $backupPath" "Green"
                
                # Apply fix
                $updatedContent = $content -replace $guidance.code_fix.pattern, $guidance.code_fix.replacement
                $updatedContent | Out-File -FilePath $file.FullName -Encoding UTF8
                
                $script:FixesApplied += @{
                    File = $file.FullName
                    RuleId = $Finding.RuleId
                    BackupPath = $backupPath
                }
                
                $fixApplied = $true
                Write-ColorOutput "  ✅ Fix applied successfully" "Green"
            }
        }
        
        if (!$fixApplied) {
            Write-ColorOutput "  No matching patterns found in source files" "Yellow"
        }
        
        return $fixApplied
    } catch {
        Write-ColorOutput "Error applying fix: $_" "Red"
        return $false
    }
}

# Function to show interactive menu
function Show-InteractiveMenu {
    param([array]$Findings)
    
    while ($true) {
        Clear-Host
        Write-ColorOutput "╔══════════════════════════════════════════════════════════════╗" "Cyan"
        Write-ColorOutput "║                 Security Remediation Assistant              ║" "Cyan"
        Write-ColorOutput "╚══════════════════════════════════════════════════════════════╝" "Cyan"
        
        Write-ColorOutput "`nFound $($Findings.Count) security findings" "Yellow"
        
        # Group findings by severity
        $groupedFindings = $Findings | Group-Object -Property Severity | Sort-Object { 
            switch ($_.Name) {
                "CRITICAL" { 0 }
                "HIGH" { 1 }
                "MEDIUM" { 2 }
                "LOW" { 3 }
                default { 4 }
            }
        }
        
        Write-ColorOutput "`nFindings by Severity:" "White"
        foreach ($group in $groupedFindings) {
            $color = switch ($group.Name) {
                "CRITICAL" { "Red" }
                "HIGH" { "Red" }
                "MEDIUM" { "Yellow" }
                "LOW" { "Green" }
                default { "Gray" }
            }
            Write-ColorOutput "  $($group.Name): $($group.Count)" $color
        }
        
        Write-ColorOutput "`nOptions:" "Cyan"
        Write-ColorOutput "1. View all findings" "White"
        Write-ColorOutput "2. View findings by severity" "White"
        Write-ColorOutput "3. Get remediation guidance for specific finding" "White"
        Write-ColorOutput "4. Apply automated fixes" "White"
        Write-ColorOutput "5. Generate remediation report" "White"
        Write-ColorOutput "6. Exit" "White"
        
        Write-ColorOutput "`nSelect option (1-6): " "Cyan" -NoNewline
        $choice = Read-Host
        
        switch ($choice) {
            "1" {
                Show-AllFindings -Findings $Findings
                Read-Host "`nPress Enter to continue"
            }
            "2" {
                Show-FindingsBySeverity -Findings $Findings
                Read-Host "`nPress Enter to continue"
            }
            "3" {
                Show-SpecificGuidance -Findings $Findings
                Read-Host "`nPress Enter to continue"
            }
            "4" {
                Invoke-BulkFixes -Findings $Findings
                Read-Host "`nPress Enter to continue"
            }
            "5" {
                New-RemediationReport -Findings $Findings
                Read-Host "`nPress Enter to continue"
            }
            "6" {
                Write-ColorOutput "`nExiting..." "Green"
                return
            }
            default {
                Write-ColorOutput "`nInvalid option. Please try again." "Red"
                Start-Sleep 2
            }
        }
    }
}

# Function to show all findings
function Show-AllFindings {
    param([array]$Findings)
    
    Clear-Host
    Write-ColorOutput "All Security Findings" "Cyan"
    Write-ColorOutput "====================" "Cyan"
    
    for ($i = 0; $i -lt $Findings.Count; $i++) {
        $finding = $Findings[$i]
        $severityColor = switch ($finding.Severity) {
            "CRITICAL" { "Red" }
            "HIGH" { "Red" }
            "MEDIUM" { "Yellow" }
            "LOW" { "Green" }
            default { "Gray" }
        }
        
        Write-ColorOutput "`n[$($i + 1)] $($finding.RuleId) - $($finding.Severity)" $severityColor
        Write-ColorOutput "    Tool: $($finding.Tool)" "Gray"
        Write-ColorOutput "    Resource: $($finding.Resource)" "Gray"
        Write-ColorOutput "    File: $($finding.File):$($finding.Line)" "Gray"
        Write-ColorOutput "    Description: $($finding.Description)" "White"
    }
}

# Function to show findings by severity
function Show-FindingsBySeverity {
    param([array]$Findings)
    
    Clear-Host
    Write-ColorOutput "Select severity level:" "Cyan"
    Write-ColorOutput "1. Critical" "Red"
    Write-ColorOutput "2. High" "Red"
    Write-ColorOutput "3. Medium" "Yellow"
    Write-ColorOutput "4. Low" "Green"
    
    Write-ColorOutput "`nEnter choice (1-4): " "Cyan" -NoNewline
    $choice = Read-Host
    
    $selectedSeverity = switch ($choice) {
        "1" { "CRITICAL" }
        "2" { "HIGH" }
        "3" { "MEDIUM" }
        "4" { "LOW" }
        default { return }
    }
    
    $filteredFindings = $Findings | Where-Object { $_.Severity -eq $selectedSeverity }
    
    Clear-Host
    Write-ColorOutput "$selectedSeverity Severity Findings" "Cyan"
    Write-ColorOutput ("=" * 30) "Cyan"
    
    if ($filteredFindings.Count -eq 0) {
        Write-ColorOutput "No $selectedSeverity severity findings found." "Green"
        return
    }
    
    Show-AllFindings -Findings $filteredFindings
}

# Function to show specific guidance
function Show-SpecificGuidance {
    param([array]$Findings)
    
    Clear-Host
    Write-ColorOutput "Select finding for detailed guidance:" "Cyan"
    
    for ($i = 0; $i -lt [Math]::Min($Findings.Count, 20); $i++) {
        $finding = $Findings[$i]
        Write-ColorOutput "[$($i + 1)] $($finding.RuleId) - $($finding.Severity)" "White"
    }
    
    if ($Findings.Count -gt 20) {
        Write-ColorOutput "[...] and $($Findings.Count - 20) more" "Gray"
    }
    
    Write-ColorOutput "`nEnter finding number: " "Cyan" -NoNewline
    $choice = Read-Host
    
    try {
        $index = [int]$choice - 1
        if ($index -ge 0 -and $index -lt $Findings.Count) {
            Clear-Host
            Show-RemediationGuidance -Finding $Findings[$index]
        } else {
            Write-ColorOutput "Invalid selection." "Red"
        }
    } catch {
        Write-ColorOutput "Invalid input." "Red"
    }
}

# Function to apply bulk fixes
function Invoke-BulkFixes {
    param([array]$Findings)
    
    Clear-Host
    Write-ColorOutput "Automated Fix Application" "Cyan"
    Write-ColorOutput "=========================" "Cyan"
    
    $fixableFindings = $Findings | Where-Object { 
        $script:RemediationDatabase[$_.Tool][$_.RuleId] -and 
        $script:RemediationDatabase[$_.Tool][$_.RuleId].code_fix 
    }
    
    if ($fixableFindings.Count -eq 0) {
        Write-ColorOutput "No automated fixes available for current findings." "Yellow"
        return
    }
    
    Write-ColorOutput "`nFound $($fixableFindings.Count) findings with automated fixes:" "Green"
    
    foreach ($finding in $fixableFindings) {
        Write-ColorOutput "  • $($finding.RuleId) - $($finding.Severity)" "White"
    }
    
    Write-ColorOutput "`nApply all automated fixes? (y/n): " "Cyan" -NoNewline
    $response = Read-Host
    
    if ($response -eq "y" -or $response -eq "yes") {
        foreach ($finding in $fixableFindings) {
            Invoke-AutomatedFix -Finding $finding
        }
        
        Write-ColorOutput "`n✅ Bulk fix application completed!" "Green"
        Write-ColorOutput "Applied fixes: $($script:FixesApplied.Count)" "Yellow"
        
        if ($script:FixesApplied.Count -gt 0) {
            Write-ColorOutput "`nFiles modified:" "Cyan"
            foreach ($fix in $script:FixesApplied) {
                Write-ColorOutput "  • $($fix.File) (backup: $($fix.BackupPath))" "Gray"
            }
        }
    }
}

# Function to generate remediation report
function New-RemediationReport {
    param([array]$Findings)
    
    $reportPath = "$ReportsPath/remediation-guidance-$(Get-Date -Format 'yyyy-MM-dd_HH-mm-ss').md"
    
    $reportContent = @"
# Security Remediation Guidance Report

**Generated:** $(Get-Date -Format "MMMM dd, yyyy 'at' HH:mm:ss")
**Total Findings:** $($Findings.Count)

## Executive Summary

This report provides detailed remediation guidance for security findings identified in the Terraform infrastructure code.

"@

    # Group findings by severity
    $groupedFindings = $Findings | Group-Object -Property Severity
    
    foreach ($group in $groupedFindings) {
        $reportContent += @"

## $($group.Name) Severity Issues ($($group.Count))

"@
        
        foreach ($finding in $group.Group) {
            $guidance = $script:RemediationDatabase[$finding.Tool][$finding.RuleId]
            
            $reportContent += @"

### $($finding.RuleId): $($finding.Description)

**Resource:** $($finding.Resource)
**File:** $($finding.File):$($finding.Line)
**Tool:** $($finding.Tool)

"@
            
            if ($guidance) {
                $reportContent += @"
**Impact:** $($guidance.impact)
**Effort:** $($guidance.effort)
**Category:** $($guidance.category)

#### Remediation Steps:
"@
                foreach ($step in $guidance.remediation_steps) {
                    $reportContent += "`n$step"
                }
                
                if ($guidance.code_fix) {
                    $reportContent += @"

#### Code Fix:
``````hcl
$($guidance.code_fix.replacement)
``````
"@
                }
                
                $reportContent += @"

#### References:
"@
                foreach ($ref in $guidance.references) {
                    $reportContent += "`n- $ref"
                }
            }
            
            $reportContent += "`n`n---`n"
        }
    }
    
    $reportContent += @"

## Summary

- **Total Findings:** $($Findings.Count)
- **Automated Fixes Available:** $(($Findings | Where-Object { $script:RemediationDatabase[$_.Tool][$_.RuleId] -and $script:RemediationDatabase[$_.Tool][$_.RuleId].code_fix }).Count)
- **Manual Review Required:** $(($Findings | Where-Object { !$script:RemediationDatabase[$_.Tool][$_.RuleId] -or !$script:RemediationDatabase[$_.Tool][$_.RuleId].code_fix }).Count)

## Next Steps

1. Review high and critical severity findings first
2. Apply automated fixes where available
3. Manually address remaining issues
4. Re-run security scans to verify fixes
5. Update security baseline

---
*Report generated by Terraform Security Enhancement Suite*
"@

    $reportContent | Out-File -FilePath $reportPath -Encoding UTF8
    Write-ColorOutput "`n📄 Remediation report generated: $reportPath" "Green"
}

# Main execution
function Start-RemediationAssistant {
    Write-ColorOutput "╔══════════════════════════════════════════════════════════════╗" "Cyan"
    Write-ColorOutput "║              Security Remediation Assistant                 ║" "Cyan"
    Write-ColorOutput "╚══════════════════════════════════════════════════════════════╝" "Cyan"
    
    # Initialize remediation database
    Initialize-RemediationDatabase
    
    # Load security findings
    $findings = Get-SecurityFindings
    
    if ($findings.Count -eq 0) {
        Write-ColorOutput "`nNo security findings found." "Green"
        Write-ColorOutput "Run security scans first: .\security\scripts\local-security-scan.ps1" "Yellow"
        exit 0
    }
    
    # Filter by specific rule if provided
    if ($RuleId) {
        $findings = $findings | Where-Object { $_.RuleId -eq $RuleId }
        if ($findings.Count -eq 0) {
            Write-ColorOutput "`nNo findings found for rule: $RuleId" "Yellow"
            exit 0
        }
    }
    
    # Filter by tool if provided
    if ($Tool) {
        $findings = $findings | Where-Object { $_.Tool -eq $Tool.ToLower() }
        if ($findings.Count -eq 0) {
            Write-ColorOutput "`nNo findings found for tool: $Tool" "Yellow"
            exit 0
        }
    }
    
    Write-ColorOutput "`nLoaded $($findings.Count) security findings" "Green"
    
    if ($Interactive) {
        Show-InteractiveMenu -Findings $findings
    } else {
        # Non-interactive mode - show all guidance
        foreach ($finding in $findings) {
            Show-RemediationGuidance -Finding $finding
            
            if ($ApplyFixes) {
                Invoke-AutomatedFix -Finding $finding
            }
        }
        
        # Generate report
        New-RemediationReport -Findings $findings
    }
}

# Execute main function
Start-RemediationAssistant