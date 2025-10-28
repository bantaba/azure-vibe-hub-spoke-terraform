#############################################################################
# DATA SOURCES SECTION
# This section defines data sources used to retrieve information about the
# current Azure environment and external services
#############################################################################

# Get current Azure client configuration (tenant, subscription, object ID)
# Used for configuring Key Vault access policies and RBAC assignments
data "azurerm_client_config" "current" {}

# Get current Azure subscription details
# Used for scoping RBAC assignments and resource deployments
data "azurerm_subscription" "primary" {}

# Get the current public IP address of the deployment agent
# Used for configuring network access rules and firewall exceptions
# Source: https://www.ipify.org/ - reliable public IP detection service
data "http" "public_ip" {
  url = "https://api.ipify.org/"
}

#############################################################################
# RANDOM RESOURCES SECTION
# This section defines random resources used for generating unique names
# and secure passwords to ensure resource uniqueness and security
#############################################################################

# Generate random suffix for Key Vault name to ensure global uniqueness
# Key Vault names must be globally unique across all Azure tenants
resource "random_id" "kvault" {
  byte_length = 3  # Generates 6-character hex string (3 bytes = 6 hex chars)
}

# Generate random suffix for Storage Account name to ensure global uniqueness
# Storage Account names must be globally unique across all Azure tenants
resource "random_id" "sa" {
  byte_length = 3  # Generates 6-character hex string (3 bytes = 6 hex chars)
}

# Generate secure random password for VM admin accounts and service accounts
# Meets Azure complexity requirements with mixed case, numbers, and special characters
resource "random_password" "pwd_gen" {
  min_lower   = 4   # Minimum lowercase letters
  min_upper   = 4   # Minimum uppercase letters
  min_numeric = 4   # Minimum numeric characters
  min_special = 4   # Minimum special characters
  length      = 25  # Total password length for enhanced security
}

#############################################################################
# MODULES SECTION
# This section defines all module calls for deploying Azure infrastructure
# Modules are organized by functional area: networking, security, compute, etc.
#############################################################################

#############################################################################
# RESOURCE GROUPS MODULE
# Creates all resource groups needed for the hub-and-spoke architecture
# Organizes resources by function: networking, core infrastructure, web tier, data tier
#############################################################################
module "rg" {
  source                  = "./modules/resourceGroup"
  resource_group_location = var.location
  tags                    = local.standard_tags
}

#############################################################################
# NETWORKING MODULES
# Implements hub-and-spoke network architecture with security controls
# Includes VNet, subnets, NSGs, Bastion host, and network security rules
#############################################################################

# Virtual Network Module
# Creates the main hub virtual network with standardized address space
# Serves as the central connectivity point for all spoke networks
module "vnet" {
  source      = "./modules/network/vnet"
  depends_on  = [module.rg]
  vnet_name   = local.resource_names.vnet_main
  rg_name     = module.rg.rg_name["NetLab"]
  rg_location = module.rg.rg_location["NetLab"]
  tags        = local.standard_tags
}

# Subnet Module
# Creates multiple subnets for network segmentation and security isolation
# Includes subnets for: web tier, app tier, data tier, infrastructure, bastion
module "subnet" {
  source     = "./modules/network/subnet"
  depends_on = [module.vnet]
  rg_name    = module.rg.rg_name["NetLab"]
  vnet       = module.vnet.vnet_name
  tags       = local.standard_tags
}

# Network Security Group Module
# Implements network security rules with least privilege access principles
# Includes flow logging for security monitoring and compliance
module "nsg" {
  source                        = "./modules/network/nsg"
  depends_on                    = [module.subnet]
  nsg_name                      = local.resource_names.nsg_main
  location                      = module.rg.rg_location["NetLab"]
  rg_name                       = module.rg.rg_name["NetLab"]
  # Associate NSG with all application subnets (excludes AzureBastionSubnet)
  subnet_id                     = [module.subnet.subnet_ids["CachingTierSubnet"], module.subnet.subnet_ids["LabNetSubnet"], module.subnet.subnet_ids["CoreInfraSubnet"], module.subnet.subnet_ids["DB_backendSubnet"], module.subnet.subnet_ids["webFESubnet"]]
  network_watcher_flow_log_name = "${local.resource_names.nsg_main}-flow-logs"
  law_id                        = module.law.law_id
  law_resource_id               = module.law.law_resource_id
  storage_account_id            = module.CoreInfra_sa.sa_id
  tags                          = local.standard_tags
}

