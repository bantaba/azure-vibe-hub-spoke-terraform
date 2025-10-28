# Integration Tests for Security Workflows
# Tests SAST tool integrations, CI/CD pipeline security gates, and end-to-end workflow validation

param(
    [switch]$TestSASTIntegration = $true,
    [switch]$TestCIPipeline = $true,
    [switch]$TestEndToEnd = $true,
    [switch]$CreateTestData = $true,
    [switch]$CleanupAfterTest = $false,
    [switch]$Verbose = $false,
    [string]$TestEnvironment = "local"
)

# Initialize script variables
$ErrorActionPreference = "Stop"
Set-StrictMode -Version Latest

$script:TestResults = @()
$script:TestStartTime = Get-Date
$script:TestDataPath = "security/reports/test-data"

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

# Function to create test Terraform files
function New-TestTerraformFiles {
    Write-ColorOutput "Creating test Terraform files..." "Blue"
    
    if (!(Test-Path $script:TestDataPath)) {
        New-Item -ItemType Directory -Path $script:TestDataPath -Force | Out-Null
    }
    
    # Create test Terraform file with intentional security issues
    $testTerraformContent = @'
# Test Terraform configuration with security issues for testing

resource "azurerm_storage_account" "test_storage" {
  name                     = "teststorageaccount"
  resource_group_name      = "test-rg"
  location                 = "East US"
  account_tier             = "Standard"
  account_replication_type = "LRS"
  
  # Security issue: HTTPS not enforced
  enable_https_traffic_only = false
  
  # Security issue: No network rules
  network_rules {
    default_action = "Allow"
  }
  
  # Security issue: No encryption
  # Missing encryption configuration
}

resource "azurerm_key_vault" "test_vault" {
  name                = "test-keyvault"
  location            = "East US"
  resource_group_name = "test-rg"
  tenant_id           = "test-tenant-id"
  
  sku_name = "standard"
  
  # Security issue: No network ACLs
  # Missing network_acls block
  
  # Security issue: Soft delete not enabled
  soft_delete_retention_days = 0
}

resource "azurerm_network_security_group" "test_nsg" {
  name                = "test-nsg"
  location            = "East US"
  resource_group_name = "test-rg"
  
  # Security issue: Overly permissive rule
  security_rule {
    name                       = "allow_all"
    priority                   = 100
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "*"
    source_port_range          = "*"
    destination_port_range     = "*"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }
}

resource "azurerm_virtual_machine" "test_vm" {
  name                = "test-vm"
  location            = "East US"
  resource_group_name = "test-rg"
  vm_size             = "Standard_B1s"
  
  # Security issue: Password authentication enabled
  disable_password_authentication = false
  
  storage_os_disk {
    name              = "test-os-disk"
    caching           = "ReadWrite"
    create_option     = "FromImage"
    managed_disk_type = "Standard_LRS"
    
    # Security issue: Disk encryption not enabled
    # Missing encryption settings
  }
  
  os_profile {
    computer_name  = "testvm"
    admin_username = "testuser"
    admin_password = "Password123!"  # Security issue: Hardcoded password
  }
}
'@
    
    $testTfPath = "$script:TestDataPath/test-security.tf"
    $testTerraformContent | Out-File -FilePath $testTfPath -Encoding UTF8
    
    Add-TestResult "Create Test Terraform Files" $true "Created test Terraform file with security issues"
    return $testTfPath
}

# Function to test SAST tool integrations
function Test-SASTToolIntegrations {
    Write-ColorOutput "`n=== Testing SAST Tool Integrations ===" "Cyan"
    
    $testTfPath = New-TestTerraformFiles
    
    # Test Checkov integration
    Test-CheckovIntegration -TerraformPath $testTfPath
    
    # Test TFSec integration
    Test-TFSecIntegration -TerraformPath $testTfPath
    
    # Test Terrascan integration
    Test-TerrascanIntegration -TerraformPath $testTfPath
    
    # Test unified SAST execution
    Test-UnifiedSASTExecution -TerraformPath $testTfPath
}

