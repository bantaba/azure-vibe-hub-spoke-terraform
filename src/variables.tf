locals {
  ingress_ip_address = trimspace(data.http.public_ip.response_body)
}

variable "location" {
  type        = string
  default     = "westus3"
  description = " (Required) The Azure Region where the Resource Group should exist. Changing this forces a new Resource Group to be created."
}

variable "allowed_ip_rules" { #TODO to be imported from csv file to include user who added along with IP scope etc with PR
  type = set(string)
  default = [
    "131.107.0.0/16",    #Corp from https://msitexternalip.azurewebsites.net/ current IP is broad need to be scope down further same with 104.*
    "104.44.112.128/25", #Corp
    "67.183.33.89"       #nonWork i.e who this IP belongs to etc
  ]
}

variable "builtin_role_def" {
  type        = map(string)
  description = "builtin roles https://learn.microsoft.com/en-us/azure/role-based-access-control/built-in-roles#user-access-administrator"
  default = {
    KeyVaultSecretsOfficer    = "Key Vault Secrets Officer"
    KeyVaultAdministrator     = "Key Vault Administrator"
    Contributor               = "Contributor"
    VirtualMachineContributor = "Virtual Machine Contributor"
  }
}
variable "default_tags" {
  type = map(string)
  default = {
    deployed_vai = "Terraform"
    owner        = "Me"
    Team         = "XGO"
    Contact      = "majeng"
    CostCenter   = "85513"
    Organization = "Gaming"
    Repo         = "AzDO - msblox-terraform-azure-hub-spoke"
    # RequestID    = "TBD"
  }
  description = "A mapping of tags which should be assigned to the Resource Group."
}

#   https://learn.microsoft.com/en-us/azure/cloud-adoption-framework/ready/azure-best-practices/resource-abbreviations
variable "location_abbreviation" {
  description = "The abbreviation of the location."
  type        = map(string)
  default = {
    "westus2"        = "wus2"
    "westus3"        = "wus3"
    "eastus"         = "eus"
    "westus"         = "wus"
    "eastus2"        = "eus2"
    "southcentralus" = "scus"
  }
}

variable "resource_abbreviation" {
  description = "The abbreviation of the location."
  type        = map(string)
  default = {
    "resourceGroup"           = "rg"
    "virtualNetwork"          = "vnet"
    "NetworkInterface"        = "nic"
    "storageAccount"          = "st"
    "availabilitySets"        = "avail"
    "virtualMachines"         = "vm"
    "virtualMachineScaleSets" = "vmss"
    "azureFirewall"           = "afw"
    "firewallPolicy"          = "afwp"
    "internalLoadBalancer"    = "lbi"
    "externalLoadBalancer"    = "lbe"
    "inboundNatRule"          = "rule"
    "publicIPAddress"         = "pip"
    "routeTable"              = "rt"
    "subnet"                  = "snet"
    "bastionHost"             = "bas"
    "vaults"                  = "kv"
    "userAssignedIdentities"  = "id"
  }
}

variable "test_vm_names" {
  type        = set(string)
  default     = ["w3TestVM01"]
  description = "Name(s) of the Windows VM"
}

variable "dc_vm_names" {
  type        = set(string)
  default     = ["W3DC01"]
  description = "Name(s) of the Windows VM"
}
