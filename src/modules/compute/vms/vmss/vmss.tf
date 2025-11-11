resource "azurerm_windows_virtual_machine_scale_set" "vmss" {
  name                         = var.vmss_name
  resource_group_name          = var.vmss_rg_name
  location                     = var.vmss_location
  sku                          = var.sku
  upgrade_mode                 = var.upgrade_mode
  instances                    = var.instances
  admin_username               = var.admin_user_name
  admin_password               = var.admin_user_password
  extension_operations_enabled = true
  platform_fault_domain_count  = var.platform_fault_domain_count
  provision_vm_agent           = true
  vtpm_enabled                 = false
  enable_automatic_updates     = false
  encryption_at_host_enabled   = false
  secure_boot_enabled          = true

  # automatic_instance_repair {#"Automatic repairs not supported for this Virtual Machine Scale Set because a health probe or health extension was not provided."
  #   enabled = false
  #   grace_period = "10"
  # }

  #TODO: To be implemented in a future iteration
  # rolling_upgrade_policy {  # rolling_upgrade_policy` block must be specified when `upgrade_mode` is set to "Rolling
  #   cross_zone_upgrades_enabled = 
  #   max_batch_instance_percent = 
  #   max_unhealthy_instance_percent = 
  #   max_unhealthy_upgraded_instance_percent = 
  #   pause_time_between_batches = 
  #   prioritize_unhealthy_instances_enabled = 
  # } # rolling_upgrade_policy` block must be specified when `upgrade_mode` is set to "Rolling

  automatic_os_upgrade_policy { #Automatic OS Upgrade is not supported for this Virtual Machine Scale Set because a health probe or health extension was not specified."
    enable_automatic_os_upgrade = false
    disable_automatic_rollback  = false #Microsoft.Compute/EncryptionAtHost' feature is not enabled for this subscription
  }

  identity {
    type         = "UserAssigned"
    identity_ids = ["${var.user_managed_identity_id}"]
  }

  source_image_reference {
    publisher = "MicrosoftWindowsServer"
    offer     = "WindowsServer"
    sku       = "2022-datacenter-azure-edition"
    version   = "latest"
  }

  os_disk {
    storage_account_type = "Standard_LRS"
    caching              = "ReadWrite"
  }

  network_interface {
    name    = "${var.vmss_name}nic"
    primary = true

    ip_configuration {
      name      = "internal"
      primary   = true
      subnet_id = var.vmss_ipConfig_subnet_id
    }
  }

  tags = var.tags
}


resource "azurerm_monitor_autoscale_setting" "vmss_auto_scale" {
  name                = "${azurerm_windows_virtual_machine_scale_set.vmss.name}myAutoscaleSetting"
  resource_group_name = azurerm_windows_virtual_machine_scale_set.vmss.resource_group_name
  location            = azurerm_windows_virtual_machine_scale_set.vmss.location
  target_resource_id  = azurerm_windows_virtual_machine_scale_set.vmss.id

  profile {
    name = "${title(terraform.workspace)}DefaultProfile"

    capacity {
      default = 2  #auto_scale_default
      minimum = 2  #auto_scale_min
      maximum = 10 #auto_scale_max
    }

    rule {
      metric_trigger {
        metric_name        = "Percentage CPU"
        metric_resource_id = azurerm_windows_virtual_machine_scale_set.vmss.id
        time_grain         = "PT1M"
        statistic          = "Average"
        time_window        = "PT5M"
        time_aggregation   = "Average"
        operator           = "GreaterThan"
        threshold          = 75
        metric_namespace   = "microsoft.compute/virtualmachinescalesets"
        dimensions {
          name     = "AppName"
          operator = "Equals"
          values   = ["App1"]
        }
      }

      scale_action {
        direction = "Increase"
        type      = "ChangeCount"
        value     = "1" #scale_in_interval
        cooldown  = "PT1M"
      }
    }

    rule {
      metric_trigger {
        metric_name        = "Percentage CPU"
        metric_resource_id = azurerm_windows_virtual_machine_scale_set.vmss.id
        time_grain         = "PT1M"
        statistic          = "Average"
        time_window        = "PT5M"
        time_aggregation   = "Average"
        operator           = "LessThan"
        threshold          = 25
      }

      scale_action {
        direction = "Decrease"
        type      = "ChangeCount"
        value     = "1" #scale_out_interval
        cooldown  = "PT1M"
      }
    }
  }

  notification {
    email {
      send_to_subscription_administrator    = false
      send_to_subscription_co_administrator = false
      custom_emails                         = ["admin@me.io"]
    }
  }

  depends_on = [
    azurerm_windows_virtual_machine_scale_set.vmss
  ]
}