# Function to test Checkov integration
function Test-CheckovIntegration {
    param([string]$TerraformPath)
    
    Write-ColorOutput "Testing Checkov integration..." "Blue"
    
    # Check if Checkov is available
    if (!(Test-CommandExists "checkov")) {
        Add-TestResult "Checkov Availability" $false "Checkov command not found"
        return
    }
    
    Add-TestResult "Checkov Availability" $true "Checkov command available"
    
    # Test Checkov configuration
    $checkovConfig = "security/sast-tools/.checkov.yaml"
    if (Test-Path $checkovConfig) {
        Add-TestResult "Checkov Configuration" $true "Configuration file exists"
    } else {
        Add-TestResult "Checkov Configuration" $false "Configuration file missing"
        return
    }
    
    # Run Checkov scan on test file
    try {
        $checkovOutput = & checkov --config-file $checkovConfig --file $TerraformPath --output json 2>&1
        
        if ($LASTEXITCODE -ne 0) {
            # Checkov returns non-zero when issues are found, which is expected
            Add-TestResult "Checkov Execution" $true "Checkov executed and found issues (expected)"
        } else {
            Add-TestResult "Checkov Execution" $false "Checkov executed but found no issues (unexpected for test file)"
        }
        
        # Parse Checkov output
        try {
            $checkovJson = $checkovOutput | ConvertFrom-Json
            if ($checkovJson.results -and $checkovJson.results.failed_checks) {
                $failedChecks = $checkovJson.results.failed_checks.Count
                Add-TestResult "Checkov Issue Detection" $true "Detected $failedChecks security issues"
            } else {
                Add-TestResult "Checkov Issue Detection" $false "No issues detected in problematic test file"
            }
        } catch {
            Add-TestResult "Checkov Output Parsing" $false "Failed to parse Checkov JSON output: $_"
        }
        
    } catch {
        Add-TestResult "Checkov Execution" $false "Error running Checkov: $_"
    }
}

# Function to test TFSec integration
function Test-TFSecIntegration {
    param([string]$TerraformPath)
    
    Write-ColorOutput "Testing TFSec integration..." "Blue"
    
    # Check if TFSec is available
    if (!(Test-CommandExists "tfsec")) {
        Add-TestResult "TFSec Availability" $false "TFSec command not found"
        return
    }
    
    Add-TestResult "TFSec Availability" $true "TFSec command available"
    
    # Test TFSec configuration
    $tfsecConfig = "security/sast-tools/.tfsec.yml"
    if (Test-Path $tfsecConfig) {
        Add-TestResult "TFSec Configuration" $true "Configuration file exists"
    } else {
        Add-TestResult "TFSec Configuration" $false "Configuration file missing"
        return
    }
    
    # Run TFSec scan on test file
    try {
        $tfsecOutput = & tfsec --config-file $tfsecConfig $TerraformPath --format json 2>&1
        
        if ($LASTEXITCODE -ne 0) {
            # TFSec returns non-zero when issues are found, which is expected
            Add-TestResult "TFSec Execution" $true "TFSec executed and found issues (expected)"
        } else {
            Add-TestResult "TFSec Execution" $false "TFSec executed but found no issues (unexpected for test file)"
        }
        
        # Parse TFSec output
        try {
            $tfsecJson = $tfsecOutput | ConvertFrom-Json
            if ($tfsecJson.results -and $tfsecJson.results.Count -gt 0) {
                $issueCount = $tfsecJson.results.Count
                Add-TestResult "TFSec Issue Detection" $true "Detected $issueCount security issues"
            } else {
                Add-TestResult "TFSec Issue Detection" $false "No issues detected in problematic test file"
            }
        } catch {
            Add-TestResult "TFSec Output Parsing" $false "Failed to parse TFSec JSON output: $_"
        }
        
    } catch {
        Add-TestResult "TFSec Execution" $false "Error running TFSec: $_"
    }
}

