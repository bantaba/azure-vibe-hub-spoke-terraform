# Standardized naming and configuration locals
locals {
  # Get current public IP for network access rules
  ingress_ip_address = trimspace(data.http.public_ip.response_body)

  # Location abbreviation lookup with fallback
  location_abbr = try(var.location_abbreviation[var.location], "na")

  # Standardized resource naming convention
  # Format: {project}-{resource_type}-{environment}-{location_abbr}-{instance}
  resource_names = {
    # Resource groups
    rg_netlab      = "${var.project_name}-${var.resource_abbreviation.resource_group}-netlab-${local.location_abbr}"
    rg_coreinfra   = "${var.project_name}-${var.resource_abbreviation.resource_group}-coreinfra-${local.location_abbr}"
    rg_webfe       = "${var.project_name}-${var.resource_abbreviation.resource_group}-webfe-${local.location_abbr}"
    rg_databackend = "${var.project_name}-${var.resource_abbreviation.resource_group}-databackend-${local.location_abbr}"

    # Network resources
    vnet_main    = "${var.project_name}-${var.resource_abbreviation.virtual_network}-main-${local.location_abbr}"
    nsg_main     = "${var.project_name}-${var.resource_abbreviation.network_security_group}-main-${local.location_abbr}"
    bastion_main = "${var.project_name}-${var.resource_abbreviation.bastion_host}-main-${local.location_abbr}"

    # Storage and security
    kv_main = "${var.project_name}-${var.resource_abbreviation.key_vault}-main-${local.location_abbr}"
    sa_main = "${var.project_name}${var.resource_abbreviation.storage_account}main${local.location_abbr}"

    # Compute resources
    aa_main  = "${var.project_name}-${var.resource_abbreviation.automation_account}-main-${local.location_abbr}"
    law_main = "${var.project_name}-${var.resource_abbreviation.log_analytics_workspace}-main-${local.location_abbr}"
  }

  # Standardized tags applied to all resources
  standard_tags = merge(var.default_tags, {
    environment         = var.environment
    project             = var.project_name
    deployed_on         = formatdate("YYYY-MM-DD", timestamp())
    terraform_workspace = terraform.workspace
    location            = var.location
  })

  # Network configuration
  authorized_ip_ranges = concat(
    tolist(var.allowed_ip_rules),
    ["${local.ingress_ip_address}/32"]
  )
}