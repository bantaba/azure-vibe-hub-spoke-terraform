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
    prevent_destroy = var.prevent_destroy
  }
}

# Federated identity credential for enhanced security
resource "azurerm_user_assigned_identity_federated_identity_credential" "federated_credential" {
  count               = var.enable_federated_identity ? 1 : 0
  name                = "${var.uami_name}-federated-credential"
  resource_group_name = var.uami_resource_group_name
  parent_id           = azurerm_user_assigned_identity.User_identity.id
  audience            = var.federated_audience
  issuer              = var.federated_issuer
  subject             = var.federated_subject
}