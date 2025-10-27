# Terraform Azure Infrastructure with Security Enhancements

## Overview

This project implements a comprehensive Azure infrastructure solution using Terraform with a focus on security best practices, compliance, and operational excellence. The infrastructure follows a hub-and-spoke network architecture with integrated security controls, monitoring, and automation capabilities.

## Key Features

### 🔒 Security-First Design
- **Zero Trust Network Model**: Default deny-all policies with explicit allow rules
- **Identity-Based Access**: Azure AD authentication with disabled shared keys
- **Data Protection**: Comprehensive encryption, versioning, and retention policies
- **Private Connectivity**: Private endpoints for secure network isolation
- **Compliance Ready**: Aligned with CIS Azure Foundations and security baselines

### 🏗️ Infrastructure Components
- **Network Architecture**: Hub-and-spoke topology with bastion hosts and NSGs
- **Storage Solutions**: Enhanced storage accounts with advanced security features
- **Identity & Access**: Key Vault integration with managed identities and RBAC
- **Monitoring & Logging**: Log Analytics workspace with comprehensive monitoring
- **Automation**: Azure Automation Account with DSC configurations

### 🛡️ Security Scanning Integration
- **Checkov**: Infrastructure as Code security scanner
- **TFSec**: Terraform-specific security analysis
- **Terrascan**: Policy-as-code security validation
- **Automated Workflows**: CI/CD pipeline integration with security gates

## Recent Enhancements (December 2024)

### Storage Account Security Improvements
- ✅ **Network Access Control**: Default deny-all with configurable IP/subnet allowlists
- ✅ **Authentication Enhancement**: OAuth enforcement with shared key disabling
- ✅ **Data Protection**: Blob versioning, change feed, and retention policies
- ✅ **Private Endpoints**: Optional private connectivity for network isolation
- ✅ **Compliance Validation**: SAST tool integration and security baseline alignment

### Key Security Features Implemented
- Public network access disabled by default
- Shared access keys disabled by default
- OAuth authentication enforced by default
- Network rules with deny-all default policy
- Comprehensive blob protection and retention
- Infrastructure encryption enabled
- Private endpoint support for secure connectivity

## Project Structure

```
├── .git/                    # Git version control
├── .kiro/                   # Kiro AI assistant configuration
│   ├── hooks/               # Automation hooks
│   ├── specs/               # Project specifications
│   └── steering/            # AI guidance rules
├── docs/                    # Comprehensive documentation
│   ├── security/            # Security documentation and procedures
│   ├── setup/               # Configuration and setup guides
│   ├── operations/          # Operational procedures and troubleshooting
│   └── changelog/           # Version history and change tracking
├── scripts/                 # Automation and utility scripts
│   ├── git/                 # Git workflow automation
│   ├── security/            # Security scanning and validation
│   ├── ci-cd/               # CI/CD pipeline configurations
│   └── utils/               # General utility scripts
├── security/                # Security tools and configurations
│   ├── sast-tools/          # SAST tool configurations
│   ├── scripts/             # Security automation scripts
│   ├── policies/            # Custom security policies
│   └── reports/             # Security scan reports
└── src/                     # Terraform source code
    ├── main.tf              # Primary infrastructure definitions
    ├── provider.tf          # Provider configurations
    ├── variables.tf         # Variable definitions
    ├── terraform.tf         # Version constraints
    ├── output.tf            # Output definitions
    └── modules/             # Reusable Terraform modules
        ├── authorization/   # RBAC and role assignments
        ├── automation/      # Azure Automation Account
        ├── compute/         # Virtual machines and availability sets
        ├── monitoring/      # Log Analytics and monitoring
        ├── network/         # Networking components
        ├── resourceGroup/   # Resource group management
        ├── Security/        # Key Vault, managed identities
        └── Storage/         # Enhanced storage accounts
```

## Quick Start

### Prerequisites
- Azure CLI installed and configured
- Terraform >= 1.0
- PowerShell (for automation scripts)
- Python 3.8+ (for SAST tools)

### Installation
1. **Clone the repository**
   ```bash
   git clone <repository-url>
   cd terraform-azure-security
   ```

2. **Install SAST tools**
   ```bash
   # Install Checkov
   pip install checkov
   
   # Install TFSec
   # Download from https://github.com/aquasecurity/tfsec/releases
   
   # Install Terrascan
   # Download from https://github.com/tenable/terrascan/releases
   ```

3. **Configure Azure authentication**
   ```bash
   az login
   az account set --subscription "<subscription-id>"
   ```

4. **Initialize Terraform**
   ```bash
   cd src
   terraform init
   ```

