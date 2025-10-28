# Azure Hub-and-Spoke Infrastructure with Terraform

This Terraform project implements a secure, scalable Azure infrastructure using a hub-and-spoke network architecture with comprehensive security controls, monitoring, and automation capabilities.

## Architecture Overview

The infrastructure follows Microsoft's recommended hub-and-spoke network topology with the following key components:

### Network Architecture
- **Hub VNet**: Central connectivity point with shared services
- **Spoke Subnets**: Segmented network tiers for different application layers
- **Azure Bastion**: Secure RDP/SSH access without public IPs
- **Network Security Groups**: Micro-segmentation and traffic filtering
- **Private Endpoints**: Secure connectivity to Azure PaaS services

### Security Features
- **Azure Key Vault**: Centralized secret and certificate management
- **User-Assigned Managed Identity**: Secure service authentication
- **RBAC**: Role-based access control with least privilege
- **Network Isolation**: Private subnets with controlled internet access
- **Encryption**: At-rest and in-transit encryption for all data

### Monitoring & Automation
- **Log Analytics Workspace**: Centralized logging and monitoring
- **Azure Automation Account**: Configuration management and DSC
- **Diagnostic Settings**: Comprehensive resource monitoring
- **Flow Logs**: Network traffic analysis and security monitoring

## Project Structure

```
src/
├── main.tf                  # Main infrastructure definitions
├── variables.tf             # Input variables and validation
├── locals.tf                # Local values and naming conventions
├── output.tf                # Output values for resource references
├── provider.tf              # Azure provider configuration
├── terraform.tf             # Terraform version constraints
└── modules/                 # Reusable Terraform modules
    ├── authorization/       # RBAC and role assignments
    ├── automation/          # Azure Automation Account
    ├── compute/             # Virtual machines and availability sets
    ├── monitoring/          # Log Analytics and monitoring
    ├── network/             # Networking components
    ├── resourceGroup/       # Resource group management
    ├── Security/            # Key Vault, managed identities
    └── Storage/             # Storage accounts and containers
```

## Resource Naming Convention

The project follows Microsoft Cloud Adoption Framework naming standards:

**Format**: `{project}-{resource_type}-{purpose}-{environment}-{location}`

**Examples**:
- Resource Group: `hubspoke-rg-coreinfra-dev-wus3`
- Virtual Network: `hubspoke-vnet-main-dev-wus3`
- Key Vault: `hubspoke-kv-main-dev-wus3-abc123`
- Storage Account: `hubspokestmaindevwus3abc123`

## Prerequisites

1. **Azure CLI** - Version 2.30.0 or later
2. **Terraform** - Version 1.0.0 or later
3. **Azure Subscription** - With Contributor or Owner permissions
4. **PowerShell** - Version 5.1 or later (for automation scripts)

## Quick Start

### 1. Authentication
```bash
# Login to Azure
az login

# Set subscription (if multiple subscriptions)
az account set --subscription "your-subscription-id"
```

### 2. Initialize Terraform
```bash
# Navigate to source directory
cd src/

# Initialize Terraform
terraform init

# Create workspace for environment
terraform workspace new dev
```

### 3. Configure Variables
Create a `terraform.tfvars` file:
```hcl
# Basic Configuration
location = "westus3"
environment = "dev"
project_name = "hubspoke"

# Network Configuration
allowed_ip_rules = [
  "your.public.ip.address/32",
  "131.107.0.0/16"  # Microsoft corporate network
]

# VM Configuration
dc_vm_names = ["W3DC01"]
test_vm_names = ["W3TestVM01"]

# Tags (using standardized lowercase naming with underscores)
default_tags = {
  deployed_via = "Terraform"
  owner        = "YourName"
  team         = "Infrastructure"
  contact      = "your.email@company.com"
  cost_center  = "12345"
  organization = "IT"
  repository   = "azure-hubspoke-terraform"
}
```

### 4. Deploy Infrastructure
```bash
# Plan deployment
terraform plan

# Apply changes
terraform apply

# Confirm with 'yes' when prompted
```

