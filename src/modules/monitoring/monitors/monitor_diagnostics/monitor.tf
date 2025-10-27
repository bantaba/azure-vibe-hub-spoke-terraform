resource "azurerm_monitor_diagnostic_setting" "example" {
  name               = var.name
  target_resource_id = var.target_resource_id
  storage_account_id = var.storage_account_id

  enabled_log {
    category = "AuditEvent"

    retention_policy {
      enabled = true
      days = 14
    }
  }

  metric {
    category = "AllMetrics"

    retention_policy {
      enabled = true
      days = 14
    }
  }
}