# Storage Module Configuration Guide

## Overview

This guide provides detailed configuration instructions for the enhanced storage account module with security best practices.

## Module Structure

```
src/modules/Storage/stgAccount/
├── sa.tf                    # Main storage account resource
├── variables_sa.tf          # Variable definitions
├── output_sa.tf            # Output definitions
└── stage/                  # Environment-specific configurations
```

## Required Variables

### Basic Configuration
```hcl
variable "sa_name" {
  description = "Storage account name (3-24 characters, lowercase alphanumeric)"
  type        = string
  validation {
    condition     = can(regex("^[a-z0-9]{3,24}$", var.sa_name))
    error_message = "Storage account name must be 3-24 characters, lowercase letters and numbers only."
  }
}

variable "sa_location" {
  description = "Azure region for storage account deployment"
  type        = string
  default     = "westUS2"
}

variable "sa_rg_name" {
  description = "Resource group name for storage account"
  type        = string
}
```

### Security Configuration

#### Network Access Control
```hcl
# Disable public network access (recommended)
public_network_access_enabled = false

# Configure network rules
network_rules_enabled = true
network_rules_default_action = "Deny"

# Allow specific IP ranges (optional)
allowed_ip_ranges = [
  "203.0.113.0/24",  # Office network
  "198.51.100.0/24"  # VPN network
]

# Allow specific subnets
allowed_subnet_ids = [
  "/subscriptions/{subscription-id}/resourceGroups/{rg}/providers/Microsoft.Network/virtualNetworks/{vnet}/subnets/{subnet}"
]
```

#### Authentication Settings
```hcl
# Enforce Azure AD authentication (recommended)
default_to_oauth_authentication = true

# Disable shared access keys (recommended)
shared_access_key_enabled = false
```

#### Data Protection
```hcl
# Enable blob versioning for data protection
blob_versioning_enabled = true

# Enable change feed for audit trails
blob_change_feed_enabled = true

# Configure retention policies
blob_delete_retention_days = 30        # 1-365 days
container_delete_retention_days = 7    # 1-365 days
```

## Configuration Examples

### Development Environment
```hcl
module "dev_storage" {
  source = "./modules/Storage/stgAccount"
  
  # Basic settings
  sa_name     = "devstorageacct001"
  sa_location = "East US"
  sa_rg_name  = "rg-dev-storage"
  
  # Relaxed security for development
  public_network_access_enabled = true
  shared_access_key_enabled     = true
  network_rules_enabled         = false
  
  # Standard data protection
  blob_delete_retention_days      = 7
  container_delete_retention_days = 1
  
  tags = {
    environment = "development"
    team        = "devops"
    project     = "terraform-security"
    deployed_via = "terraform"
  }
}
```

### Production Environment
```hcl
module "prod_storage" {
  source = "./modules/Storage/stgAccount"
  
  # Basic settings
  sa_name     = "prodstorageacct001"
  sa_location = "East US"
  sa_rg_name  = "rg-prod-storage"
  
  # Maximum security configuration
  public_network_access_enabled    = false
  default_to_oauth_authentication  = true
  shared_access_key_enabled        = false
  
  # Strict network controls
  network_rules_enabled       = true
  network_rules_default_action = "Deny"
  allowed_subnet_ids = [
    var.app_subnet_id,
    var.db_subnet_id
  ]
  
  # Enhanced data protection
  blob_versioning_enabled         = true
  blob_change_feed_enabled        = true
  blob_last_access_time_enabled   = true
  blob_delete_retention_days      = 90
  container_delete_retention_days = 30
  
  # Private endpoint configuration
  enable_private_endpoint    = true
  private_endpoint_subnet_id = var.private_endpoint_subnet_id
  private_dns_zone_ids      = [var.blob_private_dns_zone_id]
  
  tags = {
    environment = "production"
    team        = "devops"
    project     = "terraform-security"
    compliance  = "required"
    deployed_via = "terraform"
  }
}
```

