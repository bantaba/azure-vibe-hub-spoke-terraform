resource "azurerm_storage_account" "sa" { 
  name                      = lower(var.sa_name)  
  location                  = var.sa_location
  resource_group_name       = var.sa_rg_name
  account_tier              = var.account_tier
  account_kind              = var.account_kind
  account_replication_type  = var.replication_type
  enable_https_traffic_only = var.enable_https_traffic_only
  min_tls_version           = var.min_tls_version
  access_tier = var.access_tier 
  allow_nested_items_to_be_public = var.allow_nested_items_to_be_public
  infrastructure_encryption_enabled = var.infrastructure_encryption_enabled
  
  # Enhanced security configurations
  public_network_access_enabled = var.public_network_access_enabled
  default_to_oauth_authentication = var.default_to_oauth_authentication
  shared_access_key_enabled = var.shared_access_key_enabled
  
  # Network access restrictions
  dynamic "network_rules" {
    for_each = var.network_rules_enabled ? [1] : []
    content {
      default_action             = var.network_rules_default_action
      bypass                     = var.network_rules_bypass
      ip_rules                   = var.allowed_ip_ranges
      virtual_network_subnet_ids = var.allowed_subnet_ids
    }
  }
  
  # Blob properties for enhanced security
  blob_properties {
    versioning_enabled       = var.blob_versioning_enabled
    change_feed_enabled      = var.blob_change_feed_enabled
    last_access_time_enabled = var.blob_last_access_time_enabled
    
    dynamic "delete_retention_policy" {
      for_each = var.blob_delete_retention_days > 0 ? [1] : []
      content {
        days = var.blob_delete_retention_days
      }
    }
    
    dynamic "container_delete_retention_policy" {
      for_each = var.container_delete_retention_days > 0 ? [1] : []
      content {
        days = var.container_delete_retention_days
      }
    }
  }
  
  tags = var.tags 
}

resource "azurerm_storage_container" "sa_container" {
  depends_on = [  azurerm_storage_account.sa  ]
  name                 = lower(var.sa_container_name)
  storage_account_name = azurerm_storage_account.sa.name
  container_access_type = var.container_access_type
}

resource "azurerm_storage_blob" "sa_blob" { #working but actual file names being truncated
  depends_on = [  azurerm_storage_account.sa, azurerm_storage_container.sa_container  ]
  for_each               = fileset(".", "${path.module}/fileUploads/*") #TODO: check for existance first
  name                   = trim(each.key, "${path.module}/fileUploads/")
  storage_account_name   = azurerm_storage_account.sa.name
  storage_container_name = azurerm_storage_container.sa_container.name
  type                   = var.sa_blob_type
  source                 = each.key
  content_md5            = filemd5(each.key)
}

# Private endpoint for enhanced security
resource "azurerm_private_endpoint" "sa_private_endpoint" {
  count               = var.enable_private_endpoint ? 1 : 0
  name                = "${var.sa_name}-pe"
  location            = var.sa_location
  resource_group_name = var.sa_rg_name
  subnet_id           = var.private_endpoint_subnet_id

  private_service_connection {
    name                           = "${var.sa_name}-psc"
    private_connection_resource_id = azurerm_storage_account.sa.id
    subresource_names              = ["blob"]
    is_manual_connection           = false
  }

  private_dns_zone_group {
    name                 = "default"
    private_dns_zone_ids = var.private_dns_zone_ids
  }

  tags = var.tags
}
