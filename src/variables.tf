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
    deployed_via = "Terraform"
    owner        = "Me"
    team         = "XGO"
    contact      = "majeng"
    cost_center  = "85513"
    organization = "Gaming"
    repository   = "AzDO - msblox-terraform-azure-hub-spoke"
    # request_id    = "TBD"
  }
  description = "A mapping of tags which should be assigned to all resources. Uses standardized lowercase naming with underscores."
  
  validation {
    condition = alltrue([
      for key in keys(var.default_tags) : can(regex("^[a-z_]+$", key))
    ])
    error_message = "Tag keys must use lowercase letters and underscores only."
  }
}

# Azure location abbreviations following Microsoft CAF standards
# https://learn.microsoft.com/en-us/azure/cloud-adoption-framework/ready/azure-best-practices/resource-abbreviations
variable "location_abbreviation" {
  description = "Standardized abbreviations for Azure locations following Microsoft Cloud Adoption Framework."
  type        = map(string)
  default = {
    "westus2"        = "wus2"
    "westus3"        = "wus3"
    "eastus"         = "eus"
    "westus"         = "wus"
    "eastus2"        = "eus2"
    "southcentralus" = "scus"
    "centralus"      = "cus"
    "northcentralus" = "ncus"
    "westcentralus"  = "wcus"
    "canadacentral"  = "cac"
    "canadaeast"     = "cae"
  }
  
  validation {
    condition = alltrue([
      for abbr in values(var.location_abbreviation) : can(regex("^[a-z0-9]+$", abbr))
    ])
    error_message = "Location abbreviations must contain only lowercase letters and numbers."
  }
}

# Azure resource type abbreviations following Microsoft CAF standards
# https://learn.microsoft.com/en-us/azure/cloud-adoption-framework/ready/azure-best-practices/resource-abbreviations
variable "resource_abbreviation" {
  description = "Standardized abbreviations for Azure resource types following Microsoft Cloud Adoption Framework."
  type        = map(string)
  default = {
    "resource_group"               = "rg"
    "virtual_network"              = "vnet"
    "network_interface"            = "nic"
    "storage_account"              = "st"
    "availability_set"             = "avail"
    "virtual_machine"              = "vm"
    "virtual_machine_scale_set"    = "vmss"
    "azure_firewall"               = "afw"
    "firewall_policy"              = "afwp"
    "load_balancer_internal"       = "lbi"
    "load_balancer_external"       = "lbe"
    "nat_rule"                     = "rule"
    "public_ip_address"            = "pip"
    "route_table"                  = "rt"
    "subnet"                       = "snet"
    "bastion_host"                 = "bas"
    "key_vault"                    = "kv"
    "user_assigned_identity"       = "id"
    "network_security_group"       = "nsg"
    "log_analytics_workspace"      = "law"
    "automation_account"           = "aa"
    "application_security_group"   = "asg"
    "private_endpoint"             = "pep"
    "private_dns_zone"             = "pdz"
  }
  
  validation {
    condition = alltrue([
      for abbr in values(var.resource_abbreviation) : can(regex("^[a-z0-9]+$", abbr))
    ])
    error_message = "Resource abbreviations must contain only lowercase letters and numbers."
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
  description = "Name(s) of the Windows Domain Controller VMs"
  
  validation {
    condition = alltrue([
      for name in var.dc_vm_names : can(regex("^[A-Za-z0-9]+$", name)) && length(name) <= 15
    ])
    error_message = "VM names must be alphanumeric and 15 characters or less."
  }
}

# Environment configuration
variable "environment" {
  type        = string
  default     = "dev"
  description = "Environment name (dev, staging, prod)"
  
  validation {
    condition     = contains(["dev", "staging", "prod"], var.environment)
    error_message = "Environment must be one of: dev, staging, prod."
  }
}

# Project configuration
variable "project_name" {
  type        = string
  default     = "hubspoke"
  description = "Project name used in resource naming"
  
  validation {
    condition     = can(regex("^[a-z0-9]+$", var.project_name)) && length(var.project_name) <= 10
    error_message = "Project name must be lowercase alphanumeric and 10 characters or less."
  }
}

# Naming convention locals
locals {
  # Standard naming convention: {project}-{resource_type}-{environment}-{location_abbr}-{instance}
  naming_convention = {
    prefix = "${var.project_name}-${var.environment}-${var.location_abbreviation[var.location]}"
  }
  
  # Common tags applied to all resources
  common_tags = merge(var.default_tags, {
    environment   = var.environment
    project       = var.project_name
    deployed_on   = formatdate("YYYY-MM-DD", timestamp())
    terraform_ws  = terraform.workspace
  })
}
