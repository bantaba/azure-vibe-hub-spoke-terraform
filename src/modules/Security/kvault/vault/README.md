# Azure Key Vault Module

This module creates an Azure Key Vault with comprehensive security configurations, network access controls, and optional private endpoint connectivity.

## Features

- **Secure Configuration**: RBAC-enabled with purge protection
- **Network Security**: Configurable network access rules and IP restrictions
- **Private Connectivity**: Optional private endpoint support
- **Monitoring**: Diagnostic settings integration
- **Compliance**: Follows Azure security best practices

## Usage

### Basic Usage
```hcl
module "key_vault" {
  source = "./modules/Security/kvault/vault"
  
  vault_name     = "my-keyvault-${random_id.kv.hex}"
  vault_location = "West US 3"
  vault_rg_name  = "my-resource-group"
  tenant_id      = data.azurerm_client_config.current.tenant_id
  
  # Network access configuration
  network_acls_default_action = "Deny"
  allowed_ip_ranges          = ["192.168.1.0/24", "10.0.0.0/8"]
  virtual_network_subnet_ids = [azurerm_subnet.example.id]
  
  tags = {
    Environment = "Production"
    Purpose     = "Secret Management"
  }
}
```

### Advanced Usage with Private Endpoint
```hcl
module "key_vault" {
  source = "./modules/Security/kvault/vault"
  
  vault_name     = "my-keyvault-${random_id.kv.hex}"
  vault_location = "West US 3"
  vault_rg_name  = "my-resource-group"
  tenant_id      = data.azurerm_client_config.current.tenant_id
  
  # Enhanced security configuration
  purge_protection_enabled       = true
  soft_delete_retention_days     = 90
  enable_rbac_authorization      = true
  public_network_access_enabled  = false
  
  # Private endpoint configuration
  enable_private_endpoint    = true
  private_endpoint_subnet_id = azurerm_subnet.private.id
  private_dns_zone_ids      = [azurerm_private_dns_zone.keyvault.id]
  
  # Monitoring
  enable_diagnostic_settings   = true
  log_analytics_workspace_id   = azurerm_log_analytics_workspace.main.id
  
  tags = local.common_tags
}
```

## Requirements

| Name | Version |
|------|---------|
| terraform | >= 1.0 |
| azurerm | >= 3.65, <= 3.68 |

## Providers

| Name | Version |
|------|---------|
| azurerm | >= 3.65, <= 3.68 |

## Resources

| Name | Type |
|------|------|
| [azurerm_key_vault.main-kv](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/key_vault) | resource |
| [azurerm_private_endpoint.kv_private_endpoint](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/private_endpoint) | resource |
| [azurerm_monitor_diagnostic_setting.kv_diagnostics](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/monitor_diagnostic_setting) | resource |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| vault_name | The name of the Key Vault. Must be globally unique. | `string` | n/a | yes |
| vault_location | The Azure region where the Key Vault will be created. | `string` | n/a | yes |
| vault_rg_name | The name of the resource group for the Key Vault. | `string` | n/a | yes |
| tenant_id | The Azure AD tenant ID for the Key Vault. | `string` | n/a | yes |
| sku_name | The SKU name for the Key Vault (standard or premium). | `string` | `"standard"` | no |
| soft_delete_retention_days | Number of days to retain soft-deleted items (7-90). | `number` | `14` | no |
| purge_protection_enabled | Enable purge protection for the Key Vault. | `bool` | `true` | no |
| public_network_access_enabled | Allow public network access to the Key Vault. | `bool` | `true` | no |
| network_acls_default_action | Default action for network ACLs (Allow or Deny). | `string` | `"Deny"` | no |
| network_acls_bypass | Traffic that can bypass network rules. | `string` | `"AzureServices"` | no |
| virtual_network_subnet_ids | Set of subnet IDs allowed to access the Key Vault. | `set(string)` | n/a | yes |
| allowed_ip_ranges | Set of IP addresses/ranges allowed to access the Key Vault. | `set(string)` | n/a | yes |
| enable_rbac_authorization | Use RBAC for Key Vault authorization. | `bool` | `true` | no |
| enabled_for_deployment | Allow VMs to retrieve certificates from Key Vault. | `bool` | `false` | no |
| enabled_for_disk_encryption | Allow disk encryption to access Key Vault. | `bool` | `true` | no |
| enabled_for_template_deployment | Allow ARM templates to access Key Vault. | `bool` | `false` | no |
| enable_private_endpoint | Create a private endpoint for the Key Vault. | `bool` | `false` | no |
| private_endpoint_subnet_id | Subnet ID for the private endpoint. | `string` | `null` | no |
| private_dns_zone_ids | List of private DNS zone IDs for the private endpoint. | `list(string)` | `[]` | no |
| enable_diagnostic_settings | Enable diagnostic settings for the Key Vault. | `bool` | `true` | no |
| log_analytics_workspace_id | Log Analytics workspace ID for diagnostics. | `string` | `null` | no |
| tags | A map of tags to assign to the Key Vault. | `map(string)` | n/a | yes |

## Outputs

