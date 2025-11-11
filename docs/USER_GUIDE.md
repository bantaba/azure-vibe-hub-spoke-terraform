# User Guide - Terraform Security Enhancement

## Table of Contents
1. [Getting Started](#getting-started)
2. [Daily Workflow](#daily-workflow)
3. [Integration System](#integration-system)
4. [Security Scanning](#security-scanning)
5. [CI/CD Pipelines](#cicd-pipelines)
6. [Troubleshooting](#troubleshooting)
7. [Advanced Usage](#advanced-usage)

## Getting Started

### Prerequisites

Before using the Terraform Security Enhancement system, ensure you have:

- **Terraform** >= 1.5.7 installed
- **PowerShell** 5.1 or later
- **Git** repository initialized
- **Azure CLI** (optional, for deployment)
- **Visual Studio Code** (recommended) with Terraform extension

### Initial Setup

1. **Clone and Navigate to Project**
   ```bash
   git clone <repository-url>
   cd terraform-security-enhancement
   ```

2. **Initialize Integration System**
   ```powershell
   # Setup all integration components
   .\scripts\integration\master-integration.ps1 -Action setup
   
   # Validate the setup
   .\scripts\integration\master-integration.ps1 -Action validate
   ```

3. **Verify Installation**
   ```powershell
   # Check integration status
   .\scripts\integration\master-integration.ps1 -Action status
   
   # Run security validation
   .\scripts\integration\security-validation-report.ps1
   ```

### First-Time Configuration

1. **Configure Git Settings** (if not already done)
   ```bash
   git config user.name "Your Name"
   git config user.email "your.email@company.com"
   ```

2. **Review Default Settings**
   - Check `src/variables.tf` for default configurations
   - Review `security/sast-tools/` for security tool settings
   - Examine `.github/workflows/` for CI/CD pipeline configuration

## Daily Workflow

### Working with Tasks

The integration system is designed around task-based development. Here's the typical workflow:

#### 1. Start a New Task
```powershell
# Begin working on a task
# Make your changes to Terraform files, scripts, or documentation
```

#### 2. Complete a Task
```powershell
# Complete a task with full integration
.\scripts\integration\master-integration.ps1 -Action task-complete -TaskName "Implement storage account encryption" -TaskId "4.1"

# Complete a task without security scan (for documentation-only changes)
.\scripts\integration\master-integration.ps1 -Action task-complete -TaskName "Update README" -SkipScan

# Complete a task without documentation update
.\scripts\integration\master-integration.ps1 -Action task-complete -TaskName "Fix bug" -SkipDocs
```

#### 3. Review Results
After task completion, the system will:
- ✅ Automatically commit your changes with standardized messages
- ✅ Run security scans (if applicable)
- ✅ Update documentation
- ✅ Trigger CI/CD pipelines

### Task Types and Automation

The system automatically detects task types and applies appropriate workflows:

| Task Type | Auto-Commit | Security Scan | Documentation Update |
|-----------|-------------|---------------|---------------------|
| `security` | ✅ | ✅ | ✅ |
| `terraform` | ✅ | ✅ | ✅ |
| `sast` | ✅ | ✅ | ✅ |
| `cicd` | ✅ | ⚠️ | ✅ |
| `docs` | ✅ | ❌ | ✅ |
| `fix` | ✅ | ⚠️ | ⚠️ |

**Legend:** ✅ Always, ⚠️ Conditional, ❌ Never

### Manual Task Completion

For more control, use the task completion hook directly:

```powershell
# Specify task type explicitly
.\scripts\integration\task-completion-hook.ps1 -TaskName "Configure Checkov rules" -TaskType "sast" -TaskId "3.1"

# Skip specific integrations
.\scripts\integration\task-completion-hook.ps1 -TaskName "Update config" -SkipSecurityScan -SkipDocumentationUpdate

# Dry run to see what would happen
.\scripts\integration\task-completion-hook.ps1 -TaskName "Test task" -DryRun -Verbose
```

## Integration System

### Master Integration Script

The `master-integration.ps1` script is your main interface:

```powershell
# Show help
.\scripts\integration\master-integration.ps1 -Help

# Available actions
.\scripts\integration\master-integration.ps1 -Action setup           # Initialize system
.\scripts\integration\master-integration.ps1 -Action validate        # Validate configuration
.\scripts\integration\master-integration.ps1 -Action status          # Show current status
.\scripts\integration\master-integration.ps1 -Action task-complete   # Complete a task
.\scripts\integration\master-integration.ps1 -Action security-scan   # Run security scan
```

### Integration Components

#### Auto-Commit System
Automatically commits changes with intelligent commit messages:

```powershell
# Manual commit with task context
.\scripts\git\commit-task.ps1 -TaskName "Add network security rules" -TaskType "security"

# Auto-detect task type
.\scripts\git\commit-task.ps1 -TaskName "Update Terraform modules"

# Force commit without validation
.\scripts\git\commit-task.ps1 -TaskName "Emergency fix" -Force
```

#### Documentation Integration
Automatically updates project documentation:

```powershell
# Update documentation for security scan results
.\scripts\integration\documentation-integration.ps1 -UpdateTrigger security-scan

# Update for task completion
.\scripts\integration\documentation-integration.ps1 -UpdateTrigger task-completion -TaskName "Your task"

# Full documentation update
.\scripts\integration\documentation-integration.ps1 -UpdateTrigger full-update
```

## Security Scanning

### Running Security Scans

#### Comprehensive Security Scan
```powershell
# Run all SAST tools
.\security\scripts\run-sast-scan.ps1

# Run with specific options
.\security\scripts\run-sast-scan.ps1 -FailOnHigh $false -Verbose

# Skip specific tools
.\security\scripts\run-sast-scan.ps1 -SkipCheckov -SkipTerrascan
```

#### Individual Tool Scans
```powershell
# Checkov only
checkov --config-file security/sast-tools/.checkov.yaml --directory src/

# TFSec only
tfsec src/ --config-file security/sast-tools/.tfsec.yml

# Terrascan only
terrascan scan --config-path security/sast-tools/.terrascan_config.toml --iac-dir src/
```

### Security Validation Report
```powershell
# Generate comprehensive security report
.\scripts\integration\security-validation-report.ps1

# Detailed report with verbose output
.\scripts\integration\security-validation-report.ps1 -DetailedReport -VerboseOutput

# Export results to JSON
.\scripts\integration\security-validation-report.ps1 -ExportJson
```

### Understanding Security Results

#### Security Score Breakdown
- **Terraform Configuration (20 points)**: Format and validation
- **Security Modules (25 points)**: Module completeness and configuration
- **SAST Tools (20 points)**: Tool configuration and functionality
- **CI/CD Pipelines (20 points)**: Pipeline security integration
- **Integration System (15 points)**: System component completeness

#### Security Levels
- **🟢 Excellent (80-100)**: Production ready
- **🟡 Good (60-79)**: Minor improvements needed
- **🔴 Needs Improvement (<60)**: Significant issues to address

## CI/CD Pipelines

### GitHub Actions

The project includes a comprehensive GitHub Actions workflow:

#### Triggering Workflows
- **Automatic**: Push to main/develop branches
- **Manual**: Workflow dispatch with custom parameters
- **Pull Request**: Automatic validation on PRs

#### Workflow Features
```yaml
# Manual trigger with options
workflow_dispatch:
  inputs:
    skip_checkov: false
    skip_tfsec: false
    skip_terrascan: false
    fail_on_high: true
```

#### Monitoring Workflow Results
1. Go to **Actions** tab in GitHub
2. Select the **Terraform Security Scan** workflow
3. Review security scan results and reports
4. Check **Security** tab for SARIF results

### Azure DevOps

For Azure DevOps integration:

#### Pipeline Configuration
- File: `azure-pipelines.yml`
- Triggers: Branch policies and manual runs
- Features: Multi-stage pipeline with security gates

#### Running Pipelines
1. Navigate to **Pipelines** in Azure DevOps
2. Select the security pipeline
3. Click **Run pipeline**
4. Review results and artifacts

## Troubleshooting

### Common Issues

#### Integration Scripts Not Found
```
Error: Integration orchestrator not found
```
**Solution:**
```powershell
.\scripts\integration\master-integration.ps1 -Action setup
```

#### Git Repository Issues
```
Error: Not in a git repository
```
**Solution:**
```bash
git init
git add .
git commit -m "Initial commit"
```

#### Security Scan Failures
```
Security scan integration failed
```
**Solution:**
```powershell
# Install SAST tools
.\security\scripts\install-all-sast-tools.ps1

# Verify configuration
.\scripts\integration\cicd-integration-config.ps1 -Platform validate
```

#### Terraform Validation Errors
```
Terraform validation failed
```
**Solution:**
```powershell
# Format Terraform files
terraform fmt -recursive src/

# Initialize and validate
cd src
terraform init -backend=false
terraform validate
```

### Debug Mode

Enable verbose output for troubleshooting:

```powershell
# Verbose integration execution
.\scripts\integration\master-integration.ps1 -Action validate -VerboseOutput

# Dry run to see what would happen
.\scripts\integration\master-integration.ps1 -Action task-complete -TaskName "Test" -DryRun
```

### Log Files and Reports

Check these locations for detailed information:
- `security/reports/` - Security scan results and integration reports
- `docs/tasks/task-completion-log.md` - Task completion history
- `.github/workflows/` - CI/CD pipeline logs (in GitHub Actions)

## Advanced Usage

### Custom Task Types

Define custom workflows for specialized tasks:

```powershell
# Custom security task
.\scripts\integration\task-completion-hook.ps1 -TaskName "Custom security enhancement" -TaskType "security"

# Custom infrastructure task
.\scripts\integration\task-completion-hook.ps1 -TaskName "Infrastructure update" -TaskType "terraform"
```

### Selective Integration

Run only specific parts of the integration:

```powershell
# Only auto-commit, skip scan and docs
.\scripts\integration\integration-orchestrator.ps1 -IntegrationType task-completion -SkipScan -SkipDocs

# Only security scan
.\scripts\integration\integration-orchestrator.ps1 -IntegrationType security-scan

# Only documentation update
.\scripts\integration\integration-orchestrator.ps1 -IntegrationType documentation-update
```

### Batch Operations

Process multiple tasks efficiently:

```powershell
# Process multiple completed tasks
$tasks = @(
    @{Name="Task 1"; Id="1.1"},
    @{Name="Task 2"; Id="1.2"},
    @{Name="Task 3"; Id="1.3"}
)

foreach ($task in $tasks) {
    .\scripts\integration\master-integration.ps1 -Action task-complete -TaskName $task.Name -TaskId $task.Id
}
```

### Environment Variables

Configure default behavior with environment variables:

```powershell
# Set default dry run mode
$env:INTEGRATION_DRY_RUN = "true"

# Enable verbose output by default
$env:INTEGRATION_VERBOSE = "true"

# Skip security scans by default
$env:SKIP_SECURITY_SCAN = "true"
```

### Integration with External Systems

#### Webhook Integration
```powershell
# Example webhook handler
param($WebhookData)
$taskName = $WebhookData.task_name
$taskId = $WebhookData.task_id

.\scripts\integration\master-integration.ps1 -Action task-complete -TaskName $taskName -TaskId $taskId
```

#### API Integration
```powershell
# Get integration status as structured data
$status = .\scripts\integration\master-integration.ps1 -Action status | ConvertFrom-Json
```

## Best Practices

### Development Workflow
1. **Always validate** before committing changes
2. **Use descriptive task names** for better tracking
3. **Review security scan results** before proceeding
4. **Keep documentation updated** with changes
5. **Test integration workflows** in development

### Security Practices
1. **Run security scans regularly** on all changes
2. **Address critical and high severity issues** immediately
3. **Review security reports** for trends and patterns
4. **Keep SAST tools updated** to latest versions
5. **Monitor CI/CD pipeline security gates**

### Operational Practices
1. **Monitor integration health** regularly
2. **Review task completion logs** for issues
3. **Keep integration scripts updated**
4. **Document custom workflows** for team knowledge
5. **Test disaster recovery procedures**

## Getting Help

### Documentation Resources
- `docs/PROJECT_OVERVIEW.md` - Project overview and architecture
- `docs/setup/` - Installation and configuration guides
- `docs/operations/` - Operational procedures and troubleshooting
- `scripts/integration/README.md` - Integration system documentation

### Diagnostic Tools
```powershell
# System health check
.\scripts\integration\master-integration.ps1 -Action status

# Comprehensive validation
.\scripts\integration\security-validation-report.ps1

# CI/CD integration check
.\scripts\integration\cicd-integration-config.ps1 -Platform validate
```

### Support Workflow
1. **Check documentation** for common issues
2. **Run diagnostic tools** to identify problems
3. **Review log files** for error details
4. **Use verbose mode** for detailed debugging
5. **Create support ticket** with diagnostic information

Remember: The integration system is designed to be self-healing and provide clear error messages. Most issues can be resolved by following the troubleshooting steps and using the built-in diagnostic tools.