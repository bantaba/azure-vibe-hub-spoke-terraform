variable "rg_name" {
  type        = string
  description = "The name of the resource group in which to create the virtual network. Changing this forces a new resource to be created."

  validation {
    condition     = can(regex("^[a-zA-Z0-9._-]+$", var.rg_name)) && length(var.rg_name) <= 90
    error_message = "Resource group name must be alphanumeric with periods, underscores, hyphens allowed. Maximum length is 90 characters."
  }
}

variable "rg_location" {
  type        = string
  description = "The location/region where the virtual network is created. Changing this forces a new resource to be created."

  validation {
    condition = contains([
      "eastus", "eastus2", "southcentralus", "westus2", "westus3", "australiaeast",
      "southeastasia", "northeurope", "swedencentral", "uksouth", "westeurope",
      "centralus", "northcentralus", "westus", "southafricanorth", "centralindia",
      "eastasia", "japaneast", "koreacentral", "canadacentral", "francecentral",
      "germanywestcentral", "norwayeast", "switzerlandnorth", "uaenorth",
      "brazilsouth", "centraluseuap", "eastus2euap", "qatarcentral", "westcentralus"
    ], var.rg_location)
    error_message = "The location must be a valid Azure region."
  }
}

variable "vnet_name" {
  type        = string
  description = "The name of the virtual network. Changing this forces a new resource to be created."

  validation {
    condition     = can(regex("^[a-zA-Z0-9._-]+$", var.vnet_name)) && length(var.vnet_name) >= 2 && length(var.vnet_name) <= 64
    error_message = "Virtual network name must be 2-64 characters long and contain only alphanumeric characters, periods, underscores, and hyphens."
  }
}

variable "vnet_address_space" {
  type        = list(string)
  default     = ["192.168.0.0/16"]
  description = "The address space that is used for the virtual network. You can supply more than one address space. Each must be a valid CIDR block."

  validation {
    condition = alltrue([
      for cidr in var.vnet_address_space : can(cidrhost(cidr, 0))
    ])
    error_message = "All address spaces must be valid CIDR blocks (e.g., 10.0.0.0/16, 192.168.0.0/24)."
  }

  validation {
    condition     = length(var.vnet_address_space) > 0
    error_message = "At least one address space must be specified."
  }
}

variable "tags" {
  type        = map(string)
  description = "A mapping of tags which should be assigned to the virtual network and associated resources."

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
