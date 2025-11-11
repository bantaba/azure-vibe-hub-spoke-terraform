variable "avset_location" {
  type        = string
  nullable    = false
  description = "Specifies the supported Azure location where the resource exists."
}

variable "avset_name" {
  type        = string
  nullable    = false
  description = "Specifies the name of the availability set. "
}

variable "avset_rg_name" {
  type        = string
  nullable    = false
  description = "The name of the resource group in which to create the availability set."
}

variable "platform_fault_domain_count" {
  type        = number
  default     = 2
  description = "Specifies the number of fault domains that are used. Defaults to 3."
}

variable "platform_update_domain_count" {
  type        = number
  default     = 2
  description = "Specifies the number of update domains that are used. Defaults to 5. "
}

variable "managed" {
  type        = bool
  default     = true
  nullable    = false
  description = " Specifies whether the availability set is managed or not. Possible values are true (to specify aligned) or false (to specify classic). Default is true."
}

variable "tags" {
  type        = map(string)
  nullable    = false
  description = "(optional) describe your variable"
}