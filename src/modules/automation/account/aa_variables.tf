# data "local_file" "start_vm_ps1" {
#   filename = "../runbooks/powershell/start-VM.ps1"
# }

variable "aa_name" {
    type = string
    description = "Specifies the name of the Automation Account. Changing this forces a new resource to be created."
}

variable "aa_location" {
    type = string
    description = "Specifies the supported Azure location where the resource exists. Changing this forces a new resource to be created."
}

variable "aa_rg" {
    type = string
    description = "Specifies the supported Azure location where the resource exists. Changing this forces a new resource to be created."
}

variable "tags" {
    type = map(string)
    description = ""
}

variable "frequency" {
    type = string
    default = "Week"
    description = "The frequency of the schedule. - can be either OneTime, Day, Hour, Week, or Month."
}

variable "interval" {
    type = string
    default = "1"
    description = "The number of frequencys between runs. Only valid when frequency is Day, Hour, Week, or Month and defaults to 1."
}

variable "timezone" {
    type = string
    default = "America/Los_Angeles"
    description = "The timezone of the start time. Defaults to UTC. For possible values see: https://docs.microsoft.com/en-us/rest/api/maps/timezone/gettimezoneenumwindows"
}

variable "sku_name" {
    type = string
    default = "Basic"
    description = "The SKU of the account. Possible values are Basic and Free."
}
variable "start_time" {
    type = string
    default = "2023-03-08T07:04:05-08:00"
    description = "Start time of the schedule. Must be at least five minutes in the future. Defaults to seven minutes in the future from the time the resource is created."
}

variable "domain_admin_username" {
    type = string
    description = "Domain admin username"
}

variable "domain_admin_pwd" {
    type = string
    sensitive = true
    description = "Domain admin password"
}

variable "domain_safe_mode_pwd" {
    type = string
    sensitive = true
    description = "Domain controller safe mode password"
}

variable "user_default_username" {
    type = string
    default = "defaultDomainUser"
    description = "sets default username be associated with new user acct. This will not be used in the user's acct"
}

variable "user_default_pwd" {
    type = string
    sensitive = true
    description = "Sets domain password to be used for new user account creation"
}
