output "rg_name" {
    value = {
        for name in keys(var.resource_group_names) : name => azurerm_resource_group.resourceGroup[name].name
    }
}

output "rg_id" {
    value = {
        for id in keys(var.resource_group_names) : id => azurerm_resource_group.resourceGroup[id].id
    }
}

output "rg_location" {
    value = {
        for location in keys(var.resource_group_names) : location => azurerm_resource_group.resourceGroup[location].location
    }
}