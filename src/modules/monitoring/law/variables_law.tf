
locals {
  solution_name = toset([
    "Security", "SecurityInsights", "AgentHealthAssessment", "AzureActivity", "SecurityCenterFree", "DnsAnalytics", "ADAssessment", "AntiMalware", "ServiceMap", "SQLAssessment", "SQLAdvancedThreatProtection", "AzureAutomation", "Containers", "ChangeTracking", "Updates", "VMInsights"
  ])
}

variable "law_name" {
  type        = string
  nullable    = false
  description = "Specifies the name of the Log Analytics Workspace. Workspace name should include 4-63 letters, digits or '-'. The '-' shouldn't be the first or the last symbol."

  validation { # check for valid name char # ([a-zA-Z0-9-]* == [\w-]*) 
    condition     = can(regex("^[a-z0-9-]{4,63}$", var.law_name))
    error_message = "The Log Analytics name resource variable name must be between 4-63 characters in length, and only  alphanumeric characters and hyphens allowed, but not in the beginning/end."
  }
}


variable "law_location" {
  type        = string
  description = "Specifies the supported Azure location where the resource exists. Changing this forces a new resource to be created."
}


variable "law_rg_name" {
  type        = string
  nullable    = false
  description = "The name of the resource group in which the Log Analytics workspace is created."
}

variable "law_sku" {
  type        = string
  nullable    = false
  default     = "PerGB2018"
  description = "Specifies the SKU of the Log Analytics Workspace. Possible values are Free, PerNode, Premium, Standard, Standalone, Unlimited, CapacityReservation, and PerGB2018"

  validation {
    condition     = (contains(["PerGB2018", "Free", "PerNode", "Premium", "Standard", "Standalone", "Unlimited", "CapacityReservation"], var.law_sku))
    error_message = "Invalid input, can be one of the following: \"PerGB2018\", \"Free\", \"PerNode\", \"Premium\", \"Standard\", \"Standalone\", \"Unlimited\" or \"CapacityReservation\"."
  }
}

variable "retention_in_days" {
  type        = number
  nullable    = false
  default     = 30
  description = "The workspace data retention in days. Possible values are either 7 (Free Tier only) or range between 30 and 730."

  validation {
    condition     = (var.retention_in_days >= 30) && (var.retention_in_days <= 730)
    error_message = "The retention period must be between 30 and 730 days."
  }
}

variable "automation_acct_id" {
  type        = string
  nullable    = false
  description = "The ID of the Log Analytics Workspace that will contain the Log Analytics Linked Service resource."
}

variable "log_analytics_storage_insightsStorage_account_id" {
  type        = string
  nullable    = false
  description = "The ID of the Storage Account used by this Log Analytics Storage Insights."
  sensitive   = true
}

variable "log_analytics_storage_insightsStorage_account_key" {
  type        = string
  nullable    = false
  description = "The storage access key to be used to connect to the storage account."
  sensitive   = true
}

variable "law_storage_insights_name" {
  type        = string
  description = "The name which should be used for this Log Analytics Storage Insights. Changing this forces a new Log Analytics Storage Insights to be created."
}

variable "tags" {
  type        = map(string)
  nullable    = false
  description = "A mapping of tags to assign to the resource."
}

