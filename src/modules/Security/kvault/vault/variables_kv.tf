variable "vault_name" {
  type = string
  description = "Specifies the name of the Key Vault. Changing this forces a new resource to be created. The name must be globally unique. If the vault is in a recoverable state then the vault will need to be purged before reusing the name."
}

variable "vault_location" {
  type = string
  description = "Specifies the supported Azure location where the resource exists. Changing this forces a new resource to be created."
}

variable "vault_rg_name" {
  type = string
  description = "The name of the resource group in which to create the Key Vault. Changing this forces a new resource to be created."
}

variable "tenant_id" {
  type = string
  description = "The Azure Active Directory tenant ID that should be used for authenticating requests to the key vault."
}

variable "sku_name" {
  type = string
  default = "standard"
  description = "The Name of the SKU used for this Key Vault. Possible values are standard and premium."
}
variable "soft_delete_retention_days" {
  type = number
  default = 14
  description = "The number of days that items should be retained for once soft-deleted. This value can be between 7 and 90 (the default) days."
}

variable "purge_protection_enabled" {
  type = bool
  default = true
  description = "Is Purge Protection enabled for this Key Vault?"
}

variable "public_network_access_enabled" {
  type = bool
  default = true
  description = "Whether public network access is allowed for this Key Vault. Defaults to true."
}

variable "network_acls_bypass" {
  type = string
  default = "AzureServices"
  description = "Specifies which traffic can bypass the network rules. Possible values are AzureServices and None."
}

variable "network_acls_default_action" {
  type = string
  default = "Deny" 
  description = "The Default Action to use when no rules match from ip_rules / virtual_network_subnet_ids. Possible values are Allow and Deny."
}

variable "virtual_network_subnet_ids" {
  type = set(string)
  description = "One or more Subnet IDs which should be able to access this Key Vault."
}

variable "allowed_ip_ranges" {
  type = set(string)
  description = "allowed_ip_ranges"
}

variable "tags" {
    type = map(string)
    description = "A mapping of tags to assign to the resource."
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