
#############################################################################
#                   Log Analytics Workspace
#############################################################################

resource "azurerm_log_analytics_workspace" "law" {
  name                = var.law_name 
  location            = var.law_location
  resource_group_name = var.law_rg_name
  sku                 = var.law_sku 
  retention_in_days   = var.retention_in_days
  tags                = var.tags   
}

resource "azurerm_log_analytics_linked_service" "linkAutoAcct" {
  resource_group_name = azurerm_log_analytics_workspace.law.resource_group_name
  workspace_id        = azurerm_log_analytics_workspace.law.id
  read_access_id      = var.automation_acct_id   
}


resource "azurerm_log_analytics_datasource_windows_event" "lawWE" {
  name                = "${azurerm_log_analytics_workspace.law.name}-WindowsEvents"
  resource_group_name = azurerm_log_analytics_workspace.law.resource_group_name
  workspace_name      = azurerm_log_analytics_workspace.law.name
  event_log_name      = "Application"
  event_types         = ["Error"]
}

resource "azurerm_log_analytics_datasource_windows_performance_counter" "lawWPC" {
  name                = "${azurerm_log_analytics_workspace.law.name}--windowsperfCounter"
  resource_group_name = azurerm_log_analytics_workspace.law.resource_group_name
  workspace_name      = azurerm_log_analytics_workspace.law.name
  object_name         = "CPU"
  instance_name       = "*"
  counter_name        = "CPU"
  interval_seconds    = 10
}

resource "azurerm_log_analytics_storage_insights" "analyticsStorageInsights" {
  name                = var.law_storage_insights_name
  resource_group_name = azurerm_log_analytics_workspace.law.resource_group_name
  workspace_id        = azurerm_log_analytics_workspace.law.id
  storage_account_id  = var.log_analytics_storage_insightsStorage_account_id 
  storage_account_key = var.log_analytics_storage_insightsStorage_account_key
}