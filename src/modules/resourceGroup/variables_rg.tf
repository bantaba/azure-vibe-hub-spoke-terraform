
variable "resource_group_names" {
  type = map(string)
  default = {
    NetLab      = "mainVnet"
    CoreInfra   = "CoreInfra"
    WebFE       = "WebFE"
    DB_backend  = "DataTier"
    K8s_kubenet = "k8knet"
    K8s_cni     = "k8cni"
    K8s_acr     = "k8acr"
  }
  description = "Map of resource group names by purpose. Keys represent the logical grouping, values are the resource group names."

  validation {
    condition = alltrue([
      for name in values(var.resource_group_names) : can(regex("^[a-zA-Z0-9._-]+$", name)) && length(name) <= 90
    ])
    error_message = "Resource group names must be alphanumeric with periods, underscores, hyphens, and parentheses allowed. Maximum length is 90 characters."
  }
}

variable "tags" {
  type        = map(string)
  description = "A mapping of tags which should be assigned to the Resource Group. All tags will be applied to created resources."

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

variable "resource_group_location" {
  type        = string
  description = "The Azure Region where the Resource Group should exist. Must be a valid Azure region name."

  validation {
    condition = contains([
      "eastus", "eastus2", "southcentralus", "westus2", "westus3", "australiaeast",
      "southeastasia", "northeurope", "swedencentral", "uksouth", "westeurope",
      "centralus", "northcentralus", "westus", "southafricanorth", "centralindia",
      "eastasia", "japaneast", "koreacentral", "canadacentral", "francecentral",
      "germanywestcentral", "norwayeast", "switzerlandnorth", "uaenorth",
      "brazilsouth", "centraluseuap", "eastus2euap", "qatarcentral", "westcentralus"
    ], var.resource_group_location)
    error_message = "The location must be a valid Azure region."
  }
}
