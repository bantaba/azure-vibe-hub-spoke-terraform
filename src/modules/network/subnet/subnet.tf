resource "azurerm_subnet" "PrivateSubs" {
  for_each             = var.subnets
  name = ( (each.value["name"] == "AzureBastionSubnet") || (each.value["name"] == "GatewaySubnet") || (each.value["name"] == "AzureFirewallSubnet") ) ? each.value["name"] : "${each.value["name"]}-${title(terraform.workspace)}"
  resource_group_name  = var.rg_name
  virtual_network_name = var.vnet
  address_prefixes     = each.value["addressPrefixes"]

 service_endpoints = ( (each.value["name"] == "AzureBastionSubnet") || each.value["name"] == "AzureFirewallSubnet" || each.value["name"] == "GatewaySubnet" ) ? null : ["Microsoft.Storage", "Microsoft.AzureActiveDirectory", "Microsoft.KeyVault" ] 

}