| Name | Description |
|------|-------------|
| kvault_id | The resource ID of the Key Vault |
| kvault_name | The name of the Key Vault |
| kvault_uri | The URI of the Key Vault |
| kvault_location | The Azure region of the Key Vault |
| kvault_resource_group_name | The resource group name of the Key Vault |
| kvault_tenant_id | The tenant ID of the Key Vault |
| private_endpoint_id | The resource ID of the private endpoint (if enabled) |
| private_endpoint_ip | The private IP address of the private endpoint (if enabled) |
| rbac_authorization_enabled | Whether RBAC authorization is enabled |
| purge_protection_enabled | Whether purge protection is enabled |
| network_acls | The network access control configuration |
| kvault_details | Complete Key Vault configuration details |

## Security Considerations

### Network Security
- **Default Deny**: Network access is denied by default
- **IP Restrictions**: Only specified IP ranges can access the Key Vault
- **VNet Integration**: Subnet-level access control
- **Private Endpoints**: Eliminate internet exposure

### Access Control
- **RBAC**: Role-based access control is enabled by default
- **Least Privilege**: Grant minimum required permissions
- **Managed Identities**: Use managed identities instead of service principals

### Data Protection
- **Purge Protection**: Prevents accidental deletion of Key Vault
- **Soft Delete**: Provides recovery window for deleted items
- **Encryption**: All data encrypted at rest and in transit

### Monitoring
- **Diagnostic Logs**: All access and operations logged
- **Audit Trail**: Complete audit trail for compliance
- **Alerts**: Configure alerts for suspicious activities

## Examples

### Development Environment
```hcl
module "dev_keyvault" {
  source = "./modules/Security/kvault/vault"
  
  vault_name     = "dev-kv-${random_id.kv.hex}"
  vault_location = "West US 3"
  vault_rg_name  = "dev-security-rg"
  tenant_id      = data.azurerm_client_config.current.tenant_id
  
  # Relaxed settings for development
  network_acls_default_action = "Allow"
  purge_protection_enabled    = false
  soft_delete_retention_days  = 7
  
  allowed_ip_ranges          = ["0.0.0.0/0"]  # Allow all IPs for dev
  virtual_network_subnet_ids = []
  
  tags = {
    Environment = "Development"
    Purpose     = "Development Testing"
  }
}
```

### Production Environment
```hcl
module "prod_keyvault" {
  source = "./modules/Security/kvault/vault"
  
  vault_name     = "prod-kv-${random_id.kv.hex}"
  vault_location = "West US 3"
  vault_rg_name  = "prod-security-rg"
  tenant_id      = data.azurerm_client_config.current.tenant_id
  
  # Maximum security for production
  network_acls_default_action   = "Deny"
  purge_protection_enabled      = true
  soft_delete_retention_days    = 90
  public_network_access_enabled = false
  
  # Private endpoint for secure access
  enable_private_endpoint    = true
  private_endpoint_subnet_id = azurerm_subnet.private.id
  private_dns_zone_ids      = [azurerm_private_dns_zone.keyvault.id]
  
  # Restricted network access
  allowed_ip_ranges = [
    "10.0.0.0/8",      # Internal networks only
    "192.168.0.0/16"   # Corporate networks
  ]
  virtual_network_subnet_ids = [
    azurerm_subnet.app.id,
    azurerm_subnet.data.id
  ]
  
  # Enhanced monitoring
  enable_diagnostic_settings = true
  log_analytics_workspace_id = azurerm_log_analytics_workspace.prod.id
  
  tags = {
    Environment = "Production"
    Purpose     = "Production Secret Management"
    Compliance  = "Required"
  }
}
```

## Best Practices

1. **Naming**: Use descriptive names with environment prefixes
2. **Network Security**: Always use network restrictions in production
3. **RBAC**: Enable RBAC and assign minimal required permissions
4. **Monitoring**: Enable diagnostic settings for audit trails
5. **Backup**: Use soft delete and purge protection in production
6. **Private Endpoints**: Use private endpoints for enhanced security
7. **Key Rotation**: Implement regular key and secret rotation
8. **Access Reviews**: Regularly review and audit access permissions

## Troubleshooting

### Common Issues

1. **Access Denied Errors**
   - Verify RBAC permissions are correctly assigned
   - Check network access rules and IP restrictions
   - Ensure managed identity has required permissions

2. **Name Conflicts**
   - Key Vault names must be globally unique
   - Use random suffixes or environment-specific naming

3. **Network Connectivity Issues**
   - Verify subnet IDs are correct
   - Check NSG rules allow Key Vault traffic
   - Ensure private DNS is configured for private endpoints

4. **Purge Protection Issues**
   - Cannot disable purge protection once enabled
   - Plan carefully before enabling in production

### Validation
```bash
# Test Key Vault connectivity
az keyvault secret list --vault-name "your-keyvault-name"

# Check network access
az keyvault network-rule list --name "your-keyvault-name"

# Verify RBAC assignments
az role assignment list --scope "/subscriptions/{subscription-id}/resourceGroups/{rg-name}/providers/Microsoft.KeyVault/vaults/{kv-name}"
```