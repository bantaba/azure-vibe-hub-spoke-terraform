# Storage Account Module

## Overview

This module creates an Azure Storage Account with enhanced security configurations, following Azure security best practices and compliance requirements.

## Features

### Security Enhancements
- **Network Access Control**: Configurable public access with default deny-all policy
- **Authentication**: OAuth enforcement with optional shared key disabling
- **Data Protection**: Blob versioning, change feed, and retention policies
- **Private Connectivity**: Optional private endpoint support
- **Encryption**: Infrastructure encryption enabled by default

### Compliance
- CIS Azure Foundations Benchmark compliant
- Azure Security Baseline aligned
- SAST tool validated (Checkov, TFSec, Terrascan)

## Usage

### Basic Usage
```hcl
module "storage_account" {
  source = "./modules/Storage/stgAccount"
  
  sa_name     = "mystorageaccount001"
  sa_location = "East US"
  sa_rg_name  = "my-resource-group"
  
  sa_container_name = "mycontainer"
  
  tags = {
    environment = "production"
    team        = "devops"
    deployed_via = "terraform"
  }
}
```

### Secure Configuration
```hcl
module "secure_storage" {
  source = "./modules/Storage/stgAccount"
  
  # Basic configuration
  sa_name     = "securestorage001"
  sa_location = "East US"
  sa_rg_name  = "rg-secure-storage"
  
  # Container configuration
  sa_container_name     = "secure-data"
  container_access_type = "private"
  
  # Security settings
  public_network_access_enabled    = false
  default_to_oauth_authentication  = true
  shared_access_key_enabled        = false
  
  # Network restrictions
  network_rules_enabled       = true
  network_rules_default_action = "Deny"
  allowed_subnet_ids = [
    "/subscriptions/{sub-id}/resourceGroups/{rg}/providers/Microsoft.Network/virtualNetworks/{vnet}/subnets/{subnet}"
  ]
  
  # Data protection
  blob_versioning_enabled         = true
  blob_change_feed_enabled        = true
  blob_delete_retention_days      = 30
  container_delete_retention_days = 7
  
  tags = {
    Environment = "Production"
    Security    = "Enhanced"
  }
}
```

### Private Endpoint Configuration
```hcl
module "private_storage" {
  source = "./modules/Storage/stgAccount"
  
  # Basic configuration
  sa_name     = "privatestorage001"
  sa_location = "East US"
  sa_rg_name  = "rg-private-storage"
  
  # Container configuration
  sa_container_name = "private-data"
  
  # Private endpoint
  enable_private_endpoint    = true
  private_endpoint_subnet_id = var.private_endpoint_subnet_id
  private_dns_zone_ids      = [var.blob_private_dns_zone_id]
  
  # Disable public access completely
  public_network_access_enabled = false
  
  tags = var.common_tags
}
```

## Variables

### Required Variables

| Name | Type | Description |
|------|------|-------------|
| `sa_name` | `string` | Storage account name (3-24 chars, lowercase alphanumeric) |
| `sa_location` | `string` | Azure region for deployment |
| `sa_rg_name` | `string` | Resource group name |
| `sa_container_name` | `string` | Container name (3-24 chars, lowercase alphanumeric and hyphens) |
| `tags` | `map(string)` | Resource tags |

### Optional Variables

#### Storage Configuration
| Name | Type | Default | Description |
|------|------|---------|-------------|
| `account_kind` | `string` | `"StorageV2"` | Storage account kind |
| `account_tier` | `string` | `"Standard"` | Storage account tier |
| `replication_type` | `string` | `"LRS"` | Replication type |
| `access_tier` | `string` | `"Hot"` | Access tier for blob storage |

#### Security Configuration
| Name | Type | Default | Description |
|------|------|---------|-------------|
| `public_network_access_enabled` | `bool` | `false` | Enable public network access |
| `default_to_oauth_authentication` | `bool` | `true` | Default to OAuth authentication |
| `shared_access_key_enabled` | `bool` | `false` | Enable shared access keys |
| `enable_https_traffic_only` | `bool` | `true` | Force HTTPS traffic |
| `min_tls_version` | `string` | `"TLS1_2"` | Minimum TLS version |
| `infrastructure_encryption_enabled` | `bool` | `true` | Enable infrastructure encryption |

