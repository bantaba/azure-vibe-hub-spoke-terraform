# SAST Tools Documentation

## Overview

This document provides comprehensive documentation for the Static Application Security Testing (SAST) tools integrated into the Terraform security enhancement project. The project uses three primary SAST tools to ensure comprehensive security coverage:

- **Checkov**: Infrastructure-as-code security scanner with custom Python policies
- **TFSec**: Terraform-specific security scanner with YAML configuration
- **Terrascan**: Policy-as-code security validation using Open Policy Agent (OPA)

## Table of Contents

1. [Tool Overview](#tool-overview)
2. [Installation Guide](#installation-guide)
3. [Configuration Details](#configuration-details)
4. [Usage Instructions](#usage-instructions)
5. [Custom Policies](#custom-policies)
6. [CI/CD Integration](#cicd-integration)
7. [Troubleshooting](#troubleshooting)
8. [Best Practices](#best-practices)

## Tool Overview

### Checkov

**Purpose**: Infrastructure-as-code security scanner that analyzes Terraform files for security misconfigurations.

**Key Features**:
- 1000+ built-in policies for cloud security
- Custom policy development in Python
- Multiple output formats (CLI, JSON, JUnit, SARIF)
- Integration with CI/CD pipelines
- Baseline comparison support
- Azure-specific security checks

**Supported Frameworks**: Terraform, CloudFormation, Kubernetes, Docker, ARM templates

### TFSec

**Purpose**: Terraform-specific static analysis security scanner focused on detecting potential security issues.

**Key Features**:
- Terraform-native security rules
- Custom rule development
- Fast scanning performance
- Multiple output formats
- Integration with popular IDEs
- Severity-based filtering

**Supported Providers**: AWS, Azure, GCP, and others

### Terrascan

**Purpose**: Policy-as-code security validation using Open Policy Agent (OPA) for infrastructure compliance.

**Key Features**:
- OPA/Rego policy language
- Compliance framework support
- Custom policy development
- Multiple IaC format support
- Server mode for API integration
- Kubernetes admission controller

**Supported Formats**: Terraform, CloudFormation, Kubernetes, Docker

## Installation Guide

### Prerequisites

Before installing SAST tools, ensure you have:

- **PowerShell 5.1+** or **PowerShell Core 7+**
- **Python 3.7+** (for Checkov)
- **Internet connection** for downloading tools
- **Administrator privileges** (recommended for system-wide installation)

### Automated Installation

Use the unified installation script to install all tools:

```powershell
# Install all SAST tools
.\security\scripts\install-all-sast-tools.ps1

# Install with custom path
.\security\scripts\install-all-sast-tools.ps1 -InstallPath "C:\Tools"

# Force reinstallation
.\security\scripts\install-all-sast-tools.ps1 -Force

# Skip specific tools
.\security\scripts\install-all-sast-tools.ps1 -SkipCheckov -SkipTerrascan
```

### Manual Installation

#### Checkov Installation

```powershell
# Install via pip
pip install checkov

# Install via pipx (recommended)
pipx install checkov

# Verify installation
checkov --version
```

#### TFSec Installation

```powershell
# Download and install TFSec
.\security\scripts\install-tfsec.ps1

# Manual installation (Windows)
# Download from: https://github.com/aquasecurity/tfsec/releases
# Extract to PATH directory
```

#### Terrascan Installation

```powershell
# Download and install Terrascan
.\security\scripts\install-terrascan.ps1

# Manual installation (Windows)
# Download from: https://github.com/tenable/terrascan/releases
# Extract to PATH directory
```

### Verification

Verify all tools are installed correctly:

```powershell
# Check tool versions
checkov --version
tfsec --version
terrascan version

# Test basic functionality
checkov --help
tfsec --help
terrascan --help
```

## Configuration Details

### Checkov Configuration

**Configuration File**: `security/sast-tools/.checkov.yaml`

**Key Configuration Options**:

```yaml
# Framework configuration
framework:
  - terraform
  - terraform_plan

# Output configuration
output:
  - cli
  - json
  - junit
  - sarif

# Severity levels
severity:
  - CRITICAL
  - HIGH
  - MEDIUM
  - LOW
  - INFO

# Hard fail conditions
hard-fail-on:
  - CRITICAL
  - HIGH
```

**Azure-Specific Checks Enabled**:
- Storage Account security (CKV_AZURE_33, CKV_AZURE_35, CKV_AZURE_36)
- Key Vault security (CKV_AZURE_40, CKV_AZURE_41, CKV_AZURE_42)
- Network Security Groups (CKV_AZURE_9, CKV_AZURE_10, CKV_AZURE_11)
- Virtual Machine security (CKV_AZURE_1, CKV_AZURE_149, CKV_AZURE_178)
- RBAC and Identity (CKV_AZURE_74, CKV_AZURE_107, CKV_AZURE_111)

### TFSec Configuration

**Configuration File**: `security/sast-tools/.tfsec.yml`

**Key Configuration Options**:

```yaml
# Severity overrides
severity_overrides:
  azure-storage-default-action-deny: HIGH
  azure-keyvault-specify-network-acl: HIGH
  azure-network-no-public-ingress: CRITICAL

# Output configuration
format: json
output: security/reports/tfsec-report.json

# Additional outputs
additional_outputs:
  - format: sarif
    output: security/reports/tfsec-sarif.json
  - format: junit
    output: security/reports/tfsec-junit.xml
```

**Custom Rules**: Located in `security/sast-tools/tfsec-rules/azure_custom_rules.json`

### Terrascan Configuration

**Configuration File**: `security/sast-tools/.terrascan_config.toml`

**Key Configuration Options**:

```toml
[scan]
iac-type = "terraform"
cloud-provider = ["azure"]
policy-type = ["opa"]
policy-path = ["security/sast-tools/terrascan-policies/"]

# Output configuration
output = ["json", "sarif", "junit-xml"]
output-dir = "security/reports/"

# Categories to scan
categories = [
    "IDENTITY AND ACCESS MANAGEMENT",
    "DATA PROTECTION", 
    "LOGGING AND MONITORING",
    "NETWORKING",
    "RESILIENCE",
    "ENCRYPTION"
]
```

**Custom Policies**: Located in `security/sast-tools/terrascan-policies/`

## Usage Instructions

### Unified Execution

Use the unified script to run all SAST tools:

```powershell
# Run all tools with default settings
.\security\scripts\run-sast-scan.ps1

# Run with custom options
.\security\scripts\run-sast-scan.ps1 -SourcePath "src/" -ReportsPath "security/reports/" -Verbose

# Skip specific tools
.\security\scripts\run-sast-scan.ps1 -SkipCheckov -SkipTerrascan

# Configure failure conditions
.\security\scripts\run-sast-scan.ps1 -FailOnHigh:$false -FailOnCritical:$true
```

### Individual Tool Execution

#### Running Checkov

```powershell
# Basic scan with config file
checkov --config-file security/sast-tools/.checkov.yaml

# Scan specific directory
checkov -d src/ --framework terraform

# Generate multiple output formats
checkov -d src/ --output cli --output json --output-file-path security/reports/checkov-report.json

# Run with baseline comparison
checkov -d src/ --baseline security/reports/checkov-baseline.json

# Skip specific checks
checkov -d src/ --skip-check CKV_AZURE_1,CKV_AZURE_2
```

#### Running TFSec

```powershell
# Basic scan with config file
tfsec --config-file security/sast-tools/.tfsec.yml src/

# Scan with specific output format
tfsec src/ --format json --out security/reports/tfsec-report.json

# Run with custom severity
tfsec src/ --minimum-severity HIGH

# Include passed checks
tfsec src/ --include-passed

# Run with custom rules
tfsec src/ --custom-check-dir security/sast-tools/tfsec-rules/
```

#### Running Terrascan

```powershell
# Basic scan with config file
terrascan scan --config-path security/sast-tools/.terrascan_config.toml

# Scan specific directory
terrascan scan --iac-dir src/ --iac-type terraform

# Generate specific output format
terrascan scan --iac-dir src/ --output json --output-dir security/reports/

# Run with specific policies
terrascan scan --iac-dir src/ --policy-path security/sast-tools/terrascan-policies/

# Run with severity filtering
terrascan scan --iac-dir src/ --severity high,medium
```

### Output Formats

All tools support multiple output formats:

**Checkov Output Formats**:
- `cli`: Human-readable console output
- `json`: Machine-readable JSON format
- `junit`: JUnit XML for CI/CD integration
- `sarif`: SARIF format for security tools integration

**TFSec Output Formats**:
- `default`: Human-readable console output
- `json`: Machine-readable JSON format
- `csv`: Comma-separated values
- `checkstyle`: Checkstyle XML format
- `junit`: JUnit XML format
- `sarif`: SARIF format

**Terrascan Output Formats**:
- `human`: Human-readable console output
- `json`: Machine-readable JSON format
- `yaml`: YAML format
- `xml`: XML format
- `junit-xml`: JUnit XML format
- `sarif`: SARIF format

## Custom Policies

### Checkov Custom Policies

Custom Checkov policies are written in Python and located in `security/sast-tools/checkov-policies/`.

**Example Custom Policy Structure**:

```python
from checkov.terraform.checks.resource.base_resource_check import BaseResourceCheck
from checkov.common.models.enums import Checkov_Result

class AzureStorageCustomCheck(BaseResourceCheck):
    def __init__(self):
        name = "Ensure Storage Account uses customer-managed keys"
        id = "CKV_AZURE_CUSTOM_001"
        supported_resources = ['azurerm_storage_account']
        categories = [CheckCategories.ENCRYPTION]
        super().__init__(name=name, id=id, categories=categories, supported_resources=supported_resources)

    def scan_resource_conf(self, conf):
        # Implementation logic here
        if 'customer_managed_key' in conf:
            return CheckResult.PASSED
        return CheckResult.FAILED

check = AzureStorageCustomCheck()
```

**Available Custom Policies**:
- `azure_storage_custom.py`: Storage Account security policies
- `azure_keyvault_custom.py`: Key Vault security policies

### TFSec Custom Rules

Custom TFSec rules are defined in JSON format in `security/sast-tools/tfsec-rules/azure_custom_rules.json`.

**Example Custom Rule Structure**:

```json
{
  "rules": [
    {
      "id": "CUSTOM_AZURE_001",
      "description": "Ensure storage account uses customer-managed keys",
      "impact": "Data may not be encrypted with customer-controlled keys",
      "resolution": "Configure customer-managed key encryption",
      "provider": "azure",
      "service": "storage",
      "severity": "HIGH",
      "requiredTypes": ["resource"],
      "requiredLabels": ["azurerm_storage_account"],
      "rule": {
        "and": [
          {
            "key": "customer_managed_key",
            "operation": "isPresent"
          }
        ]
      }
    }
  ]
}
```

### Terrascan Custom Policies

Custom Terrascan policies are written in Rego (OPA policy language) and located in `security/sast-tools/terrascan-policies/`.

**Example Custom Policy Structure**:

```rego
package accurics

# Rule to ensure storage account encryption
storageAccountEncryption[retVal] {
    resource := input.azurerm_storage_account[_]
    not resource.config.encryption
    
    retVal := {
        "Id": "AC_AZURE_CUSTOM_001",
        "RuleId": "AC_AZURE_CUSTOM_001",
        "Severity": "HIGH",
        "Description": "Storage account should have encryption enabled",
        "Category": "ENCRYPTION"
    }
}
```

**Available Custom Policies**:
- `azure_storage_policies.rego`: Storage Account OPA policies
- `azure_keyvault_policies.rego`: Key Vault OPA policies
- `azure_network_policies.rego`: Network Security Group OPA policies

## CI/CD Integration

### GitHub Actions Integration

**Example GitHub Actions Workflow**:

```yaml
name: Security Scan
on: [push, pull_request]

jobs:
  security-scan:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v3
      
      - name: Install SAST Tools
        run: |
          pip install checkov
          # Install TFSec and Terrascan
          
      - name: Run Security Scan
        run: |
          ./security/scripts/run-sast-scan.ps1
          
      - name: Upload Reports
        uses: actions/upload-artifact@v3
        with:
          name: security-reports
          path: security/reports/
```

### Azure DevOps Integration

**Example Azure DevOps Pipeline**:

```yaml
trigger:
  - main

pool:
  vmImage: 'windows-latest'

steps:
- task: PowerShell@2
  displayName: 'Install SAST Tools'
  inputs:
    filePath: 'security/scripts/install-all-sast-tools.ps1'

- task: PowerShell@2
  displayName: 'Run Security Scan'
  inputs:
    filePath: 'security/scripts/run-sast-scan.ps1'
    arguments: '-FailOnHigh -FailOnCritical'

- task: PublishTestResults@2
  displayName: 'Publish Security Results'
  inputs:
    testResultsFormat: 'JUnit'
    testResultsFiles: 'security/reports/*junit*.xml'
```

### Pre-commit Hooks Integration

**Example Pre-commit Configuration** (`.pre-commit-config.yaml`):

```yaml
repos:
  - repo: local
    hooks:
      - id: checkov
        name: Checkov
        entry: checkov
        args: ['--config-file', 'security/sast-tools/.checkov.yaml']
        language: python
        files: \.tf$
        
      - id: tfsec
        name: TFSec
        entry: tfsec
        args: ['--config-file', 'security/sast-tools/.tfsec.yml']
        language: golang
        files: \.tf$
```

## Troubleshooting

### Common Installation Issues

#### Checkov Installation Problems

**Issue**: `pip install checkov` fails with permission errors
**Solution**:
```powershell
# Use user installation
pip install --user checkov

# Or use pipx
pipx install checkov

# Or use virtual environment
python -m venv venv
.\venv\Scripts\Activate.ps1
pip install checkov
```

**Issue**: Checkov not found in PATH
**Solution**:
```powershell
# Add Python Scripts directory to PATH
$env:PATH += ";$env:USERPROFILE\AppData\Local\Programs\Python\Python39\Scripts"

# Or use full path
& "$env:USERPROFILE\AppData\Local\Programs\Python\Python39\Scripts\checkov.exe" --version
```

#### TFSec Installation Problems

**Issue**: TFSec binary not found
**Solution**:
```powershell
# Download manually and add to PATH
$tfsecPath = "$env:USERPROFILE\bin"
New-Item -ItemType Directory -Path $tfsecPath -Force
# Download tfsec.exe to $tfsecPath
$env:PATH += ";$tfsecPath"
```

**Issue**: TFSec fails with "access denied"
**Solution**:
```powershell
# Run PowerShell as Administrator
# Or unblock the downloaded file
Unblock-File -Path "path\to\tfsec.exe"
```

#### Terrascan Installation Problems

**Issue**: Terrascan binary not executable
**Solution**:
```powershell
# Ensure binary has execute permissions
# Download correct architecture (x64/x86)
# Verify with: terrascan version
```

### Common Execution Issues

#### Configuration File Errors

**Issue**: "Config file not found" errors
**Solution**:
```powershell
# Verify config file paths
Test-Path "security/sast-tools/.checkov.yaml"
Test-Path "security/sast-tools/.tfsec.yml"
Test-Path "security/sast-tools/.terrascan_config.toml"

# Run from project root directory
cd path\to\project\root
.\security\scripts\run-sast-scan.ps1
```

**Issue**: YAML/TOML syntax errors
**Solution**:
```powershell
# Validate YAML syntax
Get-Content "security/sast-tools/.checkov.yaml" | ConvertFrom-Yaml

# Validate TOML syntax (use online validator)
# Check for indentation and special characters
```

#### Scan Execution Errors

**Issue**: "No Terraform files found" errors
**Solution**:
```powershell
# Verify source directory exists and contains .tf files
Get-ChildItem -Path "src/" -Filter "*.tf" -Recurse

# Check directory permissions
# Ensure relative paths are correct
```

**Issue**: Custom policy loading errors
**Solution**:
```powershell
# Verify custom policy syntax
python -m py_compile security/sast-tools/checkov-policies/azure_storage_custom.py

# Check Rego policy syntax
opa fmt security/sast-tools/terrascan-policies/azure_storage_policies.rego
```

#### Report Generation Issues

**Issue**: Reports directory not created
**Solution**:
```powershell
# Create reports directory manually
New-Item -ItemType Directory -Path "security/reports" -Force

# Check directory permissions
Get-Acl "security/reports"
```

**Issue**: JSON parsing errors in reports
**Solution**:
```powershell
# Validate JSON syntax
Get-Content "security/reports/checkov-report.json" | ConvertFrom-Json

# Check for truncated files
# Verify disk space availability
```

### Performance Issues

#### Slow Scan Performance

**Issue**: Scans taking too long
**Solution**:
```powershell
# Exclude unnecessary directories
# Add to .checkov.yaml:
# skip-path:
#   - .terraform/
#   - .git/

# Use parallel execution where supported
# Optimize custom policies for performance
```

**Issue**: High memory usage
**Solution**:
```powershell
# Run tools individually instead of unified script
# Increase available memory
# Split large Terraform files
```

### Debug Mode

Enable debug/verbose output for troubleshooting:

```powershell
# Checkov debug mode
checkov -d src/ --verbose

# TFSec debug mode
tfsec src/ --debug

# Terrascan verbose mode
terrascan scan --iac-dir src/ --verbose

# Unified script verbose mode
.\security\scripts\run-sast-scan.ps1 -Verbose
```

### Log Analysis

Check individual tool outputs for detailed error information:

```powershell
# Check PowerShell execution logs
Get-EventLog -LogName "Windows PowerShell" -Newest 10

# Review tool-specific error messages
# Check security/reports/ directory for partial outputs
# Verify network connectivity for tool downloads
```

## Best Practices

### Configuration Management

1. **Version Control**: Keep all configuration files in version control
2. **Environment-Specific Configs**: Use different configs for dev/staging/prod
3. **Regular Updates**: Keep tool configurations updated with latest rules
4. **Documentation**: Document all custom policies and rule modifications

### Policy Development

1. **Test Thoroughly**: Test custom policies with sample Terraform code
2. **Follow Conventions**: Use consistent naming and documentation
3. **Performance Considerations**: Optimize policies for scan performance
4. **Backward Compatibility**: Consider impact of policy changes on existing code

### CI/CD Integration

1. **Fail Fast**: Configure appropriate failure conditions for different environments
2. **Report Storage**: Store scan reports as build artifacts
3. **Trend Analysis**: Track security metrics over time
4. **Notification**: Set up alerts for critical security issues

### Maintenance

1. **Regular Updates**: Keep SAST tools updated to latest versions
2. **Policy Reviews**: Regularly review and update custom policies
3. **Performance Monitoring**: Monitor scan execution times and resource usage
4. **Training**: Ensure team members understand tool usage and results

### Security Considerations

1. **Tool Security**: Keep SAST tools themselves updated for security
2. **Report Handling**: Secure storage and transmission of security reports
3. **Access Control**: Limit access to security configurations and reports
4. **Incident Response**: Integrate with security incident response procedures

## References

- [Checkov Documentation](https://www.checkov.io/1.Welcome/Quick%20Start.html)
- [TFSec Documentation](https://aquasecurity.github.io/tfsec/)
- [Terrascan Documentation](https://runterrascan.io/docs/)
- [Azure Security Best Practices](https://docs.microsoft.com/en-us/azure/security/)
- [Open Policy Agent (OPA)](https://www.openpolicyagent.org/docs/latest/)
- [SARIF Format Specification](https://sarifweb.azurewebsites.net/)
- [Terraform Security Best Practices](https://www.terraform.io/docs/cloud/guides/recommended-practices/index.html)