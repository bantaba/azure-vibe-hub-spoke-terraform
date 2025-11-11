
#############################################################################
# VIRTUAL NETWORK MODULE
#
# This module creates an Azure Virtual Network (VNet) that serves as the
# foundation for the hub-and-spoke network architecture. The VNet provides
# isolated network environment for Azure resources with custom DNS configuration.
#
# Features:
# - Configurable address space for network segmentation
# - Custom DNS servers for domain resolution
# - Support for multiple subnets and network security groups
# - Integration with Azure services and on-premises networks
#
# Network Architecture:
# - Hub VNet design for centralized connectivity
# - Private address space (RFC 1918 compliant)
# - Custom DNS for Active Directory integration
#############################################################################

# Create Azure Virtual Network
# This VNet serves as the hub in a hub-and-spoke architecture
# Provides isolated network environment with custom DNS configuration
resource "azurerm_virtual_network" "vnet" {
  name                = var.vnet_name
  resource_group_name = var.rg_name
  location            = var.rg_location
  address_space       = var.vnet_address_space

  # DNS Configuration:
  # - 192.168.10.4: Domain Controller (primary DNS)
  # - 1.1.1.1: Cloudflare public DNS (fallback)
  dns_servers = ["192.168.10.4", "1.1.1.1"]

  tags = var.tags
}



