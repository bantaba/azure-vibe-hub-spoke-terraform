output "vmss_id" {
    value = azurerm_windows_virtual_machine_scale_set.vmss.id
}

output "vmss_nic_name" {
    value = azurerm_windows_virtual_machine_scale_set.vmss.network_interface[0].ip_configuration[0].name
}

output "subnet_id" {
    value = azurerm_windows_virtual_machine_scale_set.vmss.network_interface[0].ip_configuration[0].subnet_id
}

# output "nic_id" {
#     value = azurerm_windows_virtual_machine_scale_set.vmss.network_interface[0].ip_configuration[0].
# }