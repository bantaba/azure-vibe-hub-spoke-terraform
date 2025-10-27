output "uami_Name" {
    value = azurerm_user_assigned_identity.User_identity.name
}

output "uami_Client_id" {
    value = azurerm_user_assigned_identity.User_identity.client_id
}

output "uami_id" {
    value = azurerm_user_assigned_identity.User_identity.id
}

output "principal_id" {
    value = azurerm_user_assigned_identity.User_identity.principal_id
}

output "tenant_id" {
    description = "The tenant ID associated with the User Assigned Managed Identity"
    value = azurerm_user_assigned_identity.User_identity.tenant_id
}

output "identity_purpose" {
    description = "The purpose of this managed identity"
    value = var.identity_purpose
}

output "federated_credential_id" {
    description = "The ID of the federated identity credential"
    value = var.enable_federated_identity ? azurerm_user_assigned_identity_federated_identity_credential.federated_credential[0].id : null
}

output "prevent_destroy_enabled" {
    description = "Whether prevent destroy is enabled"
    value = var.prevent_destroy
}