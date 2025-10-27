locals {
  //wspace_name = terraform.workspace
  nsg_rules = csvdecode(file("${path.module}/nsg_rules.csv"))

}

variable "nsg_name" {
    type = string
    description = "Specifies the name of the network security group."
}

variable "location" {
    type = string
    description = "Specifies the supported Azure location where the resource exists."
}

variable "rg_name" {
    type = string
    description = "The name of the resource group in which to create the network security group."
}

variable "tags" {
    type = map(string)
    description = "A mapping of tags to assign to the resource."
}

variable "subnet_id" {
    type = set(string)
    description = "The ID of the Subnet to be associated with the NSG."
}

variable "network_watcher_flow_log_name" {
    type = string
    description = "The name of the Network Watcher Flow Log. Changing this forces a new resource to be created."
}

variable "storage_account_id" {
    type = string
    description = "The ID of the Storage Account where flow logs are stored."
}

variable "law_id" {
    type = string
    description = "The resource GUID of the attached workspace."
}

variable "law_resource_id" {
    type = string
    description = "The resource ID of the attached workspace."
}