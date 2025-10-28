variable "vault_name" {
  type        = string
  description = "Specifies the name of the Key Vault. Changing this forces a new resource to be created. The name must be globally unique. If the vault is in a recoverable state then the vault will need to be purged before reusing the name."
  
  validation {
    condition     = can(regex("^[a-zA-Z0-9-]+$", var.vault_name)) && length(var.vault_name) >= 3 && length(var.vault_name) <= 24
    error_message = "Key Vault name must be 3-24 characters long and contain only alphanumeric characters and hyphens."
  }
  
  validation {
    condition     = can(regex("^[a-zA-Z]", var.vault_name)) && can(regex("[a-zA-Z0-9]$", var.vault_name))
    error_message = "Key Vault name must start with a letter and end with a letter or number."
  }
}

variable "vault_location" {
  type        = string
  description = "Specifies the supported Azure location where the resource exists. Changing this forces a new resource to be created."
  
  validation {
    condition = contains([
      "eastus", "eastus2", "southcentralus", "westus2", "westus3", "australiaeast",
      "southeastasia", "northeurope", "swedencentral", "uksouth", "westeurope",
      "centralus", "northcentralus", "westus", "southafricanorth", "centralindia",
      "eastasia", "japaneast", "koreacentral", "canadacentral", "francecentral",
      "germanywestcentral", "norwayeast", "switzerlandnorth", "uaenorth",
      "brazilsouth", "centraluseuap", "eastus2euap", "qatarcentral", "westcentralus"
    ], var.vault_location)
    error_message = "The location must be a valid Azure region."
  }
}

variable "vault_rg_name" {
  type        = string
  description = "The name of the resource group in which to create the Key Vault. Changing this forces a new resource to be created."
  
  validation {
    condition     = can(regex("^[a-zA-Z0-9._-]+$", var.vault_rg_name)) && length(var.vault_rg_name) <= 90
    error_message = "Resource group name must be alphanumeric with periods, underscores, hyphens allowed. Maximum length is 90 characters."
  }
}

variable "tenant_id" {
  type = string
  description = "The Azure Active Directory tenant ID that should be used for authenticating requests to the key vault."
}

variable "sku_name" {
  type        = string
  default     = "standard"
  description = "The Name of the SKU used for this Key Vault. Possible values are standard and premium."
  
  validation {
    condition     = contains(["standard", "premium"], var.sku_name)
    error_message = "SKU name must be either 'standard' or 'premium'."
  }
}

variable "soft_delete_retention_days" {
  type        = number
  default     = 14
  description = "The number of days that items should be retained for once soft-deleted. This value can be between 7 and 90 days."
  
  validation {
    condition     = var.soft_delete_retention_days >= 7 && var.soft_delete_retention_days <= 90
    error_message = "Soft delete retention days must be between 7 and 90."
  }
}

variable "purge_protection_enabled" {
  type        = bool
  default     = true
  description = "Is Purge Protection enabled for this Key Vault? Recommended to be true for production environments."
}

variable "public_network_access_enabled" {
  type        = bool
  default     = true
  description = "Whether public network access is allowed for this Key Vault. Set to false for enhanced security."
}

variable "network_acls_bypass" {
  type        = string
  default     = "AzureServices"
  description = "Specifies which traffic can bypass the network rules. Possible values are AzureServices and None."
  
  validation {
    condition     = contains(["AzureServices", "None"], var.network_acls_bypass)
    error_message = "Network ACLs bypass must be either 'AzureServices' or 'None'."
  }
}

variable "network_acls_default_action" {
  type        = string
  default     = "Deny"
  description = "The Default Action to use when no rules match from ip_rules / virtual_network_subnet_ids. Possible values are Allow and Deny."
  
  validation {
    condition     = contains(["Allow", "Deny"], var.network_acls_default_action)
    error_message = "Network ACLs default action must be either 'Allow' or 'Deny'."
  }
}

