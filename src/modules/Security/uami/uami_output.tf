output "uami_name" {
  description = "The name of the user-assigned managed identity"
  value       = azurerm_user_assigned_identity.User_identity.name
  sensitive   = false
}

output "uami_Name" {
  description = "Alias for uami_name for backward compatibility"
  value       = azurerm_user_assigned_identity.User_identity.name
  sensitive   = false
}

output "uami_client_id" {
  description = "The client ID (application ID) of the user-assigned managed identity"
  value       = azurerm_user_assigned_identity.User_identity.client_id
  sensitive   = false
}

output "uami_Client_id" {
  description = "Alias for uami_client_id for backward compatibility"
  value       = azurerm_user_assigned_identity.User_identity.client_id
  sensitive   = false
}

output "uami_id" {
  description = "The resource ID of the user-assigned managed identity"
  value       = azurerm_user_assigned_identity.User_identity.id
  sensitive   = false
}

output "principal_id" {
  description = "The principal ID (object ID) of the user-assigned managed identity"
  value       = azurerm_user_assigned_identity.User_identity.principal_id
  sensitive   = true
}

output "tenant_id" {
  description = "The tenant ID associated with the user-assigned managed identity"
  value       = azurerm_user_assigned_identity.User_identity.tenant_id
  sensitive   = false
}

output "uami_location" {
  description = "The Azure region where the user-assigned managed identity is deployed"
  value       = azurerm_user_assigned_identity.User_identity.location
  sensitive   = false
}

output "uami_resource_group_name" {
  description = "The name of the resource group containing the user-assigned managed identity"
  value       = azurerm_user_assigned_identity.User_identity.resource_group_name
  sensitive   = false
}

output "identity_purpose" {
  description = "The purpose of this managed identity (if specified)"
  value       = try(var.identity_purpose, "General purpose managed identity")
  sensitive   = false
}

output "federated_credential_id" {
  description = "The resource ID of the federated identity credential (if enabled)"
  value       = try(var.enable_federated_identity ? azurerm_user_assigned_identity_federated_identity_credential.federated_credential[0].id : null, null)
  sensitive   = false
}

output "prevent_destroy_enabled" {
  description = "Whether prevent destroy is enabled for this managed identity"
  value       = try(var.prevent_destroy, false)
  sensitive   = false
}

output "uami_details" {
  description = "Complete details of the user-assigned managed identity including all properties"
  value = {
    id                  = azurerm_user_assigned_identity.User_identity.id
    name                = azurerm_user_assigned_identity.User_identity.name
    location            = azurerm_user_assigned_identity.User_identity.location
    resource_group_name = azurerm_user_assigned_identity.User_identity.resource_group_name
    client_id           = azurerm_user_assigned_identity.User_identity.client_id
    principal_id        = azurerm_user_assigned_identity.User_identity.principal_id
    tenant_id           = azurerm_user_assigned_identity.User_identity.tenant_id
    tags                = azurerm_user_assigned_identity.User_identity.tags
  }
  sensitive = true
}