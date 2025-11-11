
data "local_file" "start_vm_by_tags" {
  filename = "${path.module}/startVMbyTag.ps1"
}


resource "azurerm_automation_account" "automationAcct" {
  name                = var.aa_name
  location            = var.aa_location
  resource_group_name = var.aa_rg
  sku_name            = var.sku_name
  identity {
    type = "SystemAssigned"
    # identity_ids = [ "value" ]
  }
  # public_network_access_enabled = "false"
  # encryption {
  #   key_vault_key_id = "value"
  #   user_assigned_identity_id = "value"
  # }

  tags = var.tags
}

resource "azurerm_automation_runbook" "vm_start_runbook" {
  name                    = "Start-AzureVM"
  location                = azurerm_automation_account.automationAcct.location
  resource_group_name     = azurerm_automation_account.automationAcct.resource_group_name
  automation_account_name = azurerm_automation_account.automationAcct.name
  log_progress            = true
  log_verbose             = true
  runbook_type            = "PowerShell"
  content                 = data.local_file.start_vm_by_tags.content
  description             = "This runbook starts an Azure VM"

  # publish_content_link { }
}


resource "azurerm_automation_schedule" "scheduledstartvm" {
  name                    = "StartVM"
  resource_group_name     = azurerm_automation_account.automationAcct.resource_group_name
  automation_account_name = azurerm_automation_account.automationAcct.name
  frequency               = var.frequency
  interval                = var.interval
  timezone                = var.timezone
  start_time              = var.start_time
  week_days               = ["Monday", "Tuesday", "Wednesday", "Thursday", "Friday"]
  description             = "Runs daily M-F"
}

resource "azurerm_automation_job_schedule" "startvm_sched" {
  resource_group_name     = azurerm_automation_account.automationAcct.resource_group_name
  automation_account_name = azurerm_automation_account.automationAcct.name
  schedule_name           = azurerm_automation_schedule.scheduledstartvm.name
  runbook_name            = azurerm_automation_runbook.vm_start_runbook.name
  parameters = {
    action = "Start"
  }
  depends_on = [azurerm_automation_schedule.scheduledstartvm]
}

data "local_file" "sqlconfig" {
  filename = "${path.module}/dsc/SqlConfig.ps1"
}

resource "azurerm_automation_dsc_configuration" "dsc_sql_config" {
  name                    = "SQLConfig"
  resource_group_name     = azurerm_automation_account.automationAcct.resource_group_name
  automation_account_name = azurerm_automation_account.automationAcct.name
  location                = azurerm_automation_account.automationAcct.location
  log_verbose             = true
  tags                    = var.tags
  content_embedded        = data.local_file.sqlconfig.content
}

resource "azurerm_automation_dsc_configuration" "dc_config" {
  name                    = "DC"
  resource_group_name     = azurerm_automation_account.automationAcct.resource_group_name
  automation_account_name = azurerm_automation_account.automationAcct.name
  location                = azurerm_automation_account.automationAcct.location
  log_verbose             = true
  tags                    = var.tags
  content_embedded        = file("${path.module}/dsc/dc.ps1")
}

resource "azurerm_automation_dsc_configuration" "geneva_monitoring_config" {
  name                    = "GenevaMonitoring"
  resource_group_name     = azurerm_automation_account.automationAcct.resource_group_name
  automation_account_name = azurerm_automation_account.automationAcct.name
  location                = azurerm_automation_account.automationAcct.location
  log_verbose             = true
  tags                    = var.tags
  content_embedded        = file("${path.module}/dsc/GenevaMonitoring.ps1")
}

resource "azurerm_automation_dsc_configuration" "iis_config" {
  name                    = "WebServerConfiguration"
  resource_group_name     = azurerm_automation_account.automationAcct.resource_group_name
  automation_account_name = azurerm_automation_account.automationAcct.name
  location                = azurerm_automation_account.automationAcct.location
  log_verbose             = true
  tags                    = var.tags
  content_embedded        = file("${path.module}/dsc/iis_config.ps1")
}

resource "azurerm_automation_credential" "domain_admin" {
  name                    = "domainAdmin"
  resource_group_name     = azurerm_automation_account.automationAcct.resource_group_name
  automation_account_name = azurerm_automation_account.automationAcct.name
  username                = var.domain_admin_username
  password                = var.domain_admin_pwd
  description             = "domain admin creds"
}

resource "azurerm_automation_credential" "domain_safemode_pwd" {
  name                    = "domainSafeModePwd"
  resource_group_name     = azurerm_automation_account.automationAcct.resource_group_name
  automation_account_name = azurerm_automation_account.automationAcct.name
  username                = var.domain_admin_username
  password                = var.domain_safe_mode_pwd
  description             = "domain controller safe mode creds"
}

resource "azurerm_automation_variable_string" "domainName" {
  name                    = "domainName"
  resource_group_name     = azurerm_automation_account.automationAcct.resource_group_name
  automation_account_name = azurerm_automation_account.automationAcct.name
  value                   = "jamano.live"
  encrypted               = true
}
resource "azurerm_automation_variable_string" "domainDN" {
  name                    = "domainDN"
  resource_group_name     = azurerm_automation_account.automationAcct.resource_group_name
  automation_account_name = azurerm_automation_account.automationAcct.name
  value                   = "dc=jamano,dc=live"
  encrypted               = true
}


resource "azurerm_automation_credential" "local_admin" {
  name                    = "DefaultUserPwd"
  resource_group_name     = azurerm_automation_account.automationAcct.resource_group_name
  automation_account_name = azurerm_automation_account.automationAcct.name
  username                = var.user_default_username
  password                = var.user_default_pwd
  description             = "Setting up new user default password."
}

/*
resource "azurerm_automation_dsc_configuration" "Geneva_monitoring_config" {
  name                    = "GenevaMonitoring" 
  resource_group_name     = azurerm_automation_account.automationAcct.resource_group_name 
  automation_account_name = azurerm_automation_account.automationAcct.name  
  location                = azurerm_automation_account.automationAcct.location
  log_verbose             = true
  tags                    = var.tags
  content_embedded        = file("${path.module}/dsc/GenevaMonitoring.ps1")
}

resource "azurerm_automation_dsc_configuration" "dsc_base_config" {
  name                    = "Basic" #var.dsc_config_name 
  resource_group_name     = azurerm_automation_account.automationAcct.resource_group_name #var.dsc_config_rg_name
  automation_account_name = azurerm_automation_account.automationAcct.name  
  location                = azurerm_automation_account.automationAcct.location
  log_verbose = true
  tags = var.tags
  content_embedded        = file("${path.module}/dsc/basictest.ps1") 
}
*/