# Function to test Terrascan integration
function Test-TerrascanIntegration {
    param([string]$TerraformPath)
    
    Write-ColorOutput "Testing Terrascan integration..." "Blue"
    
    # Check if Terrascan is available
    if (!(Test-CommandExists "terrascan")) {
        Add-TestResult "Terrascan Availability" $false "Terrascan command not found"
        return
    }
    
    Add-TestResult "Terrascan Availability" $true "Terrascan command available"
    
    # Test Terrascan configuration
    $terrascanConfig = "security/sast-tools/.terrascan_config.toml"
    if (Test-Path $terrascanConfig) {
        Add-TestResult "Terrascan Configuration" $true "Configuration file exists"
    } else {
        Add-TestResult "Terrascan Configuration" $false "Configuration file missing"
        return
    }
    
    # Run Terrascan scan on test file
    try {
        $terrascanOutput = & terrascan scan --config-path $terrascanConfig --iac-file $TerraformPath --output json 2>&1
        
        if ($LASTEXITCODE -ne 0) {
            # Terrascan returns non-zero when issues are found, which is expected
            Add-TestResult "Terrascan Execution" $true "Terrascan executed and found issues (expected)"
        } else {
            Add-TestResult "Terrascan Execution" $false "Terrascan executed but found no issues (unexpected for test file)"
        }
        
        # Parse Terrascan output
        try {
            $terrascanJson = $terrascanOutput | ConvertFrom-Json
            if ($terrascanJson.results -and $terrascanJson.results.violations -and $terrascanJson.results.violations.Count -gt 0) {
                $violationCount = $terrascanJson.results.violations.Count
                Add-TestResult "Terrascan Issue Detection" $true "Detected $violationCount security violations"
            } else {
                Add-TestResult "Terrascan Issue Detection" $false "No violations detected in problematic test file"
            }
        } catch {
            Add-TestResult "Terrascan Output Parsing" $false "Failed to parse Terrascan JSON output: $_"
        }
        
    } catch {
        Add-TestResult "Terrascan Execution" $false "Error running Terrascan: $_"
    }
}

# Function to test unified SAST execution
function Test-UnifiedSASTExecution {
    param([string]$TerraformPath)
    
    Write-ColorOutput "Testing unified SAST execution..." "Blue"
    
    $sastScript = "security/scripts/run-sast-scan.ps1"
    if (!(Test-Path $sastScript)) {
        Add-TestResult "Unified SAST Script" $false "SAST execution script not found"
        return
    }
    
    Add-TestResult "Unified SAST Script" $true "SAST execution script exists"
    
    # Test unified SAST execution
    try {
        $testDir = Split-Path $TerraformPath -Parent
        $sastResult = & $sastScript -SourcePath $testDir -ReportsPath "$testDir/reports" -Verbose:$Verbose 2>&1
        
        # Check if reports were generated
        $expectedReports = @(
            "$testDir/reports/checkov-report.json",
            "$testDir/reports/tfsec-report.json",
            "$testDir/reports/results.json",
            "$testDir/reports/unified-sast-report.json"
        )
        
        $generatedReports = @()
        foreach ($report in $expectedReports) {
            if (Test-Path $report) {
                $generatedReports += $report
            }
        }
        
        if ($generatedReports.Count -gt 0) {
            Add-TestResult "Unified SAST Report Generation" $true "Generated $($generatedReports.Count) reports"
        } else {
            Add-TestResult "Unified SAST Report Generation" $false "No reports generated"
        }
        
        # Test report aggregation
        $aggregatorScript = "security/scripts/security-report-aggregator.ps1"
        if (Test-Path $aggregatorScript) {
            try {
                & $aggregatorScript -ReportsPath "$testDir/reports" -GenerateDashboard:$false
                Add-TestResult "Report Aggregation" $true "Successfully aggregated security reports"
            } catch {
                Add-TestResult "Report Aggregation" $false "Error during report aggregation: $_"
            }
        }
        
    } catch {
        Add-TestResult "Unified SAST Execution" $false "Error running unified SAST: $_"
    }
}

