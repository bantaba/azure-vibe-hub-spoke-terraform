resource "azurerm_subnet" "PrivateSubs" {
  for_each             = var.subnets
  name = ( (each.value["name"] == "AzureBastionSubnet") || (each.value["name"] == "GatewaySubnet") || (each.value["name"] == "AzureFirewallSubnet") ) ? each.value["name"] : "${each.value["name"]}-${title(terraform.workspace)}"
  resource_group_name  = var.rg_name
  virtual_network_name = var.vnet
  address_prefixes     = each.value["addressPrefixes"]

  # Enhanced service endpoints based on subnet purpose
  service_endpoints = ( (each.value["name"] == "AzureBastionSubnet") || each.value["name"] == "AzureFirewallSubnet" || each.value["name"] == "GatewaySubnet" ) ? null : [
    "Microsoft.Storage", 
    "Microsoft.AzureActiveDirectory", 
    "Microsoft.KeyVault",
    "Microsoft.Sql",
    "Microsoft.Web",
    "Microsoft.AzureCosmosDB"
  ]

  # Enhanced security features
  private_endpoint_network_policies_enabled     = lookup(each.value, "private_endpoint_network_policies_enabled", true)
  private_link_service_network_policies_enabled = lookup(each.value, "private_link_service_network_policies_enabled", true)

  # Delegation for specific services if specified
  dynamic "delegation" {
    for_each = lookup(each.value, "delegation", null) != null ? [each.value.delegation] : []
    content {
      name = delegation.value.name
      service_delegation {
        name    = delegation.value.service_delegation.name
        actions = delegation.value.service_delegation.actions
      }
    }
  }
}

# Route table for enhanced network segmentation
resource "azurerm_route_table" "subnet_routes" {
  for_each                      = var.enable_custom_routes ? var.subnets : {}
  name                          = "${each.value["name"]}-rt-${title(terraform.workspace)}"
  location                      = var.location
  resource_group_name           = var.rg_name
  disable_bgp_route_propagation = lookup(each.value, "disable_bgp_route_propagation", false)

  dynamic "route" {
    for_each = lookup(each.value, "routes", [])
    content {
      name                   = route.value.name
      address_prefix         = route.value.address_prefix
      next_hop_type          = route.value.next_hop_type
      next_hop_in_ip_address = lookup(route.value, "next_hop_in_ip_address", null)
    }
  }

  tags = var.tags
}

# Associate route tables with subnets
resource "azurerm_subnet_route_table_association" "subnet_route_association" {
  for_each       = var.enable_custom_routes ? var.subnets : {}
  subnet_id      = azurerm_subnet.PrivateSubs[each.key].id
  route_table_id = azurerm_route_table.subnet_routes[each.key].id
}