#### Network Configuration
| Name | Type | Default | Description |
|------|------|---------|-------------|
| `network_rules_enabled` | `bool` | `true` | Enable network access rules |
| `network_rules_default_action` | `string` | `"Deny"` | Default network action |
| `network_rules_bypass` | `set(string)` | `["AzureServices", "Logging", "Metrics"]` | Services that bypass network rules |
| `allowed_ip_ranges` | `list(string)` | `[]` | Allowed IP ranges in CIDR format |
| `allowed_subnet_ids` | `list(string)` | `[]` | Allowed subnet resource IDs |

#### Data Protection
| Name | Type | Default | Description |
|------|------|---------|-------------|
| `blob_versioning_enabled` | `bool` | `true` | Enable blob versioning |
| `blob_change_feed_enabled` | `bool` | `true` | Enable blob change feed |
| `blob_last_access_time_enabled` | `bool` | `true` | Enable last access time tracking |
| `blob_delete_retention_days` | `number` | `30` | Blob soft delete retention (0-365 days) |
| `container_delete_retention_days` | `number` | `7` | Container soft delete retention (0-365 days) |

#### Private Endpoint
| Name | Type | Default | Description |
|------|------|---------|-------------|
| `enable_private_endpoint` | `bool` | `false` | Create private endpoint |
| `private_endpoint_subnet_id` | `string` | `null` | Subnet ID for private endpoint |
| `private_dns_zone_ids` | `list(string)` | `[]` | Private DNS zone IDs |

#### Container Configuration
| Name | Type | Default | Description |
|------|------|---------|-------------|
| `container_access_type` | `string` | `"private"` | Container access level |
| `sa_blob_type` | `string` | `"Block"` | Blob type for uploads |
| `allow_nested_items_to_be_public` | `bool` | `false` | Allow public nested items |

## Outputs

| Name | Description | Sensitive |
|------|-------------|-----------|
| `sa_id` | Storage account resource ID | No |
| `sa_name` | Storage account name | No |
| `sa_key` | Primary access key | Yes |
| `sa_blob_endpoint` | Primary blob endpoint URL | No |
| `infrastructure_encryption_enabled` | Infrastructure encryption status | No |
| `public_network_access_enabled` | Public network access status | No |
| `private_endpoint_id` | Private endpoint resource ID | No |
| `private_endpoint_ip` | Private endpoint IP address | No |

## Security Considerations

### Default Security Posture
- Public network access is **disabled** by default
- Shared access keys are **disabled** by default
- OAuth authentication is **enforced** by default
- Network rules default to **deny-all** policy
- Infrastructure encryption is **enabled** by default

### Network Security
- Configure `allowed_ip_ranges` for specific public IP access
- Use `allowed_subnet_ids` for virtual network access
- Consider private endpoints for maximum security
- Monitor network access patterns and adjust rules accordingly

### Data Protection
- Blob versioning provides point-in-time recovery
- Change feed enables audit trail and compliance
- Retention policies prevent accidental data loss
- Regular backup strategies should complement soft delete

### Access Management
- Use Azure AD authentication instead of shared keys
- Implement least-privilege access with RBAC
- Regular access reviews and key rotation (if keys are used)
- Monitor access patterns for anomalies

## Compliance and Validation

### SAST Tool Validation
The module passes security validation from:
- **Checkov**: All Azure storage account security checks
- **TFSec**: Terraform security analysis
- **Terrascan**: Policy-as-code validation

### Compliance Standards
- CIS Azure Foundations Benchmark
- Azure Security Baseline
- NIST Cybersecurity Framework
- SOC 2 Type II controls

## Troubleshooting

### Common Issues
1. **Access Denied**: Check network rules and authentication method
2. **Name Validation**: Ensure storage account name follows Azure conventions
3. **Private Endpoint**: Verify DNS configuration and network connectivity
4. **Retention Policies**: Ensure retention days are within valid ranges (0-365)

### Diagnostic Commands
```bash
# Check storage account configuration
az storage account show --name <storage-account> --resource-group <rg>

# Validate network rules
az storage account show --name <storage-account> --resource-group <rg> --query networkRuleSet

# Test connectivity
az storage blob list --account-name <storage-account> --container-name <container> --auth-mode login
```

## Examples

See `docs/setup/storage-module-configuration.md` for detailed configuration examples and `docs/operations/storage-troubleshooting.md` for troubleshooting procedures.

## Version History

- **v2.0** (December 2024): Enhanced security features, private endpoints, comprehensive data protection
- **v1.0** (Initial): Basic storage account with container and blob support

## Contributing

When modifying this module:
1. Ensure all security defaults remain secure
2. Add appropriate variable validation
3. Update documentation and examples
4. Run SAST tools for validation
5. Test with different security configurations

## License

This module is part of the Terraform Security Enhancement project.