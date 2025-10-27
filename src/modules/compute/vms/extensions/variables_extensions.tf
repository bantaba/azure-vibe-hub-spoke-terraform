variable "virtual_machine_id" {
    type = set(string)
    description = "The ID of the Virtual Machine. Changing this forces a new resource to be created"
}

# variable "analytics_workspace_id" {
#     type = string
#     sensitive = false
#     description = "The Workspace (or Customer) ID for the Log Analytics Workspace."
# }


# variable "analytics_workspace_key" { 
#     type = string
#     sensitive = true
#     description = "The Primary/Secondary shared key for the Log Analytics Workspace."
# }

# # variable "vault_observed_certificate" { 
# #     type = string
# #     description = ""
# # }

# variable "storage_acct_name" {
#     type = string
#     description = " Specifies the name of the storage account to associate with."
# }

# variable "storage_acct_key" {
#     type = string
#     sensitive = true
#     description = "The primary/secondary access key for the storage account."
# }

# variable "active_directory_password" {
#     type = string
#     nullable = false
#     description = "Domain user password"
# }

# variable "active_directory_username" {
#     type = string
#     nullable = false
#     description = "Domain NetBiosName plus User name of a domain user with sufficient rights to perfom domain join operation. E.g. domain\\username"
# }

# variable "ou_path" {
#     type = string
#     nullable = false
#     description = "Specifies an organizational unit (OU) for the domain account. Enter the full distinguished name of the OU in quotation marks. Example: \"OU=testOU; DC=domain; DC=Domain; DC=com\""
# }

# variable "active_directory_domain" {
#     type = string
#     nullable = false
#     description = "Domain FQDN name of the Active Directory domain where the virtual machine will be joined."
# }

variable "location" {
    type = string
    description = "Specifies the supported Azure location where the resource exists."
}

variable "dsc_server_endpoint" {
    type = string
    description = "The endpoint of the DSC server"
}

variable "dsc_config" {
    type = string
    description = "The DSC Node Configuration name"
}

variable "dsc_mode" {
    type = string
    default = "ApplyAndMonitor"
    description = "Specifies how the LCM actually applies the configuration to the target nodes. Possible values are ApplyOnly, ApplyAndMonitor, and ApplyAndAutoCorrect."
}
variable "dsc_primary_access_key" {
    type = string
    sensitive = true
    description = "The DSC Primary/Secondary access key"
}

