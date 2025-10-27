variable "rg_name" {
    type = string
    description = " The name of the resource group in which to create the virtual network. Changing this forces a new resource to be created."
    # default = "value"
}

variable "rg_location" {
    type = string
    description = "The location/region where the virtual network is created. Changing this forces a new resource to be created."
}

variable "vnet_name" {
    type = string
    description = "The name of the virtual network. Changing this forces a new resource to be created."
}

variable "vnet_address_space" {
    type = list(any)
    default = [ "192.168.0.0/16"]
    description = "The address space that is used the virtual network. You can supply more than one address space."
}


variable "tags" {
  type        = map(string)
  description = "A mapping of tags which should be assigned to the Resource Group."  
}
