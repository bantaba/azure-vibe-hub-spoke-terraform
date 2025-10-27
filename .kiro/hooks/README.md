# Kiro Hooks Documentation

This directory contains Kiro hooks that automate various development workflows for the Terraform security enhancement project.

## Available Hooks

### 1. Auto-Commit Task Completion
**File**: `auto-commit-task-completion.kiro.hook`
**Trigger**: When task files (`.kiro/specs/**/tasks.md`) are modified
**Purpose**: Automatically detects task completion and commits changes

### 2. Smart Auto-Commit
**File**: `smart-auto-commit.kiro.hook`  
**Trigger**: When security, scripts, Terraform, or documentation files are modified
**Purpose**: Intelligently analyzes changes and commits logical units of work

### 3. Manual Commit Changes
**File**: `manual-commit-changes.kiro.hook`
**Trigger**: Manual activation
**Purpose**: Manually triggered commit with intelligent message generation

### 4. Quick Commit Button
**File**: `quick-commit-button.kiro.hook`
**Trigger**: Manual activation (button)
**Purpose**: One-click commit of all current changes

### 5. Terraform Documentation Sync
**File**: `terraform-docs-sync.kiro.hook`
**Trigger**: When Terraform or script files are modified
**Purpose**: Automatically updates project documentation

## Smart Commit Script

The hooks use the intelligent commit script located at `scripts/git/smart-commit.ps1` which provides:

- **Automatic file staging** with pattern-based filtering
- **Intelligent commit message generation** using conventional commit format
- **Change analysis** to determine appropriate commit type (feat, fix, docs, etc.)
- **Dry-run mode** for testing without actual commits
- **Interactive mode** for manual confirmation

### Usage Examples

```powershell
# Dry run to see what would be committed
.\scripts\git\smart-commit.ps1 -DryRun

# Interactive commit with confirmation
.\scripts\git\smart-commit.ps1 -Interactive

# Commit with custom message
.\scripts\git\smart-commit.ps1 -CommitMessage "feat: implement new feature"

# Include only specific file patterns
.\scripts\git\smart-commit.ps1 -IncludePatterns @("*.tf", "*.md")
```

## Hook Configuration

### Enabling/Disabling Hooks

Each hook can be enabled or disabled by modifying the `"enabled"` field in the hook file:

```json
{
  "enabled": true,  // Set to false to disable
  "name": "Hook Name",
  // ... rest of configuration
}
```

### Customizing Triggers

Hooks can be customized by modifying the `"when"` section:

```json
"when": {
  "type": "fileEdited",  // or "manual"
  "patterns": [
    "src/**/*.tf",       // File patterns to watch
    "security/**/*"
  ]
}
```

## Conventional Commit Format

The hooks follow conventional commit format:

- `feat:` - New features
- `fix:` - Bug fixes  
- `docs:` - Documentation changes
- `config:` - Configuration changes
- `test:` - Test-related changes
- `chore:` - Maintenance tasks
- `refactor:` - Code refactoring

## Best Practices

1. **Review Changes**: Always review what will be committed, especially with auto-commit hooks
2. **Logical Units**: Commit logical units of work rather than random file changes
3. **Clear Messages**: Use descriptive commit messages that explain the "why" not just the "what"
4. **Test First**: Use dry-run mode to verify commit behavior before enabling auto-commit
5. **Hook Management**: Disable hooks temporarily if you need manual control over commits

## Troubleshooting

### Hook Not Triggering
- Check that the hook is enabled (`"enabled": true`)
- Verify file patterns match the files you're editing
- Check Kiro IDE hook settings

### Commit Failures
- Ensure you have git configured with user name and email
- Check for merge conflicts or other git issues
- Verify file permissions and git repository status

### Smart Commit Issues
- Run with `-DryRun` flag to debug without committing
- Check PowerShell execution policy if script fails to run
- Verify git is available in PATH

## Manual Hook Activation

To manually trigger hooks:

1. Open Kiro command palette (Ctrl/Cmd + Shift + P)
2. Search for "Kiro Hook" commands
3. Select the hook you want to execute

Or use the Agent Hooks panel in the Kiro IDE sidebar.

## Security Considerations

- Hooks have access to your git repository and can make commits
- Review hook code before enabling, especially for auto-commit functionality
- Consider using interactive mode for sensitive changes
- Backup your repository before enabling auto-commit hooks

## Contributing

When modifying hooks:

1. Test thoroughly with dry-run mode
2. Document any new configuration options
3. Follow the existing hook structure and naming conventions
4. Update this README with any new hooks or features