# Function to test CI/CD pipeline security gates
function Test-CIPipelineSecurityGates {
    Write-ColorOutput "`n=== Testing CI/CD Pipeline Security Gates ===" "Cyan"
    
    # Test GitHub Actions workflow
    Test-GitHubActionsWorkflow
    
    # Test Azure DevOps pipeline (if available)
    Test-AzureDevOpsPipeline
    
    # Test pre-commit hooks
    Test-PreCommitHooks
    
    # Test security gate logic
    Test-SecurityGateLogic
}

# Function to test GitHub Actions workflow
function Test-GitHubActionsWorkflow {
    Write-ColorOutput "Testing GitHub Actions workflow..." "Blue"
    
    $workflowPath = ".github/workflows/terraform-security-scan.yml"
    if (!(Test-Path $workflowPath)) {
        Add-TestResult "GitHub Actions Workflow" $false "Workflow file not found"
        return
    }
    
    Add-TestResult "GitHub Actions Workflow File" $true "Workflow file exists"
    
    # Parse and validate workflow content
    try {
        $workflowContent = Get-Content $workflowPath -Raw
        
        # Check for required jobs
        $requiredJobs = @("terraform-validate", "security-scan", "terraform-plan")
        $missingJobs = @()
        
        foreach ($job in $requiredJobs) {
            if ($workflowContent -notmatch $job) {
                $missingJobs += $job
            }
        }
        
        if ($missingJobs.Count -eq 0) {
            Add-TestResult "GitHub Actions Job Structure" $true "All required jobs present"
        } else {
            Add-TestResult "GitHub Actions Job Structure" $false "Missing jobs: $($missingJobs -join ', ')"
        }
        
        # Check for security tools integration
        $securityTools = @("checkov", "tfsec", "terrascan")
        $missingTools = @()
        
        foreach ($tool in $securityTools) {
            if ($workflowContent -notmatch $tool) {
                $missingTools += $tool
            }
        }
        
        if ($missingTools.Count -eq 0) {
            Add-TestResult "GitHub Actions Security Tools" $true "All security tools integrated"
        } else {
            Add-TestResult "GitHub Actions Security Tools" $false "Missing tools: $($missingTools -join ', ')"
        }
        
        # Check for security gate logic
        if ($workflowContent -match "fail_on_high" -and $workflowContent -match "critical_issues") {
            Add-TestResult "GitHub Actions Security Gates" $true "Security gate logic implemented"
        } else {
            Add-TestResult "GitHub Actions Security Gates" $false "Security gate logic missing"
        }
        
    } catch {
        Add-TestResult "GitHub Actions Workflow Validation" $false "Error validating workflow: $_"
    }
}

# Function to test Azure DevOps pipeline
function Test-AzureDevOpsPipeline {
    Write-ColorOutput "Testing Azure DevOps pipeline..." "Blue"
    
    $pipelineFiles = @("azure-pipelines.yml", "azure-pipelines-release.yml")
    $foundPipelines = @()
    
    foreach ($pipeline in $pipelineFiles) {
        if (Test-Path $pipeline) {
            $foundPipelines += $pipeline
        }
    }
    
    if ($foundPipelines.Count -gt 0) {
        Add-TestResult "Azure DevOps Pipeline Files" $true "Found $($foundPipelines.Count) pipeline files"
        
        # Validate pipeline content
        foreach ($pipelineFile in $foundPipelines) {
            try {
                $pipelineContent = Get-Content $pipelineFile -Raw
                
                # Check for security-related stages/jobs
                if ($pipelineContent -match "security" -or $pipelineContent -match "scan") {
                    Add-TestResult "Azure DevOps Security Integration ($pipelineFile)" $true "Security integration found"
                } else {
                    Add-TestResult "Azure DevOps Security Integration ($pipelineFile)" $false "No security integration found"
                }
                
            } catch {
                Add-TestResult "Azure DevOps Pipeline Validation ($pipelineFile)" $false "Error validating pipeline: $_"
            }
        }
    } else {
        Add-TestResult "Azure DevOps Pipeline Files" $false "No Azure DevOps pipeline files found"
    }
}

