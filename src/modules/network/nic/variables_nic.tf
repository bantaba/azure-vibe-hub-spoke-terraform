variable "nic_name" {
    type = set(string)
    description = "The name of the Network Interface."
}

variable "nic_location" {
    type = string
    description = "The location where the Network Interface should exist."
}

variable "nic_resource_group" {
    type = string
    description = "The name of the Resource Group in which to create the Network Interface."
}

variable "tags" {
    type = map(string)
    description = "A mapping of tags to assign to the resource."
}

variable "nic_subnet_id" {
    type = string
    description = "The ID of the Subnet where this Network Interface should be located in."
}

variable "ip_configuration_name" {
    type = string
    default = "internalNic"
    description = ""
}

variable "private_ip_address_allocation" {
    type = string
    default = "Dynamic"
    description = "The allocation method used for the Private IP Address. Possible values are Dynamic and Static. Dynamic means \"An IP is automatically assigned during creation of this Network Interface\"; Static means \"User supplied IP address will be used\""
}

variable "enable_accelerated_networking" {
    type = bool
    default = false
    description = ""
}

variable "enable_ip_forwarding" {
    type = bool
    default = false
    description = ""
}