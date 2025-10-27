variable "bastion_name" {   #The name must begin with a letter or number, end with a letter, number or underscore, and may contain only letters, numbers, underscores, periods, or hyphens.
    type = string
    default = "ibastionDev"
    description = "Specifies the name of the Bastion Host."
}

variable "location" {
    type = string
    description = "The name of the resource group in which to create the Bastion Host.."
}

variable "rg_name" {
    type = string
    description = "The name of the resource group in which to create the Bastion Host."
}

variable "sku" {
    type = string
    default = "Basic"
    description = "The SKU of the Bastion Host. Accepted values are Basic and Standard. Defaults to Basic."
}

variable "ip_configuration_name" {
    type = string
    description = "The name of the IP configuration. Changing this forces a new resource to be created."
}

variable "public_ip_address_id" {
    type = string
    description = "Reference to a Public IP Address to associate with this Bastion Host. "
}

variable "subnet_id" {
    type = string
    description = "Reference to a subnet in which this Bastion Host has been created. The Subnet used for the Bastion Host must have the name AzureBastionSubnet and the subnet mask must be at least a /26."
}

variable "tunneling_enabled" {
    type = bool
    default = false
    description = "Is Tunneling feature enabled for the Bastion Host. Defaults to false. Only supported when sku is Standard."
}

variable "ip_connect_enabled" {
    type = bool
    default = false
    description = "Is IP Connect feature enabled for the Bastion Host. Defaults to false. Only supported when sku is Standard."
}

variable "scale_units" {
    type = number
    default = 2
    description = "The number of scale units with which to provision the Bastion Host. Possible values are between 2 and 50. Defaults to 2. Can be changed when sku is Standard. scale_units is always 2 when sku is Basic."
}

variable "shareable_link_enabled" {
    type = bool
    default = false
    description = "Is Shareable Link feature enabled for the Bastion Host. Defaults to false. Only supported when sku is Standard."
}
variable "tags" {
    type = map(string)
    description = "A mapping of tags to assign to the resource."
}