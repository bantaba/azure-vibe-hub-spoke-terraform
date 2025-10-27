# Enhanced RBAC role assignment with least privilege principles

# Validate least privilege role assignment
locals {
  # Define least privilege role mappings for different resource types
  least_privilege_roles = {
    keyvault = [
      "Key Vault Secrets User", "Key Vault Crypto User", "Key Vault Certificate User",
      "Key Vault Secrets Officer", "Key Vault Crypto Officer", "Key Vault Administrator"
    ]
    storage = [
      "Storage Blob Data Reader", "Storage Blob Data Contributor", "Storage Blob Data Owner"
    ]
    compute = [
      "Virtual Machine Contributor", "Virtual Machine User Login"
    ]
    network = [
      "Network Contributor", "DNS Zone Contributor"
    ]
    general = [
      "Reader", "Contributor", "Owner", "User Access Administrator", "Security Reader", "Security Admin"
    ]
  }

  # Validate role assignment follows least privilege
  is_least_privilege = var.enable_least_privilege ? contains(local.least_privilege_roles[var.resource_type], var.role_definition_name) : true
}

# Data source for role definition
data "azurerm_role_definition" "builtin_role" {
  name  = var.role_definition_name
  scope = var.primary_subscription_id
}

# Enhanced role assignment with conditional access and validation
resource "azurerm_role_assignment" "role_assignment" {
  scope                                  = var.scope
  role_definition_id                     = data.azurerm_role_definition.builtin_role.id
  principal_id                           = var.resource_principal_id
  condition                              = var.condition
  condition_version                      = var.condition_version
  delegated_managed_identity_resource_id = var.delegated_managed_identity_resource_id
  description                            = var.description != null ? var.description : "Role assignment for ${var.role_definition_name} to ${var.principal_type}"
  skip_service_principal_aad_check       = var.skip_service_principal_aad_check

  # Lifecycle management
  lifecycle {
    precondition {
      condition     = local.is_least_privilege
      error_message = "Role assignment does not follow least privilege principles for resource type ${var.resource_type}. Allowed roles: ${join(", ", local.least_privilege_roles[var.resource_type])}"
    }
  }
}

# Audit log for role assignments
resource "azurerm_monitor_diagnostic_setting" "role_assignment_audit" {
  count                      = var.enable_audit_logging ? 1 : 0
  name                       = "role-assignment-audit-${substr(var.resource_principal_id, 0, 8)}"
  target_resource_id         = var.scope
  log_analytics_workspace_id = var.log_analytics_workspace_id

  enabled_log {
    category = "Administrative"
  }

  enabled_log {
    category = "Security"
  }
}
