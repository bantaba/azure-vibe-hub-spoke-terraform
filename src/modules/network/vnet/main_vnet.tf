
resource "azurerm_virtual_network" "vnet" {
  name                = var.vnet_name 
  resource_group_name = var.rg_name 
  location            = var.rg_location                                  
  address_space       = var.vnet_address_space
  dns_servers = [ "192.168.10.4", "1.1.1.1" ]
  tags                = var.tags 
}



