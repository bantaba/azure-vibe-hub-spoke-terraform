output "rg_name" {
  description = "Map of resource group names by their logical purpose"
  value = {
    for name in keys(var.resource_group_names) : name => azurerm_resource_group.resourceGroup[name].name
  }
}

output "rg_id" {
  description = "Map of resource group resource IDs by their logical purpose"
  value = {
    for id in keys(var.resource_group_names) : id => azurerm_resource_group.resourceGroup[id].id
  }
}

output "rg_location" {
  description = "Map of resource group locations by their logical purpose"
  value = {
    for location in keys(var.resource_group_names) : location => azurerm_resource_group.resourceGroup[location].location
  }
}

output "resource_group_details" {
  description = "Complete details of all created resource groups including name, ID, location, and tags"
  value = {
    for key in keys(var.resource_group_names) : key => {
      name     = azurerm_resource_group.resourceGroup[key].name
      id       = azurerm_resource_group.resourceGroup[key].id
      location = azurerm_resource_group.resourceGroup[key].location
      tags     = azurerm_resource_group.resourceGroup[key].tags
    }
  }
}