############################################################################
#  END vmss

#region vmss ext

resource "azurerm_virtual_machine_scale_set_extension" "BGInfoExt" {
  depends_on                   = [azurerm_windows_virtual_machine_scale_set.vmss]
  name                         = "BGInfoExt"
  virtual_machine_scale_set_id = azurerm_windows_virtual_machine_scale_set.vmss.id
  publisher                    = "Microsoft.Compute"
  type                         = "BGInfo"
  type_handler_version         = "2.1"
}

resource "azurerm_virtual_machine_scale_set_extension" "DependencyAgentWindowsExt" {
  depends_on = [azurerm_windows_virtual_machine_scale_set.vmss]
  name       = "DependencyAgentWindows"

  virtual_machine_scale_set_id = azurerm_windows_virtual_machine_scale_set.vmss.id
  auto_upgrade_minor_version   = true
  automatic_upgrade_enabled    = true
  publisher                    = "Microsoft.Azure.Monitoring.DependencyAgent"
  type                         = "DependencyAgentWindows"
  type_handler_version         = "9.6"

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

resource "azurerm_virtual_machine_scale_set_extension" "AzureMonitorExt" {
  depends_on = [
    azurerm_windows_virtual_machine_scale_set.vmss,
    azurerm_virtual_machine_scale_set_extension.DependencyAgentWindowsExt
  ]
  name = "AzureMonitorWindowsAgent"

  virtual_machine_scale_set_id = azurerm_windows_virtual_machine_scale_set.vmss.id
  auto_upgrade_minor_version   = true
  automatic_upgrade_enabled    = true
  publisher                    = "Microsoft.Azure.Monitor"
  type                         = "AzureMonitorWindowsAgent"
  type_handler_version         = "1.11"
}

resource "azurerm_virtual_machine_scale_set_extension" "CustomScriptExt" {
  depends_on = [
    azurerm_windows_virtual_machine_scale_set.vmss,
    azurerm_virtual_machine_scale_set_extension.DependencyAgentWindowsExt,
    azurerm_virtual_machine_scale_set_extension.AzureMonitorExt
  ]
  name                         = "CustomScriptExtension"
  virtual_machine_scale_set_id = azurerm_windows_virtual_machine_scale_set.vmss.id
  publisher                    = "Microsoft.Compute"
  auto_upgrade_minor_version   = true
  type                         = "CustomScriptExtension"
  type_handler_version         = "1.10"

  settings = <<SETTINGS
        {}
  SETTINGS

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

resource "azurerm_virtual_machine_scale_set_extension" "GenevaMonitoringExt" {
  depends_on = [
    azurerm_windows_virtual_machine_scale_set.vmss,
    azurerm_virtual_machine_scale_set_extension.DependencyAgentWindowsExt,
    azurerm_virtual_machine_scale_set_extension.AzureMonitorExt,
    azurerm_virtual_machine_scale_set_extension.CustomScriptExt
  ]
  name                         = "GenevaMonitoring"
  virtual_machine_scale_set_id = azurerm_windows_virtual_machine_scale_set.vmss.id
  auto_upgrade_minor_version   = true
  automatic_upgrade_enabled    = true
  publisher                    = "Microsoft.Azure.Geneva"
  type                         = "GenevaMonitoring"
  type_handler_version         = "2.5"
}


resource "azurerm_virtual_machine_scale_set_extension" "IaaSAntimalwareExt" {
  depends_on = [
    azurerm_windows_virtual_machine_scale_set.vmss,
    azurerm_virtual_machine_scale_set_extension.DependencyAgentWindowsExt,
    azurerm_virtual_machine_scale_set_extension.AzureMonitorExt,
    azurerm_virtual_machine_scale_set_extension.CustomScriptExt,
    azurerm_virtual_machine_scale_set_extension.GenevaMonitoringExt
  ]
  name                         = "IaaSAntimalware"
  virtual_machine_scale_set_id = azurerm_windows_virtual_machine_scale_set.vmss.id
  auto_upgrade_minor_version   = true
  automatic_upgrade_enabled    = false
  publisher                    = "Microsoft.Azure.Security"
  type                         = "IaaSAntimalware"
  type_handler_version         = "1.3"

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

resource "azurerm_virtual_machine_scale_set_extension" "AzurePolicyExt" {
  depends_on = [
    azurerm_windows_virtual_machine_scale_set.vmss,
    azurerm_virtual_machine_scale_set_extension.DependencyAgentWindowsExt,
    azurerm_virtual_machine_scale_set_extension.AzureMonitorExt,
    azurerm_virtual_machine_scale_set_extension.CustomScriptExt,
    azurerm_virtual_machine_scale_set_extension.GenevaMonitoringExt,
    azurerm_virtual_machine_scale_set_extension.IaaSAntimalwareExt,
    azurerm_virtual_machine_scale_set_extension.BGInfoExt
  ]
  name                         = "AzurePolicyforWindows"
  virtual_machine_scale_set_id = azurerm_windows_virtual_machine_scale_set.vmss.id
  auto_upgrade_minor_version   = true
  automatic_upgrade_enabled    = true
  publisher                    = "Microsoft.GuestConfiguration"
  type                         = "ConfigurationforWindows"
  type_handler_version         = "1.0"
}

resource "azurerm_virtual_machine_scale_set_extension" "GuestHealthWindowsAgentExt" {
  depends_on                   = [azurerm_windows_virtual_machine_scale_set.vmss]
  name                         = "GuestHealthWindowsAgent"
  virtual_machine_scale_set_id = azurerm_windows_virtual_machine_scale_set.vmss.id
  auto_upgrade_minor_version   = true
  automatic_upgrade_enabled    = false
  publisher                    = "Microsoft.Azure.Monitor.VirtualMachines.GuestHealth"
  type                         = "GuestHealthWindowsAgent"
  type_handler_version         = "1.0"
}

resource "azurerm_virtual_machine_scale_set_extension" "KeyVaultExtensionForWindows" {
  depends_on = [
    azurerm_windows_virtual_machine_scale_set.vmss,
    azurerm_virtual_machine_scale_set_extension.DependencyAgentWindowsExt,
    azurerm_virtual_machine_scale_set_extension.AzureMonitorExt,
    azurerm_virtual_machine_scale_set_extension.CustomScriptExt,
    azurerm_virtual_machine_scale_set_extension.GenevaMonitoringExt,
    azurerm_virtual_machine_scale_set_extension.IaaSAntimalwareExt,
    azurerm_virtual_machine_scale_set_extension.BGInfoExt,
    azurerm_virtual_machine_scale_set_extension.AzurePolicyExt
  ]

  name                         = "KeyVaultForWindows"
  virtual_machine_scale_set_id = azurerm_windows_virtual_machine_scale_set.vmss.id
  auto_upgrade_minor_version   = true
  automatic_upgrade_enabled    = true
  publisher                    = "Microsoft.azure.keyvault"
  type                         = "KeyVaultForWindows"
  type_handler_version         = "1.0"
  settings                     = <<SETTINGS
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

resource "azurerm_virtual_machine_scale_set_extension" "domain-join" {
  name = "domainJoin"
  depends_on = [
    azurerm_virtual_machine_scale_set_extension.CustomScriptExt,
    azurerm_virtual_machine_scale_set_extension.AzureMonitorExt,
    azurerm_virtual_machine_scale_set_extension.BGInfoExt,
    azurerm_virtual_machine_scale_set_extension.IaaSAntimalwareExt,
    azurerm_virtual_machine_scale_set_extension.AzurePolicyExt,
    azurerm_virtual_machine_scale_set_extension.GuestHealthWindowsAgentExt,
    azurerm_virtual_machine_scale_set_extension.KeyVaultExtensionForWindows
  ]

  virtual_machine_scale_set_id = azurerm_windows_virtual_machine_scale_set.vmss.id
  publisher                    = "Microsoft.Compute"
  type                         = "JsonADDomainExtension"
  type_handler_version         = "1.3"

  settings = <<SETTINGS
    {
        "Name": "${var.active_directory_domain}",
        "OUPath": "${var.ou_path != null ? var.ou_path : ""}",
        "User": "${var.active_directory_username}@${var.active_directory_domain}",
        "Restart": "true",
        "Options": "3"
    }
SETTINGS

  protected_settings = <<SETTINGS
    {
        "Password": "${var.active_directory_password}"
    }
SETTINGS  
}

/* TODO: later


endregion vmss ext


############################################################################
                  VM autoshutdown
############################################################################
resource "azurerm_dev_test_global_vm_shutdown_schedule" "autoShutdown" {
  virtual_machine_id = azurerm_windows_virtual_machine_scale_set.vmss.id
  location           = azurerm_windows_virtual_machine_scale_set.vmss.location
  enabled            = true

  daily_recurrence_time = "1800"
  timezone              = "Pacific Standard Time"

  notification_settings {
    enabled = false
    # time_in_minutes = "60"
    # webhook_url     = "https://sample-webhook-url.example.com"
  }
}
*/
#############################################################################
#   END autoShutdown

