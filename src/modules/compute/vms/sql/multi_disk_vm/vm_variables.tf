variable "vm_names" {
  type        = set(string)
  description = "Specifies the name(s) of the Virtual Machine."
}

variable "subnet_id" {
  type        = string
  description = "(optional) describe your variable"
}

variable "resource_location" {
  type        = string
  description = "Specifies the Azure Region where the Virtual Machine exists."
}

variable "rg_name" {
  type        = string
  description = "pecifies the name of the Resource Group in which the Virtual Machine should exist."
}

variable "vm_size" {
  type        = string
  default     = "Standard_DS2_v2"
  description = "pecifies the size of the Virtual Machine. Reference https://learn.microsoft.com/en-us/azure/virtual-machines/sizes-general"
}

variable "delete_data_disks_on_termination" {
  type        = bool
  default     = true
  description = "Should the Data Disks (either the Managed Disks / VHD Blobs) be deleted when the Virtual Machine is destroyed? Defaults to false."
}

variable "delete_os_disk_on_termination" {
  type        = bool
  default     = true
  description = "Should the OS Disk (either the Managed Disk / VHD Blob) be deleted when the Virtual Machine is destroyed? Defaults to false."
}

variable "ultra_ssd_enabled" {
  type        = bool
  default     = false
  description = " Should Ultra SSD disk be enabled for this Virtual Machine?"
}

variable "create_option" {
  type        = string
  default     = "FromImage"
  description = "Specifies how the OS Disk should be created. Possible values are Attach (managed disks only) and FromImage"
}

variable "os_disk_caching" {
  type        = string
  default     = "ReadWrite"
  description = "Specifies the caching requirements for the OS Disk. Possible values include None, ReadOnly and ReadWrite."
}

variable "provision_vm_agent" {
  type        = bool
  default     = true
  description = "Should the Azure Virtual Machine Guest Agent be installed on this Virtual Machine? Defaults to false."
}

variable "enable_automatic_upgrades" {
  type        = bool
  default     = true
  description = "Are automatic updates enabled on this Virtual Machine? Defaults to false."
}

variable "admin_username" {
  type        = string
  description = "Specifies the name of the local administrator account."
}

variable "admin_password" {
  type        = string
  description = "The password associated with the local administrator account."
}

variable "write_accelerator_enabled" {
  type        = bool
  default     = false
  description = "Specifies if Write Accelerator is enabled on the disk. This can only be enabled on Premium_LRS managed disks with no caching and M-Series VMs. Defaults to false."
}

variable "data_disk_caching" {
  type        = map(string)
  description = "Specifies the caching requirements for the Data Disk. Possible values include None, ReadOnly and ReadWrite."
  default = {
    none = "None"
    RO   = "ReadOnly"
    RW   = "ReadWrite"
  }
}

variable "data_disk_create_option" {
  type        = map(string)
  description = "Specifies the caching requirements for the Data Disk. Possible values include None, ReadOnly and ReadWrite."
  default = {
    empty      = "Empty"
    attach     = "Attach"
    from_image = "FromImage"
  }
}

# variable "" {
#     type = string
#     default = "Standard_LRS"
#     description = "Specifies the type of managed disk to create. Possible values are either Standard_LRS, StandardSSD_LRS, Premium_LRS or UltraSSD_LRS."
# }

variable "managed_disk_type" {
  type        = map(string)
  description = "Specifies the type of managed disk to create. Possible values are either Standard_LRS, StandardSSD_LRS, Premium_LRS or UltraSSD_LRS."
  default = {
    standard     = "Standard_LRS"
    standard_ssd = "StandardSSD_LRS"
    premium      = "Premium_LRS"
    ultra_ssd    = "UltraSSD_LRS"
  }
}

variable "data_disk_size_gb" {
  type = map(number)
  default = {
    minimal = 64
    BAK     = 1024
    DATA    = 1024
    LOGS    = 1024
    TEMPDB  = 512
  }
  description = "Specifies the size of the data disk in gigabytes."
}

variable "storage_image_reference" {
  type = list(object({
    publisher = string
    offer     = string
    sku       = string
    version   = string
  }))
  description = "This block provisions the Virtual Machine from one of two sources: an Azure Platform Image (e.g. Ubuntu/Windows Server) or a Custom Image"
  default = [{
    publisher = "microsoftsqlserver"
    offer     = "sql2022-ws2022"
    sku       = "enterprise-gen2"
    version   = "latest"
  }]
}

variable "availability_set_id" {
  type        = string
  description = "The ID of the Availability Set in which the Virtual Machine should exist."
}

variable "user_managed_identity_id" {
  type        = string
  description = "Specifies a list of User Assigned Managed Identity IDs to be assigned to this Virtual Machine."
}


variable "tags" {
  type        = map(string)
  description = " (Optional) A mapping of tags which should be assigned to this Virtual Machine Scale Set"
}