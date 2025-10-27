output "sa_id" {
     description = "Outputs the storage account id associated with resource."
    value = azurerm_storage_account.sa.id
}

output "sa_name" {
     description = "Outputs the storage account name for the associated with resource."
    value = azurerm_storage_account.sa.name
}

output "sa_key" {
     description = "Outputs the storage account primary access key associated with resource."
    value = azurerm_storage_account.sa.primary_access_key
    sensitive = true
}

output "infrastructure_encryption_enabled" {
     description = "Outputs storage account infrastructure encyrption status."
    value = azurerm_storage_account.sa.infrastructure_encryption_enabled
    sensitive = false
}

output "sa_blob_endpoint" {
    value = azurerm_storage_account.sa.primary_blob_endpoint
    sensitive = false
}

output "private_endpoint_id" {
    description = "The ID of the private endpoint"
    value = var.enable_private_endpoint ? azurerm_private_endpoint.sa_private_endpoint[0].id : null
    sensitive = false
}

output "private_endpoint_ip" {
    description = "The private IP address of the private endpoint"
    value = var.enable_private_endpoint ? azurerm_private_endpoint.sa_private_endpoint[0].private_service_connection[0].private_ip_address : null
    sensitive = false
}

output "public_network_access_enabled" {
    description = "Whether public network access is enabled"
    value = azurerm_storage_account.sa.public_network_access_enabled
    sensitive = false
}