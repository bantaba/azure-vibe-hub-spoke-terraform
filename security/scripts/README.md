# Security Scripts Documentation

This directory contains PowerShell scripts for local security scan execution, report generation, and remediation assistance.

## Scripts Overview

### 🔍 Local Security Scan Execution

#### `local-security-scan.ps1`
Enhanced script for executing SAST tools locally with comprehensive reporting and remediation guidance.

**Features:**
- Interactive and automated execution modes
- Detailed security findings analysis
- Built-in remediation guidance
- Multiple output formats (detailed, summary, JSON)
- Severity filtering
- Baseline generation

**Usage:**
```powershell
# Run all tools with detailed output
.\local-security-scan.ps1

# Run specific tool with interactive mode
.\local-security-scan.ps1 -Tool checkov -Interactive

# Filter by severity and generate baseline
.\local-security-scan.ps1 -Severity high -GenerateBaseline

# Dry run to preview execution
.\local-security-scan.ps1 -DryRun -Verbose

# JSON output for CI/CD integration
.\local-security-scan.ps1 -OutputFormat json
```

**Parameters:**
- `-SourcePath`: Path to Terraform source code (default: "src/")
- `-ReportsPath`: Path for report output (default: "security/reports/")
- `-Tool`: Tool selection (all, checkov, tfsec, terrascan)
- `-Interactive`: Enable interactive mode with confirmations
- `-DryRun`: Preview execution without running scans
- `-Verbose`: Enable verbose output
- `-ShowRemediation`: Include remediation guidance (default: true)
- `-GenerateBaseline`: Create security baseline file
- `-Severity`: Filter by severity (all, critical, high, medium, low)
- `-OutputFormat`: Output format (detailed, summary, json)

### 📊 Report Generation

#### `generate-security-report.ps1`
Generates comprehensive security reports with analysis and remediation guidance.

**Features:**
- Multiple report formats (HTML, Markdown, JSON)
- Executive summary with risk scoring
- Detailed findings analysis
- Remediation guidance integration
- Trend analysis (when baseline available)
- Interactive HTML reports

**Usage:**
```powershell
# Generate HTML report with remediation guidance
.\generate-security-report.ps1 -ReportFormat html -OpenReport

# Generate Markdown report for documentation
.\generate-security-report.ps1 -ReportFormat markdown

# Generate JSON report for automation
.\generate-security-report.ps1 -ReportFormat json

# Executive summary report
.\generate-security-report.ps1 -ReportType executive
```

**Parameters:**
- `-ReportsPath`: Path to scan reports (default: "security/reports/")
- `-OutputPath`: Path for generated reports (default: "security/reports/")
- `-ReportFormat`: Format (html, markdown, json)
- `-ReportType`: Type (comprehensive, summary, executive)
- `-IncludeRemediation`: Include remediation guidance (default: true)
- `-IncludeTrends`: Include trend analysis
- `-BaselinePath`: Path to baseline file for comparison
- `-OpenReport`: Automatically open HTML reports

### 🔧 Remediation Assistance

#### `remediation-assistant.ps1`
Interactive tool for security finding remediation with automated fix suggestions.

**Features:**
- Interactive remediation guidance
- Automated fix application
- Comprehensive remediation database
- Bulk fix operations
- Backup creation before fixes
- Detailed remediation reports

**Usage:**
```powershell
# Interactive remediation assistant
.\remediation-assistant.ps1

# Get guidance for specific rule
.\remediation-assistant.ps1 -RuleId CKV_AZURE_33

# Apply automated fixes (dry run)
.\remediation-assistant.ps1 -ApplyFixes -DryRun

# Non-interactive mode with report generation
.\remediation-assistant.ps1 -Interactive:$false

# Filter by severity and tool
.\remediation-assistant.ps1 -Severity critical -Tool checkov
```

**Parameters:**
- `-ReportsPath`: Path to scan reports (default: "security/reports/")
- `-SourcePath`: Path to Terraform source (default: "src/")
- `-RuleId`: Specific rule ID for guidance
- `-Tool`: Filter by tool (checkov, tfsec, terrascan)
- `-Interactive`: Enable interactive mode (default: true)
- `-ApplyFixes`: Apply automated fixes
- `-DryRun`: Preview fixes without applying (default: true)
- `-Severity`: Filter by severity level

### 🛠️ Installation and Setup

#### `install-all-sast-tools.ps1`
Installs all required SAST tools for security scanning.

**Usage:**
```powershell
# Install all tools
.\install-all-sast-tools.ps1

# Force reinstall
.\install-all-sast-tools.ps1 -Force

# Skip specific tools
.\install-all-sast-tools.ps1 -SkipTerrascan
```

#### `run-sast-scan.ps1`
Legacy unified SAST execution script (use `local-security-scan.ps1` for enhanced features).

