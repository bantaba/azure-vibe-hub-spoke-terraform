resource "azurerm_availability_set" "as" {
  location            = var.avset_location
  name                = var.avset_name
  resource_group_name = var.avset_rg_name

  platform_fault_domain_count  = var.platform_fault_domain_count
  platform_update_domain_count = var.platform_update_domain_count
  managed                      = var.managed
  tags                         = var.tags
}