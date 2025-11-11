#############################################################################
#region                   NIC creation
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
#endregion NIC creation


#############################################################################
#region                   VM creation
#############################################################################
resource "azurerm_windows_virtual_machine" "WindowsVM" {
  for_each            = var.vm_names
  name                = each.value
  resource_group_name = var.rg_name
  location            = var.resource_location
  size                = var.vm_size
  admin_username      = var.admin_username
  admin_password      = var.admin_password
  network_interface_ids = [
    azurerm_network_interface.nic[each.key].id
  ]
  identity {
    type         = "UserAssigned" #"SystemAssigned, UserAssigned"
    identity_ids = ["${var.user_managed_identity_id}"]

  }

  # secret {
  #   key_vault_id = var.vault_id
  #   certificate {
  #     store = "/LocalMachine/My"
  #     url   = var.vault_cert_secret_id
  #   }
  # } # TODO: Y cert isn't showing in store


  os_disk {
    caching              = "ReadWrite"
    storage_account_type = "Standard_LRS"
  }

  source_image_reference {
    publisher = "MicrosoftWindowsServer"
    offer     = "WindowsServer"
    sku       = "2022-datacenter-azure-edition-hotpatch"
    version   = "latest"
  }


  additional_capabilities {
    ultra_ssd_enabled = var.ultra_ssd_enabled
  }

  availability_set_id = var.availability_set_id != null ? var.availability_set_id : null

  vtpm_enabled               = var.vtpm_enabled
  patch_mode                 = var.patch_mode
  patch_assessment_mode      = var.patch_mode
  enable_automatic_updates   = var.enable_automatic_updates
  hotpatching_enabled        = var.hotpatching_enabled
  allow_extension_operations = true
  encryption_at_host_enabled = var.encryption_at_host_enabled
  provision_vm_agent         = var.provision_vm_agent
  tags                       = var.tags
  secure_boot_enabled        = true

  boot_diagnostics {
    storage_account_uri = var.storage_account_uri
  }
}
#############################################################################
#endregion VM creation


