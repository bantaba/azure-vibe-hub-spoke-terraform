
variable "sql_license_type" {
    type = string
    default = "PAYG"
    description = "The SQL Server license type. Possible values are AHUB (Azure Hybrid Benefit), DR (Disaster Recovery), and PAYG (Pay-As-You-Go). "
}

variable "virtual_machine_ids" {
    type = set(string)
    description = "The ID(s) of the Virtual Machine."
}

variable "r_services_enabled" {
    type = bool
    default = true
    description = "Should R Services be enabled?"
}

variable "sql_connectivity_port" {
    type = number
    default = 1433
    description = "The SQL Server port. Defaults to 1433."
}

variable "sql_connectivity_type" {
    type = string
    default = "PRIVATE"
    description = "The connectivity type used for this SQL Server. Possible values are LOCAL, PRIVATE and PUBLIC. Defaults to PRIVATE."
}

variable "max_dop" {
    type = number
    default = 0
    description = "Maximum Degree of Parallelism of the SQL Server. Possible values are between 0 and 32767. Defaults to 0."
}

variable "collation" {
    type = string
    default = "SQL_Latin1_General_CP1_CI_AS"
    description = "Collation of the SQL Server. Defaults to SQL_Latin1_General_CP1_CI_AS."
}

variable "min_server_memory_mb" {
    type = number
    default = 0
    description = "Minimum amount memory that SQL Server Memory Manager can allocate to the SQL Server process. Possible values are between 0 and 2147483647 Defaults to 0."
}

variable "max_server_memory_mb" { # TODO validate: max_server_memory_mb must be greater than or equal to min_server_memory_mb
    type = number
    default = 2147483647
    description = "Maximum amount memory that SQL Server Memory Manager can allocate to the SQL Server process. Possible values are between 128 and 2147483647 Defaults to 2147483647."
}

variable "adhoc_workloads_optimization_enabled" {
    type = bool
    default = false
    description = "Specifies if the SQL Server is optimized for adhoc workloads. Possible values are true and false. Defaults to false."
}

variable "instant_file_initialization_enabled" {
    type = bool
    default = false
    description = "Specifies if Instant File Initialization is enabled for the SQL Server. Possible values are true and false. Defaults to false."
}

variable "enable_assessment" {
    type = bool
    default = true
    description = "Should Assessment be enabled? Defaults to true."
}

variable "lock_pages_in_memory_enabled" {
    type = bool
    default = false
    description = ") Specifies if Lock Pages in Memory is enabled for the SQL Server. Possible values are true and false. Defaults to false."
}

variable "run_assessment" {
    type = bool
    default = true
    description = "Should Assessment be run immediately? Defaults to false."
}

variable "patch_maint_window" {
    type = number
    default = 2
    description = "The Hour, in the Virtual Machine Time-Zone when the patching maintenance window should begin."
}

variable "patch_day_of_week" {
    type = string
    default = "Monday"
    description = "The day of week to apply the patch on. Possible values are Monday, Tuesday, Wednesday, Thursday, Friday, Saturday and Sunday."
}

variable "patch_duration" {
    type = number
    default = 90
    description = "The size of the Maintenance Window in minutes."
}

variable "data_lun" {
    type = list(number)
    nullable = false
    description = "The Logical Unit Numbers for the disk(s) to be assigned to the SQL data disk."
}

variable "log_lun" {
    type = list(number)
    nullable = false
    description = "The Logical Unit Numbers for the disk(s) to be assigned to the SQL log data disk."
}

variable "tempdb_log_lun" {
    type = list(number)
    nullable = false
    description = "The Logical Unit Numbers for the disk(s) to be assigned to the SQL tempdb data disk."
}

variable "storage_disk_type" {
    type = string
    default = "NEW"
    description = "The type of disk configuration to apply to the SQL Server. Valid values include NEW, EXTEND, or ADD."
}

variable "data_file_count" {
    type = number
    default = 8
    description = "The SQL Server default file count. This value defaults to 8"
}

variable "storage_workload_type" {
    type = string
    default = "OLTP"
    description = "The type of storage workload. Valid values include GENERAL, OLTP, or DW."
}

variable "data_file_growth_in_mb" {
    type = number
    default = 512
    description = "The SQL Server default file size - This value defaults to 512"
}
variable "data_file_size_mb" {
    type = number
    default = 256
    description = "The SQL Server default file size - This value defaults to 256"
}

variable "log_file_growth_mb" {
    type = number
    default = 512
    description = "The SQL Server default file size - This value defaults to 512"
}

variable "log_file_size_mb" {
    type = number
    default = 256
    description = "The SQL Server default file size - This value defaults to 256"
}

# variable "encryption_password" {
#     type = string
#     sensitive = true
#     nullable = true
#     description = "Encryption password to use. Must be specified when encryption is enabled."
# }

variable "encryption_enabled" {
    type = bool
    default = false
    description = " Enable or disable encryption for backups. Defaults to false."
}

variable "retention_period_in_days" {
    type = number
    default = 30
    description = " Retention period of backups, in days. Valid values are from 1 to 30."
}

variable "storage_account_access_key" {
    type = string
    description = "Access key for the storage account where backups will be kept."
}

variable "storage_blob_endpoint" {
    type = string
    description = "Blob endpoint for the storage account where backups will be kept."
}

variable "full_backup_frequency" {
    type = string
    default = "Daily"
    description = "Frequency of full backups. Valid values include Daily or Weekly."
}
variable "full_backup_start_hour" {
    type = number
    default = 20
    description = "Start hour of a given day during which full backups can take place. Valid values are from 0 to 23."
}
variable "full_backup_window_in_hours" {
    type = number
    default = 2
    description = "Duration of the time window of a given day during which full backups can take place, in hours. Valid values are between 1 and 23."
}
variable "log_backup_frequency_in_minutes" {
    type = number
    default = 60
    description = "Frequency of log backups, in minutes. Valid values are from 5 to 60."
}






