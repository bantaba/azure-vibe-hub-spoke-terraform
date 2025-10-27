output "kvault_id" {
    value = azurerm_key_vault.main-kv.id
}

output "kvault_name" {
    value = azurerm_key_vault.main-kv.name
}

output "kvault_vault_uri" {
    value = azurerm_key_vault.main-kv.vault_uri
}

output "private_endpoint_id" {
    description = "The ID of the private endpoint"
    value = var.enable_private_endpoint ? azurerm_private_endpoint.kv_private_endpoint[0].id : null
}

output "private_endpoint_ip" {
    description = "The private IP address of the private endpoint"
    value = var.enable_private_endpoint ? azurerm_private_endpoint.kv_private_endpoint[0].private_service_connection[0].private_ip_address : null
}

output "rbac_authorization_enabled" {
    description = "Whether RBAC authorization is enabled"
    value = azurerm_key_vault.main-kv.enable_rbac_authorization
}

output "purge_protection_enabled" {
    description = "Whether purge protection is enabled"
    value = azurerm_key_vault.main-kv.purge_protection_enabled
}