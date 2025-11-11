
resource "azurerm_mssql_virtual_machine" "sql_vm" {
  for_each              = var.virtual_machine_ids
  sql_license_type      = var.sql_license_type
  virtual_machine_id    = each.value
  r_services_enabled    = var.r_services_enabled
  sql_connectivity_port = var.sql_connectivity_port
  sql_connectivity_type = var.sql_connectivity_type

  sql_instance {
    max_dop                              = var.max_dop
    collation                            = var.collation
    min_server_memory_mb                 = var.min_server_memory_mb
    max_server_memory_mb                 = var.max_server_memory_mb
    adhoc_workloads_optimization_enabled = var.adhoc_workloads_optimization_enabled
    instant_file_initialization_enabled  = var.instant_file_initialization_enabled
    lock_pages_in_memory_enabled         = var.lock_pages_in_memory_enabled
  }

  assessment {
    enabled         = var.enable_assessment
    run_immediately = var.run_assessment

    schedule {
      monthly_occurrence = 1
      day_of_week        = "Wednesday"
      start_time         = "22:00"

    }
  }

  auto_patching {
    day_of_week                            = var.patch_day_of_week
    maintenance_window_duration_in_minutes = var.patch_duration
    maintenance_window_starting_hour       = var.patch_maint_window
  }

  storage_configuration {
    disk_type                      = var.storage_disk_type
    storage_workload_type          = var.storage_workload_type
    system_db_on_data_disk_enabled = true

    data_settings {
      default_file_path = "H:\\MSSQL\\DATA"
      luns              = var.data_lun
    }

    log_settings {
      default_file_path = "O:\\MSSQL\\DATA"
      luns              = var.log_lun
    }

    temp_db_settings {
      data_file_count        = var.data_file_count
      data_file_growth_in_mb = var.data_file_growth_in_mb
      data_file_size_mb      = var.data_file_size_mb
      default_file_path      = "T:\\MSSQL\\DATA"
      log_file_growth_mb     = var.log_file_growth_mb
      log_file_size_mb       = var.log_file_size_mb
      luns                   = var.tempdb_log_lun
    }
  }

  # key_vault_credential {
  #   key_vault_url = var.kvault_url
  #   name = var.kv_name
  #   service_principal_name = var.service_principal_name
  #   service_principal_secret = var.service_principal_secret
  # }

  auto_backup {
    encryption_enabled              = var.encryption_enabled
    retention_period_in_days        = var.retention_period_in_days
    system_databases_backup_enabled = true
    storage_account_access_key      = var.storage_account_access_key
    storage_blob_endpoint           = var.storage_blob_endpoint

    manual_schedule {
      full_backup_frequency           = var.full_backup_frequency
      full_backup_start_hour          = var.full_backup_start_hour
      full_backup_window_in_hours     = var.full_backup_window_in_hours
      log_backup_frequency_in_minutes = var.log_backup_frequency_in_minutes
    }
  }
}