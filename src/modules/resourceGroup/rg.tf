#############################################################################
# RESOURCE GROUP MODULE
# 
# This module creates multiple Azure Resource Groups based on a map of names
# Resource groups provide logical containers for Azure resources and enable
# organized resource management, access control, and billing
#
# Features:
# - Creates multiple resource groups using for_each loop
# - Applies consistent naming convention with workspace prefix
# - Applies standardized tags to all resource groups
# - Supports multiple environments through workspace naming
#############################################################################

# Create Azure Resource Groups using for_each loop
# Each resource group serves a specific functional purpose:
# - NetLab: Network infrastructure resources (VNet, NSG, Bastion)
# - CoreInfra: Core infrastructure (Key Vault, Storage, Automation)
# - WebFE: Web front-end tier resources
# - DB_backend: Database and backend tier resources
# - K8s_*: Kubernetes-related resources (future use)
resource "azurerm_resource_group" "resourceGroup" {
  for_each = var.resource_group_names
  
  # Naming convention: {Workspace}-{Purpose}-rg
  # Example: Dev-CoreInfra-rg, Prod-NetLab-rg
  name     = "${title(terraform.workspace)}-${each.value}-rg"
  location = var.resource_group_location
  tags     = var.tags
}
