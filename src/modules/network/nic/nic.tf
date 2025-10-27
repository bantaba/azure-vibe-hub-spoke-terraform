resource "azurerm_network_interface" "nic" { 
  for_each = var.nic_name
  name                = "${each.value}-nic" 
  location            = var.nic_location 
  resource_group_name =var.nic_resource_group 
  enable_accelerated_networking = var.enable_accelerated_networking
  enable_ip_forwarding = var.enable_ip_forwarding

  ip_configuration {
    name                          =  var.ip_configuration_name
    subnet_id                     = var.nic_subnet_id  
    private_ip_address_allocation = var.private_ip_address_allocation
  }

  tags = var.tags
  
}