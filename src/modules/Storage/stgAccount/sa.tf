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
