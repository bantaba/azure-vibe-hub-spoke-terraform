

#############################################################################
##               BASTION  
#############################################################################

resource "azurerm_bastion_host" "bastion" {
  name                   = var.bastion_name
  location               = var.location
  resource_group_name    = var.rg_name
  sku                    = var.sku
  ip_connect_enabled     = var.ip_connect_enabled
  scale_units            = var.scale_units
  shareable_link_enabled = var.shareable_link_enabled

  ip_configuration {
    name                 = var.ip_configuration_name
    subnet_id            = var.subnet_id
    public_ip_address_id = var.public_ip_address_id
  }

  tunneling_enabled = var.tunneling_enabled
  tags              = var.tags
}
