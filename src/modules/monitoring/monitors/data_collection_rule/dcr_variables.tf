variable "dcr_name" {
  type        = string
  nullable    = false
  default     = "test-dcr"
  description = "The name which should be used for this Data Collection Rule."

  validation {
    condition     = can(regex("[\\w-]*", var.dcr_name))
    error_message = "The dcr_name resource name must be alphanumeric characters and hyphens allowed."
  }
}

variable "dcr_rg_name" {
  type        = string
  nullable    = false
  description = "The name of the Resource Group where the Data Collection Rule should exist. "
}

variable "dcr_rg_location" {
  type        = string
  nullable    = false
  description = "he Azure Region where the Data Collection Rule should exist."
}

variable "law_id" {
  type        = string
  nullable    = false
  description = "The ID of a Log Analytic Workspace resource."
}

variable "target_resource_id" {
  type        = set(string)
  description = "The ID of the Azure Resource which to associate to a Data Collection Rule or a Data Collection Endpoint."
}

variable "tags" {
  type        = map(string)
  description = "A mapping of tags which should be assigned to the Data Collection Rule."
}

variable "counter_specifiers" {
  type        = list(string)
  description = "Specifies a list of specifier names of the performance counters you want to collect. To get a list of performance counters on Windows, run the command typeperf."
  default = [
    "\\Processor Information(_Total)\\% Processor Time",
    "\\Processor Information(_Total)\\% Privileged Time",
    "\\Processor Information(_Total)\\% User Time",
    "\\Processor Information(_Total)\\Processor Frequency",
    "\\System\\Processes",
    "\\Process(_Total)\\Thread Count",
    "\\Process(_Total)\\Handle Count",
    "\\System\\System Up Time",
    "\\System\\Context Switches/sec",
    "\\System\\Processor Queue Length",
    "\\Memory\\% Committed Bytes In Use",
    "\\Memory\\Available Bytes",
    "\\Memory\\Committed Bytes",
    "\\Memory\\Cache Bytes",
    "\\Memory\\Pool Paged Bytes",
    "\\Memory\\Pool Nonpaged Bytes",
    "\\Memory\\Pages/sec",
    "\\Memory\\Page Faults/sec",
    "\\Process(_Total)\\Working Set",
    "\\Process(_Total)\\Working Set - Private",
    "\\LogicalDisk(_Total)\\% Disk Time",
    "\\LogicalDisk(_Total)\\% Disk Read Time",
    "\\LogicalDisk(_Total)\\% Disk Write Time",
    "\\LogicalDisk(_Total)\\% Idle Time",
    "\\LogicalDisk(_Total)\\Disk Bytes/sec",
    "\\LogicalDisk(_Total)\\Disk Read Bytes/sec",
    "\\LogicalDisk(_Total)\\Disk Write Bytes/sec",
    "\\LogicalDisk(_Total)\\Disk Transfers/sec",
    "\\LogicalDisk(_Total)\\Disk Reads/sec",
    "\\LogicalDisk(_Total)\\Disk Writes/sec",
    "\\LogicalDisk(_Total)\\Avg. Disk sec/Transfer",
    "\\LogicalDisk(_Total)\\Avg. Disk sec/Read",
    "\\LogicalDisk(_Total)\\Avg. Disk sec/Write",
    "\\LogicalDisk(_Total)\\Avg. Disk Queue Length",
    "\\LogicalDisk(_Total)\\Avg. Disk Read Queue Length",
    "\\LogicalDisk(_Total)\\Avg. Disk Write Queue Length",
    "\\LogicalDisk(_Total)\\% Free Space",
    "\\LogicalDisk(_Total)\\Free Megabytes",
    "\\Network Interface(*)\\Bytes Total/sec",
    "\\Network Interface(*)\\Bytes Sent/sec",
    "\\Network Interface(*)\\Bytes Received/sec",
    "\\Network Interface(*)\\Packets/sec",
    "\\Network Interface(*)\\Packets Sent/sec",
    "\\Network Interface(*)\\Packets Received/sec",
    "\\Network Interface(*)\\Packets Outbound Errors",
    "\\Network Interface(*)\\Packets Received Errors"
  ]
}

variable "windows_event_log_streams" {
  type        = list(string)
  default     = ["Microsoft-WindowsEvent"]
  description = "Specifies a list of streams that this data source will be sent to. A stream indicates what schema will be used for this data and usually what table in Log Analytics the data will be sent to. Possible values include but not limited to Microsoft-Event,and Microsoft-WindowsEvent, Microsoft-RomeDetectionEvent, and Microsoft-SecurityEvent."
}

variable "x_path_queries" {
  type = list(string)
  default = [
    "Application!*[System[(Level=1 or Level=2 or Level=5)]]",
    "Security!*[System[(band(Keywords,13510798882111488))]]",
    "System!*[System[(Level=1 or Level=2 or Level=3 or Level=5)]]"
  ]
  description = "Specifies a list of Windows Event Log queries in XPath expression."
}

variable "extension_streams" {
  type        = list(string)
  default     = ["Microsoft-WindowsEvent"]
  description = "Specifies a list of streams that this data source will be sent to. A stream indicates what schema will be used for this data and usually what table in Log Analytics the data will be sent to. Possible values include but not limited to Microsoft-Event, Microsoft-InsightsMetrics, Microsoft-Perf, Microsoft-Syslog, Microsoft-WindowsEvent."
}

variable "performance_counter_streams" {
  type        = list(string)
  default     = ["Microsoft-Perf", "Microsoft-InsightsMetrics"]
  description = "Specifies a list of streams that this data source will be sent to. A stream indicates what schema will be used for this data and usually what table in Log Analytics the data will be sent to. Possible values include but not limited to Microsoft-InsightsMetrics,and Microsoft-Perf."
}

variable "data_flow_streams" {
  type        = list(string)
  default     = ["Microsoft-InsightsMetrics"]
  description = "Specifies a list of streams. Possible values include but not limited to Microsoft-Event, Microsoft-InsightsMetrics, Microsoft-Perf, Microsoft-Syslog,and Microsoft-WindowsEvent."
}

variable "data_flow_streams_destinations_metrics" {
  type        = list(string)
  default     = ["test-destination-metrics"]
  description = "Specifies a list of streams. Possible values include but not limited to Microsoft-Event, Microsoft-InsightsMetrics, Microsoft-Perf, Microsoft-Syslog,and Microsoft-WindowsEvent."
}

variable "data_source_syslog_facility_name" {
  type        = list(string)
  default     = ["*"]
  description = "Specifies a list of facility names. Use a wildcard * to collect logs for all facility names. Possible values are auth, authpriv, cron, daemon, kern, lpr, mail, mark, news, syslog, user, uucp, local0, local1, local2, local3, local4, local5, local6, local7,and *."
}

variable "data_source_syslog_log_levels" {
  type        = list(string)
  default     = ["*"]
  description = "Specifies a list of log levels. Use a wildcard * to collect logs for all log levels. Possible values are Debug, Info, Notice, Warning, Error, Critical, Alert, Emergency,and *."
}