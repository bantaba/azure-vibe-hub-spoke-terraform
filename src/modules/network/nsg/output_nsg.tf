output "nsgName" {
  value       = azurerm_network_security_group.main-nsg.name
  description = "NSG name"
}

output "nsgID" {
  value       = azurerm_network_security_group.main-nsg.id
  description = "NSG ID"
}

# output "netWatcherName" {
#     value = azurerm_network_watcher.netWatcher.name
# }