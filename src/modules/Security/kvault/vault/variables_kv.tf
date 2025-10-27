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