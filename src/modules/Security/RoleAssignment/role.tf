# 

data "azurerm_role_definition" "builtin_role" { 
  # role_definition_id = var.role_definition_id
  name = var.role_definition_name
  scope = var.primary_subscription_id
}

resource "azurerm_role_assignment" "role_assignment" {
  scope              = var.scope
  role_definition_id = data.azurerm_role_definition.builtin_role.id
  principal_id       = var.resource_principal_id  #data.azurerm_client_config.current.object_id // Assign to specific SG
}