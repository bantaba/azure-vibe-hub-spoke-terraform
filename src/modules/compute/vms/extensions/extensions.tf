

resource "azurerm_virtual_machine_extension" "GenevaMonitoringExt" {
  # depends_on = [ azurerm_virtual_machine_extension.DependencyAgentWindowsExt ]
  name                       = "GenevaMonitoring"
  for_each = var.virtual_machine_id
  virtual_machine_id         = each.value
  auto_upgrade_minor_version = true
  automatic_upgrade_enabled  = true
  publisher                  = "Microsoft.Azure.Geneva"
  type                       = "GenevaMonitoring"
  type_handler_version       = "2.5"
}

resource "azurerm_virtual_machine_extension" "IaaSAntimalwareExt" {
  name                       = "IaaSAntimalware"
  for_each = var.virtual_machine_id
  virtual_machine_id         = each.value
  auto_upgrade_minor_version = true
  automatic_upgrade_enabled  = false
  publisher                  = "Microsoft.Azure.Security"
  type                       = "IaaSAntimalware"
  type_handler_version       = "1.3"

  settings = <<SETTINGS
    { 
      "AntimalwareEnabled": true,
      "RealtimeProtectionEnabled": true,
      "ScheduledScanSettings":  {
        "isEnabled": true,
        "day": "7",
        "time": "120",
        "scanType":  "Quick"
      },
      "Exclusions": {
        "extensions": "",
        "Paths": "",
        "Processes": ""
      }       
    }
  SETTINGS

  protected_settings = <<PROTECTED_SETTINGS
    {        
    }
  PROTECTED_SETTINGS
}

resource "azurerm_virtual_machine_extension" "NetworkWatcherExt" {
  name                       = "NetworkWatcher"
  for_each = var.virtual_machine_id
  virtual_machine_id = each.value
  auto_upgrade_minor_version = true
  automatic_upgrade_enabled  = true
  publisher                  = "Microsoft.Azure.NetworkWatcher"
  type                       = "NetworkWatcherAgentWindows"
  type_handler_version       = "1.4"
}

resource "azurerm_virtual_machine_extension" "dsc" {
  name                 = "PoshDSC"  
  for_each             = var.virtual_machine_id
  virtual_machine_id   = each.value
  publisher            = "Microsoft.Powershell"
  type                 = "DSC"
  type_handler_version = "2.83"

  settings = <<SETTINGS
  {
    "configurationArguments": {
        "RegistrationUrl": "${var.dsc_server_endpoint}",
        "NodeConfigurationName": "${var.dsc_config}.localhost",
        "ConfigurationMode": "${var.dsc_mode}",
        "ConfigurationModeFrequencyMins": 15,
        "RefreshFrequencyMins": 30,
        "RebootNodeIfNeeded": true,
        "ActionAfterReboot": "continueConfiguration",
        "AllowModuleOverwrite": true
    }
  }
  SETTINGS

  protected_settings = <<PROTECTED_SETTINGS
  {
    "configurationArguments": {
        "RegistrationKey": {
                "UserName": "PLACEHOLDER_DONOTUSE",
                "Password": "${var.dsc_primary_access_key}"
              }
    }
  }
  PROTECTED_SETTINGS

  # lifecycle {
  #   ignore_changes = [ all ]
  # }
}

############################################################################
#region                   VM autoshutdown
#############################################################################
resource "azurerm_dev_test_global_vm_shutdown_schedule" "auto_shutdown" {
  for_each = var.virtual_machine_id
  virtual_machine_id = each.value
  location           = var.location
  enabled            = "${terraform.workspace}" == "dev" ? true : false

  daily_recurrence_time = "1630"
  timezone              = "Pacific Standard Time"

  notification_settings {
    enabled = false
    # time_in_minutes = "60"
    # webhook_url     = "https://sample-webhook-url.example.com"
  }
}
#endregion auto shutdown

#############################################################################
#   END EXT