### High-Security Environment
```hcl
module "secure_storage" {
  source = "./modules/Storage/stgAccount"
  
  # Basic settings
  sa_name     = "secstorageacct001"
  sa_location = "East US"
  sa_rg_name  = "rg-secure-storage"
  
  # Premium security tier
  account_tier = "Premium"
  account_kind = "BlockBlobStorage"
  
  # Zero-trust network model
  public_network_access_enabled = false
  network_rules_enabled         = true
  network_rules_default_action  = "Deny"
  network_rules_bypass         = ["Logging", "Metrics"]  # Minimal bypass
  
  # Identity-based access only
  default_to_oauth_authentication = true
  shared_access_key_enabled      = false
  
  # Maximum data protection
  infrastructure_encryption_enabled = true
  blob_versioning_enabled          = true
  blob_change_feed_enabled         = true
  blob_last_access_time_enabled    = true
  blob_delete_retention_days       = 365  # Maximum retention
  container_delete_retention_days  = 90
  
  # Private connectivity only
  enable_private_endpoint    = true
  private_endpoint_subnet_id = var.secure_subnet_id
  private_dns_zone_ids      = [
    var.blob_private_dns_zone_id,
    var.file_private_dns_zone_id
  ]
  
  tags = {
    environment    = "secure"
    classification = "confidential"
    compliance     = "soc2-pci-hipaa"
    deployed_via   = "terraform"
  }
}
```

## Variable Validation Rules

### Storage Account Name
- Length: 3-24 characters
- Characters: Lowercase letters and numbers only
- Uniqueness: Must be globally unique across Azure

### Network Configuration
- IP ranges must be in CIDR format (e.g., "192.168.1.0/24")
- Subnet IDs must be full Azure resource IDs
- Default action must be "Allow" or "Deny"

### Retention Policies
- Blob retention: 0-365 days (0 disables retention)
- Container retention: 0-365 days (0 disables retention)
- Values must be integers within the valid range

## Output Values

The module provides the following outputs:

```hcl
# Storage account information
output "sa_id" {
  description = "Storage account resource ID"
  value       = module.storage.sa_id
}

output "sa_name" {
  description = "Storage account name"
  value       = module.storage.sa_name
}

# Security status outputs
output "public_network_access_enabled" {
  description = "Public network access status"
  value       = module.storage.public_network_access_enabled
}

output "infrastructure_encryption_enabled" {
  description = "Infrastructure encryption status"
  value       = module.storage.infrastructure_encryption_enabled
}

# Private endpoint information (if enabled)
output "private_endpoint_id" {
  description = "Private endpoint resource ID"
  value       = module.storage.private_endpoint_id
}

output "private_endpoint_ip" {
  description = "Private endpoint IP address"
  value       = module.storage.private_endpoint_ip
}
```

## Troubleshooting

### Common Configuration Issues

#### Storage Account Name Validation Errors
```
Error: Storage account name must be 3-24 characters, lowercase letters and numbers only
```
**Solution**: Ensure the name follows Azure naming conventions:
- Use only lowercase letters (a-z) and numbers (0-9)
- Length between 3-24 characters
- No special characters, spaces, or uppercase letters

#### Network Access Denied
```
Error: This request is not authorized to perform this operation
```
**Solution**: Check network configuration:
1. Verify `allowed_ip_ranges` includes your current IP
2. Ensure `allowed_subnet_ids` includes the source subnet
3. Check if `public_network_access_enabled` should be `true` for your use case

#### Private Endpoint DNS Resolution
```
Error: Could not resolve storage account hostname
```
**Solution**: Verify private DNS configuration:
1. Ensure private DNS zone is properly configured
2. Check virtual network DNS settings
3. Verify private endpoint is in "Succeeded" state

### Validation Commands

```bash
# Validate Terraform configuration
terraform validate

# Plan deployment to check for issues
terraform plan -var-file="environments/dev.tfvars"

# Check storage account configuration
az storage account show --name <storage-account> --resource-group <rg>

# Test network connectivity
az storage blob list --account-name <storage-account> --container-name <container> --auth-mode login
```

## Security Checklist

Before deploying to production, verify:

- [ ] Public network access is disabled (`public_network_access_enabled = false`)
- [ ] Shared access keys are disabled (`shared_access_key_enabled = false`)
- [ ] OAuth authentication is enabled (`default_to_oauth_authentication = true`)
- [ ] Network rules are configured with deny-all default
- [ ] Appropriate IP ranges and subnets are allowlisted
- [ ] Blob versioning and change feed are enabled
- [ ] Retention policies meet compliance requirements
- [ ] Private endpoints are configured for production workloads
- [ ] Infrastructure encryption is enabled
- [ ] Appropriate tags are applied for governance

## Last Updated
December 2024 - Enhanced security configuration guide