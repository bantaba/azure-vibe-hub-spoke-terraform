variable "sa_name" {
    type = string
    nullable = false

    validation { # check for valid name char
      condition = can(regex("^[a-z0-9]{3,24}$", var.sa_name))
      error_message = "The storage_account_name resource variable name must be between 3-24 characters in length, and contains only lowercase numbers and letters."
    }

    # validation {
    #   condition = length(var.sa_name) >=3 && length(var.sa_name ) <= 24
    #   error_message = "The storage_account_name resource variable name must be between 3-24 characters in length."
    # }

    description = "Name of the storage account"
}

variable "sa_location" {
  type = string
  default = "westUS2"
  nullable = false
  description = "Location where the resources will be created."
}

variable "sa_rg_name" {
  type = string
  sensitive = false
  nullable = false
  description = "name of the resource group to create the resource"
}

variable "account_kind" {
  description = "Defines the Kind of account. Valid options are BlobStorage, BlockBlobStorage, FileStorage, Storage and StorageV2"
  type        = string
  sensitive = false
  nullable = false
  default     = "StorageV2"

  validation {
    condition     = (contains(["BlobStorage", "BlockBlobStorage", "Storage", "FileStorage", "StorageV2"], var.account_kind))
    error_message = "The account_kind must be one of: \"BlobStorage\", \"BlockBlobStorage\", \"FileStorage\", \"Storage\" or \"StorageV2\"."
  }
}

variable "account_tier" {
  description = "Defines the Tier to use for this storage account (Standard or Premium)."
  type        = string
  sensitive = false
  nullable = false
  default     = "Standard"

  validation {
    condition     = (contains(["Standard", "Premium"], title(var.account_tier)))
    error_message = "The account_tier must be either \"Standard\" or \"Premium\"."
  }
}


variable "replication_type" {
  description = "Storage account replication type - i.e. LRS, GRS, RAGRS, ZRS, GZRS, RAGZRS."
  type        = string
  nullable = false
  default = "LRS"

  validation {
    condition = (contains(["LRS", "GRS", "RAGRS", "ZRS", "GZRS", "RAGZRS"], var.replication_type))
    error_message = "Replication account must of one of the following LRS, GRS, RAGRS, ZRS, GZRS, RAGZRS."
  }
}

variable "enable_https_traffic_only" {
  description = "Forces HTTPS if enabled."
  type        = bool
  nullable = false
  default     = true

  validation {
    condition     = can(regex("^(true|false)$", var.enable_https_traffic_only))
    error_message = "Invalid input, options: \"true\", \"false\"."
  }
}

variable "min_tls_version" {
  description = "The minimum supported TLS version for the storage account."
  type        = string
  nullable = false
  default     = "TLS1_2"
}

variable "infrastructure_encryption_enabled" {
  description = "Is infrastructure encryption enabled? Changing this forces a new resource to be created."
  type        = bool
  default     = true
}

variable "container_delete_retention_days" {
  description = "Retention days for deleted container. Valid value is between 1 and 365 (set to 0 to disable)."
  type        = number
  nullable = false
  default     = 7
}

variable "sa_container_name" {
    type = string
    nullable = false
    description = "The name of the Container which should be created within the Storage Account. Changing this forces a new resource to be created."

    validation { # check for valid name char # ([a-zA-Z0-9-]* == [\w-]*) 
      condition = can(regex("^[a-z0-9-]{3,24}$", var.sa_container_name))
      error_message = "The storage_account_name resource variable name must be between 3-24 characters in length, and only lowercase alphanumeric characters and hyphens allowed."
    }
}

variable "sa_blob_type" {
    type = string
    nullable = false
    default = "Block"
    description = "he type of the storage blob to be created. Possible values are Append, Block or Page."

    validation {
      condition = (contains(["Append", "Block", "Page"], var.sa_blob_type))    
      error_message = "Invalid input, can be one of the following: \"Append\", \"Block\", or \"Page\"."
    }    
}

variable "container_access_type" {
    type = string
    default = "private"
    nullable = false
    description = "The Access Level configured for this Container. Possible values are blob, container or private. Defaults to private."

    validation {
      condition = (contains(["blob", "container", "private"], var.container_access_type))    
      error_message = "Invalid input, can be one of the following: \"blob\", \"container\", or \"private\"."
    }
}

variable "access_tier" {
    type = string
    default = "Hot"
    nullable = false
    description = "Defines the access tier for BlobStorage, FileStorage and StorageV2 accounts. Valid options are Hot and Cool, defaults to Hot."

    validation {
      condition = (contains(["Hot", "Cool"], var.access_tier))    
      error_message = "Invalid input, can be one of: \"Hot\", or \"Cool\"."
    }
}

variable "allow_nested_items_to_be_public" {
  type = bool
  default = false
  description = "(optional) describe your variable"
}

variable "tags" {
  type = map(string)
  nullable = false
  description = "tags to be applied to resources"
}