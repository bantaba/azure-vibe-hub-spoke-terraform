

#############################################################################
#      ################### Creates KV resource         
#############################################################################
resource "azurerm_key_vault" "main-kv" {
  name                = var.vault_name  
  location            = var.vault_location 
  resource_group_name = var.vault_rg_name
  sku_name            = var.sku_name
  enable_rbac_authorization       = var.enable_rbac_authorization
  enabled_for_deployment          = var.enabled_for_deployment
  enabled_for_disk_encryption     = var.enabled_for_disk_encryption
  enabled_for_template_deployment = var.enabled_for_template_deployment
  purge_protection_enabled        = var.purge_protection_enabled
  soft_delete_retention_days      = var.soft_delete_retention_days
  tenant_id                       = var.tenant_id

  # Enhanced security settings
  public_network_access_enabled = var.public_network_access_enabled
  
  network_acls { 
    bypass         = var.network_acls_bypass  
    default_action = var.network_acls_default_action  
    ip_rules = var.allowed_ip_ranges
    virtual_network_subnet_ids = var.virtual_network_subnet_ids  
  }

  tags = merge(var.tags, {
    SecurityLevel = "Enhanced"
    LastUpdated   = timestamp()
  })
}

# Private endpoint for Key Vault
resource "azurerm_private_endpoint" "kv_private_endpoint" {
  count               = var.enable_private_endpoint ? 1 : 0
  name                = "${var.vault_name}-pe"
  location            = var.vault_location
  resource_group_name = var.vault_rg_name
  subnet_id           = var.private_endpoint_subnet_id

  private_service_connection {
    name                           = "${var.vault_name}-psc"
    private_connection_resource_id = azurerm_key_vault.main-kv.id
    subresource_names              = ["vault"]
    is_manual_connection           = false
  }

  private_dns_zone_group {
    name                 = "default"
    private_dns_zone_ids = var.private_dns_zone_ids
  }

  tags = var.tags
}

# Diagnostic settings for Key Vault
resource "azurerm_monitor_diagnostic_setting" "kv_diagnostics" {
  count              = var.enable_diagnostic_settings ? 1 : 0
  name               = "${var.vault_name}-diagnostics"
  target_resource_id = azurerm_key_vault.main-kv.id
  log_analytics_workspace_id = var.log_analytics_workspace_id

  enabled_log {
    category = "AuditEvent"
  }

  enabled_log {
    category = "AzurePolicyEvaluationDetails"
  }

  metric {
    category = "AllMetrics"
    enabled  = true
  }
}

# Key Vault access policy for managed identity (if RBAC is disabled)
resource "azurerm_key_vault_access_policy" "managed_identity_policy" {
  count        = var.enable_rbac_authorization ? 0 : (var.managed_identity_object_id != null ? 1 : 0)
  key_vault_id = azurerm_key_vault.main-kv.id
  tenant_id    = var.tenant_id
  object_id    = var.managed_identity_object_id

  key_permissions = var.managed_identity_key_permissions
  secret_permissions = var.managed_identity_secret_permissions
  certificate_permissions = var.managed_identity_certificate_permissions
}