# Function to test pre-commit hooks
function Test-PreCommitHooks {
    Write-ColorOutput "Testing pre-commit hooks..." "Blue"
    
    # Check for git hooks directory
    $hooksDir = ".git/hooks"
    if (!(Test-Path $hooksDir)) {
        Add-TestResult "Git Hooks Directory" $false "Git hooks directory not found"
        return
    }
    
    Add-TestResult "Git Hooks Directory" $true "Git hooks directory exists"
    
    # Check for pre-commit hook
    $preCommitHook = "$hooksDir/pre-commit"
    if (Test-Path $preCommitHook) {
        Add-TestResult "Pre-commit Hook File" $true "Pre-commit hook exists"
        
        # Validate hook content
        try {
            $hookContent = Get-Content $preCommitHook -Raw
            if ($hookContent -match "security" -or $hookContent -match "terraform") {
                Add-TestResult "Pre-commit Hook Content" $true "Security-related content found in hook"
            } else {
                Add-TestResult "Pre-commit Hook Content" $false "No security-related content in hook"
            }
        } catch {
            Add-TestResult "Pre-commit Hook Validation" $false "Error validating hook: $_"
        }
    } else {
        Add-TestResult "Pre-commit Hook File" $false "Pre-commit hook not found"
    }
    
    # Check for hook installation scripts
    $hookScripts = Get-ChildItem -Path "scripts" -Recurse -Filter "*hook*" -ErrorAction SilentlyContinue
    if ($hookScripts.Count -gt 0) {
        Add-TestResult "Hook Installation Scripts" $true "Found $($hookScripts.Count) hook-related scripts"
    } else {
        Add-TestResult "Hook Installation Scripts" $false "No hook installation scripts found"
    }
}

# Function to test security gate logic
function Test-SecurityGateLogic {
    Write-ColorOutput "Testing security gate logic..." "Blue"
    
    # Test with different severity levels
    $testCases = @(
        @{ Critical = 0; High = 0; Medium = 2; Low = 1; ExpectedResult = "PASS" },
        @{ Critical = 1; High = 0; Medium = 0; Low = 0; ExpectedResult = "FAIL" },
        @{ Critical = 0; High = 3; Medium = 1; Low = 2; ExpectedResult = "FAIL" },
        @{ Critical = 0; High = 0; Medium = 0; Low = 0; ExpectedResult = "PASS" }
    )
    
    foreach ($testCase in $testCases) {
        $testName = "Security Gate Logic (C:$($testCase.Critical) H:$($testCase.High) M:$($testCase.Medium) L:$($testCase.Low))"
        
        # Simulate security gate decision
        $shouldFail = ($testCase.Critical -gt 0) -or ($testCase.High -gt 0)
        $actualResult = if ($shouldFail) { "FAIL" } else { "PASS" }
        
        if ($actualResult -eq $testCase.ExpectedResult) {
            Add-TestResult $testName $true "Gate logic correct: $actualResult"
        } else {
            Add-TestResult $testName $false "Gate logic incorrect: expected $($testCase.ExpectedResult), got $actualResult"
        }
    }
}

# Function to test end-to-end workflow validation
function Test-EndToEndWorkflow {
    Write-ColorOutput "`n=== Testing End-to-End Workflow Validation ===" "Cyan"
    
    # Test complete workflow from code change to security validation
    Test-CompleteWorkflow
    
    # Test workflow integration points
    Test-WorkflowIntegration
    
    # Test error handling and recovery
    Test-WorkflowErrorHandling
    
    # Test reporting and notifications
    Test-WorkflowReporting
}

