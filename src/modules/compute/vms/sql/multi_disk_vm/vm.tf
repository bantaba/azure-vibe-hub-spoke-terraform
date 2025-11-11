#############################################################################
#region                  NIC creation
#############################################################################
resource "azurerm_network_interface" "nic" {
  for_each            = var.vm_names
  name                = "${each.value}-nic"
  location            = var.resource_location
  resource_group_name = var.rg_name

  ip_configuration {
    name                          = "internalNic"
    subnet_id                     = var.subnet_id
    private_ip_address_allocation = "Dynamic"
  }

  tags = var.tags
}
#endregion NIC

resource "azurerm_virtual_machine" "vm_multidisk" {
  location                         = var.resource_location
  for_each                         = var.vm_names
  name                             = "${terraform.workspace}${each.value}"
  network_interface_ids            = [azurerm_network_interface.nic[each.key].id]
  resource_group_name              = var.rg_name
  vm_size                          = var.vm_size
  delete_os_disk_on_termination    = "${terraform.workspace}" != "prod" ? var.delete_os_disk_on_termination : false
  delete_data_disks_on_termination = "${terraform.workspace}" != "prod" ? var.delete_data_disks_on_termination : false

  storage_os_disk {
    create_option     = var.create_option
    caching           = var.os_disk_caching
    name              = "${each.value}_os_disk"
    managed_disk_type = terraform.workspace != "prod" ? var.managed_disk_type["standard"] : var.managed_disk_type["premium"]
    disk_size_gb      = 127
    os_type           = "Windows"
  }

  storage_image_reference {
    publisher = "microsoftsqlserver"
    offer     = "sql2022-ws2022"
    sku       = "enterprise-gen2"
    version   = "latest"
  }

  additional_capabilities {
    ultra_ssd_enabled = var.ultra_ssd_enabled
  }

  os_profile_windows_config {
    provision_vm_agent        = var.provision_vm_agent
    enable_automatic_upgrades = var.enable_automatic_upgrades
  }

  os_profile {
    admin_username = var.admin_username
    admin_password = var.admin_password
    computer_name  = each.value
  }

  identity {
    type         = "UserAssigned" #"SystemAssigned, UserAssigned"
    identity_ids = ["${var.user_managed_identity_id}"]
  }

  tags = var.tags

  # SQL_DISK     LUN 0-63
  storage_data_disk { #DATA_DISK_H H:\
    name                      = "${each.value}_DATA_DISK_H"
    caching                   = var.data_disk_caching["RO"]
    create_option             = var.data_disk_create_option["empty"]
    managed_disk_type         = terraform.workspace != "prod" ? var.managed_disk_type["standard"] : var.managed_disk_type["premium"]
    disk_size_gb              = var.data_disk_size_gb["minimal"]
    lun                       = 5
    write_accelerator_enabled = var.write_accelerator_enabled
  }

  storage_data_disk { #TLOG_DISK O:\
    name                      = "${each.value}_SQL_TLOG_DISK"
    caching                   = var.data_disk_caching["RO"]
    create_option             = var.data_disk_create_option["empty"]
    managed_disk_type         = terraform.workspace != "prod" ? var.managed_disk_type["standard"] : var.managed_disk_type["premium"]
    disk_size_gb              = var.data_disk_size_gb["minimal"]
    lun                       = 10
    write_accelerator_enabled = var.write_accelerator_enabled
  }

  storage_data_disk { # TEMPDB_DISK T:\
    name                      = "${each.value}_SQL_TEMPDB_DISK"
    caching                   = var.data_disk_caching["RO"]
    create_option             = var.data_disk_create_option["empty"]
    managed_disk_type         = terraform.workspace != "prod" ? var.managed_disk_type["standard"] : var.managed_disk_type["premium"]
    disk_size_gb              = var.data_disk_size_gb["minimal"]
    lun                       = 15
    write_accelerator_enabled = var.write_accelerator_enabled
  }

  storage_data_disk { # BAK_DISK E:\
    name                      = "${each.value}_SQL_BAK_DISK"
    caching                   = var.data_disk_caching["RO"]
    create_option             = var.data_disk_create_option["empty"]
    managed_disk_type         = terraform.workspace != "prod" ? var.managed_disk_type["standard"] : var.managed_disk_type["premium"]
    disk_size_gb              = var.data_disk_size_gb["minimal"]
    lun                       = 20
    write_accelerator_enabled = var.write_accelerator_enabled
  }

  availability_set_id = var.availability_set_id
}

