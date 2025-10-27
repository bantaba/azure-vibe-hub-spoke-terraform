output "uami_Name" {
    value = azurerm_user_assigned_identity.User_identity.name
}

output "uami_Client_Id" {
    value = azurerm_user_assigned_identity.User_identity.client_id
}

output "uami_Id" {
    value = azurerm_user_assigned_identity.User_identity.id
}

output "principal_id" {
    value = azurerm_user_assigned_identity.User_identity.principal_id
}