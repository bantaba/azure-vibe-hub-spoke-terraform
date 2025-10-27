# Git Hooks for Terraform Security

This directory contains git hooks and related scripts for automated Terraform security validation and code quality checks.

## Overview

The git hooks system provides automated validation before commits to ensure:
- Terraform code is properly formatted
- Terraform configuration is valid
- No sensitive data is committed
- Security best practices are followed
- File size limits are respected

## Files

### Hook Scripts
- `pre-commit` - Main git pre-commit hook (shell script)
- `pre-commit-hook.ps1` - PowerShell implementation of pre-commit validation

### Management Scripts
- `install-hooks.ps1` - Install git hooks
- `uninstall-hooks.ps1` - Remove git hooks
- `configure-hooks.ps1` - Configure hook behavior

### Documentation
- `README.md` - This file

## Installation

### Quick Installation

```powershell
# Install hooks with default settings
.\scripts\git\install-hooks.ps1
```

### Installation Options

```powershell
# Force installation (overwrite existing hooks)
.\scripts\git\install-hooks.ps1 -Force

# Verbose output during installation
.\scripts\git\install-hooks.ps1 -Verbose
```

## Configuration

### Interactive Configuration

```powershell
# Launch interactive configuration wizard
.\scripts\git\configure-hooks.ps1 -Interactive
```

### View Current Configuration

```powershell
# Display current hook settings
.\scripts\git\configure-hooks.ps1 -ShowCurrent
```

### Manual Configuration

Edit the configuration file directly:
```
.git/hooks/config.json
```

## Usage

### Automatic Execution

Once installed, the pre-commit hook runs automatically before each commit:

```bash
git add .
git commit -m "Your commit message"
# Hook runs automatically here
```

### Manual Execution

Run the hook manually to test changes:

```bash
# Run pre-commit hook manually
.git/hooks/pre-commit

# Or run the PowerShell script directly
pwsh scripts/git/pre-commit-hook.ps1
```

### Skipping Hooks

Temporarily skip hooks when needed:

```bash
# Skip all pre-commit hooks
git commit --no-verify -m "Emergency commit"
```

## Hook Features

### Terraform Format Check
- Validates that all Terraform files are properly formatted
- Suggests running `terraform fmt` to fix issues
- **Blocks commit** if formatting issues are found

### Terraform Validation
- Initializes Terraform (without backend)
- Validates Terraform configuration syntax
- **Blocks commit** if validation fails

### Sensitive Data Detection
- Scans for hardcoded passwords, secrets, API keys
- Uses configurable regex patterns
- **Blocks commit** if sensitive data is detected

### File Size Limits
- Checks for oversized files (default: 1MB)
- Suggests using Git LFS for large files
- **Warning only** - does not block commits

### Security Scanning
- Runs quick security scans with available tools
- Supports Checkov, TFSec, and Terrascan
- **Warning only** - does not block commits
- Suggests running full security scan for detailed analysis

## Configuration Options

### Pre-commit Hook Settings

| Setting | Default | Description |
|---------|---------|-------------|
| `enabled` | `true` | Enable/disable the pre-commit hook |
| `skipSecurity` | `false` | Skip security scanning |
| `skipFormat` | `false` | Skip Terraform format check |
| `skipValidation` | `false` | Skip Terraform validation |
| `skipSensitiveData` | `false` | Skip sensitive data detection |
| `skipFileSize` | `false` | Skip file size check |
| `verbose` | `false` | Enable verbose output |
| `maxFileSize` | `1048576` | Maximum file size in bytes (1MB) |

### Security Tools Configuration

Each security tool can be individually configured:

```json
{
  "securityTools": {
    "checkov": {
      "enabled": true,
      "timeout": 60,
      "args": ["--quiet", "--compact"]
    },
    "tfsec": {
      "enabled": true,
      "timeout": 30,
      "args": ["--no-color", "--concise-output"]
    },
    "terrascan": {
      "enabled": true,
      "timeout": 60,
      "args": ["--non-recursive", "--verbose"]
    }
  }
}
```

### Sensitive Data Patterns

Customize patterns for sensitive data detection:

```json
{
  "sensitivePatterns": [
    {
      "pattern": "password\\s*=\\s*[\"'][^\"']+[\"']",
      "description": "Hardcoded password"
    },
    {
      "pattern": "secret\\s*=\\s*[\"'][^\"']+[\"']",
      "description": "Hardcoded secret"
    }
  ]
}
```

## Prerequisites

### Required Tools
- **Git** - Version control system
- **PowerShell** - For enhanced functionality (PowerShell Core recommended)
- **Terraform** - For format checking and validation

### Optional Tools (for security scanning)
- **Checkov** - Infrastructure as Code security scanner
- **TFSec** - Terraform security scanner
- **Terrascan** - Policy as Code security validation

Install security tools using:
```powershell
.\scripts\security\install-all-sast-tools.ps1
```

## Troubleshooting

### Hook Not Running
1. Check if hook is installed: `ls -la .git/hooks/pre-commit`
2. Verify hook is executable (Unix/Linux): `chmod +x .git/hooks/pre-commit`
3. Test hook manually: `.git/hooks/pre-commit`

### PowerShell Execution Policy
If you encounter execution policy errors:

```powershell
# Set execution policy for current user
Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope CurrentUser

# Or run with bypass
pwsh -ExecutionPolicy Bypass -File scripts/git/pre-commit-hook.ps1
```

### Terraform Not Found
1. Install Terraform from [terraform.io](https://terraform.io)
2. Ensure Terraform is in your PATH
3. Test: `terraform version`

### Security Tools Not Found
1. Install tools using the provided scripts
2. Or disable security scanning: `configure-hooks.ps1 -Interactive`
3. Or skip security checks: `git commit --no-verify`

### Hook Fails on Large Repositories
1. Increase timeouts in configuration
2. Skip security scanning for large commits
3. Use `--no-verify` for emergency commits

## Uninstallation

### Remove Hooks

```powershell
# Remove all installed hooks
.\scripts\git\uninstall-hooks.ps1

# Force removal without prompts
.\scripts\git\uninstall-hooks.ps1 -Force

# Keep backup files
.\scripts\git\uninstall-hooks.ps1 -KeepBackups
```

### Clean Removal

```powershell
# Remove hooks and all backups
.\scripts\git\uninstall-hooks.ps1 -Force

# Remove configuration file
Remove-Item .git/hooks/config.json -ErrorAction SilentlyContinue
```

## Advanced Usage

### Custom Hook Arguments

Pass arguments to the PowerShell hook:

```bash
# Run with verbose output
pwsh scripts/git/pre-commit-hook.ps1 -Verbose

# Skip specific checks
pwsh scripts/git/pre-commit-hook.ps1 -SkipSecurity -SkipFormat
```

### Integration with CI/CD

The hooks are designed to complement CI/CD pipelines:
- Local hooks provide fast feedback
- CI/CD pipelines provide comprehensive validation
- Both use the same security tools and configurations

### Team Configuration

Share hook configuration across the team:

1. Commit the configuration file:
   ```bash
   git add .git/hooks/config.json
   git commit -m "Add team hook configuration"
   ```

2. Team members run:
   ```powershell
   .\scripts\git\install-hooks.ps1
   ```

## Support

For issues or questions:
1. Check the troubleshooting section above
2. Review the configuration with `configure-hooks.ps1 -ShowCurrent`
3. Test individual components manually
4. Check security tool documentation for tool-specific issues

## Related Documentation

- [Security Tools Documentation](../security/README.md)
- [CI/CD Pipeline Documentation](../../.github/workflows/README.md)
- [Project Security Documentation](../../security/README.md)