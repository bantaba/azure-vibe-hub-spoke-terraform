variable "sa_name" {
  type     = string
  nullable = false

  validation { # check for valid name char
    condition     = can(regex("^[a-z0-9]{3,24}$", var.sa_name))
    error_message = "The storage_account_name resource variable name must be between 3-24 characters in length, and contains only lowercase numbers and letters."
  }

  # validation {
  #   condition = length(var.sa_name) >=3 && length(var.sa_name ) <= 24
  #   error_message = "The storage_account_name resource variable name must be between 3-24 characters in length."
  # }

  description = "Name of the storage account"
}

variable "sa_location" {
  type        = string
  default     = "westUS2"
  nullable    = false
  description = "Location where the resources will be created. Must be a valid Azure region."

  validation {
    condition = contains([
      "eastus", "eastus2", "southcentralus", "westus2", "westus3", "australiaeast",
      "southeastasia", "northeurope", "swedencentral", "uksouth", "westeurope",
      "centralus", "northcentralus", "westus", "southafricanorth", "centralindia",
      "eastasia", "japaneast", "koreacentral", "canadacentral", "francecentral",
      "germanywestcentral", "norwayeast", "switzerlandnorth", "uaenorth",
      "brazilsouth", "centraluseuap", "eastus2euap", "qatarcentral", "westcentralus"
    ], var.sa_location)
    error_message = "The location must be a valid Azure region."
  }
}

variable "sa_rg_name" {
  type        = string
  sensitive   = false
  nullable    = false
  description = "Name of the resource group to create the storage account resource."

  validation {
    condition     = can(regex("^[a-zA-Z0-9._-]+$", var.sa_rg_name)) && length(var.sa_rg_name) <= 90
    error_message = "Resource group name must be alphanumeric with periods, underscores, hyphens allowed. Maximum length is 90 characters."
  }
}

variable "account_kind" {
  description = "Defines the Kind of account. Valid options are BlobStorage, BlockBlobStorage, FileStorage, Storage and StorageV2"
  type        = string
  sensitive   = false
  nullable    = false
  default     = "StorageV2"

  validation {
    condition     = (contains(["BlobStorage", "BlockBlobStorage", "Storage", "FileStorage", "StorageV2"], var.account_kind))
    error_message = "The account_kind must be one of: \"BlobStorage\", \"BlockBlobStorage\", \"FileStorage\", \"Storage\" or \"StorageV2\"."
  }
}

variable "account_tier" {
  description = "Defines the Tier to use for this storage account (Standard or Premium)."
  type        = string
  sensitive   = false
  nullable    = false
  default     = "Standard"

  validation {
    condition     = (contains(["Standard", "Premium"], title(var.account_tier)))
    error_message = "The account_tier must be either \"Standard\" or \"Premium\"."
  }
}


variable "replication_type" {
  description = "Storage account replication type - i.e. LRS, GRS, RAGRS, ZRS, GZRS, RAGZRS."
  type        = string
  nullable    = false
  default     = "LRS"

  validation {
    condition     = (contains(["LRS", "GRS", "RAGRS", "ZRS", "GZRS", "RAGZRS"], var.replication_type))
    error_message = "Replication account must of one of the following LRS, GRS, RAGRS, ZRS, GZRS, RAGZRS."
  }
}

variable "enable_https_traffic_only" {
  description = "Forces HTTPS if enabled."
  type        = bool
  nullable    = false
  default     = true

  validation {
    condition     = can(regex("^(true|false)$", var.enable_https_traffic_only))
    error_message = "Invalid input, options: \"true\", \"false\"."
  }
}

variable "min_tls_version" {
  description = "The minimum supported TLS version for the storage account."
  type        = string
  nullable    = false
  default     = "TLS1_2"
}

variable "infrastructure_encryption_enabled" {
  description = "Is infrastructure encryption enabled? Changing this forces a new resource to be created."
  type        = bool
  default     = true
}

variable "container_delete_retention_days" {
  description = "Retention days for deleted container. Valid value is between 1 and 365 (set to 0 to disable)."
  type        = number
  nullable    = false
  default     = 7
}

variable "sa_container_name" {
  type        = string
  nullable    = false
  description = "The name of the Container which should be created within the Storage Account. Changing this forces a new resource to be created."

  validation { # check for valid name char # ([a-zA-Z0-9-]* == [\w-]*) 
    condition     = can(regex("^[a-z0-9-]{3,24}$", var.sa_container_name))
    error_message = "The storage_account_name resource variable name must be between 3-24 characters in length, and only lowercase alphanumeric characters and hyphens allowed."
  }
}

variable "sa_blob_type" {
  type        = string
  nullable    = false
  default     = "Block"
  description = "he type of the storage blob to be created. Possible values are Append, Block or Page."

  validation {
    condition     = (contains(["Append", "Block", "Page"], var.sa_blob_type))
    error_message = "Invalid input, can be one of the following: \"Append\", \"Block\", or \"Page\"."
  }
}

