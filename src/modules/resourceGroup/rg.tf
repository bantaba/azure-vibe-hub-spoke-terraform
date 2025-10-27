# with for_each with map var
resource "azurerm_resource_group" "resourceGroup" {
  for_each = var.resource_group_names
  name     = "${title(terraform.workspace)}-${each.value}-rg"
  location = var.resource_group_location
  tags     = var.tags 
}
