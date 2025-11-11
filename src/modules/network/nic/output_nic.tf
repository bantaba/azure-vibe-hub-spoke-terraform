output "nic_ids" { #Output as map
  value = { for k, v in azurerm_network_interface.nic : k => v.id }
}

output "nic_to_map_ids" { #Output as map
  value = tomap({ for k, s in azurerm_network_interface.nic : k => s.id })
}

output "nic_string_ids" { #Output as string(list)
  value = [
    for ids in azurerm_network_interface.nic : ids.id
  ]
}

output "nic_names" {
  value = [
    for intNic in azurerm_network_interface.nic : intNic.name
  ]
}

output "nic-ip-config-names" {
  value = [
    for n in azurerm_network_interface.nic : n.ip_configuration[0].name
  ]
}