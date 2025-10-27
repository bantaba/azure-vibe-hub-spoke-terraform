# Create the public ip for Azure Firewall
resource "azurerm_public_ip" "azure_firewall_public_ip" {

  name                = "${var.fw_pip_name}"
  location            = var.location
  resource_group_name = var.rg_name
  allocation_method   = "Static"
  sku                 = var.sku_tier
  
  tags = var.tags
}
resource "azurerm_firewall" "fw" {
  depends_on = [ azurerm_public_ip.azure_firewall_public_ip ]
  location            = var.location
  name                = var.fw_name
  resource_group_name = var.rg_name
  sku_name            = var.sku_name
  sku_tier            = var.sku_tier

  ip_configuration {
    name                 = var.ip_configuration_name
    public_ip_address_id = azurerm_public_ip.azure_firewall_public_ip.id
    subnet_id            = var.fw_subnet_id
  }

  firewall_policy_id = azurerm_firewall_policy.fw_policy.id
  threat_intel_mode  = "Alert" # alert, deny
  # dns_servers = [ "Default" ]
  tags = var.tags
}

resource "azurerm_firewall_policy" "fw_policy" {
  location            = var.location
  name                = var.fw_policy_name
  resource_group_name = var.rg_name

  tags = var.tags
}

resource "azurerm_firewall_policy_rule_collection_group" "fw_rule_collection" {
  firewall_policy_id = azurerm_firewall_policy.fw_policy.id
  name               = var.fw_rule_collection_group_name
  priority           = 300  # Rulle cllection group priority : 100-65000



  network_rule_collection { #with Dynamic
    name = "net-rule-test" #  # var.network_rules_collection_name
    priority = 420
    action = "Deny"
    dynamic "rule" {
        for_each = {for netrule in local.net_collection_rules : netrule.name => netrule }
        content {
          name = rule.value.name
          source_addresses = [rule.value.source_addresses]
          destination_ports = [ rule.value.destination_ports ]
          destination_addresses = [ rule.value.destination_addresses ]
          protocols = [ rule.value.protocols ]
        }
    }
  }



  application_rule_collection {
    name     = "app_rule_collection1" #  # var.app_rules_collection_name
    priority = 650
    action   = "Deny"
    dynamic "rule" {
        for_each = { for apprule in local.app_collection_rules : apprule.name => apprule }
        content {
            name              = rule.value.name
            source_addresses  = split(",", rule.value.source_addresses)
            destination_fqdns = split(",", rule.value.destination_fqdns)
            dynamic "protocols" {
                for_each = [ for protocols in split(",", rule.value.protocols)  : protocols ] 
                content {
                    type = tostring(split(":", protocols.value)[0])
                    port = tostring(split(":", protocols.value)[1])
                }
            }
        }
    }
  }
  
}