# Public IP for Azure Bastion
# Creates a static public IP address for the Bastion host
# Standard SKU required for Bastion service
module "bastion_pip" {
  source   = "./modules/network/publicIP"
  pip_name = "${local.resource_names.bastion_main}-${var.resource_abbreviation.public_ip_address}"
  rg_name  = module.rg.rg_name["NetLab"]
  location = module.rg.rg_location["NetLab"]
  tags     = local.standard_tags
}

# Azure Bastion Host Module
# Provides secure RDP/SSH connectivity to VMs without exposing them to the internet
# Eliminates the need for jump boxes and reduces attack surface
module "bastion" {
  source                = "./modules/network/bastion"
  bastion_name          = local.resource_names.bastion_main
  rg_name               = module.rg.rg_name["NetLab"]
  location              = module.rg.rg_location["NetLab"]
  ip_configuration_name = "${local.resource_names.bastion_main}-config"
  subnet_id             = module.subnet.subnet_ids["bastionSubnet"]  # Must use AzureBastionSubnet
  public_ip_address_id  = module.bastion_pip.public_ip_id
  tags                  = local.standard_tags
}

#############################################################################
# STORAGE MODULES
# Implements secure storage solutions with encryption and access controls
# Used for VM diagnostics, scripts, logs, and backup storage
#############################################################################

# Core Infrastructure Storage Account
# Provides secure storage for VM diagnostics, scripts, and operational data
# Configured with encryption at rest, HTTPS-only access, and network restrictions
module "CoreInfra_sa" {
  source            = "./modules/Storage/stgAccount"
  depends_on        = [module.rg]
  sa_location       = module.rg.rg_location["CoreInfra"]
  sa_rg_name        = module.rg.rg_name["CoreInfra"]
  sa_name           = "${local.resource_names.sa_main}${random_id.sa.hex}"  # Append random suffix for uniqueness
  sa_container_name = "${var.project_name}-scripts-${var.environment}"
  tags              = local.standard_tags
}

#############################################################################
# SECURITY MODULES
# Implements identity, access management, and secret storage solutions
# Includes managed identities, Key Vault, and RBAC assignments
#############################################################################

# User-Assigned Managed Identity
# Provides secure identity for VMs and services to access Azure resources
# Eliminates the need for storing credentials in code or configuration
module "uami" {
  source                   = "./modules/Security/uami"
  uami_location            = module.rg.rg_location["CoreInfra"]
  uami_name                = "${var.project_name}-${var.resource_abbreviation.user_assigned_identity}-main-${var.environment}"
  uami_resource_group_name = module.rg.rg_name["CoreInfra"]
  tags                     = local.standard_tags
}

# module "uami_role_assignment" {
#   source                  = "./modules/Security/RoleAssignment"
#   depends_on              = [module.uami]
#   role_definition_name    = var.builtin_role_def["KeyVaultSecretsOfficer"]
#   primary_subscription_id = data.azurerm_subscription.primary.id
#   resource_principal_id   = module.uami.principal_id
#   scope                   = module.kvault.kvault_id
# }

module "aa" {
  source                = "./modules/automation/account"
  aa_name               = local.resource_names.aa_main
  aa_location           = module.rg.rg_location["CoreInfra"]
  aa_rg                 = module.rg.rg_name["CoreInfra"]
  start_time            = timeadd(timestamp(), "10h")
  domain_admin_pwd      = module.domain_creds.kvault_secret_value
  domain_admin_username = module.domain_creds.kvault_secret_name
  domain_safe_mode_pwd  = module.iaasUser.kvault_secret_value
  user_default_pwd      = random_password.pwd_gen.result
  tags                  = local.standard_tags
}

