output "nic-ip-config-name" {
    value = [
        for n in azurerm_network_interface.nic : n.ip_configuration[0].name
    ]
}

output "nic_string_ids" { #Output as string
value = [
    for nic_id in azurerm_network_interface.nic : nic_id.id
]
} 

output "virtual_machine_ids" { 
    value = [
    for vm in azurerm_windows_virtual_machine.WindowsVM : vm.id
    ] 
}

