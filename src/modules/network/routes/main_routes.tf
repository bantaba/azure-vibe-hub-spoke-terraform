
resource "azurerm_route_table" "main-routeTable" {
  name                          = var.routableName            // "${var.mainName}-RouteTable"
  location                      = var.routableLocation        // azurerm_resource_group.main-vnet.location
  resource_group_name           = var.routeTableResourceGroup // azurerm_resource_group.main-vnet.name
  disable_bgp_route_propagation = true
  tags                          = var.tag
}

resource "azurerm_route" "main-route" {
  name                = var.routeName //"${var.mainName}-route"
  resource_group_name = azurerm_resource_group.main-vnet.name
  route_table_name    = azurerm_route_table.main-routeTable.name
  address_prefix      = var.routeAddrPrefix //var.subnet_prefixes[0]
  next_hop_type       = "None"              //VirtualNetworkGateway, VnetLocal, Internet, VirtualAppliance (require *ip_address) and None
  #   next_hop_in_ip_address = "192.168.1.1"
}