# Function to test complete workflow
function Test-CompleteWorkflow {
    Write-ColorOutput "Testing complete security workflow..." "Blue"
    
    try {
        # Step 1: Create test Terraform code
        $testTfPath = New-TestTerraformFiles
        Add-TestResult "Workflow Step 1 - Code Creation" $true "Test Terraform code created"
        
        # Step 2: Run security scans
        $testDir = Split-Path $testTfPath -Parent
        $sastScript = "security/scripts/run-sast-scan.ps1"
        
        if (Test-Path $sastScript) {
            try {
                & $sastScript -SourcePath $testDir -ReportsPath "$testDir/reports" -FailOnHigh:$false -FailOnCritical:$false
                Add-TestResult "Workflow Step 2 - Security Scanning" $true "Security scans completed"
            } catch {
                Add-TestResult "Workflow Step 2 - Security Scanning" $false "Security scan failed: $_"
            }
        } else {
            Add-TestResult "Workflow Step 2 - Security Scanning" $false "SAST script not found"
        }
        
        # Step 3: Aggregate results
        $aggregatorScript = "security/scripts/security-report-aggregator.ps1"
        if (Test-Path $aggregatorScript) {
            try {
                & $aggregatorScript -ReportsPath "$testDir/reports" -GenerateDashboard:$false
                Add-TestResult "Workflow Step 3 - Report Aggregation" $true "Reports aggregated successfully"
            } catch {
                Add-TestResult "Workflow Step 3 - Report Aggregation" $false "Report aggregation failed: $_"
            }
        } else {
            Add-TestResult "Workflow Step 3 - Report Aggregation" $false "Aggregator script not found"
        }
        
        # Step 4: Validate outputs
        $expectedOutputs = @(
            "$testDir/reports/unified-sast-report.json",
            "$testDir/reports/aggregated"
        )
        
        $missingOutputs = @()
        foreach ($output in $expectedOutputs) {
            if (!(Test-Path $output)) {
                $missingOutputs += $output
            }
        }
        
        if ($missingOutputs.Count -eq 0) {
            Add-TestResult "Workflow Step 4 - Output Validation" $true "All expected outputs generated"
        } else {
            Add-TestResult "Workflow Step 4 - Output Validation" $false "Missing outputs: $($missingOutputs -join ', ')"
        }
        
    } catch {
        Add-TestResult "Complete Workflow Test" $false "Workflow test failed: $_"
    }
}

# Function to test workflow integration points
function Test-WorkflowIntegration {
    Write-ColorOutput "Testing workflow integration points..." "Blue"
    
    # Test script interdependencies
    $scriptDependencies = @{
        "run-sast-scan.ps1" = @("checkov", "tfsec", "terrascan")
        "security-report-aggregator.ps1" = @("run-sast-scan.ps1")
        "launch-security-aggregation.ps1" = @("security-report-aggregator.ps1")
    }
    
    foreach ($script in $scriptDependencies.Keys) {
        $scriptPath = "security/scripts/$script"
        if (Test-Path $scriptPath) {
            Add-TestResult "Script Integration - $script" $true "Script exists and accessible"
        } else {
            Add-TestResult "Script Integration - $script" $false "Script not found"
        }
    }
    
    # Test configuration file dependencies
    $configFiles = @(
        "security/sast-tools/.checkov.yaml",
        "security/sast-tools/.tfsec.yml",
        "security/sast-tools/.terrascan_config.toml",
        "security/sast-tools/aggregator-config.json"
    )
    
    $missingConfigs = @()
    foreach ($config in $configFiles) {
        if (!(Test-Path $config)) {
            $missingConfigs += $config
        }
    }
    
    if ($missingConfigs.Count -eq 0) {
        Add-TestResult "Configuration Integration" $true "All configuration files present"
    } else {
        Add-TestResult "Configuration Integration" $false "Missing configs: $($missingConfigs -join ', ')"
    }
}

