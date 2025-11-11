
output "law_key" {
  value     = azurerm_log_analytics_workspace.law.primary_shared_key
  sensitive = true
}

output "law_resource_id" {
  value = azurerm_log_analytics_workspace.law.id
}

output "law_region" {
  value = azurerm_log_analytics_workspace.law.location
}

output "law_id" {
  value = azurerm_log_analytics_workspace.law.workspace_id
}

output "law_name" {
  value = azurerm_log_analytics_workspace.law.name
}