module "aa_role_assignment" {
  source                  = "./modules/authorization/role_assignment"
  depends_on              = [module.aa]
  role_definition_name    = var.builtin_role_def["VirtualMachineContributor"]
  primary_subscription_id = data.azurerm_subscription.primary.id
  resource_principal_id   = module.aa.automation_object_id
  scope                   = data.azurerm_subscription.primary.id
}

module "kvault" {
  source                      = "./modules/Security/kvault/vault"
  vault_location              = module.rg.rg_location["CoreInfra"]
  vault_rg_name               = module.rg.rg_name["CoreInfra"]
  vault_name                  = "${local.resource_names.kv_main}-${random_id.kvault.hex}"
  tenant_id                   = data.azurerm_client_config.current.tenant_id
  network_acls_default_action = "Allow"
  allowed_ip_ranges           = local.authorized_ip_ranges
  virtual_network_subnet_ids  = [module.subnet.subnet_ids["CachingTierSubnet"], module.subnet.subnet_ids["CoreInfraSubnet"], module.subnet.subnet_ids["DB_backendSubnet"], module.subnet.subnet_ids["LabNetSubnet"], module.subnet.subnet_ids["webFESubnet"]]
  tags                        = local.standard_tags
}

# grant self/SP KV admin (otherwise, RBAC unauthorized to create keys/Certs/Secrets)
module "self_role_assignment" {
  source                  = "./modules/Security/RoleAssignment"
  role_definition_name    = var.builtin_role_def["KeyVaultAdministrator"]
  primary_subscription_id = data.azurerm_subscription.primary.id
  resource_principal_id   = data.azurerm_client_config.current.object_id #if u need to grant user/group can add [group/user]_id
  scope                   = module.kvault.kvault_id
}

####### KV Secret
module "iaasUser" {
  source                 = "./modules/Security/kvault/secret"
  depends_on             = [module.kvault]
  vault_id               = module.kvault.kvault_id
  vault_secret_name      = "super-admin-password"
  vault_secret_value     = random_password.pwd_gen.result
  secret_expiration_date = "2025-12-31T00:00:00Z"
  tags                   = local.standard_tags
}

module "domain_creds" {
  source                 = "./modules/Security/kvault/secret"
  depends_on             = [module.kvault]
  vault_id               = module.kvault.kvault_id
  vault_secret_name      = "domain-admin-password"
  vault_secret_value     = random_password.pwd_gen.result
  secret_expiration_date = "2025-12-31T00:00:00Z"
  tags                   = local.standard_tags
}

module "kvault_logging" {
  source             = "./modules/monitoring/monitors/monitor_diagnostics"
  depends_on         = [module.kvault]
  name               = "${local.resource_names.kv_main}-diagnostics"
  target_resource_id = module.kvault.kvault_id
  storage_account_id = module.CoreInfra_sa.sa_id
}

module "law" {
  source     = "./modules/monitoring/law"
  depends_on = [module.CoreInfra_sa]

  law_name                                          = local.resource_names.law_main
  law_location                                      = module.rg.rg_location["CoreInfra"]
  law_rg_name                                       = module.rg.rg_name["CoreInfra"]
  automation_acct_id                                = module.aa.automationAcct_id
  log_analytics_storage_insightsStorage_account_id  = module.CoreInfra_sa.sa_id
  log_analytics_storage_insightsStorage_account_key = module.CoreInfra_sa.sa_key
  law_storage_insights_name                         = "${local.resource_names.law_main}-storage-insights"
  tags                                              = local.standard_tags
}

# DSC with AD DC
module "dc_avset" {
  source         = "./modules/compute/avset"
  avset_location = module.rg.rg_location["CoreInfra"]
  avset_name     = "${var.project_name}-${var.resource_abbreviation.availability_set}-dc-${var.environment}"
  avset_rg_name  = module.rg.rg_name["CoreInfra"]
  tags           = local.standard_tags
}

