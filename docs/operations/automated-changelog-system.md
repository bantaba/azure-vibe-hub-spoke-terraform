# Automated Changelog System

This document describes the automated changelog system implemented for the Terraform security enhancement project. The system provides comprehensive change tracking, version management, and release documentation capabilities.

## Overview

The automated changelog system consists of several integrated components:

- **Changelog Generation**: Automated generation from git commit history
- **Change Categorization**: Intelligent categorization of changes by type and impact
- **Impact Analysis**: Security and infrastructure impact assessment
- **Version Tracking**: Semantic versioning and release management
- **Release Documentation**: Automated release notes and migration guides

## System Components

### Core Scripts

| Script | Purpose | Location |
|--------|---------|----------|
| `generate-changelog.ps1` | Generate changelog from git history | `scripts/utils/` |
| `update-changelog.ps1` | Update and manage changelog files | `scripts/utils/` |
| `release-manager.ps1` | Manage releases and version tracking | `scripts/utils/` |
| `change-impact-analyzer.ps1` | Analyze change impact and security implications | `scripts/utils/` |
| `automated-changelog-system.ps1` | Unified interface for all operations | `scripts/utils/` |

### Configuration Files

| File | Purpose | Location |
|------|---------|----------|
| `changelog-config.json` | Changelog generation configuration | `docs/changelog/` |
| `VERSION` | Current project version | Root directory |
| `CHANGELOG.md` | Main changelog file | `docs/changelog/` |

### Output Directories

| Directory | Purpose | Contents |
|-----------|---------|----------|
| `docs/changelog/` | Changelog files | Main and versioned changelogs |
| `docs/releases/` | Release documentation | Release notes and migration guides |

## Features

### 1. Automated Changelog Generation

The system automatically generates changelogs from git commit history using conventional commit patterns:

- **Conventional Commits**: Supports standard conventional commit format
- **Change Categorization**: Automatically categorizes changes by type (feat, fix, docs, etc.)
- **Impact Assessment**: Determines impact level (major, minor, patch)
- **Multiple Formats**: Supports Markdown and JSON output formats

#### Supported Commit Types

| Type | Category | Icon | Impact | Description |
|------|----------|------|--------|-------------|
| `feat` | Features | ✨ | Minor | New features and functionality |
| `fix` | Bug Fixes | 🐛 | Patch | Bug fixes and error corrections |
| `security` | Security | 🔒 | Patch | Security improvements and fixes |
| `docs` | Documentation | 📚 | Patch | Documentation updates |
| `refactor` | Code Refactoring | ♻️ | Patch | Code refactoring without functional changes |
| `perf` | Performance | ⚡ | Minor | Performance optimizations |
| `test` | Tests | ✅ | Patch | Test additions and improvements |
| `build` | Build System | 👷 | Patch | Build system and dependency changes |
| `ci` | CI/CD | 🔧 | Patch | CI/CD pipeline changes |
| `chore` | Chores | 🔨 | Patch | Maintenance tasks |
| `breaking` | Breaking Changes | 💥 | Major | Breaking changes |

### 2. Change Impact Analysis

The system provides comprehensive impact analysis including:

#### Security Impact Assessment

- **Risk Categorization**: High, Medium, Low risk changes
- **Security Pattern Detection**: Identifies security-related changes
- **Affected Components**: Lists security-affected files and modules
- **Compliance Tracking**: Maps changes to security requirements

#### Infrastructure Impact Assessment

- **Module Analysis**: Identifies affected Terraform modules
- **Configuration Changes**: Tracks infrastructure configuration changes
- **Deployment Impact**: Assesses deployment complexity and risk
- **Rollback Planning**: Provides rollback recommendations

### 3. Version Tracking and Release Management

#### Semantic Versioning

The system follows semantic versioning (SemVer) principles:

- **Major (X.0.0)**: Breaking changes or major new features
- **Minor (0.X.0)**: New features without breaking changes
- **Patch (0.0.X)**: Bug fixes and minor improvements

#### Release Process

1. **Analysis**: Analyze changes since last release
2. **Version Calculation**: Determine appropriate version bump
3. **Changelog Generation**: Create versioned changelog
4. **Release Notes**: Generate comprehensive release notes
5. **Documentation**: Update version tracking and documentation

### 4. Integration with Git Workflows

The system integrates with git workflows through:

- **Pre-commit Hooks**: Validate commit message format
- **Post-commit Hooks**: Automatically update changelog
- **CI/CD Integration**: Generate changelogs in build pipelines
- **Release Automation**: Automate release preparation and tagging

## Usage

### Command Line Interface

The system provides a unified command-line interface through `automated-changelog-system.ps1`:

```powershell
# Generate changelog
.\scripts\utils\automated-changelog-system.ps1 -Command generate

# Update main changelog
.\scripts\utils\automated-changelog-system.ps1 -Command update

# Prepare a new release
.\scripts\utils\automated-changelog-system.ps1 -Command release -ReleaseType minor

# Analyze change impact
.\scripts\utils\automated-changelog-system.ps1 -Command analyze

# Show version information
.\scripts\utils\automated-changelog-system.ps1 -Command version

# Show system status
.\scripts\utils\automated-changelog-system.ps1 -Command status
```

### Individual Script Usage

#### Generate Changelog

```powershell
# Generate changelog from all history
.\scripts\utils\generate-changelog.ps1

# Generate changelog since specific tag
.\scripts\utils\generate-changelog.ps1 -Since "v1.0.0"

# Generate JSON format
.\scripts\utils\generate-changelog.ps1 -Format json
```

#### Release Management

