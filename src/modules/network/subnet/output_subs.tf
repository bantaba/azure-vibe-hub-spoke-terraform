output "map_of_subnet_id" {
  value = {
    for id in keys(var.subnets) : id => azurerm_subnet.PrivateSubs[id].id
  }
  description = "Lists the ID's of the subnet"
}

output "subnet_ids" {
  description = "The name of the subnet addresses"
  value       = {for k, v in azurerm_subnet.PrivateSubs: k => v.id}
} 


output "azure_subnet_id" {
  value = {
    for id in keys(var.subnets) : id => azurerm_subnet.PrivateSubs[id].id
  }
  description = "Lists the ID's of the subnet"
}

output "list_of_subnet_ids" {
  value = [
    for id in azurerm_subnet.PrivateSubs : id.id
  ]
}

output "route_table_ids" {
  description = "Map of route table IDs"
  value = var.enable_custom_routes ? {
    for k, v in azurerm_route_table.subnet_routes : k => v.id
  } : {}
}

output "subnet_address_prefixes" {
  description = "Map of subnet address prefixes"
  value = {
    for k, v in azurerm_subnet.PrivateSubs : k => v.address_prefixes
  }
}
