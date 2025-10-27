# Git Automation Setup Guide

This guide covers the setup and configuration of the automated git workflow system for the Terraform Security Enhancement project.

## Overview

The git automation system provides intelligent commit message generation, file analysis, and task completion tracking through a suite of PowerShell scripts.

## Prerequisites

- Git installed and configured
- PowerShell 5.1 or later
- Initialized git repository in project root

## Quick Setup

1. **Verify Git Configuration**
   ```powershell
   git config --global user.name "Your Name"
   git config --global user.email "your.email@example.com"
   ```

2. **Test Smart Commit Tool**
   ```powershell
   cd scripts/git
   .\smart-commit.ps1 -DryRun
   ```

3. **Configure Kiro Hook** (Optional)
   - The manual commit hook is pre-configured in `.kiro/hooks/manual-commit-changes.kiro.hook`
   - Enables one-click commits from the Kiro interface

## Script Configuration

### Smart Commit Parameters

| Parameter | Type | Default | Description |
|-----------|------|---------|-------------|
| `CommitMessage` | string | "" | Custom commit message (auto-generated if empty) |
| `DryRun` | switch | false | Preview changes without committing |
| `Interactive` | switch | false | Prompt for confirmation before commit |
| `CommitType` | string | "auto" | Override auto-detected commit type |
| `IncludePatterns` | string[] | @() | File patterns to include (empty = all files) |
| `ExcludePatterns` | string[] | See below | File patterns to exclude |

### Default Exclusion Patterns

The smart commit tool automatically excludes:
- `*.log` - Log files
- `*.tmp` - Temporary files
- `.DS_Store` - macOS system files
- `Thumbs.db` - Windows thumbnail cache
- `node_modules/` - Node.js dependencies
- `.terraform/` - Terraform cache and state

### Custom Exclusion Patterns

Add project-specific exclusions:
```powershell
.\smart-commit.ps1 -ExcludePatterns @("*.log", "*.tmp", "backup/*", "archive/*")
```

## Commit Type Detection

The system automatically detects commit types based on file changes:

### Detection Rules

| Commit Type | Trigger Conditions |
|-------------|-------------------|
| `feat` | New `.tf`, `.ps1`, `.py`, `.js`, `.ts` files |
| `fix` | Bug fix patterns in commit content |
| `docs` | Changes to `.md`, `.txt`, `.rst` files |
| `config` | Updates to `.yaml`, `.yml`, `.json`, `.toml` files |
| `test` | Changes in test files or directories |
| `chore` | Default for other changes |

### Manual Override

Force a specific commit type:
```powershell
.\smart-commit.ps1 -CommitType "feat" -CommitMessage "feat: add new security module"
```

## Message Generation

### Automatic Message Structure

```
type: brief description

- Detailed bullet points about changes
- Context about what was implemented
- Reference to task IDs when detected

New files:
- path/to/new/file1.ext
- path/to/new/file2.ext

Modified files:
- path/to/modified/file1.ext
- path/to/modified/file2.ext
```

### Task Integration

The system detects task-related changes:
- Updates to `.kiro/specs/*/tasks.md`
- Changes in security-related directories
- Script modifications in `scripts/` directory

## Workflow Integration

### Daily Development Workflow

1. **Make Changes** - Implement features, fix issues, update docs
2. **Smart Commit** - Run `.\scripts\git\smart-commit.ps1`
3. **Review** - Check generated commit message
4. **Confirm** - Commit automatically or interactively

### Task Completion Workflow

1. **Complete Task** - Finish implementation work
2. **Update Tasks** - Mark task as complete in `tasks.md`
3. **Auto Commit** - Use Kiro hook or run smart commit
4. **Verify** - Check commit includes task references

## Troubleshooting

### Common Issues

**No changes detected**
```powershell
# Check git status
git status

# Force commit if needed
.\smart-commit.ps1 -CommitMessage "chore: force commit for testing"
```

**Files not staged**
```powershell
# Check exclusion patterns
.\smart-commit.ps1 -DryRun

# Override patterns if needed
.\smart-commit.ps1 -ExcludePatterns @()
```

**Commit message too generic**
```powershell
# Use custom message
.\smart-commit.ps1 -CommitMessage "feat: implement advanced security scanning"

# Or use interactive mode
.\smart-commit.ps1 -Interactive
```

### Debug Mode

Enable verbose output:
```powershell
$VerbosePreference = "Continue"
.\smart-commit.ps1 -DryRun
```

## Best Practices

### Commit Frequency
- Commit after each logical change
- Use smart commit for automatic message generation
- Commit task completions immediately

### Message Quality
- Let the system generate messages for routine changes
- Override with custom messages for significant features
- Use interactive mode for important commits

### File Management
- Keep exclusion patterns updated
- Review dry run output before important commits
- Use include patterns for selective commits

## Integration with CI/CD

The git automation system integrates with:
- **GitHub Actions** - Triggered by commit patterns
- **Azure DevOps** - Pipeline execution on commits
- **Pre-commit Hooks** - Local validation before commits
- **Security Scanning** - Automated scans on commits

## Security Considerations

- Commit messages may contain sensitive information
- Review auto-generated messages before pushing
- Use `.gitignore` to exclude sensitive files
- Validate exclusion patterns regularly

## Advanced Configuration

### Custom Commit Templates

Modify `smart-commit.ps1` to add custom templates:
```powershell
# Add to New-CommitMessage function
if ($fileName -match "custom-pattern") {
    $subject = "custom: implement custom feature"
}
```

### Integration Scripts

Create wrapper scripts for specific workflows:
```powershell
# commit-security-task.ps1
param([string]$TaskId)
.\smart-commit.ps1 -CommitMessage "security: complete task $TaskId" -IncludePatterns @("security/*", "*.tf")
```

## Support

For issues with git automation:
1. Check PowerShell execution policy
2. Verify git repository status
3. Review script parameters and patterns
4. Enable debug mode for detailed output
5. Consult the troubleshooting section above