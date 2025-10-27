# Git Workflow Operations Guide

This guide covers the operational procedures for managing git workflows in the Terraform Security Enhancement project.

## Daily Operations

### Standard Commit Workflow

1. **Check Repository Status**
   ```powershell
   git status
   git log --oneline -5
   ```

2. **Execute Smart Commit**
   ```powershell
   .\scripts\git\smart-commit.ps1
   ```

3. **Verify Commit**
   ```powershell
   git show HEAD --stat
   ```

### Task Completion Workflow

1. **Update Task Status**
   - Mark task as complete in `.kiro/specs/terraform-security-enhancement/tasks.md`
   - Update any related documentation

2. **Commit Changes**
   ```powershell
   # Using Kiro hook (recommended)
   # Click "Manual Commit Changes" in Kiro interface
   
   # Or using command line
   .\scripts\git\smart-commit.ps1 -Interactive
   ```

3. **Validate Commit Message**
   - Ensure task ID is referenced
   - Verify commit type is appropriate
   - Check file list is complete

## Commit Message Standards

### Conventional Commit Format

```
type(scope): description

Body with detailed explanation
- Bullet points for specific changes
- Context about implementation
- References to tasks or issues

Footer with metadata
Task-ID: X.X
Files: N changed
```

### Commit Types

| Type | Usage | Example |
|------|-------|---------|
| `feat` | New features | `feat: add Checkov security scanning` |
| `fix` | Bug fixes | `fix: resolve Terraform validation errors` |
| `docs` | Documentation | `docs: update security setup guide` |
| `config` | Configuration | `config: update SAST tool settings` |
| `security` | Security improvements | `security: implement Key Vault encryption` |
| `chore` | Maintenance | `chore: update file exclusion patterns` |
| `test` | Testing | `test: add security validation tests` |
| `refactor` | Code refactoring | `refactor: optimize Terraform modules` |

### Scope Guidelines

Common scopes for this project:
- `terraform` - Terraform infrastructure changes
- `security` - Security-related modifications
- `sast` - SAST tool configurations
- `cicd` - CI/CD pipeline changes
- `docs` - Documentation updates
- `scripts` - Automation script changes

## File Management

### Inclusion Strategies

**All Files (Default)**
```powershell
.\smart-commit.ps1
```

**Terraform Only**
```powershell
.\smart-commit.ps1 -IncludePatterns @("*.tf", "*.tfvars", "*.hcl")
```

**Documentation Only**
```powershell
.\smart-commit.ps1 -IncludePatterns @("*.md", "docs/*")
```

**Security Files**
```powershell
.\smart-commit.ps1 -IncludePatterns @("security/*", "*.tf", "scripts/security/*")
```

### Exclusion Management

**Default Exclusions**
- Log files (`*.log`)
- Temporary files (`*.tmp`, `*.temp`)
- System files (`.DS_Store`, `Thumbs.db`)
- Dependencies (`node_modules/`)
- Terraform cache (`.terraform/`)

**Custom Exclusions**
```powershell
.\smart-commit.ps1 -ExcludePatterns @("*.log", "backup/*", "archive/*", "*.old")
```

## Monitoring and Maintenance

### Daily Checks

1. **Repository Health**
   ```powershell
   git status
   git log --oneline --since="1 day ago"
   git branch -v
   ```

2. **Commit Quality**
   - Review recent commit messages
   - Verify conventional commit format
   - Check for missing task references

3. **File Tracking**
   - Ensure no sensitive files are tracked
   - Verify `.gitignore` effectiveness
   - Check for large files or binaries

### Weekly Maintenance

1. **Commit History Review**
   ```powershell
   git log --oneline --since="1 week ago" --pretty=format:"%h %s"
   ```

2. **Branch Management**
   ```powershell
   git branch --merged
   git remote prune origin
   ```

3. **Repository Cleanup**
   ```powershell
   git gc --prune=now
   git fsck --full
   ```

## Troubleshooting

### Common Issues

**Smart Commit Not Working**
```powershell
# Check PowerShell execution policy
Get-ExecutionPolicy
Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope CurrentUser

# Verify git configuration
git config --list

# Test with dry run
.\scripts\git\smart-commit.ps1 -DryRun
```

