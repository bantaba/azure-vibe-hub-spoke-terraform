
variable "vm_names" {
    type = set(string)
    description = "The name(s) of the Windows Virtual Machine."
}


variable "rg_name" {
    type = string
    description = "The name of the Resource Group in which the Windows Virtual Machine should be exist."
}

variable "subnet_id" {
    type = string
    description = "The subnet id for the Windows Virtual Machine(s) to be assigned"
}


variable "resource_location" {
    type = string
    description = "The Azure location where the Windows Virtual Machine should exist. "
}


variable "vm_size" {
    type = string
    default = "Standard_B2s"
    description = "The SKU which should be used for this Virtual Machine, such as Standard_B2s"
}

variable "availability_set_id" {
    type = string
    description = "(optional) describe your variable"
}

# variable "vault_id" {
#     type = string
#     description = "The ID of the Key Vault from which all Secrets should be sourced."
# }

# variable "vault_cert_secret_id" {
#     type = string
#     description = "The Secret URL of a Key Vault Certificate."
# }

variable "admin_password" {
    type = string
    sensitive = true
    description = "The Password which should be used for the local-administrator on this Virtual Machine. "
}

variable "admin_username" {
    type = string
    description = "The username of the local administrator used for the Virtual Machine. "
}


variable "tags" {
    type = map(string)
    description = "(optional) describe your variable"
}

variable "user_managed_identity_id" {
    type = string
    description = "Specifies the type of Managed Service Identity that should be configured on this Windows Virtual Machine. Possible values are SystemAssigned, UserAssigned, SystemAssigned, UserAssigned (to enable both)."
}

variable "vtpm_enabled" {
    type = bool
    default = true
    nullable = false
    description = "Specifies if vTPM (virtual Trusted Platform Module) and Trusted Launch is enabled for the Virtual Machine."

}

variable "patch_mode" {
    type = string
    default = "AutomaticByPlatform"
    nullable = false
    description = "Specifies the mode of in-guest patching to this Windows Virtual Machine. Possible values are Manual, AutomaticByOS and AutomaticByPlatform. Defaults to AutomaticByOS."
    
    validation {
      condition = (contains(["Manual", "Block", "AutomaticByOS", "AutomaticByPlatform"], var.patch_mode))    
      error_message = "Invalid input, can be one of the following: \"Manual\", \"AutomaticByOS\", or \"AutomaticByPlatform\"."
    }
}


variable "enable_automatic_updates" {
    type = bool
    default = true
    nullable = false
    description = "Specifies if Automatic Updates are Enabled for the Windows Virtual Machine."

}

variable "encryption_at_host_enabled" {
    type = bool
    default = false
    nullable = false
    description = "Should all of the disks (including the temp disk) attached to this Virtual Machine be encrypted by enabling Encryption at Host?"

}

variable "provision_vm_agent" {
    type = bool
    default = true
    nullable = false
    description = "Should the Azure VM Agent be provisioned on this Virtual Machine? Defaults to true."

}

variable "hotpatching_enabled" {
    type = string
    nullable = false
    default = false
    description = "Should the VM be patched without requiring a reboot? Possible values are true or false. Defaults to false. "
}

variable "ultra_ssd_enabled" {
    type = bool
    default = false
    nullable = false
    description = "Should the capacity to enable Data Disks of the UltraSSD_LRS storage account type be supported on this Virtual Machine? Defaults to false."

}

variable "storage_account_uri" {
    type = string
    description = "The storage account blob endpoint to associate."
}

# variable "os_disk" {
#     type = map(object)
#     description = "(optional) describe your variable"
#     default = {
#         key1 = "val1"
#         key2 = "val2"
#     }
# }

/* Image ref

2022-datacenter-azure-edition                     
2022-datacenter-azure-edition-core                
2022-datacenter-azure-edition-core-smalldisk      
2022-datacenter-azure-edition-hotpatch            
2022-datacenter-azure-edition-hotpatch-smalldisk  
2022-datacenter-azure-edition-smalldisk

2022-datacenter-smalldisk-g2
2022-datacenter-g2
*/
