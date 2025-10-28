output "kvault_id" {
  description = "The resource ID of the Key Vault"
  value       = azurerm_key_vault.main-kv.id
  sensitive   = false
}

output "kvault_name" {
  description = "The name of the Key Vault"
  value       = azurerm_key_vault.main-kv.name
  sensitive   = false
}

output "kvault_uri" {
  description = "The URI of the Key Vault for accessing secrets, keys, and certificates"
  value       = azurerm_key_vault.main-kv.vault_uri
  sensitive   = false
}

output "kvault_vault_uri" {
  description = "Alias for kvault_uri for backward compatibility"
  value       = azurerm_key_vault.main-kv.vault_uri
  sensitive   = false
}

output "kvault_location" {
  description = "The Azure region where the Key Vault is deployed"
  value       = azurerm_key_vault.main-kv.location
  sensitive   = false
}

output "kvault_resource_group_name" {
  description = "The name of the resource group containing the Key Vault"
  value       = azurerm_key_vault.main-kv.resource_group_name
  sensitive   = false
}

output "kvault_tenant_id" {
  description = "The Azure Active Directory tenant ID used by the Key Vault"
  value       = azurerm_key_vault.main-kv.tenant_id
  sensitive   = false
}

output "kvault_sku_name" {
  description = "The SKU name of the Key Vault (standard or premium)"
  value       = azurerm_key_vault.main-kv.sku_name
  sensitive   = false
}

output "private_endpoint_id" {
  description = "The resource ID of the private endpoint (if enabled)"
  value       = var.enable_private_endpoint ? azurerm_private_endpoint.kv_private_endpoint[0].id : null
  sensitive   = false
}

output "private_endpoint_ip" {
  description = "The private IP address of the private endpoint (if enabled)"
  value       = var.enable_private_endpoint ? azurerm_private_endpoint.kv_private_endpoint[0].private_service_connection[0].private_ip_address : null
  sensitive   = false
}

output "rbac_authorization_enabled" {
  description = "Whether RBAC authorization is enabled for the Key Vault"
  value       = azurerm_key_vault.main-kv.enable_rbac_authorization
  sensitive   = false
}

output "purge_protection_enabled" {
  description = "Whether purge protection is enabled for the Key Vault"
  value       = azurerm_key_vault.main-kv.purge_protection_enabled
  sensitive   = false
}

output "soft_delete_retention_days" {
  description = "The number of days that items should be retained for once soft-deleted"
  value       = azurerm_key_vault.main-kv.soft_delete_retention_days
  sensitive   = false
}

output "network_acls" {
  description = "The network access control list configuration of the Key Vault"
  value = {
    default_action             = azurerm_key_vault.main-kv.network_acls[0].default_action
    bypass                     = azurerm_key_vault.main-kv.network_acls[0].bypass
    ip_rules                   = azurerm_key_vault.main-kv.network_acls[0].ip_rules
    virtual_network_subnet_ids = azurerm_key_vault.main-kv.network_acls[0].virtual_network_subnet_ids
  }
  sensitive = false
}

output "kvault_details" {
  description = "Complete details of the Key Vault including all properties and configuration"
  value = {
    id                         = azurerm_key_vault.main-kv.id
    name                       = azurerm_key_vault.main-kv.name
    location                   = azurerm_key_vault.main-kv.location
    resource_group_name        = azurerm_key_vault.main-kv.resource_group_name
    vault_uri                  = azurerm_key_vault.main-kv.vault_uri
    tenant_id                  = azurerm_key_vault.main-kv.tenant_id
    sku_name                   = azurerm_key_vault.main-kv.sku_name
    rbac_authorization_enabled = azurerm_key_vault.main-kv.enable_rbac_authorization
    purge_protection_enabled   = azurerm_key_vault.main-kv.purge_protection_enabled
    soft_delete_retention_days = azurerm_key_vault.main-kv.soft_delete_retention_days
    tags                       = azurerm_key_vault.main-kv.tags
  }
  sensitive = false
}