**No Changes Detected**
```powershell
# Check git status
git status --porcelain

# Check for staged changes
git diff --cached

# Force commit if needed
git add .
.\smart-commit.ps1 -CommitMessage "chore: manual commit"
```

**Commit Message Issues**
```powershell
# Use interactive mode
.\smart-commit.ps1 -Interactive

# Override auto-generation
.\smart-commit.ps1 -CommitMessage "feat: custom commit message"

# Check message format
git log -1 --pretty=format:"%B"
```

**File Exclusion Problems**
```powershell
# Check what would be committed
.\smart-commit.ps1 -DryRun

# Override exclusions
.\smart-commit.ps1 -ExcludePatterns @()

# Use specific inclusions
.\smart-commit.ps1 -IncludePatterns @("*.tf", "*.md")
```

### Error Recovery

**Failed Commit**
```powershell
# Check git status
git status

# Reset if needed
git reset HEAD~1

# Retry with different approach
.\smart-commit.ps1 -Interactive
```

**Corrupted Repository**
```powershell
# Check repository integrity
git fsck --full

# Repair if possible
git gc --prune=now

# Backup and reinitialize if necessary
```

## Performance Optimization

### Large Repository Handling

**Selective Commits**
```powershell
# Commit specific directories
.\smart-commit.ps1 -IncludePatterns @("src/*")

# Exclude large files
.\smart-commit.ps1 -ExcludePatterns @("*.log", "*.zip", "*.tar.gz")
```

**Batch Operations**
```powershell
# Process files in batches
$files = git diff --name-only
$batches = $files | Group-Object { [math]::Floor($_.Index / 10) }
foreach ($batch in $batches) {
    git add $batch.Group
    git commit -m "batch: commit batch $($batch.Name)"
}
```

### Script Performance

**Optimize File Analysis**
- Use specific include patterns
- Minimize file system operations
- Cache git status results

**Reduce Processing Time**
- Skip unnecessary validations with `-Force`
- Use dry run for testing
- Batch similar operations

## Integration Points

### Kiro Integration

The git automation integrates with Kiro through:
- **Manual Commit Hook** - One-click commits from interface
- **Task Completion Detection** - Automatic task status updates
- **File Context** - Integration with open files and changes

### CI/CD Integration

**GitHub Actions**
```yaml
on:
  push:
    branches: [main]
jobs:
  validate:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v3
      - name: Validate Commit Message
        run: |
          echo "${{ github.event.head_commit.message }}" | grep -E "^(feat|fix|docs|config|security|chore|test|refactor):"
```

**Azure DevOps**
```yaml
trigger:
  branches:
    include:
      - main
steps:
  - script: |
      echo "Validating commit message format"
      git log -1 --pretty=format:"%s" | grep -E "^(feat|fix|docs|config|security|chore|test|refactor):"
    displayName: 'Validate Commit Message'
```

## Security Considerations

### Sensitive Information

**Prevention**
- Review auto-generated messages
- Use `.gitignore` for sensitive files
- Validate exclusion patterns

**Detection**
```powershell
# Check for potential secrets
git log --all --grep="password\|secret\|key\|token" --oneline

# Scan commit messages
git log --pretty=format:"%s %b" | grep -i "password\|secret\|key"
```

### Access Control

**Repository Security**
- Use appropriate branch protection
- Require commit message standards
- Implement pre-commit hooks

**Script Security**
- Validate input parameters
- Sanitize commit messages
- Log security-relevant operations

## Best Practices

### Commit Hygiene

1. **Atomic Commits** - One logical change per commit
2. **Clear Messages** - Descriptive and standardized
3. **Regular Commits** - Frequent, small commits
4. **Task Alignment** - Commits aligned with task completion

### Workflow Efficiency

1. **Use Smart Commit** - Leverage automation for routine commits
2. **Interactive Mode** - Use for important or complex commits
3. **Dry Run Testing** - Preview changes before committing
4. **Pattern Management** - Keep inclusion/exclusion patterns updated

### Quality Assurance

1. **Message Review** - Verify auto-generated messages
2. **File Validation** - Ensure correct files are included
3. **History Maintenance** - Keep clean, readable commit history
4. **Documentation Sync** - Update docs with workflow changes