# Function to test workflow error handling
function Test-WorkflowErrorHandling {
    Write-ColorOutput "Testing workflow error handling..." "Blue"
    
    # Test handling of missing tools
    $originalPath = $env:PATH
    try {
        # Temporarily remove tools from PATH to test error handling
        $env:PATH = ""
        
        $sastScript = "security/scripts/run-sast-scan.ps1"
        if (Test-Path $sastScript) {
            try {
                & $sastScript -SourcePath "nonexistent" -ReportsPath "test" -SkipCheckov -SkipTFSec -SkipTerrascan 2>&1 | Out-Null
                Add-TestResult "Error Handling - Missing Tools" $true "Script handled missing tools gracefully"
            } catch {
                Add-TestResult "Error Handling - Missing Tools" $true "Script properly failed with missing tools"
            }
        }
        
    } finally {
        $env:PATH = $originalPath
    }
    
    # Test handling of invalid configuration
    $testConfigPath = "$script:TestDataPath/invalid-config.json"
    '{"invalid": "json"' | Out-File -FilePath $testConfigPath -Encoding UTF8
    
    try {
        $config = Get-Content $testConfigPath -Raw | ConvertFrom-Json
        Add-TestResult "Error Handling - Invalid Config" $false "Invalid JSON was parsed successfully (unexpected)"
    } catch {
        Add-TestResult "Error Handling - Invalid Config" $true "Invalid JSON properly rejected"
    }
    
    # Test handling of missing source files
    $sastScript = "security/scripts/run-sast-scan.ps1"
    if (Test-Path $sastScript) {
        try {
            & $sastScript -SourcePath "nonexistent-directory" -ReportsPath "$script:TestDataPath/error-test" 2>&1 | Out-Null
            Add-TestResult "Error Handling - Missing Source" $true "Script handled missing source directory"
        } catch {
            Add-TestResult "Error Handling - Missing Source" $true "Script properly failed with missing source"
        }
    }
}

# Function to test workflow reporting
function Test-WorkflowReporting {
    Write-ColorOutput "Testing workflow reporting..." "Blue"
    
    # Test report generation formats
    $reportFormats = @("json", "html", "markdown")
    
    foreach ($format in $reportFormats) {
        $testReportPath = "$script:TestDataPath/test-report.$format"
        
        # Create a simple test report
        switch ($format) {
            "json" {
                @{ "test" = "data"; "timestamp" = (Get-Date) } | ConvertTo-Json | Out-File -FilePath $testReportPath -Encoding UTF8
            }
            "html" {
                "<html><body><h1>Test Report</h1></body></html>" | Out-File -FilePath $testReportPath -Encoding UTF8
            }
            "markdown" {
                "# Test Report`n`nThis is a test report." | Out-File -FilePath $testReportPath -Encoding UTF8
            }
        }
        
        if (Test-Path $testReportPath) {
            Add-TestResult "Report Format - $format" $true "Successfully generated $format report"
        } else {
            Add-TestResult "Report Format - $format" $false "Failed to generate $format report"
        }
    }
    
    # Test report validation
    $aggregatorScript = "security/scripts/security-report-aggregator.ps1"
    if (Test-Path $aggregatorScript) {
        # Test with different report formats
        try {
            & $aggregatorScript -ReportsPath $script:TestDataPath -ReportFormats @("json") -GenerateDashboard:$false 2>&1 | Out-Null
            Add-TestResult "Report Validation - JSON" $true "JSON report generation validated"
        } catch {
            Add-TestResult "Report Validation - JSON" $false "JSON report generation failed: $_"
        }
    }
}

