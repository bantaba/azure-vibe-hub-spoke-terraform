

#############################################################################
#      ################### Creates KV resource         
#############################################################################
resource "azurerm_key_vault" "main-kv" {
  name                = var.vault_name  
  location            = var.vault_location 
  resource_group_name = var.vault_rg_name
  sku_name            = var.sku_name
  enable_rbac_authorization       = true
  enabled_for_deployment          = true
  enabled_for_disk_encryption     = true
  enabled_for_template_deployment = true
  purge_protection_enabled        = var.purge_protection_enabled
  soft_delete_retention_days      = var.soft_delete_retention_days
  tenant_id                       = var.tenant_id

  public_network_access_enabled = var.public_network_access_enabled
  network_acls { 
    bypass         = var.network_acls_bypass  
    default_action = var.network_acls_default_action  
    ip_rules = var.allowed_ip_ranges
    virtual_network_subnet_ids = var.virtual_network_subnet_ids  
  }

  tags = var.tags 
}