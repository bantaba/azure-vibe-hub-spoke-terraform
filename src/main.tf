#############################################################################
#region DATA SECTION                                                                              
############################################################################# 

data "azurerm_client_config" "current" {}
data "azurerm_subscription" "primary" {
}
# Get the public IP address
data "http" "public_ip" {        #https://www.ipify.org/
  url = "https://api.ipify.org/" #"https://ifconfig.co/ip"    
}

resource "random_id" "kvault" {
  byte_length = 3
  # prefix = "value"
}

resource "random_id" "sa" {
  byte_length = 3

}

resource "random_password" "pwd_gen" {
  min_lower   = 4
  min_upper   = 4
  min_numeric = 4
  min_special = 4
  length      = 25
}

#region MODULES SECTION #############################################################################

module "rg" {
  source                  = "./modules/resourceGroup"
  resource_group_location = var.location
  tags                    = merge(var.default_tags, tomap({ "Environmet" = "${terraform.workspace}", "DeployedOn" = "${formatdate("YYYY-MMM-DD hh:mm ZZZ", timestamp())}" }))
}

#region NETWORKING
module "vnet" {
  source      = "./modules/network/vnet"
  depends_on  = [module.rg]
  vnet_name   = "vnet-wus3"
  rg_name     = module.rg.rg_name["NetLab"]
  rg_location = module.rg.rg_location["NetLab"]
  tags        = merge(var.default_tags, tomap({ "Environmet" = "${terraform.workspace}", "DeployedOn" = "${formatdate("YYYY-MMM-DD hh:mm ZZZ", timestamp())}" }))
}

module "subnet" {
  source     = "./modules/network/subnet"
  depends_on = [module.vnet]
  rg_name    = module.rg.rg_name["NetLab"]
  vnet       = module.vnet.vnet_name
  tags       = merge(var.default_tags, tomap({ "Environmet" = "${terraform.workspace}", "DeployedOn" = "${formatdate("YYYY-MMM-DD hh:mm ZZZ", timestamp())}" }))
}

module "nsg" {
  source                        = "./modules/network/nsg"
  depends_on                    = [module.subnet]
  nsg_name                      = "${terraform.workspace}-nsg"
  location                      = module.rg.rg_location["NetLab"]
  rg_name                       = module.rg.rg_name["NetLab"]
  subnet_id                     = [module.subnet.subnet_ids["CachingTierSubnet"], module.subnet.subnet_ids["LabNetSubnet"], module.subnet.subnet_ids["CoreInfraSubnet"], module.subnet.subnet_ids["DB_backendSubnet"], module.subnet.subnet_ids["webFESubnet"]]
  network_watcher_flow_log_name = "${terraform.workspace}-nsgflow-logs"
  law_id                        = module.law.law_id
  law_resource_id               = module.law.law_resource_id
  storage_account_id            = module.CoreInfra_sa.sa_id
  tags                          = merge(var.default_tags, tomap({ "Environmet" = "${terraform.workspace}", "DeployedOn" = "${formatdate("YYYY-MMM-DD hh:mm ZZZ", timestamp())}" }))
}

module "bastion_pip" {
  source   = "./modules/network/publicIP"
  pip_name = "${terraform.workspace}-bastion-pip"
  rg_name  = module.rg.rg_name["NetLab"]
  location = module.rg.rg_location["NetLab"]
  tags     = merge(var.default_tags, tomap({ "Environmet" = "${terraform.workspace}", "DeployedOn" = "${formatdate("YYYY-MMM-DD", timestamp())}" }))
}

module "bastion" {
  source                = "./modules/network/bastion"
  # bastion_name          = "${terraform.workspace}Bastion}"
  #     The name must begin with a letter or number, end with a letter, number or underscore, and may contain only letters, numbers, underscores, periods, or hyphens. "name": "devBastion}"
  rg_name               = module.rg.rg_name["NetLab"]
  location              = module.rg.rg_location["NetLab"]
  ip_configuration_name = "${terraform.workspace}-bastionConfig"
  subnet_id             = module.subnet.subnet_ids["bastionSubnet"]
  public_ip_address_id  = module.bastion_pip.public_ip_id
  tags                  = merge(var.default_tags, tomap({ "Environmet" = "${terraform.workspace}", "DeployedOn" = "${formatdate("YYYY-MMM-DD", timestamp())}" }))
}
#endregion NETWORKING

module "CoreInfra_sa" {
  source            = "./modules/Storage/stgAccount"
  depends_on        = [module.rg]
  sa_location       = module.rg.rg_location["CoreInfra"]
  sa_rg_name        = module.rg.rg_name["CoreInfra"]
  sa_name           = "${terraform.workspace}sa${random_id.sa.hex}"
  sa_container_name = "${terraform.workspace}-scripts"
  tags              = merge(var.default_tags, tomap({ "Environmet" = "${terraform.workspace}", "DeployedOn" = "${formatdate("YYYY-MMM-DD hh:mm ZZZ", timestamp())}" }))
}

module "uami" {
  source                   = "./modules/Security/uami"
  uami_location            = module.rg.rg_location["CoreInfra"]
  uami_name                = "${title(terraform.workspace)}-uami"
  uami_resource_group_name = module.rg.rg_name["CoreInfra"]
  tags                     = merge(var.default_tags, tomap({ "Environmet" = "${terraform.workspace}", "DeployedOn" = "${formatdate("YYYY-MMM-DD hh:mm ZZZ", timestamp())}" }))
}