## Module Documentation

### Resource Group Module (`modules/resourceGroup/`)
Creates multiple resource groups for logical organization:
- **NetLab**: Network infrastructure resources
- **CoreInfra**: Core services (Key Vault, Storage, Automation)
- **WebFE**: Web front-end tier
- **DB_backend**: Database and backend tier

### Network Modules (`modules/network/`)
- **VNet**: Hub virtual network with custom DNS
- **Subnets**: Segmented subnets for different tiers
- **NSG**: Network security groups with flow logging
- **Bastion**: Secure VM access service
- **Public IP**: Static IP addresses for services

### Security Modules (`modules/Security/`)
- **Key Vault**: Secret and certificate management
- **User-Assigned Managed Identity**: Service authentication
- **Role Assignments**: RBAC configuration

### Storage Module (`modules/Storage/`)
- **Storage Account**: Secure storage with encryption
- **Containers**: Blob storage for scripts and diagnostics

### Compute Modules (`modules/compute/`)
- **Availability Sets**: VM high availability
- **Windows VMs**: Domain controllers and test VMs
- **Extensions**: VM configuration and monitoring

### Monitoring Module (`modules/monitoring/`)
- **Log Analytics Workspace**: Centralized logging
- **Diagnostic Settings**: Resource monitoring configuration

## Security Best Practices

### Network Security
- All VMs deployed in private subnets
- Azure Bastion for secure remote access
- Network Security Groups with least privilege rules
- Private endpoints for Azure services
- Custom DNS for domain integration

### Identity & Access Management
- User-assigned managed identities for services
- RBAC with principle of least privilege
- Key Vault for secret management
- No hardcoded credentials in code

### Data Protection
- Encryption at rest for all storage
- HTTPS-only access for web services
- TLS 1.2 minimum for all connections
- Secure key management in Key Vault

### Monitoring & Compliance
- Comprehensive logging to Log Analytics
- Network flow logs for security analysis
- Diagnostic settings for all resources
- Automated compliance checking

## Environment Management

### Workspaces
Use Terraform workspaces for environment separation:
```bash
# Create environments
terraform workspace new dev
terraform workspace new staging
terraform workspace new prod

# Switch environments
terraform workspace select dev
```

### Variable Files
Use environment-specific variable files:
- `dev.tfvars` - Development environment
- `staging.tfvars` - Staging environment
- `prod.tfvars` - Production environment

```bash
# Deploy to specific environment
terraform apply -var-file="dev.tfvars"
```

## Outputs

The deployment provides comprehensive outputs for integration:

### Network Outputs
- Virtual network ID and name
- Subnet IDs for application deployment
- Bastion FQDN for secure access

### Security Outputs
- Key Vault URI for secret access
- Managed identity IDs for service authentication
- Storage account endpoints

### Monitoring Outputs
- Log Analytics workspace ID
- Automation account details

## Troubleshooting

### Common Issues

1. **Key Vault Access Denied**
   - Ensure your user has Key Vault Administrator role
   - Check network access rules and IP restrictions

2. **Storage Account Name Conflicts**
   - Storage account names must be globally unique
   - Random suffix is automatically added

3. **VM Deployment Failures**
   - Verify subnet has sufficient IP addresses
   - Check NSG rules allow required traffic

4. **Bastion Connection Issues**
   - Ensure AzureBastionSubnet is properly configured
   - Verify public IP is associated with Bastion

### Validation Commands
```bash
# Validate Terraform configuration
terraform validate

# Check formatting
terraform fmt -check

# Plan without applying
terraform plan

# Show current state
terraform show
```

## Contributing

1. Follow the established naming conventions
2. Add comprehensive variable validation
3. Include detailed output descriptions
4. Document all modules with README files
5. Test changes in development environment first

## Support

For issues and questions:
1. Check the troubleshooting section
2. Review Terraform and Azure documentation
3. Contact the infrastructure team
4. Create an issue in the project repository

## License

This project is licensed under the MIT License - see the LICENSE file for details.