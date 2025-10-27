# Scripts

This directory contains automation scripts for the Terraform security enhancement project.

## Structure

- `git/` - Git automation and workflow scripts
- `security/` - Security scanning and validation scripts
- `ci-cd/` - CI/CD pipeline scripts and configurations
- `utils/` - Utility scripts for project maintenance

## Script Standards

All scripts follow these conventions:
- PowerShell scripts use `.ps1` extension
- Include proper error handling and logging
- Document parameters and usage in script headers
- Follow consistent naming conventions

## Documentation

Comprehensive documentation is available in the `docs/` directory:
- **Setup Guide**: `docs/setup/git-automation-setup.md` - Installation and configuration
- **Operations Guide**: `docs/operations/git-workflow-operations.md` - Daily operations and troubleshooting
- **Git Scripts**: `scripts/git/README.md` - Detailed usage and examples

## Quick Start

```powershell
# Smart commit with auto-generated message
.\git\smart-commit.ps1

# Interactive commit with confirmation
.\git\smart-commit.ps1 -Interactive

# Preview changes without committing
.\git\smart-commit.ps1 -DryRun
```