```powershell
# Prepare patch release
.\scripts\utils\release-manager.ps1 -Action prepare -ReleaseType patch

# Preview release without making changes
.\scripts\utils\release-manager.ps1 -Action preview

# Create git tag for release
.\scripts\utils\release-manager.ps1 -Action tag -Version "v1.1.0"
```

#### Impact Analysis

```powershell
# Analyze all changes
.\scripts\utils\change-impact-analyzer.ps1

# Analyze changes since specific point
.\scripts\utils\change-impact-analyzer.ps1 -Since "v1.0.0"

# Generate JSON report
.\scripts\utils\change-impact-analyzer.ps1 -OutputFormat json
```

## Configuration

### Changelog Configuration

The `docs/changelog/changelog-config.json` file controls changelog generation:

```json
{
  "changelog_config": {
    "version": "1.0.0",
    "format": "keepachangelog",
    "conventional_commits": true,
    "categories": {
      "feat": {
        "name": "Features",
        "icon": "✨",
        "impact": "minor"
      }
    },
    "filters": {
      "exclude_patterns": ["^Merge ", "^WIP:"],
      "include_merge_commits": false
    }
  }
}
```

### Version File

The `VERSION` file in the root directory tracks the current project version:

```
v1.0.0
```

## Integration with CI/CD

### GitHub Actions Integration

```yaml
name: Update Changelog
on:
  push:
    branches: [main]

jobs:
  changelog:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v3
      - name: Update Changelog
        run: |
          pwsh scripts/utils/automated-changelog-system.ps1 -Command update -Interactive:$false
      - name: Commit Changes
        run: |
          git config --local user.email "action@github.com"
          git config --local user.name "GitHub Action"
          git add docs/changelog/
          git commit -m "docs: update changelog [skip ci]" || exit 0
          git push
```

### Azure DevOps Integration

```yaml
trigger:
  branches:
    include:
      - main

pool:
  vmImage: 'windows-latest'

steps:
- task: PowerShell@2
  displayName: 'Update Changelog'
  inputs:
    targetType: 'filePath'
    filePath: 'scripts/utils/automated-changelog-system.ps1'
    arguments: '-Command update -Interactive:$false'

- task: PowerShell@2
  displayName: 'Commit Changelog'
  inputs:
    targetType: 'inline'
    script: |
      git config --local user.email "build@azuredevops.com"
      git config --local user.name "Azure DevOps"
      git add docs/changelog/
      git commit -m "docs: update changelog [skip ci]" || exit 0
      git push origin HEAD:$(Build.SourceBranchName)
```

## Best Practices

### Commit Message Format

Follow conventional commit format for optimal changelog generation:

```
<type>[optional scope]: <description>

[optional body]

[optional footer(s)]
```

Examples:
```
feat(storage): add encryption at rest support
fix(network): resolve NSG rule conflict
docs: update security configuration guide
security(auth): implement OAuth2 authentication
```

### Release Workflow

1. **Development Phase**:
   - Use conventional commits
   - Regular changelog updates
   - Impact analysis for major changes

2. **Pre-Release**:
   - Run impact analysis
   - Review security implications
   - Generate release preview

3. **Release Preparation**:
   - Create versioned changelog
   - Generate release notes
   - Update documentation

4. **Release**:
   - Create git tag
   - Deploy to environments
   - Monitor for issues

### Security Considerations

- **Sensitive Information**: Ensure no secrets in commit messages
- **Security Changes**: Use `security:` prefix for security-related commits
- **Impact Assessment**: Always analyze security impact before releases
- **Audit Trail**: Maintain complete changelog for compliance

## Troubleshooting

### Common Issues

#### Changelog Not Updating

**Problem**: Changelog doesn't reflect recent commits
**Solution**: 
```powershell
# Force regenerate changelog
.\scripts\utils\automated-changelog-system.ps1 -Command generate -Verbose
```

#### Version Mismatch

**Problem**: VERSION file doesn't match git tags
**Solution**:
```powershell
# Sync version with latest tag
.\scripts\utils\release-manager.ps1 -Action tag -Version $(git describe --tags --abbrev=0)
```

#### Missing Dependencies

**Problem**: Scripts not found or missing
**Solution**:
```powershell
# Check system status
.\scripts\utils\automated-changelog-system.ps1 -Command status
```

### Error Messages

| Error | Cause | Solution |
|-------|-------|----------|
| "Not in a git repository" | Script run outside git repo | Run from repository root |
| "Generator script not found" | Missing script files | Ensure all scripts are present |
| "Invalid version format" | Malformed version string | Use semantic versioning format |
| "No commits found" | Empty git history | Ensure commits exist in range |

## Maintenance

### Regular Tasks

- **Weekly**: Review changelog accuracy
- **Monthly**: Analyze change patterns and impact trends
- **Quarterly**: Update configuration and patterns
- **Annually**: Review and optimize system performance

### Updates and Improvements

- Monitor conventional commit adoption
- Enhance security pattern detection
- Improve impact analysis accuracy
- Add new integration capabilities

## Support

For issues with the automated changelog system:

1. Check the [troubleshooting section](#troubleshooting)
2. Review system status with `.\scripts\utils\automated-changelog-system.ps1 -Command status`
3. Consult the [git workflow documentation](git-workflow-operations.md)
4. Review the [security documentation](../security/)

## References

- [Keep a Changelog](https://keepachangelog.com/)
- [Semantic Versioning](https://semver.org/)
- [Conventional Commits](https://www.conventionalcommits.org/)
- [Git Best Practices](https://git-scm.com/book/en/v2/Distributed-Git-Contributing-to-a-Project)