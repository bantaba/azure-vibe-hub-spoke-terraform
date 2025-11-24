Feature: Network Security Controls
  As a network security engineer
  I want to ensure network resources are properly secured
  So that unauthorized access is prevented

  Scenario: Virtual networks must have DDoS protection enabled
    Given I have azurerm_virtual_network defined
    When it contains ddos_protection_plan
    Then it must contain enable
    And its value must be true

  Scenario: Subnets must have Network Security Groups attached
    Given I have azurerm_subnet defined
    Then it must contain network_security_group_id

  Scenario: Application Gateway must use WAF SKU
    Given I have azurerm_application_gateway defined
    When it contains sku
    Then it must contain tier
    And its value must match WAF|WAF_v2

  Scenario: Application Gateway WAF must be in prevention mode
    Given I have azurerm_application_gateway defined
    When it contains waf_configuration
    Then it must contain firewall_mode
    And its value must be Prevention

  Scenario: Azure Bastion must be deployed for VM access
    Given I have azurerm_virtual_network defined
    Then I have azurerm_bastion_host defined

  Scenario: Private endpoints must be used for PaaS services
    Given I have azurerm_storage_account defined
    Then I have azurerm_private_endpoint defined

  Scenario: Network interfaces must not have public IPs for internal VMs
    Given I have azurerm_network_interface defined
    When it contains tags
    And it contains tier
    And its value matches internal|private
    Then it must not contain public_ip_address_id

  Scenario: VPN Gateway must use strong encryption
    Given I have azurerm_virtual_network_gateway defined
    When it contains type
    And its value is Vpn
    When it contains vpn_client_configuration
    Then it must contain vpn_auth_types
    And its value must contain Certificate

  Scenario: ExpressRoute circuits must have encryption enabled
    Given I have azurerm_express_route_circuit defined
    Then it must contain allow_classic_operations
    And its value must be false

  Scenario: Network Watcher must be enabled
    Given I have azurerm_resource_group defined
    Then I have azurerm_network_watcher defined

  Scenario: Flow logs must be enabled for NSGs
    Given I have azurerm_network_security_group defined
    Then I have azurerm_network_watcher_flow_log defined

  Scenario: Traffic Analytics must be enabled for flow logs
    Given I have azurerm_network_watcher_flow_log defined
    When it contains traffic_analytics
    Then it must contain enabled
    And its value must be true
