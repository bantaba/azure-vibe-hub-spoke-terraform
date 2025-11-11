# Network and connectivity outputs
output "agent_ip" {
  description = "The public IP address of the deployment agent/client for network access configuration"
  value       = local.ingress_ip_address
}

output "bastion_id" {
  description = "The resource ID of the Azure Bastion host for secure VM access"
  value       = module.bastion.bastionID
  sensitive   = false
}

output "virtual_network_id" {
  description = "The resource ID of the main virtual network"
  value       = module.vnet.lab_vnet_id
}

output "virtual_network_name" {
  description = "The name of the main virtual network"
  value       = module.vnet.vnet_name
}

# Resource group outputs
output "resource_groups" {
  description = "Map of all created resource groups with their names and IDs"
  value = {
    names     = module.rg.rg_name
    ids       = module.rg.rg_id
    locations = module.rg.rg_location
  }
}

# Security outputs
output "key_vault_uri" {
  description = "The URI of the Key Vault for accessing secrets and certificates"
  value       = module.kvault.kvault_uri
  sensitive   = false
}

output "key_vault_id" {
  description = "The resource ID of the Key Vault"
  value       = module.kvault.kvault_id
  sensitive   = false
}

output "managed_identity_id" {
  description = "The resource ID of the user-assigned managed identity"
  value       = module.uami.uami_id
  sensitive   = false
}

output "managed_identity_principal_id" {
  description = "The principal ID of the user-assigned managed identity"
  value       = module.uami.principal_id
  sensitive   = true
}

# Storage outputs
output "storage_account_name" {
  description = "The name of the core infrastructure storage account"
  value       = module.CoreInfra_sa.sa_name
  sensitive   = false
}

output "storage_account_primary_endpoint" {
  description = "The primary blob endpoint of the storage account"
  value       = module.CoreInfra_sa.sa_blob_endpoint
  sensitive   = false
}

# Monitoring outputs
output "log_analytics_workspace_id" {
  description = "The resource ID of the Log Analytics workspace"
  value       = module.law.law_id
  sensitive   = false
}

output "log_analytics_workspace_name" {
  description = "The name of the Log Analytics workspace"
  value       = module.law.law_name
  sensitive   = false
}

# Automation outputs
output "automation_account_id" {
  description = "The resource ID of the Azure Automation Account"
  value       = module.aa.automationAcct_id
  sensitive   = false
}

# Compute outputs
output "domain_controller_vm_ids" {
  description = "Map of domain controller virtual machine resource IDs"
  value       = module.DC_VM.virtual_machine_ids
  sensitive   = false
}

output "test_vm_ids" {
  description = "Map of test virtual machine resource IDs"
  value       = module.testVM.virtual_machine_ids
  sensitive   = false
}

# Environment and configuration outputs
output "environment" {
  description = "The deployment environment (dev, staging, prod)"
  value       = var.environment
}

output "project_name" {
  description = "The project name used in resource naming"
  value       = var.project_name
}

output "terraform_workspace" {
  description = "The Terraform workspace used for this deployment"
  value       = terraform.workspace
}

