# Git Automation System

This directory contains PowerShell scripts for automated git operations with intelligent commit message generation, file analysis, and task completion detection.

## Files

- **`auto-commit.ps1`** - Core auto-commit script with git operations and error handling
- **`auto-commit-wrapper.ps1`** - Wrapper functions with task completion detection and commit templates
- **`commit-task.ps1`** - Simple command-line interface for committing completed tasks
- **`smart-commit.ps1`** - Advanced intelligent commit tool with file pattern analysis and automated message generation

## Usage

### Smart Commit Tool (Recommended)

```powershell
# Intelligent commit with auto-generated message
.\smart-commit.ps1

# Interactive mode with confirmation
.\smart-commit.ps1 -Interactive

# Dry run to preview changes
.\smart-commit.ps1 -DryRun

# Custom commit message
.\smart-commit.ps1 -CommitMessage "feat: implement new security features"

# Include only specific file patterns
.\smart-commit.ps1 -IncludePatterns @("*.tf", "*.ps1")

# Exclude additional patterns
.\smart-commit.ps1 -ExcludePatterns @("*.log", "temp/*")
```

### Quick Start (Legacy)

```powershell
# Commit a completed task with auto-detection
.\commit-task.ps1 -TaskName "Create auto-commit PowerShell script" -TaskId "2.1"

# Dry run to see what would be committed
.\commit-task.ps1 -TaskName "Configure Checkov" -TaskId "3.1" -DryRun

# Force commit without validation
.\commit-task.ps1 -TaskName "Fix configuration" -Force
```

### Advanced Usage

```powershell
# Use specific task type
.\commit-task.ps1 -TaskName "Update Terraform modules" -TaskType "terraform" -TaskId "4.1"

# Add additional description
.\commit-task.ps1 -TaskName "Setup SAST tools" -TaskType "sast" -Description "Configured Checkov, TFSec, and Terrascan"
```

## Smart Commit Features

The `smart-commit.ps1` script provides advanced automation with:

### Intelligent File Analysis
- **Pattern Recognition** - Automatically detects file types and changes
- **Content Analysis** - Analyzes file content to determine commit type
- **Change Classification** - Categorizes changes as features, fixes, docs, config, etc.
- **File Filtering** - Smart exclusion of temporary files, logs, and build artifacts

### Automated Message Generation
- **Conventional Commits** - Generates messages following conventional commit format
- **Context-Aware** - Creates messages based on actual file changes
- **Task Integration** - Detects task-related changes and references
- **Multi-line Support** - Generates detailed commit bodies with file summaries

### Advanced Options
- **Dry Run Mode** - Preview commits without executing
- **Interactive Mode** - Confirm changes before committing
- **Custom Patterns** - Include/exclude specific file patterns
- **Flexible Messaging** - Override auto-generated messages when needed

### File Pattern Detection

The smart commit tool automatically detects:
- **New Features** - New `.tf`, `.ps1`, `.py`, `.js`, `.ts` files
- **Documentation** - Changes to `.md`, `.txt`, `.rst` files
- **Configuration** - Updates to `.yaml`, `.yml`, `.json`, `.toml` files
- **Tests** - Modifications to test files and directories
- **Security** - Changes in security-related directories and files

## Task Types

The system automatically detects task types based on keywords in the task name:

- **setup** - Project initialization and structure setup
- **security** - Security enhancements and implementations
- **sast** - SAST tool integration and configuration
- **cicd** - CI/CD pipeline implementation
- **terraform** - Terraform infrastructure improvements
- **docs** - Documentation updates
- **test** - Testing and validation
- **fix** - Bug fixes and issue resolution
- **refactor** - Code refactoring and optimization

## Commit Message Format

The system generates standardized commit messages following conventional commit format:

```
type(scope): task description

Detailed description with context
Additional information about changes

Timestamp: 2024-01-01 12:00:00
Task-ID: 2.1
Task Type: security
Files changed: 3
Changed files:
  A+ scripts/git/auto-commit.ps1
  M  scripts/git/README.md
  ?? logs/auto-commit.log
```

## Task Completion Detection

The wrapper functions include intelligent task completion detection:

### File-based Detection
- Checks for expected file types based on task type
- Validates that relevant files have been modified
- Ensures changes align with task requirements

### Pattern-based Detection
- Searches for required code patterns in changed files
- Validates Terraform syntax for infrastructure tasks
- Checks configuration formats for SAST tasks

### Override Options
- Use `-Force` to skip completion validation
- Use `-DryRun` to preview commits without executing

## Error Handling

The system includes comprehensive error handling:

- **Retry Logic** - Automatic retry with exponential backoff for transient failures
- **Validation** - Pre-commit validation of git repository state
- **Logging** - Detailed logging to console and file (if logs directory exists)
- **Rollback** - Safe failure handling without corrupting git history

## Configuration

### Task Templates

Task templates are defined in `auto-commit-wrapper.ps1` and can be customized:

```powershell
$Global:TaskTemplates = @{
    "security" = @{
        "type" = "security"
        "description" = "Security enhancement implementation"
    }
    # Add custom templates here
}
```

### Logging

Create a `logs` directory in the project root to enable file logging:

```powershell
mkdir logs
```

Log files will be created at `logs/auto-commit.log`.

## Integration with Task Management

The auto-commit system is designed to integrate with the Terraform Security Enhancement project tasks:

1. **Task Execution** - Run tasks from the implementation plan
2. **Completion Detection** - System validates task completion
3. **Auto-Commit** - Automatically commits changes with standardized messages
4. **Progress Tracking** - Maintains detailed commit history for audit trails

## Examples

### Smart Commit Examples

```powershell
# Automatic commit with intelligent message generation
.\smart-commit.ps1
# Output: "feat: implement security enhancements and update tasks"

# Preview changes before committing
.\smart-commit.ps1 -DryRun
# Shows what would be committed without executing

# Interactive confirmation
.\smart-commit.ps1 -Interactive
# Prompts for confirmation before committing

# Commit only Terraform files
.\smart-commit.ps1 -IncludePatterns @("*.tf", "*.tfvars")

# Exclude specific directories
.\smart-commit.ps1 -ExcludePatterns @("logs/*", "temp/*", "*.backup")
```

### Legacy Task Examples

```powershell
# After implementing security enhancements
.\commit-task.ps1 -TaskName "Improve storage account security" -TaskId "4.1" -TaskType "security"

# After configuring Checkov
.\commit-task.ps1 -TaskName "Install and configure Checkov" -TaskId "3.1" -TaskType "sast"

# After updating documentation
.\commit-task.ps1 -TaskName "Create security improvements documentation" -TaskId "7.1" -TaskType "docs"
```

## Troubleshooting

### Common Issues

1. **Not in git repository**
   - Ensure you're running the script from the project root
   - Initialize git repository if needed: `git init`

2. **No changes detected**
   - Verify files have been modified
   - Check git status: `git status`
   - Use `-Force` to override if needed

3. **Task completion validation fails**
   - Review expected files for the task type
   - Ensure changes match task requirements
   - Use `-Force` to skip validation

4. **Commit message too long**
   - The system handles multi-line messages automatically
   - Long descriptions are properly formatted

### Debug Mode

Enable verbose output by setting:

```powershell
$VerbosePreference = "Continue"
```

## Best Practices

1. **Consistent Task Naming** - Use clear, descriptive task names
2. **Proper Task IDs** - Include task IDs from the implementation plan
3. **Incremental Commits** - Commit after each completed task
4. **Validation** - Let the system validate task completion when possible
5. **Documentation** - Include additional descriptions for complex changes