variable "virtual_network_subnet_ids" {
  type        = set(string)
  description = "One or more Subnet IDs which should be able to access this Key Vault. Each must be a valid Azure subnet resource ID."
  
  validation {
    condition = alltrue([
      for subnet_id in var.virtual_network_subnet_ids : can(regex("^/subscriptions/[a-f0-9-]+/resourceGroups/.+/providers/Microsoft.Network/virtualNetworks/.+/subnets/.+$", subnet_id))
    ])
    error_message = "All subnet IDs must be valid Azure subnet resource IDs."
  }
}

variable "allowed_ip_ranges" {
  type        = set(string)
  description = "Set of IP addresses or CIDR blocks that should be allowed to access this Key Vault. Each must be a valid IP address or CIDR block."
  
  validation {
    condition = alltrue([
      for ip_range in var.allowed_ip_ranges : can(regex("^([0-9]{1,3}\\.){3}[0-9]{1,3}(/[0-9]{1,2})?$", ip_range))
    ])
    error_message = "All IP ranges must be valid IP addresses or CIDR blocks (e.g., 192.168.1.1 or 192.168.1.0/24)."
  }
}

variable "tags" {
  type        = map(string)
  description = "A mapping of tags to assign to the Key Vault resource."
  
  validation {
    condition = alltrue([
      for key in keys(var.tags) : length(key) <= 512
    ])
    error_message = "Tag keys must be 512 characters or less."
  }
  
  validation {
    condition = alltrue([
      for value in values(var.tags) : length(value) <= 256
    ])
    error_message = "Tag values must be 256 characters or less."
  }
}

# Enhanced security variables
variable "enable_rbac_authorization" {
  type        = bool
  default     = true
  description = "Boolean flag to specify whether Azure Key Vault uses Role Based Access Control (RBAC) for authorization of data actions"
}

variable "enabled_for_deployment" {
  type        = bool
  default     = false
  description = "Boolean flag to specify whether Azure Virtual Machines are permitted to retrieve certificates stored as secrets from the key vault"
}

variable "enabled_for_disk_encryption" {
  type        = bool
  default     = true
  description = "Boolean flag to specify whether Azure Disk Encryption is permitted to retrieve secrets from the vault and unwrap keys"
}

variable "enabled_for_template_deployment" {
  type        = bool
  default     = false
  description = "Boolean flag to specify whether Azure Resource Manager is permitted to retrieve secrets from the key vault"
}

variable "enable_private_endpoint" {
  type        = bool
  default     = false
  description = "Enable private endpoint for the Key Vault"
}

variable "private_endpoint_subnet_id" {
  type        = string
  default     = null
  description = "The subnet ID where the private endpoint will be created"
}

variable "private_dns_zone_ids" {
  type        = list(string)
  default     = []
  description = "List of private DNS zone IDs for the private endpoint"
}

variable "enable_diagnostic_settings" {
  type        = bool
  default     = true
  description = "Enable diagnostic settings for Key Vault"
}

variable "log_analytics_workspace_id" {
  type        = string
  default     = null
  description = "The ID of the Log Analytics workspace to send diagnostics to"
}

variable "managed_identity_object_id" {
  type        = string
  default     = null
  description = "The object ID of the managed identity to grant access to the Key Vault"
}

variable "managed_identity_key_permissions" {
  type        = list(string)
  default     = ["Get", "List", "Create", "Delete", "Update", "Recover", "Backup", "Restore"]
  description = "List of key permissions to grant to the managed identity"
}

variable "managed_identity_secret_permissions" {
  type        = list(string)
  default     = ["Get", "List", "Set", "Delete", "Recover", "Backup", "Restore"]
  description = "List of secret permissions to grant to the managed identity"
}

variable "managed_identity_certificate_permissions" {
  type        = list(string)
  default     = ["Get", "List", "Create", "Delete", "Update", "ManageContacts", "ManageIssuers"]
  description = "List of certificate permissions to grant to the managed identity"
}