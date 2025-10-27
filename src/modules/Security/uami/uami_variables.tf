variable "uami_name" {
    type        = string
    description = "The name of the User Assigned Managed Identity"
    
    validation {
        condition     = can(regex("^[a-zA-Z0-9-_]{3,128}$", var.uami_name))
        error_message = "UAMI name must be 3-128 characters and contain only alphanumeric characters, hyphens, and underscores."
    }
}

variable "uami_location" {
    type        = string
    description = "The Azure region where the User Assigned Managed Identity will be created"
}

variable "uami_resource_group_name" {
    type        = string
    description = "The name of the resource group where the User Assigned Managed Identity will be created"
}

variable "tags" {
    type        = map(string)
    description = "A mapping of tags to assign to the User Assigned Managed Identity"
    default     = {}
}

# Enhanced security variables
variable "identity_purpose" {
    type        = string
    description = "The purpose of this managed identity (e.g., 'KeyVault Access', 'Storage Access', 'Compute Access')"
    default     = "General Purpose"
}

variable "prevent_destroy" {
    type        = bool
    description = "Prevent accidental destruction of the managed identity"
    default     = true
}

variable "enable_federated_identity" {
    type        = bool
    description = "Enable federated identity credential for enhanced security"
    default     = false
}

variable "federated_audience" {
    type        = list(string)
    description = "The audience for the federated identity credential"
    default     = ["api://AzureADTokenExchange"]
}

variable "federated_issuer" {
    type        = string
    description = "The issuer for the federated identity credential"
    default     = null
}

variable "federated_subject" {
    type        = string
    description = "The subject for the federated identity credential"
    default     = null
}