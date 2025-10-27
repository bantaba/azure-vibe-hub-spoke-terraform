#############################################################################
#      
#############################################################################

resource "azurerm_network_security_group" "main-nsg" {
  name                = var.nsg_name
  location            = var.location
  resource_group_name = var.rg_name
  tags                = var.tags
}

#NSG Rules all
resource "azurerm_network_security_rule" "all_nsg_rules" {
  count = length(local.nsg_rules)
  name                        = "${local.nsg_rules[count.index].name}-${count.index}"
  direction                   = local.nsg_rules[count.index].direction
  access                      = local.nsg_rules[count.index].access
  priority                    = local.nsg_rules[count.index].priority # priority to be in the range (100 - 4096)
  protocol                    = local.nsg_rules[count.index].protocol
  source_address_prefix       = local.nsg_rules[count.index].source_address_prefix
  source_port_range           = local.nsg_rules[count.index].source_port_range
  destination_address_prefix  = local.nsg_rules[count.index].destination_address_prefix
  destination_port_range      = local.nsg_rules[count.index].destination_port_range
  network_security_group_name = azurerm_network_security_group.main-nsg.name
  resource_group_name         = azurerm_network_security_group.main-nsg.resource_group_name
}

resource "azurerm_subnet_network_security_group_association" "subnetNsga" {
  for_each =  var.subnet_id
  subnet_id                 = each.value
  network_security_group_id = azurerm_network_security_group.main-nsg.id 
}

data "azurerm_network_watcher" "NetworkWatcher_westus3" {
  name = "NetworkWatcher_westus3"
  resource_group_name = "NetworkWatcherRG"
}

resource "azurerm_network_watcher_flow_log" "watcher_flow_log" {  
  name = var.network_watcher_flow_log_name
  network_watcher_name = data.azurerm_network_watcher.NetworkWatcher_westus3.name
  resource_group_name = data.azurerm_network_watcher.NetworkWatcher_westus3.resource_group_name
  storage_account_id = var.storage_account_id
  network_security_group_id = azurerm_network_security_group.main-nsg.id
  enabled = true
  version = 2
  retention_policy {
    days = 30 
    enabled = true
  }

  traffic_analytics {
    enabled = true
    interval_in_minutes = 10
    workspace_id = var.law_id
    workspace_region = var.location
    workspace_resource_id = var.law_resource_id
  }
}
