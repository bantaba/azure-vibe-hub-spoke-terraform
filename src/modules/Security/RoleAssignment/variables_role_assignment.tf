variable "role_definition_name" {
  type        = string
  description = "The name of the built-in role definition to assign"
  
  validation {
    condition = contains([
      "Owner", "Contributor", "Reader", "User Access Administrator",
      "Key Vault Administrator", "Key Vault Secrets User", "Key Vault Secrets Officer",
      "Key Vault Crypto User", "Key Vault Crypto Officer", "Key Vault Certificate User",
      "Storage Blob Data Owner", "Storage Blob Data Contributor", "Storage Blob Data Reader",
      "Virtual Machine Contributor", "Network Contributor", "Security Admin", "Security Reader"
    ], var.role_definition_name)
    error_message = "Role definition name must be a valid Azure built-in role."
  }
}

variable "scope" {
  type        = string
  description = "The scope at which the role assignment applies"
}

variable "resource_principal_id" {
  type        = string
  description = "The principal ID of the user, group, or service principal to assign the role to"
}

variable "primary_subscription_id" {
  type        = string
  description = "The primary subscription ID for role definition lookup"
}

# Enhanced RBAC variables
variable "condition" {
  type        = string
  default     = null
  description = "The condition that limits the resources that the role can be assigned to"
}

variable "condition_version" {
  type        = string
  default     = null
  description = "The version of the condition syntax"
  
  validation {
    condition = var.condition_version == null || contains(["1.0", "2.0"], var.condition_version)
    error_message = "Condition version must be either '1.0' or '2.0'."
  }
}

variable "delegated_managed_identity_resource_id" {
  type        = string
  default     = null
  description = "The delegated Azure Resource Id which contains a Managed Identity"
}

variable "description" {
  type        = string
  default     = null
  description = "The description for this role assignment"
}

variable "skip_service_principal_aad_check" {
  type        = bool
  default     = false
  description = "Skip the Azure Active Directory check for the service principal"
}

variable "tags" {
  type        = map(string)
  default     = {}
  description = "A mapping of tags to assign to the role assignment"
}

# Least privilege role mappings
variable "enable_least_privilege" {
  type        = bool
  default     = true
  description = "Enable least privilege role assignment validation"
}

variable "resource_type" {
  type        = string
  default     = "general"
  description = "The type of resource this role assignment is for (keyvault, storage, compute, network)"
  
  validation {
    condition = contains(["general", "keyvault", "storage", "compute", "network"], var.resource_type)
    error_message = "Resource type must be one of: general, keyvault, storage, compute, network."
  }
}

variable "principal_type" {
  type        = string
  default     = "ServicePrincipal"
  description = "The type of principal (User, Group, ServicePrincipal)"
  
  validation {
    condition = contains(["User", "Group", "ServicePrincipal"], var.principal_type)
    error_message = "Principal type must be one of: User, Group, ServicePrincipal."
  }
}

variable "enable_audit_logging" {
  type        = bool
  default     = true
  description = "Enable audit logging for role assignments"
}

variable "log_analytics_workspace_id" {
  type        = string
  default     = null
  description = "The ID of the Log Analytics workspace for audit logging"
}