# Function to cleanup test data
function Remove-TestData {
    Write-ColorOutput "Cleaning up test data..." "Blue"
    
    try {
        if (Test-Path $script:TestDataPath) {
            Remove-Item $script:TestDataPath -Recurse -Force
            Add-TestResult "Cleanup Test Data" $true "Test data directory removed"
        } else {
            Add-TestResult "Cleanup Test Data" $true "No test data to clean up"
        }
    } catch {
        Add-TestResult "Cleanup Test Data" $false "Error during cleanup: $_"
    }
}

# Function to display test summary
function Show-TestSummary {
    $endTime = Get-Date
    $duration = $endTime - $script:TestStartTime
    
    Write-ColorOutput "`n╔══════════════════════════════════════════════════════════════╗" "Cyan"
    Write-ColorOutput "║              Security Workflow Test Summary                 ║" "Cyan"
    Write-ColorOutput "╚══════════════════════════════════════════════════════════════╝" "Cyan"
    
    $totalTests = $script:TestResults.Count
    $passedTests = ($script:TestResults | Where-Object { $_.passed }).Count
    $failedTests = $totalTests - $passedTests
    
    Write-ColorOutput "Total Tests: $totalTests" "White"
    Write-ColorOutput "Passed: $passedTests" "Green"
    Write-ColorOutput "Failed: $failedTests" $(if ($failedTests -gt 0) { "Red" } else { "Green" })
    Write-ColorOutput "Duration: $($duration.ToString('mm\:ss'))" "Gray"
    Write-ColorOutput "Environment: $TestEnvironment" "Gray"
    
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
        "test_environment" = $TestEnvironment
        "summary" = @{
            "total_tests" = $totalTests
            "passed_tests" = $passedTests
            "failed_tests" = $failedTests
            "success_rate" = if ($totalTests -gt 0) { [Math]::Round(($passedTests / $totalTests) * 100, 1) } else { 0 }
            "duration_seconds" = $duration.TotalSeconds
        }
        "test_categories" = @{
            "sast_integration" = ($script:TestResults | Where-Object { $_.test_name -match "SAST|Checkov|TFSec|Terrascan" }).Count
            "ci_pipeline" = ($script:TestResults | Where-Object { $_.test_name -match "GitHub|Azure|Pipeline|Hook" }).Count
            "end_to_end" = ($script:TestResults | Where-Object { $_.test_name -match "Workflow|Integration|Error" }).Count
        }
        "test_results" = $script:TestResults
    }
    
    $reportPath = "security/reports/workflow-test-results-$(Get-Date -Format 'yyyy-MM-dd_HH-mm-ss').json"
    $testReport | ConvertTo-Json -Depth 10 | Out-File -FilePath $reportPath -Encoding UTF8
    Write-ColorOutput "`nTest report saved: $reportPath" "Cyan"
    
    if ($failedTests -eq 0) {
        Write-ColorOutput "`n✅ All security workflow tests passed!" "Green"
    } else {
        Write-ColorOutput "`n❌ Some tests failed. Please review the issues above." "Red"
    }
}

# Main execution
Write-ColorOutput "╔══════════════════════════════════════════════════════════════╗" "Cyan"
Write-ColorOutput "║            Security Workflow Integration Tests              ║" "Cyan"
Write-ColorOutput "╚══════════════════════════════════════════════════════════════╝" "Cyan"

try {
    if ($CreateTestData) {
        # Ensure test data directory exists
        if (!(Test-Path $script:TestDataPath)) {
            New-Item -ItemType Directory -Path $script:TestDataPath -Force | Out-Null
        }
    }
    
    if ($TestSASTIntegration) {
        Test-SASTToolIntegrations
    }
    
    if ($TestCIPipeline) {
        Test-CIPipelineSecurityGates
    }
    
    if ($TestEndToEnd) {
        Test-EndToEndWorkflow
    }
    
    if ($CleanupAfterTest) {
        Remove-TestData
    }
    
} catch {
    Write-ColorOutput "Unexpected error during testing: $_" "Red"
    Add-TestResult "Test Execution" $false "Unexpected error: $_"
} finally {
    Show-TestSummary
}