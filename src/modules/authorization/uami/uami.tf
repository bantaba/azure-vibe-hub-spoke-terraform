resource "azurerm_user_assigned_identity" "User_identity" {
  location            = var.uami_location
  name                = var.uami_name
  resource_group_name = var.uami_resource_group_name

  tags = var.tags
}