### Basic Deployment
```bash
# Plan deployment
terraform plan -var-file="environments/dev.tfvars"

# Apply changes
terraform apply -var-file="environments/dev.tfvars"
```

## Security Configuration

### Storage Account Security
The enhanced storage account module provides multiple security configurations:

#### Production Security (Recommended)
```hcl
module "secure_storage" {
  source = "./modules/Storage/stgAccount"
  
  sa_name     = "prodstorage001"
  sa_location = "East US"
  sa_rg_name  = "rg-prod-storage"
  
  # Maximum security configuration
  public_network_access_enabled    = false
  default_to_oauth_authentication  = true
  shared_access_key_enabled        = false
  
  # Network restrictions
  network_rules_enabled       = true
  network_rules_default_action = "Deny"
  allowed_subnet_ids = [var.app_subnet_id]
  
  # Data protection
  blob_versioning_enabled         = true
  blob_delete_retention_days      = 90
  
  # Private connectivity
  enable_private_endpoint    = true
  private_endpoint_subnet_id = var.private_endpoint_subnet_id
  
  tags = var.common_tags
}
```

#### Development Configuration
```hcl
module "dev_storage" {
  source = "./modules/Storage/stgAccount"
  
  sa_name     = "devstorage001"
  sa_location = "East US"
  sa_rg_name  = "rg-dev-storage"
  
  # Relaxed security for development
  public_network_access_enabled = true
  shared_access_key_enabled     = true
  network_rules_enabled         = false
  
  # Basic data protection
  blob_delete_retention_days = 7
  
  tags = var.dev_tags
}
```

## Security Validation

### Automated Security Scanning
```bash
# Run all SAST tools
./scripts/security/run-security-scan.ps1

# Individual tool scans
checkov -d src/ --framework terraform
tfsec src/
terrascan scan -t terraform -d src/
```

### Compliance Validation
The infrastructure is validated against:
- CIS Azure Foundations Benchmark
- Azure Security Baseline
- NIST Cybersecurity Framework
- SOC 2 Type II controls

## Documentation

### Security Documentation
- [Storage Security Enhancements](docs/security/storage-security-enhancements.md)
- [Security Policies and Procedures](security/README.md)

### Setup and Configuration
- [Storage Module Configuration](docs/setup/storage-module-configuration.md)
- [Git Automation Setup](docs/setup/git-automation-setup.md)

### Operations and Troubleshooting
- [Storage Troubleshooting Guide](docs/operations/storage-troubleshooting.md)
- [Git Workflow Operations](docs/operations/git-workflow-operations.md)

## CI/CD Integration

### GitHub Actions
```yaml
name: Security Validation
on: [push, pull_request]
jobs:
  security-scan:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v3
      - name: Run Checkov
        run: checkov -d src/ --framework terraform
      - name: Run TFSec
        run: tfsec src/
```

### Azure DevOps
```yaml
trigger:
  - main
pool:
  vmImage: 'ubuntu-latest'
steps:
  - task: TerraformInstaller@0
  - script: |
      checkov -d src/ --framework terraform
      tfsec src/
    displayName: 'Security Scan'
```

## Monitoring and Alerting

### Key Metrics
- Storage account availability and performance
- Network access patterns and anomalies
- Authentication failures and security events
- Compliance posture and policy violations

### Recommended Alerts
- Failed authentication attempts
- Unusual network access patterns
- Policy violations and compliance drift
- Resource configuration changes

## Contributing

### Development Workflow
1. Create feature branch from main
2. Implement changes with security considerations
3. Run SAST tools and validate compliance
4. Update documentation and examples
5. Submit pull request with security review

### Security Guidelines
- All new resources must follow security-first principles
- Default configurations should be secure by default
- Document security implications of configuration changes
- Validate changes with SAST tools before submission

## Support and Troubleshooting

### Common Issues
- [Storage Account Access Issues](docs/operations/storage-troubleshooting.md)
- [Network Connectivity Problems](docs/operations/network-troubleshooting.md)
- [Authentication and Authorization Issues](docs/operations/auth-troubleshooting.md)

### Getting Help
- Review documentation in the `docs/` directory
- Check troubleshooting guides in `docs/operations/`
- Create an issue with detailed error information
- Contact the DevOps team for escalation

## License

This project is licensed under the MIT License - see the LICENSE file for details.

## Acknowledgments

- Azure Security Team for security baseline guidance
- Terraform community for best practices
- SAST tool maintainers for security validation capabilities

---

**Last Updated**: December 2024 - Storage security enhancements and documentation updates