module "DC_VM" {
  source                   = "./modules/compute/vms/windows"
  depends_on               = [module.dc_avset]
  vm_names                 = var.dc_vm_names
  resource_location        = module.rg.rg_location["CoreInfra"]
  rg_name                  = module.rg.rg_name["CoreInfra"]
  subnet_id                = module.subnet.subnet_ids["CoreInfraSubnet"]
  storage_account_uri      = module.CoreInfra_sa.sa_blob_endpoint
  admin_username           = module.domain_creds.kvault_secret_name
  admin_password           = module.domain_creds.kvault_secret_value
  user_managed_identity_id = module.uami.uami_id
  availability_set_id      = module.dc_avset.availability_set_id
  tags                     = local.standard_tags
}

module "DC_VM_ext" {
  source                 = "./modules/compute/vms/extensions"
  depends_on             = [module.DC_VM]
  virtual_machine_id     = module.DC_VM.virtual_machine_ids
  dsc_server_endpoint    = module.aa.dsc_server_endpoint
  dsc_config             = module.aa.dsc_dc_config
  dsc_primary_access_key = module.aa.automation_acct_primary_access_key
  location               = module.rg.rg_location["CoreInfra"]
  # analytics_workspace_id = module.law.law_id
  # analytics_workspace_key = module.law.law_key
}

# Test VM Domain Join
module "fe_avset" {
  source         = "./modules/compute/avset"
  avset_location = module.rg.rg_location["WebFE"]
  avset_name     = "${var.project_name}-${var.resource_abbreviation.availability_set}-fe-${var.environment}"
  avset_rg_name  = module.rg.rg_name["WebFE"]
  tags           = local.standard_tags
}

module "testVM" {
  source                   = "./modules/compute/vms/windows"
  depends_on               = [module.fe_avset]
  vm_names                 = var.test_vm_names
  resource_location        = module.rg.rg_location["WebFE"]
  rg_name                  = module.rg.rg_name["WebFE"]
  subnet_id                = module.subnet.subnet_ids["webFESubnet"]
  storage_account_uri      = module.CoreInfra_sa.sa_blob_endpoint
  admin_username           = module.iaasUser.kvault_secret_name
  admin_password           = module.iaasUser.kvault_secret_value
  user_managed_identity_id = module.uami.uami_id
  availability_set_id      = module.fe_avset.availability_set_id
  tags                     = local.standard_tags
}


module "testVM_ext" {
  source = "./modules/compute/vms/extensions"
  depends_on = [module.testVM]
  virtual_machine_id = module.testVM.virtual_machine_ids
  location = module.rg.rg_location["WebFE"]
  dsc_server_endpoint = module.aa.dsc_server_endpoint
  dsc_config = module.aa.dsc_geneva_monitoring_config
  dsc_primary_access_key = module.aa.automation_acct_primary_access_key
  # analytics_workspace_id = module.law.law_id
  # analytics_workspace_key = module.law.law_key
  # storage_acct_name = module.CoreInfra_sa.sa_name
  # storage_acct_key = module.CoreInfra_sa.sa_key
}
#endregion MODULES #############################################################################

/*



module "fw" {
  source                        = "./modules/network/firewall"
  fw_pip_name                   = "fw-pip"
  fw_name                       = "main-fw"
  fw_policy_name                = "main-fw-policy"
  fw_rule_collection_group_name = "main-fw-collection"
  fw_subnet_id                  = module.subnet.subnet_ids["firewallSubnet"]
  ip_configuration_name         = "fw-config"
  location                      = module.rg.rg_location["NetLab"]
  rg_name                       = module.rg.rg_name["NetLab"]
  tags                          = merge(var.default_tags, tomap({ "Environmet" = "${terraform.workspace}", "DeployedOn" = "${formatdate("YYYY-MMM-DD hh:mm ZZZ", timestamp())}" }))
}
*/