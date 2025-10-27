
variable "subnets" {
  type        = map(any)
  description = "The names of the subnet."
  default = {
    LabNetSubnet = {
      name            = "LabNet"
      addressPrefixes = ["192.168.1.0/28"]
    }
    CoreInfraSubnet = {
      name            = "CoreInfra"
      addressPrefixes = ["192.168.10.0/28"]
    }
    DB_backendSubnet = {
      name            = "Backend"
      addressPrefixes = ["192.168.2.0/28"]
    }
    CachingTierSubnet = {
      name            = "CachingTier"
      addressPrefixes = ["192.168.3.0/28"]
    }
    webFESubnet = {
      name            = "WebFE"
      addressPrefixes = ["192.168.4.0/28"]
    }
    firewallSubnet = {
      name            = "AzureFirewallSubnet"
      addressPrefixes = ["192.168.220.0/26"]
    }
    bastionSubnet = {
      name            = "AzureBastionSubnet"
      addressPrefixes = ["192.168.210.0/26"]
    }
    gatewaySubnet = {
      name            = "GatewaySubnet"
      addressPrefixes = ["192.168.200.0/26"]
    }
  }
}

variable "vnet" {
    type = string
    description = "The name of the virtual network to which to attach the subnet."
}

variable "rg_name" {
    type = string
    description = "The name of the resource group in which to create the subnet."
}

variable "tags" {
  type        = map(string)
  description = "A mapping of tags which should be assigned to the Resource Group."  
}

variable "location" {
  type        = string
  description = "The Azure region where resources will be created"
}

variable "enable_custom_routes" {
  type        = bool
  default     = true
  description = "Enable custom route tables for subnets"
}