/* Parking Lot


resource "azurerm_virtual_machine_extension" "GuestHealthWindowsAgentExt" {
  depends_on = [ 
    azurerm_virtual_machine_extension.DependencyAgentWindowsExt,
    azurerm_virtual_machine_extension.GenevaMonitoringExt 
  ]
  name                       = "GuestHealthWindowsAgent"
  for_each = var.virtual_machine_id
  virtual_machine_id         = each.value
  auto_upgrade_minor_version = true
  automatic_upgrade_enabled  = false
  publisher                  = "Microsoft.Azure.Monitor.VirtualMachines.GuestHealth"
  type                       = "GuestHealthWindowsAgent"
  type_handler_version       = "1.0"
}

resource "azurerm_virtual_machine_extension" "DependencyAgentWindowsExt" {
  name                       = "DependencyAgentWindows"
  for_each = var.virtual_machine_id
  virtual_machine_id         = each.value
  auto_upgrade_minor_version = true
  automatic_upgrade_enabled  = true
  publisher                  = "Microsoft.Azure.Monitoring.DependencyAgent"
  type                       = "DependencyAgentWindows"
  type_handler_version       = "9.6"

  settings = <<SETTINGS
        {
          "workspaceId": "${var.analytics_workspace_id}"
        }
  SETTINGS
 
  protected_settings = <<PROTECTED_SETTINGS
        {
          "workspaceKey": "${var.analytics_workspace_key}"
        }
  PROTECTED_SETTINGS
}




resource "azurerm_virtual_machine_extension" "AzureMonitorExt" {
  name                       = "AzureMonitorWindowsAgent"
  for_each = var.virtual_machine_id
  virtual_machine_id         = each.value
  auto_upgrade_minor_version = true
  automatic_upgrade_enabled  = true
  publisher                  = "Microsoft.Azure.Monitor"
  type                       = "AzureMonitorWindowsAgent"
  type_handler_version       = "1.11"
}

resource "azurerm_virtual_machine_extension" "BGInfoExt" {
  name                       = "BGInfo"
  for_each = var.virtual_machine_id
  virtual_machine_id         = each.value
  auto_upgrade_minor_version = true
  automatic_upgrade_enabled  = false
  publisher                  = "Microsoft.Compute"
  type                       = "BGInfo"
  type_handler_version       = "2.1"
}

resource "azurerm_virtual_machine_extension" "AzurePolicyExt" {
  name                       = "AzurePolicyforWindows"
  for_each = var.virtual_machine_id
  virtual_machine_id         = each.value
  auto_upgrade_minor_version = true
  automatic_upgrade_enabled  = true
  publisher                  = "Microsoft.GuestConfiguration"
  type                       = "ConfigurationforWindows" 
  type_handler_version       = "1.0"
}

resource "azurerm_virtual_machine_extension" "KeyVaultExtensionForWindows" {
  name                       = "KeyVaultForWindows"
  for_each = var.virtual_machine_id
  virtual_machine_id         = each.value
  auto_upgrade_minor_version = true
  automatic_upgrade_enabled  = false
  publisher                  = "Microsoft.azure.keyvault"
  type                       = "KeyVaultForWindows"
  type_handler_version       = "1.0"
  settings = <<SETTINGS
      {
        "secretsManagementSettings": {
        "pollingIntervalInS": "3600",
        "certificateStoreName": "MY",
        "linkOnRenewal":  true,
        "certificateStoreLocation": "LocalMachine",
        "requireInitialSync": true,
        "observedCertificates": ["${var.vault_observed_certificate}"] 
        }
      }
  SETTINGS

  protected_settings = <<PROTECTED_SETTINGS
    { }
  PROTECTED_SETTINGS
}


resource "azurerm_virtual_machine_extension" "domain-join" {
  name = "domainJoin"
  depends_on = [
    azurerm_virtual_machine_extension.AzureMonitorExt,
    azurerm_virtual_machine_extension.BGInfoExt,
    azurerm_virtual_machine_extension.IaaSAntimalwareExt,
    azurerm_virtual_machine_extension.AzurePolicyExt,
    azurerm_virtual_machine_extension.KeyVaultExtensionForWindows,
    azurerm_dev_test_global_vm_shutdown_schedule.auto_shutdown
  ]
  for_each = var.virtual_machine_id
  virtual_machine_id = each.value
  publisher = "Microsoft.Compute"
  type = "JsonADDomainExtension"
  type_handler_version = "1.3"

  settings = <<SETTINGS
    {
        "Name": "${var.active_directory_domain}",
        "OUPath": "${var.ou_path != null ? var.ou_path : ""}",
        "User": "${var.active_directory_username}@${var.active_directory_domain}",
        "Restart": "true",
        "Options": "3"
    }
  SETTINGS

  protected_settings = <<PROTECTED_SETTINGS
    {
        "Password": "${var.active_directory_password}"
    }
  PROTECTED_SETTINGS  
}

#####################
resource "azurerm_virtual_machine_extension" "CustomScriptExt" { # Use AA DSC instead
  name                 = "CustomScriptExtension"
  for_each             = var.virtual_machine_id
  virtual_machine_id   = each.value
  publisher            = "Microsoft.Compute" 
  automatic_upgrade_enabled = false
  auto_upgrade_minor_version = true
  type                 = "CustomScriptExtension"
  type_handler_version = "1.10"

  protected_settings = <<PROTECTED_SETTINGS
      {
          "commandToExecute": "powershell -ExecutionPolicy Unrestricted -file DeployAzSecPack.ps1",
          "storageAccountName": "${var.storage_acct_name}",
          "storageAccountKey": "${var.storage_acct_key}",
          "fileUris": [
          "https://${var.storage_acct_name}.blob.core.windows.net/test-scripts/DeployAzSecPack.ps1"
        ]
      }
  PROTECTED_SETTINGS
}


*/
