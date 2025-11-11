output "sa_id" {
  description = "The resource ID of the storage account"
  value       = azurerm_storage_account.sa.id
  sensitive   = false
}

output "sa_name" {
  description = "The name of the storage account"
  value       = azurerm_storage_account.sa.name
  sensitive   = false
}

output "sa_key" {
  description = "The primary access key for the storage account"
  value       = azurerm_storage_account.sa.primary_access_key
  sensitive   = true
}

output "sa_secondary_key" {
  description = "The secondary access key for the storage account"
  value       = azurerm_storage_account.sa.secondary_access_key
  sensitive   = true
}

output "sa_connection_string" {
  description = "The primary connection string for the storage account"
  value       = azurerm_storage_account.sa.primary_connection_string
  sensitive   = true
}

output "sa_secondary_connection_string" {
  description = "The secondary connection string for the storage account"
  value       = azurerm_storage_account.sa.secondary_connection_string
  sensitive   = true
}

output "infrastructure_encryption_enabled" {
  description = "Whether infrastructure encryption is enabled for the storage account"
  value       = azurerm_storage_account.sa.infrastructure_encryption_enabled
  sensitive   = false
}

output "sa_blob_endpoint" {
  description = "The primary blob endpoint URL for the storage account"
  value       = azurerm_storage_account.sa.primary_blob_endpoint
  sensitive   = false
}

output "sa_secondary_blob_endpoint" {
  description = "The secondary blob endpoint URL for the storage account"
  value       = azurerm_storage_account.sa.secondary_blob_endpoint
  sensitive   = false
}

output "sa_queue_endpoint" {
  description = "The primary queue endpoint URL for the storage account"
  value       = azurerm_storage_account.sa.primary_queue_endpoint
  sensitive   = false
}

output "sa_table_endpoint" {
  description = "The primary table endpoint URL for the storage account"
  value       = azurerm_storage_account.sa.primary_table_endpoint
  sensitive   = false
}

output "sa_file_endpoint" {
  description = "The primary file endpoint URL for the storage account"
  value       = azurerm_storage_account.sa.primary_file_endpoint
  sensitive   = false
}

output "sa_location" {
  description = "The Azure region where the storage account is deployed"
  value       = azurerm_storage_account.sa.location
  sensitive   = false
}

output "sa_resource_group_name" {
  description = "The name of the resource group containing the storage account"
  value       = azurerm_storage_account.sa.resource_group_name
  sensitive   = false
}

output "sa_account_tier" {
  description = "The performance tier of the storage account"
  value       = azurerm_storage_account.sa.account_tier
  sensitive   = false
}

output "sa_account_replication_type" {
  description = "The replication type of the storage account"
  value       = azurerm_storage_account.sa.account_replication_type
  sensitive   = false
}

output "private_endpoint_id" {
  description = "The resource ID of the private endpoint (if enabled)"
  value       = var.enable_private_endpoint ? azurerm_private_endpoint.sa_private_endpoint[0].id : null
  sensitive   = false
}

output "private_endpoint_ip" {
  description = "The private IP address of the private endpoint (if enabled)"
  value       = var.enable_private_endpoint ? azurerm_private_endpoint.sa_private_endpoint[0].private_service_connection[0].private_ip_address : null
  sensitive   = false
}

output "public_network_access_enabled" {
  description = "Whether public network access is enabled for the storage account"
  value       = azurerm_storage_account.sa.public_network_access_enabled
  sensitive   = false
}

output "https_traffic_only_enabled" {
  description = "Whether HTTPS traffic only is enabled for the storage account"
  value       = azurerm_storage_account.sa.enable_https_traffic_only
  sensitive   = false
}

output "min_tls_version" {
  description = "The minimum supported TLS version for the storage account"
  value       = azurerm_storage_account.sa.min_tls_version
  sensitive   = false
}

output "sa_container_name" {
  description = "The name of the primary storage container"
  value       = azurerm_storage_container.sa_container.name
  sensitive   = false
}

output "sa_container_id" {
  description = "The resource ID of the primary storage container"
  value       = azurerm_storage_container.sa_container.id
  sensitive   = false
}

output "sa_details" {
  description = "Complete details of the storage account including all properties and configuration"
  value = {
    id                                = azurerm_storage_account.sa.id
    name                              = azurerm_storage_account.sa.name
    location                          = azurerm_storage_account.sa.location
    resource_group_name               = azurerm_storage_account.sa.resource_group_name
    account_tier                      = azurerm_storage_account.sa.account_tier
    account_replication_type          = azurerm_storage_account.sa.account_replication_type
    account_kind                      = azurerm_storage_account.sa.account_kind
    access_tier                       = azurerm_storage_account.sa.access_tier
    enable_https_traffic_only         = azurerm_storage_account.sa.enable_https_traffic_only
    min_tls_version                   = azurerm_storage_account.sa.min_tls_version
    public_network_access_enabled     = azurerm_storage_account.sa.public_network_access_enabled
    infrastructure_encryption_enabled = azurerm_storage_account.sa.infrastructure_encryption_enabled
    primary_blob_endpoint             = azurerm_storage_account.sa.primary_blob_endpoint
    primary_queue_endpoint            = azurerm_storage_account.sa.primary_queue_endpoint
    primary_table_endpoint            = azurerm_storage_account.sa.primary_table_endpoint
    primary_file_endpoint             = azurerm_storage_account.sa.primary_file_endpoint
    tags                              = azurerm_storage_account.sa.tags
  }
  sensitive = false
}