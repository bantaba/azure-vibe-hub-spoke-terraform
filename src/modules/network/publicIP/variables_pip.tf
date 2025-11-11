variable "pip_name" {
  type        = string
  description = " (Required) Specifies the name of the Public IP. Changing this forces a new Public IP to be created."
}

variable "location" {
  type        = string
  description = "(Required) Specifies the supported Azure location where the Public IP should exist. Changing this forces a new resource to be created."
}

variable "rg_name" {
  type        = string
  description = "(Required) The name of the Resource Group where this Public IP should exist. Changing this forces a new Public IP to be created."
}

variable "allocation_method" {
  type        = string
  default     = "Static"
  description = "(Required) Defines the allocation method for this IP address. Possible values are Static or Dynamic."
}

variable "sku" {
  type        = string
  default     = "Standard"
  description = "Optional) The SKU of the Public IP. Accepted values are Basic and Standard. Defaults to Basic. Changing this forces a new resource to be created."
}

variable "tags" {
  type        = map(string)
  description = ""
}