variable "role_definition_name" {
    type = string
    description = "The name of a built-in Role. Changing this forces a new resource to be created. Conflicts with role_definition_id."
}

# variable "role_definition_id" {
#     type = string
#     description = "A unique UUID/GUID which identifies this role - one will be generated if not specified. "
# }

variable "resource_principal_id" {
    type = string
    description = "The ID of the Principal (User, Group or Service Principal) to assign the Role Definition to. The Principal ID is also known as the Object ID (ie not the \"Application ID\" for applications)."
}

variable "scope" {
    type = string
    description = "The scope at which the Role Definition applies to, such as /subscriptions/0b1f6471-1bf0-4dda-aec3-111122223333, /subscriptions/0b1f6471-1bf0-4dda-aec3-111122223333/resourceGroups/myGroup, or /subscriptions/0b1f6471-1bf0-4dda-aec3-111122223333/resourceGroups/myGroup/providers/Microsoft.Compute/virtualMachines/myVM. It is recommended to use the first entry of the assignable_scopes."
}

variable "primary_subscription_id" {
    type = string
    description = "The subscription ID to associate with."
}