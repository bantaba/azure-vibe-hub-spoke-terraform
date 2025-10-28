
output "lab_vnet_id" {
  description = "The resource ID of the virtual network"
  value       = azurerm_virtual_network.vnet.id
}

output "vnet_name" {
  description = "The name of the virtual network"
  value       = azurerm_virtual_network.vnet.name
}

output "vnet_location" {
  description = "The Azure region where the virtual network is deployed"
  value       = azurerm_virtual_network.vnet.location
}

output "vnet_rg_name" {
  description = "The name of the resource group containing the virtual network"
  value       = azurerm_virtual_network.vnet.resource_group_name
}

output "vnet_address_space" {
  description = "The address space(s) used by the virtual network"
  value       = azurerm_virtual_network.vnet.address_space
}

output "vnet_guid" {
  description = "The GUID of the virtual network"
  value       = azurerm_virtual_network.vnet.guid
  sensitive   = false
}

output "vnet_details" {
  description = "Complete details of the virtual network including all properties"
  value = {
    id            = azurerm_virtual_network.vnet.id
    name          = azurerm_virtual_network.vnet.name
    location      = azurerm_virtual_network.vnet.location
    address_space = azurerm_virtual_network.vnet.address_space
    guid          = azurerm_virtual_network.vnet.guid
    tags          = azurerm_virtual_network.vnet.tags
  }
}