## Workflow Examples

### 🚀 Quick Security Assessment

```powershell
# 1. Install tools (if not already installed)
.\install-all-sast-tools.ps1

# 2. Run comprehensive security scan
.\local-security-scan.ps1 -OutputFormat detailed -ShowRemediation

# 3. Generate HTML report
.\generate-security-report.ps1 -ReportFormat html -OpenReport

# 4. Get interactive remediation guidance
.\remediation-assistant.ps1
```

### 🔄 CI/CD Integration

```powershell
# 1. Run scan with JSON output
.\local-security-scan.ps1 -OutputFormat json -Interactive:$false

# 2. Generate machine-readable report
.\generate-security-report.ps1 -ReportFormat json

# 3. Check exit code for build decisions
if ($LASTEXITCODE -ne 0) {
    Write-Host "Security issues found - failing build"
    exit 1
}
```

### 🎯 Focused Remediation

```powershell
# 1. Scan for critical issues only
.\local-security-scan.ps1 -Severity critical

# 2. Get remediation guidance for critical findings
.\remediation-assistant.ps1 -Severity critical

# 3. Apply automated fixes with confirmation
.\remediation-assistant.ps1 -ApplyFixes -DryRun:$false -Interactive

# 4. Re-scan to verify fixes
.\local-security-scan.ps1 -Severity critical
```

## Output Files

### Report Files
- `checkov-report.json` - Checkov scan results
- `tfsec-report.json` - TFSec scan results  
- `results.json` - Terrascan scan results
- `unified-sast-report.json` - Aggregated results
- `local-scan-results.json` - Enhanced scan results
- `security-report-{timestamp}.html` - HTML report
- `security-report-{timestamp}.md` - Markdown report
- `remediation-guidance-{timestamp}.md` - Remediation report

### Baseline Files
- `security-baseline.json` - Security baseline for trend analysis
- `checkov-baseline.json` - Checkov-specific baseline

### Log Files
- `{tool}-output.log` - Tool execution output
- `{tool}-error.log` - Tool execution errors

## Configuration Files

The scripts use configuration files located in `security/sast-tools/`:
- `.checkov.yaml` - Checkov configuration
- `.tfsec.yml` - TFSec configuration
- `.terrascan_config.toml` - Terrascan configuration

## Error Handling

All scripts include comprehensive error handling:
- **Prerequisites Check**: Validates tool installation and configuration
- **File Validation**: Ensures required files and directories exist
- **Graceful Failures**: Continues execution when individual tools fail
- **Backup Creation**: Creates backups before applying automated fixes
- **Exit Codes**: Proper exit codes for CI/CD integration

## Security Considerations

- **Backup Creation**: Automated fixes create timestamped backups
- **Dry Run Mode**: Default dry run prevents accidental changes
- **Interactive Confirmation**: User confirmation for destructive operations
- **Least Privilege**: Scripts only modify necessary files
- **Audit Trail**: Detailed logging of all operations

## Troubleshooting

### Common Issues

1. **Tool Not Found**
   ```powershell
   # Install missing tools
   .\install-all-sast-tools.ps1
   ```

2. **Permission Errors**
   ```powershell
   # Run as administrator or check file permissions
   Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope CurrentUser
   ```

3. **Configuration Errors**
   ```powershell
   # Validate configuration files
   Test-Path security/sast-tools/.checkov.yaml
   ```

4. **Report Generation Failures**
   ```powershell
   # Check reports directory permissions
   New-Item -ItemType Directory -Path security/reports -Force
   ```

### Debug Mode

Enable verbose output for troubleshooting:
```powershell
.\local-security-scan.ps1 -Verbose -DryRun
```

## Integration with Other Tools

### Git Integration
Scripts integrate with git workflow automation:
```powershell
# Run scan and auto-commit results
.\local-security-scan.ps1
.\..\..\scripts\git\smart-commit.ps1 -Message "Security scan results"
```

### CI/CD Integration
Example Azure DevOps integration:
```yaml
- task: PowerShell@2
  displayName: 'Run Security Scan'
  inputs:
    filePath: 'security/scripts/local-security-scan.ps1'
    arguments: '-OutputFormat json -Interactive:$false'
```

## Best Practices

1. **Regular Scanning**: Run scans before commits and in CI/CD
2. **Baseline Management**: Update baselines after legitimate changes
3. **Remediation Priority**: Address critical and high severity issues first
4. **Documentation**: Keep remediation reports for audit purposes
5. **Testing**: Test fixes in development environment first
6. **Monitoring**: Track security posture improvements over time

## Support and Documentation

For additional help:
- Check the main project documentation in `docs/`
- Review configuration files in `security/sast-tools/`
- Examine log files in `security/reports/` for detailed error information
- Use the `-Verbose` flag for detailed execution information