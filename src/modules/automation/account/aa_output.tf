output "automationAcct_id" {
  value = azurerm_automation_account.automationAcct.id
}

output "automationAcct_identity" {
  value       = azurerm_automation_account.automationAcct.identity
  description = ""
}

output "automation_object_id" {
  value       = azurerm_automation_account.automationAcct.identity[0].principal_id
  sensitive   = true
  description = "The Principal ID associated with this Managed Service Identity."
}
output "automation_acct_primary_access_key" {
  value       = azurerm_automation_account.automationAcct.dsc_primary_access_key
  description = "The Primary Access Key for the DSC Endpoint associated with this Automation Account."
  sensitive   = true
}

output "dsc_secondary_access_key" {
  value       = azurerm_automation_account.automationAcct.dsc_secondary_access_key
  sensitive   = true
  description = "The Secondary Access Key for the DSC Endpoint associated with this Automation Account."
}

output "dsc_server_endpoint" {
  value       = azurerm_automation_account.automationAcct.dsc_server_endpoint
  description = "The DSC Server Endpoint associated with this Automation Account."
}

output "hybrid_service_url" {
  value       = azurerm_automation_account.automationAcct.hybrid_service_url
  description = "The URL of automation hybrid service which is used for hybrid worker on-boarding With this Automation Account."
}

output "dsc_dc_config" {
  value       = azurerm_automation_dsc_configuration.dc_config.name
  description = ""
}


output "dsc_sqlConfig" {
  value       = azurerm_automation_dsc_configuration.dsc_sql_config.name
  description = ""
}

output "dsc_dc_confiwg" {
  value       = azurerm_automation_dsc_configuration.dc_config.content_embedded
  description = ""
}

output "dsc_geneva_monitoring_config" {
  value       = azurerm_automation_dsc_configuration.geneva_monitoring_config.name
  description = ""
}

output "dsc_iis_config" {
  value       = azurerm_automation_dsc_configuration.iis_config.name
  description = ""
}