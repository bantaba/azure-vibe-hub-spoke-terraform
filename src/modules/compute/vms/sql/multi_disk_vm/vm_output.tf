output "nic_string_ids" { #Output as string
  value = [
    for nic_id in azurerm_network_interface.nic : nic_id.id
  ]
}

output "virtual_machine_ids" {
  value = [
    for vm in azurerm_virtual_machine.vm_multidisk : vm.id
  ]
}

output "nic-ip-config-name" {
  value = [
    for n in azurerm_network_interface.nic : n.ip_configuration[0].name
  ]
}


output "datadb_lun" {
  value = [
    for l in azurerm_virtual_machine.vm_multidisk : l.storage_data_disk[0].lun
  ]
}

output "logdb_lun" {
  value = [
    for l in azurerm_virtual_machine.vm_multidisk : l.storage_data_disk[1].lun
  ]
}

output "tempdb_lun" {
  value = [
    for l in azurerm_virtual_machine.vm_multidisk : l.storage_data_disk[2].lun
  ]
}

output "data_disk_luns" {
  value = [
    flatten([for l in azurerm_virtual_machine.vm_multidisk : l.storage_data_disk[*].lun])
  ]
}

output "data_disk_luns_map" {
  value = tomap({
    for k, v in azurerm_virtual_machine.vm_multidisk : k => v.storage_data_disk[*].lun
  })
}

