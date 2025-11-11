locals {
  //wspace_name = terraform.workspace
  nsg_rules = csvdecode(file("${path.module}/nsg_rules.csv"))

}

variable "nsg_name" {
  type        = string
  description = "Specifies the name of the network security group."
}

variable "location" {
  type        = string
  description = "Specifies the supported Azure location where the resource exists."
}

variable "rg_name" {
  type        = string
  description = "The name of the resource group in which to create the network security group."
}

variable "tags" {
  type        = map(string)
  description = "A mapping of tags to assign to the resource."
}

variable "subnet_id" {
  type        = set(string)
  description = "The ID of the Subnet to be associated with the NSG."
}

variable "network_watcher_flow_log_name" {
  type        = string
  description = "The name of the Network Watcher Flow Log. Changing this forces a new resource to be created."
}

variable "storage_account_id" {
  type        = string
  description = "The ID of the Storage Account where flow logs are stored."
}

variable "law_id" {
  type        = string
  description = "The resource GUID of the attached workspace."
}

variable "law_resource_id" {
  type        = string
  description = "The resource ID of the attached workspace."
}

# Enhanced security variables
variable "flow_log_enabled" {
  type        = bool
  default     = true
  description = "Enable or disable flow logging"
}

variable "flow_log_version" {
  type        = number
  default     = 2
  description = "The version of the flow log format"

  validation {
    condition     = contains([1, 2], var.flow_log_version)
    error_message = "Flow log version must be 1 or 2."
  }
}

variable "flow_log_retention_days" {
  type        = number
  default     = 90
  description = "Number of days to retain flow logs"

  validation {
    condition     = var.flow_log_retention_days >= 1 && var.flow_log_retention_days <= 365
    error_message = "Flow log retention days must be between 1 and 365."
  }
}

variable "flow_log_retention_enabled" {
  type        = bool
  default     = true
  description = "Enable flow log retention policy"
}

variable "traffic_analytics_enabled" {
  type        = bool
  default     = true
  description = "Enable traffic analytics"
}

variable "traffic_analytics_interval" {
  type        = number
  default     = 10
  description = "Traffic analytics processing interval in minutes"

  validation {
    condition     = contains([10, 60], var.traffic_analytics_interval)
    error_message = "Traffic analytics interval must be 10 or 60 minutes."
  }
}

variable "enable_diagnostic_settings" {
  type        = bool
  default     = true
  description = "Enable diagnostic settings for NSG"
}