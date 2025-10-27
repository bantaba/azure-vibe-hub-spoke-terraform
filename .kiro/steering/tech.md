# Technology Stack

## Core Technologies

- **Terraform**: Infrastructure as Code (IaC) tool for Azure resource provisioning
- **Azure Provider**: HashiCorp AzureRM provider (version 3.65-3.68)
- **PowerShell**: Automation scripting and CI/CD operations
- **Azure CLI**: Command-line interface for Azure operations

## Terraform Configuration

- **Backend**: Azure Storage Account (azurerm backend)
- **Provider Versions**:
  - `azurerm`: >=3.65,<=3.68
  - `http`: >= 3.2
  - `random`: >= 3.4
- **Workspace Support**: Multi-environment deployments using Terraform workspaces

## Security Tools

- **Checkov**: Infrastructure as Code security scanner
- **TFSec**: Terraform-specific security scanner
- **Terrascan**: Policy as Code security validation
- **Terraform Compliance**: BDD-style security testing

## Common Commands

### Terraform Operations
```bash
# Initialize Terraform
terraform init

# Plan deployment
terraform plan

# Apply changes
terraform apply

# Destroy infrastructure
terraform destroy

# Format code
terraform fmt -recursive

# Validate configuration
terraform validate
```

### Security Scanning
```bash
# Run Checkov scan
checkov -d . --framework terraform

# Run TFSec scan
tfsec .

# Run Terrascan
terrascan scan -t terraform
```

## Development Standards

- Use Terraform workspaces for environment separation
- All resources must include standardized tags
- Follow Azure naming conventions and abbreviations
- Implement proper error handling in scripts
- Use modules for reusable infrastructure components