variable "container_access_type" {
  type        = string
  default     = "private"
  nullable    = false
  description = "The Access Level configured for this Container. Possible values are blob, container or private. Defaults to private."

  validation {
    condition     = (contains(["blob", "container", "private"], var.container_access_type))
    error_message = "Invalid input, can be one of the following: \"blob\", \"container\", or \"private\"."
  }
}

variable "access_tier" {
  type        = string
  default     = "Hot"
  nullable    = false
  description = "Defines the access tier for BlobStorage, FileStorage and StorageV2 accounts. Valid options are Hot and Cool, defaults to Hot."

  validation {
    condition     = (contains(["Hot", "Cool"], var.access_tier))
    error_message = "Invalid input, can be one of: \"Hot\", or \"Cool\"."
  }
}

variable "allow_nested_items_to_be_public" {
  type        = bool
  default     = false
  description = "(optional) describe your variable"
}

variable "tags" {
  type        = map(string)
  nullable    = false
  description = "tags to be applied to resources"
}

# Enhanced security variables
variable "public_network_access_enabled" {
  description = "Whether the public network access is enabled"
  type        = bool
  default     = false
  nullable    = false
}

variable "default_to_oauth_authentication" {
  description = "Default to Azure Active Directory authorization in the Azure portal when accessing the Storage Account"
  type        = bool
  default     = true
  nullable    = false
}

variable "shared_access_key_enabled" {
  description = "Indicates whether the storage account permits requests to be authorized with the account access key via Shared Key"
  type        = bool
  default     = false
  nullable    = false
}

variable "network_rules_enabled" {
  description = "Enable network access rules for the storage account"
  type        = bool
  default     = true
  nullable    = false
}

variable "network_rules_default_action" {
  description = "The default action of allow or deny when no other rules match"
  type        = string
  default     = "Deny"
  nullable    = false

  validation {
    condition     = contains(["Allow", "Deny"], var.network_rules_default_action)
    error_message = "The network_rules_default_action must be either 'Allow' or 'Deny'."
  }
}

variable "network_rules_bypass" {
  description = "Specifies whether traffic is bypassed for Azure services"
  type        = set(string)
  default     = ["AzureServices", "Logging", "Metrics"]
  nullable    = false

  validation {
    condition = alltrue([
      for bypass in var.network_rules_bypass : contains(["AzureServices", "Logging", "Metrics", "None"], bypass)
    ])
    error_message = "Valid values for network_rules_bypass are: AzureServices, Logging, Metrics, None."
  }
}

variable "allowed_ip_ranges" {
  description = "List of public IP or IP ranges in CIDR Format. Each must be a valid IP address or CIDR block."
  type        = list(string)
  default     = []
  nullable    = false

  validation {
    condition = alltrue([
      for ip_range in var.allowed_ip_ranges : can(regex("^([0-9]{1,3}\\.){3}[0-9]{1,3}(/[0-9]{1,2})?$", ip_range))
    ])
    error_message = "All IP ranges must be valid IP addresses or CIDR blocks (e.g., 192.168.1.1 or 192.168.1.0/24)."
  }
}

variable "allowed_subnet_ids" {
  description = "A list of virtual network subnet ids to secure the storage account. Each must be a valid Azure subnet resource ID."
  type        = list(string)
  default     = []
  nullable    = false

  validation {
    condition = alltrue([
      for subnet_id in var.allowed_subnet_ids : can(regex("^/subscriptions/[a-f0-9-]+/resourceGroups/.+/providers/Microsoft.Network/virtualNetworks/.+/subnets/.+$", subnet_id))
    ])
    error_message = "All subnet IDs must be valid Azure subnet resource IDs."
  }
}

variable "blob_versioning_enabled" {
  description = "Is versioning enabled for blobs"
  type        = bool
  default     = true
  nullable    = false
}

variable "blob_change_feed_enabled" {
  description = "Is the blob service properties for change feed events enabled"
  type        = bool
  default     = true
  nullable    = false
}

variable "blob_last_access_time_enabled" {
  description = "Is the last access time based tracking enabled"
  type        = bool
  default     = true
  nullable    = false
}

variable "blob_delete_retention_days" {
  description = "Retention days for deleted blobs. Valid value is between 1 and 365 (set to 0 to disable)"
  type        = number
  default     = 30
  nullable    = false

  validation {
    condition     = var.blob_delete_retention_days >= 0 && var.blob_delete_retention_days <= 365
    error_message = "The blob_delete_retention_days must be between 0 and 365."
  }
}

# Private endpoint variables
variable "enable_private_endpoint" {
  description = "Enable private endpoint for the storage account"
  type        = bool
  default     = false
  nullable    = false
}

variable "private_endpoint_subnet_id" {
  description = "The subnet ID where the private endpoint will be created"
  type        = string
  default     = null
}

variable "private_dns_zone_ids" {
  description = "List of private DNS zone IDs for the private endpoint"
  type        = list(string)
  default     = []
  nullable    = false
}