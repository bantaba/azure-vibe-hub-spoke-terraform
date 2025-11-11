# Quick Start Guide - Terraform Security Enhancement

Get up and running with the Terraform Security Enhancement system in under 10 minutes.

## 🚀 Prerequisites (2 minutes)

Ensure you have these installed:
- ✅ **Terraform** >= 1.5.7
- ✅ **PowerShell** 5.1+
- ✅ **Git** (repository initialized)

```bash
# Verify prerequisites
terraform version
$PSVersionTable.PSVersion
git --version
```

## ⚡ Quick Setup (3 minutes)

### Step 1: Initialize Integration System
```powershell
# Setup all components in one command
.\scripts\integration\master-integration.ps1 -Action setup
```

### Step 2: Validate Installation
```powershell
# Verify everything is working
.\scripts\integration\master-integration.ps1 -Action validate
```

**Expected Output:**
```
Integration Scripts: PASS
CI/CD Integration: PASS  
Git Repository: PASS
Security Tools: PASS
Validation Summary: 4/4 components passed
```

### Step 3: Check System Status
```powershell
# View current system status
.\scripts\integration\master-integration.ps1 -Action status
```

## 🎯 Your First Task (2 minutes)

### Complete a Simple Task
```powershell
# Complete your first task with full integration
.\scripts\integration\master-integration.ps1 -Action task-complete -TaskName "Setup complete - first task" -TaskId "0.1"
```

**What happens automatically:**
1. ✅ **Auto-Commit**: Changes committed with standardized message
2. ✅ **Security Scan**: Code scanned for security issues (if applicable)
3. ✅ **Documentation**: Project documentation updated
4. ✅ **CI/CD Trigger**: Pipeline validation initiated

## 🔍 Verify Everything Works (2 minutes)

### Run Security Validation
```powershell
# Generate comprehensive security report
.\scripts\integration\security-validation-report.ps1
```

**Target Score:** 80+ out of 100 (Excellent)

### Check Integration Health
```powershell
# Detailed system status
.\scripts\integration\master-integration.ps1 -Action status -VerboseOutput
```

## 🎉 You're Ready!

Congratulations! Your Terraform Security Enhancement system is now fully operational.

## 📋 Common Commands Cheat Sheet

### Daily Workflow
```powershell
# Complete a task
.\scripts\integration\master-integration.ps1 -Action task-complete -TaskName "Your task description"

# Run security scan only
.\scripts\integration\master-integration.ps1 -Action security-scan

# Check system status
.\scripts\integration\master-integration.ps1 -Action status
```

### Task Completion Variations
```powershell
# With task ID
.\scripts\integration\master-integration.ps1 -Action task-complete -TaskName "Fix security issue" -TaskId "2.1"

# Skip security scan (for docs-only changes)
.\scripts\integration\master-integration.ps1 -Action task-complete -TaskName "Update README" -SkipScan

# Dry run (see what would happen)
.\scripts\integration\master-integration.ps1 -Action task-complete -TaskName "Test task" -DryRun
```

### Security and Validation
```powershell
# Security validation report
.\scripts\integration\security-validation-report.ps1

# CI/CD integration check
.\scripts\integration\cicd-integration-config.ps1 -Platform both

# Terraform validation
cd src && terraform validate
```

## 🔧 Troubleshooting Quick Fixes

### Issue: "Integration scripts not found"
```powershell
# Solution: Re-run setup
.\scripts\integration\master-integration.ps1 -Action setup
```

### Issue: "Not in a git repository"
```bash
# Solution: Initialize git
git init
git add .
git commit -m "Initial commit"
```

### Issue: "Security scan failed"
```powershell
# Solution: Install SAST tools
.\security\scripts\install-all-sast-tools.ps1
```

### Issue: "Terraform validation failed"
```powershell
# Solution: Format and validate
terraform fmt -recursive src/
cd src && terraform init -backend=false && terraform validate
```

## 📚 Next Steps

Now that you're set up, explore these resources:

1. **📖 [User Guide](USER_GUIDE.md)** - Comprehensive usage documentation
2. **🏗️ [Project Overview](PROJECT_OVERVIEW.md)** - Architecture and features
3. **🔧 [Integration README](../scripts/integration/README.md)** - Technical details
4. **🔒 [Security Documentation](security/README.md)** - Security configurations

## 💡 Pro Tips

### Efficient Task Management
- Use descriptive task names for better tracking
- Include task IDs when working with formal task lists
- Use task types to control automation behavior

### Security Best Practices
- Run security validation after major changes
- Address critical/high severity issues immediately
- Review security reports regularly

### Integration Optimization
- Use dry run mode to preview changes
- Enable verbose output for troubleshooting
- Monitor CI/CD pipeline results

## 🆘 Need Help?

### Quick Diagnostics
```powershell
# System health check
.\scripts\integration\master-integration.ps1 -Action validate -VerboseOutput

# Detailed security analysis
.\scripts\integration\security-validation-report.ps1 -DetailedReport
```

### Documentation
- **Integration Issues**: `scripts/integration/README.md`
- **Security Questions**: `docs/security/README.md`
- **General Usage**: `docs/USER_GUIDE.md`

### Common Solutions
| Problem | Quick Fix |
|---------|-----------|
| Scripts not found | Run setup action |
| Git errors | Initialize repository |
| Security scan fails | Install SAST tools |
| Terraform errors | Format and validate |
| CI/CD issues | Check pipeline configuration |

---

**🎯 Success Criteria:**
- ✅ Integration validation passes (4/4 components)
- ✅ Security score ≥ 80/100
- ✅ First task completes successfully
- ✅ CI/CD pipeline triggers correctly

**⏱️ Total Setup Time:** ~10 minutes  
**🔄 Next Action:** Complete your first real task!

---

*For detailed information, see the [User Guide](USER_GUIDE.md) and [Project Overview](PROJECT_OVERVIEW.md).*