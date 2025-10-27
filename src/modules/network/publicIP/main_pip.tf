
#############################################################################
##               PUBLIC IP  
#############################################################################
resource "azurerm_public_ip" "public_ip" {
  name                = var.pip_name 
  location            = var.location
  resource_group_name = var.rg_name
  allocation_method   = var.allocation_method
  sku                 = var.sku
  
  tags = var.tags   
}