# module "uami_role_assignment" {
#   source                  = "./modules/Security/RoleAssignment"
#   depends_on              = [module.uami]
#   role_definition_name    = var.builtin_role_def["KeyVaultSecretsOfficer"]
#   primary_subscription_id = data.azurerm_subscription.primary.id
#   resource_principal_id   = module.uami.principal_id
#   scope                   = module.kvault.kvault_id
# }

module "aa" { #TODO: Use for_each to upload from single dir
  source                = "./modules/automation/account"
  aa_name               = "${terraform.workspace}-aa"
  aa_location           = module.rg.rg_location["CoreInfra"]
  aa_rg                 = module.rg.rg_name["CoreInfra"]
  start_time            = timeadd(timestamp(), "10h")
  domain_admin_pwd      = module.domain_creds.kvault_secret_value
  domain_admin_username = module.domain_creds.kvault_secret_name
  domain_safe_mode_pwd  = module.iaasUser.kvault_secret_value
  user_default_pwd      = random_password.pwd_gen.result
  tags                  = merge(var.default_tags, tomap({ "Environmet" = "${terraform.workspace}", "DeployedOn" = "${formatdate("DD-MMM-YYYY hh:mm ZZZZ", timestamp())}" }))
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
  vault_name                  = "${title(terraform.workspace)}-CoreVault"
  tenant_id                   = data.azurerm_client_config.current.tenant_id
  network_acls_default_action = "Allow"
  allowed_ip_ranges           = ["131.107.0.0/16", "${local.ingress_ip_address}"] #var.allowed_ip_rules
  virtual_network_subnet_ids  = [module.subnet.subnet_ids["CachingTierSubnet"], module.subnet.subnet_ids["CoreInfraSubnet"], module.subnet.subnet_ids["DB_backendSubnet"], module.subnet.subnet_ids["LabNetSubnet"], module.subnet.subnet_ids["webFESubnet"]]
  tags                        = merge(var.default_tags, tomap({ "Environmet" = "${terraform.workspace}", "DeployedOn" = "${formatdate("YYYY-MMM-DD hh:mm ZZZ", timestamp())}" }))
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
  vault_secret_name      = "superAdmin"
  vault_secret_value     = random_password.pwd_gen.result
  secret_expiration_date = "2024-12-31T00:00:00Z"
  tags                   = merge(var.default_tags, tomap({ "Environmet" = "${terraform.workspace}", "DeployedOn" = "${formatdate("YYYY-MMM-DD hh:mm ZZZ", timestamp())}" }))
}

module "domain_creds" {
  source                 = "./modules/Security/kvault/secret"
  depends_on             = [module.kvault]
  vault_id               = module.kvault.kvault_id
  vault_secret_name      = "DomainAdminUser"
  vault_secret_value     = random_password.pwd_gen.result
  secret_expiration_date = "2024-12-31T00:00:00Z"
  tags                   = merge(var.default_tags, tomap({ "Environmet" = "${terraform.workspace}", "DeployedOn" = "${formatdate("YYYY-MMM-DD hh:mm ZZZ", timestamp())}" }))
}

module "kvault_logging" {
  source             = "./modules/monitoring/monitors/monitor_diagnostics"
  depends_on         = [module.kvault]
  name               = "${terraform.workspace}-kvault-logging"
  target_resource_id = module.kvault.kvault_id
  storage_account_id = module.CoreInfra_sa.sa_id
}

module "law" {
  source     = "./modules/monitoring/law"
  depends_on = [module.CoreInfra_sa]

  law_name                                          = "${terraform.workspace}-law"
  law_location                                      = module.rg.rg_location["CoreInfra"]
  law_rg_name                                       = module.rg.rg_name["CoreInfra"]
  automation_acct_id                                = module.aa.automationAcct_id
  log_analytics_storage_insightsStorage_account_id  = module.CoreInfra_sa.sa_id
  log_analytics_storage_insightsStorage_account_key = module.CoreInfra_sa.sa_key
  law_storage_insights_name                         = "${terraform.workspace}-storageinsightconfig"
  tags                                              = merge(var.default_tags, tomap({ "Environmet" = "${terraform.workspace}", "DeployedOn" = "${formatdate("DD-MMM-YYYY hh:mm ZZZZ", timestamp())}" }))
}

# DSC with AD DC
module "dc_avset" {
  source         = "./modules/compute/avset"
  avset_location = module.rg.rg_location["CoreInfra"]
  avset_name     = "dc-avset"
  avset_rg_name  = module.rg.rg_name["CoreInfra"]
  tags           = merge(var.default_tags, tomap({ "Environmet" = "${terraform.workspace}", "DeployedOn" = "${formatdate("YYYY-MMM-DD hh:mm ZZZ", timestamp())}" }))
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
  tags                     = merge(var.default_tags, tomap({ "Environmet" = "${terraform.workspace}", "DeployedOn" = "${formatdate("DD-MMM-YYYY hh:mm ZZZZ", timestamp())}" }))
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

#Test VM Domain Join

module "fe_avset" {
  source         = "./modules/compute/avset"
  avset_location = module.rg.rg_location["WebFE"]
  avset_name     = "fe-avset"
  avset_rg_name  = module.rg.rg_name["WebFE"]
  tags           = merge(var.default_tags, tomap({ "Environmet" = "${terraform.workspace}", "DeployedOn" = "${formatdate("YYYY-MMM-DD hh:mm ZZZ", timestamp())}" }))
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
  tags                     = merge(var.default_tags, tomap({ "Environmet" = "${terraform.workspace}", "DeployedOn" = "${formatdate("DD-MMM-YYYY hh:mm ZZZZ", timestamp())}" }))
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