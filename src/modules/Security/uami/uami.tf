resource "azurerm_user_assigned_identity" "User_identity" {
  location            = var.uami_location
  name                = var.uami_name
  resource_group_name = var.uami_resource_group_name

  tags = merge(var.tags, {
    SecurityLevel = "Enhanced"
    LastUpdated   = timestamp()
    Purpose       = var.identity_purpose
  })

  lifecycle {
    prevent_destroy = true
  }
}

# Note: Federated identity credential resource is not available in this provider version
# This feature would require azurerm provider version 3.70.0 or later