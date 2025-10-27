output "role_assignment_id" {
  description = "The ID of the role assignment"
  value       = azurerm_role_assignment.role_assignment.id
}

output "role_assignment_name" {
  description = "The name of the role assignment"
  value       = azurerm_role_assignment.role_assignment.name
}

output "role_definition_name" {
  description = "The name of the role definition"
  value       = data.azurerm_role_definition.builtin_role.name
}

output "role_definition_id" {
  description = "The ID of the role definition"
  value       = data.azurerm_role_definition.builtin_role.id
}

output "principal_id" {
  description = "The principal ID assigned the role"
  value       = azurerm_role_assignment.role_assignment.principal_id
}

output "scope" {
  description = "The scope of the role assignment"
  value       = azurerm_role_assignment.role_assignment.scope
}

output "principal_type" {
  description = "The type of principal assigned the role"
  value       = var.principal_type
}

output "resource_type" {
  description = "The resource type this role assignment is for"
  value       = var.resource_type
}

output "least_privilege_compliant" {
  description = "Whether this role assignment follows least privilege principles"
  value       = local.is_least_privilege
}