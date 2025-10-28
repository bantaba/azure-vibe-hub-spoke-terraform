# Team Onboarding Guide

## Overview

This guide provides comprehensive setup and configuration instructions for new team members joining the Terraform Security Enhancement project. It covers all necessary tools, configurations, and workflows required to contribute effectively to the project.

## Prerequisites

### Required Software

| Software | Version | Purpose | Installation |
|----------|---------|---------|--------------|
| **Git** | 2.30+ | Version control | [Download Git](https://git-scm.com/downloads) |
| **PowerShell** | 7.0+ | Automation scripts | [Install PowerShell](https://docs.microsoft.com/en-us/powershell/scripting/install/installing-powershell) |
| **Terraform** | 1.5+ | Infrastructure as Code | [Install Terraform](https://developer.hashicorp.com/terraform/downloads) |
| **Azure CLI** | 2.50+ | Azure operations | [Install Azure CLI](https://docs.microsoft.com/en-us/cli/azure/install-azure-cli) |
| **Visual Studio Code** | Latest | Code editor | [Download VS Code](https://code.visualstudio.com/) |

### Required VS Code Extensions

```json
{
  "recommendations": [
    "hashicorp.terraform",
    "ms-vscode.powershell",
    "ms-vscode.azure-account",
    "ms-azuretools.vscode-azureterraform",
    "bridgecrew.checkov",
    "aquasec.trivy-vulnerability-scanner"
  ]
}
```

### Azure Access Requirements

- **Azure Subscription**: Access to target Azure subscription
- **Service Principal**: For Terraform operations (provided by admin)
- **RBAC Permissions**: Minimum required roles:
  - `Contributor` on target resource groups
  - `User Access Administrator` for RBAC assignments
  - `Key Vault Administrator` for Key Vault operations

## Initial Setup

### 1. Repository Setup

```powershell
# Clone the repository
git clone <repository-url>
cd terraform-security-enhancement

# Configure git settings
git config user.name "Your Name"
git config user.email "your.email@company.com"

# Verify repository structure
Get-ChildItem -Recurse -Directory | Select-Object Name, FullName
```

### 2. Azure Authentication

```powershell
# Login to Azure
az login

# Set default subscription
az account set --subscription "<subscription-id>"

# Verify access
az account show
az group list --output table
```

### 3. Terraform Configuration

```powershell
# Navigate to source directory
cd src

# Initialize Terraform
terraform init

# Create terraform.tfvars file (copy from template)
Copy-Item terraform.tfvars.example terraform.tfvars

# Edit terraform.tfvars with your values
code terraform.tfvars
```

**Sample terraform.tfvars:**
```hcl
# Azure Configuration
subscription_id = "your-subscription-id"
tenant_id      = "your-tenant-id"
client_id      = "service-principal-client-id"
client_secret  = "service-principal-secret"

# Environment Configuration
environment = "dev"
location    = "East US 2"
project     = "terraform-security"

# Resource Configuration
resource_group_name = "rg-terraform-security-dev"
```

### 4. Security Tools Setup

#### Install Checkov
```powershell
# Install via pip
pip install checkov

# Verify installation
checkov --version

# Test with project
checkov -d src --framework terraform
```

#### Install TFSec
```powershell
# Download and install TFSec
Invoke-WebRequest -Uri "https://github.com/aquasecurity/tfsec/releases/latest/download/tfsec-windows-amd64.exe" -OutFile "tfsec.exe"
Move-Item tfsec.exe C:\tools\tfsec.exe

# Add to PATH or use full path
C:\tools\tfsec.exe src
```

#### Install Terrascan
```powershell
# Download and install Terrascan
Invoke-WebRequest -Uri "https://github.com/tenable/terrascan/releases/latest/download/terrascan_Windows_x86_64.tar.gz" -OutFile "terrascan.tar.gz"
# Extract and install (adjust path as needed)

# Test installation
terrascan scan -t terraform -d src
```

### 5. Development Environment Configuration

#### PowerShell Profile Setup
```powershell
# Create or edit PowerShell profile
if (!(Test-Path $PROFILE)) {
    New-Item -Path $PROFILE -Type File -Force
}

# Add project-specific functions
Add-Content $PROFILE @"
# Terraform Security Enhancement Project Functions

function tf-init { terraform init }
function tf-plan { terraform plan -var-file="terraform.tfvars" }
function tf-apply { terraform apply -var-file="terraform.tfvars" }
function tf-destroy { terraform destroy -var-file="terraform.tfvars" }

function security-scan {
    Write-Host "Running security scans..." -ForegroundColor Green
    checkov -d src --framework terraform
    tfsec src
    terrascan scan -t terraform -d src
}

function smart-commit {
    .\scripts\git\smart-commit.ps1 @args
}

# Set location to project root
Set-Location "C:\path\to\terraform-security-enhancement"
"@

# Reload profile
. $PROFILE
```

#### Git Hooks Setup
```powershell
# Install pre-commit hooks
.\scripts\git\install-hooks.ps1

# Verify hooks are installed
Get-ChildItem .git\hooks\
```

## Project Structure Familiarization

### Key Directories

```
terraform-security-enhancement/
├── .kiro/                   # Kiro AI configuration
│   ├── specs/              # Feature specifications
│   └── steering/           # Project guidance rules
├── docs/                   # Documentation
│   ├── operations/         # Operational procedures
│   ├── security/          # Security documentation
│   └── setup/             # Setup guides
├── scripts/               # Automation scripts
│   ├── git/              # Git workflow automation
│   ├── security/         # Security scanning scripts
│   └── utils/            # Utility scripts
├── security/              # Security tools configuration
│   ├── policies/         # Security policies
│   └── sast-tools/       # SAST tool configurations
└── src/                   # Terraform source code
    ├── modules/          # Terraform modules
    └── *.tf              # Main Terraform files
```

### Important Files

| File | Purpose | When to Modify |
|------|---------|----------------|
| `src/main.tf` | Main infrastructure definition | Adding new resources |
| `src/variables.tf` | Variable definitions | Adding new parameters |
| `src/terraform.tfvars` | Environment-specific values | Environment configuration |
| `.gitignore` | Git exclusion rules | Adding new file types to ignore |
| `security/sast-tools/checkov.yaml` | Checkov configuration | Customizing security rules |

## Development Workflow

### Daily Workflow

1. **Start of Day**
   ```powershell
   # Pull latest changes
   git pull origin main
   
   # Check project status
   git status
   terraform plan
   ```

2. **Making Changes**
   ```powershell
   # Create feature branch (optional)
   git checkout -b feature/your-feature-name
   
   # Make your changes
   code src/modules/your-module/
   
   # Test changes
   terraform plan
   security-scan
   ```

3. **Committing Changes**
   ```powershell
   # Use smart commit for automated commit messages
   smart-commit
   
   # Or manual commit
   git add .
   git commit -m "feat(module): add new security feature"
   ```

4. **End of Day**
   ```powershell
   # Push changes
   git push origin main
   
   # Update documentation if needed
   ```

### Testing Workflow

#### Local Testing
```powershell
# Terraform validation
terraform validate
terraform fmt -check

# Security scanning
checkov -d src --framework terraform --check CKV_AZURE_*
tfsec src --minimum-severity MEDIUM
terrascan scan -t terraform -d src

# Run all tests
.\scripts\utils\run-all-tests.ps1
```

#### Integration Testing
```powershell
# Plan deployment to dev environment
terraform workspace select dev
terraform plan -var-file="terraform.tfvars"

# Apply to dev (if approved)
terraform apply -var-file="terraform.tfvars"

# Validate deployment
.\scripts\utils\validate-deployment.ps1
```

## Security Guidelines

### Code Security

1. **Never commit secrets**
   - Use Azure Key Vault for sensitive data
   - Use environment variables for configuration
   - Review `.gitignore` regularly

2. **Follow security scanning**
   - Run security scans before committing
   - Address high and critical findings
   - Document any accepted risks

3. **Use secure defaults**
   - Enable encryption by default
   - Implement least privilege access
   - Use private endpoints where possible

### Access Management

1. **Service Principal Security**
   - Rotate credentials regularly
   - Use minimal required permissions
   - Store credentials securely

2. **Development Environment**
   - Use separate dev/test environments
   - Implement proper RBAC
   - Monitor access and usage

## Troubleshooting Common Issues

### Authentication Issues

**Problem**: Azure CLI authentication fails
```powershell
# Solution: Clear and re-authenticate
az account clear
az login --tenant <tenant-id>
```

**Problem**: Terraform authentication fails
```powershell
# Solution: Check service principal credentials
az ad sp show --id <client-id>
# Verify terraform.tfvars has correct values
```

### Terraform Issues

**Problem**: State file conflicts
```powershell
# Solution: Refresh state
terraform refresh
# Or force unlock if needed
terraform force-unlock <lock-id>
```

**Problem**: Module not found errors
```powershell
# Solution: Reinitialize Terraform
terraform init -upgrade
```

### Security Scan Issues

**Problem**: Checkov fails with import errors
```powershell
# Solution: Reinstall in clean environment
pip uninstall checkov
pip install checkov --upgrade
```

**Problem**: TFSec not finding issues
```powershell
# Solution: Update TFSec to latest version
# Download latest release from GitHub
```

## Getting Help

### Internal Resources

1. **Documentation**: Check `docs/` directory first
2. **Team Chat**: Use designated team channel
3. **Code Reviews**: Request review from senior team members
4. **Pair Programming**: Schedule sessions for complex tasks

### External Resources

1. **Terraform Documentation**: [terraform.io](https://terraform.io)
2. **Azure Documentation**: [docs.microsoft.com](https://docs.microsoft.com/azure)
3. **Security Tools**:
   - [Checkov Documentation](https://www.checkov.io/1.Welcome/Quick%20Start.html)
   - [TFSec Documentation](https://aquasecurity.github.io/tfsec/)
   - [Terrascan Documentation](https://runterrascan.io/)

### Escalation Path

1. **Level 1**: Team members and documentation
2. **Level 2**: Team lead and senior developers
3. **Level 3**: Architecture team and security team
4. **Level 4**: External support and vendor resources

## Checklist for New Team Members

### Week 1: Setup and Familiarization
- [ ] Install all required software
- [ ] Configure development environment
- [ ] Clone and explore repository
- [ ] Run first security scan
- [ ] Complete first Terraform plan
- [ ] Attend team introduction meeting

### Week 2: First Contributions
- [ ] Make first documentation update
- [ ] Fix a minor issue or enhancement
- [ ] Participate in code review
- [ ] Run full test suite
- [ ] Deploy to dev environment

### Week 3: Integration
- [ ] Complete first feature implementation
- [ ] Conduct security review
- [ ] Update operational documentation
- [ ] Mentor another new team member (if applicable)

### Ongoing: Continuous Learning
- [ ] Stay updated with Terraform best practices
- [ ] Follow Azure security updates
- [ ] Participate in security training
- [ ] Contribute to process improvements

## Contact Information

| Role | Contact | Availability |
|------|---------|--------------|
| **Team Lead** | teamlead@company.com | Business hours |
| **DevOps Engineer** | devops@company.com | 24/7 on-call rotation |
| **Security Engineer** | security@company.com | Business hours |
| **IT Support** | itsupport@company.com | 24/7 |

## Last Updated

December 2024 - Initial team onboarding guide for Terraform Security Enhancement project