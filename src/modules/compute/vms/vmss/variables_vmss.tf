variable "vmss_name" {
  type        = string
  description = "(Required) The name of the Windows Virtual Machine Scale Set. Changing this forces a new resource to be created."
  validation { # check for valid name char # ([a-zA-Z0-9-]* == [\w-]*) 
    condition     = can(regex("[\\w-]{4,15}$", var.vmss_name))
    error_message = "The VMSS computer name may only contain alphanumeric characters and dashes. Please adjust the \"${var.vmss_name}\", or specify an explicit computer_name_prefix."
  }
}

variable "sku" {
  type        = string
  default     = "Standard_B2s"
  description = "The Virtual Machine SKU for the Scale Set, such as Standard_B1s"
}
variable "vmss_rg_name" {
  type        = string
  description = "(Required) The name of the Resource Group in which the Windows Virtual Machine Scale Set should be exist. Changing this forces a new resource to be created."
}

variable "vmss_location" {
  type        = string
  description = "(Required) The Azure location where the Windows Virtual Machine Scale Set should exist. Changing this forces a new resource to be created."
}

variable "admin_user_password" {
  type        = string
  description = "Required) The Password which should be used for the local-administrator on this Virtual Machine. Changing this forces a new resource to be created."
}

variable "admin_user_name" {
  type        = string
  description = "(Required) The username of the local administrator on each Virtual Machine Scale Set instance. Changing this forces a new resource to be created."
}

variable "vmss_ipConfig_subnet_id" {
  type        = string
  description = "Subnet ID of subnet to assign to NIC"
}

variable "user_managed_identity_id" {
  type        = string
  description = "(Required) Specifies the type of Managed Service Identity that should be configured on this Windows Virtual Machine Scale Set. Possible values are SystemAssigned, UserAssigned, SystemAssigned, UserAssigned (to enable both). identity_ids - (Optional) Specifies a list of User Assigned Managed Identity IDs to be assigned to this Windows Virtual Machine Scale Set."
}

variable "upgrade_mode" {
  type        = string
  default     = "Automatic"
  description = "(Optional) Specifies how Upgrades (e.g. changing the Image/SKU) should be performed to Virtual Machine Instances. Possible values are Automatic, Manual and Rolling. Defaults to Manual. Changing this forces a new resource to be created."
}

variable "instances" {
  type        = number
  default     = 2
  description = "(Required) The number of Virtual Machines in the Scale Set."
}

variable "platform_fault_domain_count" {
  type        = number
  default     = 2
  description = "Optional) Specifies the number of fault domains that are used by this Linux Virtual Machine Scale Set. Changing this forces a new resource to be created."

}

variable "analytics_workspace_id" {
  type        = string
  sensitive   = false
  description = "(optional) describe your variable"
}

variable "analytics_workspace_key" {
  type        = string
  sensitive   = true
  description = "(optional) describe your variable"
}

variable "storage_acct_name" {
  type        = string
  description = "(optional) describe your variable"
}

variable "storage_acct_key" {
  type        = string
  sensitive   = true
  description = "(optional) describe your variable"
}


variable "active_directory_password" {
  type        = string
  nullable    = false
  description = "Domain user password"
}

variable "active_directory_username" {
  type        = string
  nullable    = false
  description = "Domain NetBiosName plus User name of a domain user with sufficient rights to perfom domain join operation. E.g. domain\\username"
}

variable "ou_path" {
  type        = string
  nullable    = false
  default     = "OU=Servers,OU=Machines,DC=redmond,DC=corp,DC=microsoft,DC=com"
  description = "Specifies an organizational unit (OU) for the domain account. Enter the full distinguished name of the OU in quotation marks. Example: \"OU=testOU; DC=domain; DC=Domain; DC=com\""
}

variable "active_directory_domain" {
  type        = string
  nullable    = false
  default     = "redmond.corp.microsoft.com"
  description = "Domain FQDN name of the Active Directory domain where the virtual machine will be joined."
}


variable "vault_observed_certificate" {
  type        = string
  description = "(optional) describe your variable"
}

variable "tags" {
  type        = map(string)
  description = " (Optional) A mapping of tags which should be assigned to this Virtual Machine Scale Set"
}