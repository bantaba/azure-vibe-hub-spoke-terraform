Feature: Azure Security Best Practices
  As a security engineer
  I want to ensure Azure resources follow security best practices
  So that the infrastructure is secure and compliant

  Scenario: Storage accounts must use HTTPS only
    Given I have azurerm_storage_account defined
    Then it must contain enable_https_traffic_only
    And its value must be true

  Scenario: Storage accounts must use minimum TLS 1.2
    Given I have azurerm_storage_account defined
    When it contains min_tls_version
    Then its value must be TLS1_2

  Scenario: Storage accounts must deny public network access by default
    Given I have azurerm_storage_account defined
    When it contains network_rules
    Then it must contain default_action
    And its value must be Deny

  Scenario: Key Vault must have network ACLs configured
    Given I have azurerm_key_vault defined
    Then it must contain network_acls
    And it must contain default_action
    And its value must be Deny

  Scenario: Key Vault keys must have expiration dates
    Given I have azurerm_key_vault_key defined
    Then it must contain expiration_date

  Scenario: Key Vault secrets must have expiration dates
    Given I have azurerm_key_vault_secret defined
    Then it must contain expiration_date

  Scenario: Virtual machines must use managed disks
    Given I have azurerm_virtual_machine defined
    When it contains storage_os_disk
    Then it must contain managed_disk_type

  Scenario: Virtual machines must have encryption enabled
    Given I have azurerm_virtual_machine defined
    When it contains storage_os_disk
    Then it must contain encryption_settings

  Scenario: Network Security Groups must not allow unrestricted inbound access
    Given I have azurerm_network_security_rule defined
    When it contains direction
    And its value is Inbound
    When it contains access
    And its value is Allow
    Then it must not contain source_address_prefix
    Or its value must not be *
    Or its value must not be 0.0.0.0/0
    Or its value must not be Internet

  Scenario: Network Security Groups must not allow RDP from internet
    Given I have azurerm_network_security_rule defined
    When it contains direction
    And its value is Inbound
    When it contains access
    And its value is Allow
    When it contains destination_port_range
    And its value matches 3389
    Then it must not contain source_address_prefix
    Or its value must not be *
    Or its value must not be 0.0.0.0/0
    Or its value must not be Internet

  Scenario: Network Security Groups must not allow SSH from internet
    Given I have azurerm_network_security_rule defined
    When it contains direction
    And its value is Inbound
    When it contains access
    And its value is Allow
    When it contains destination_port_range
    And its value matches 22
    Then it must not contain source_address_prefix
    Or its value must not be *
    Or its value must not be 0.0.0.0/0
    Or its value must not be Internet

  Scenario: Log Analytics workspace must have retention configured
    Given I have azurerm_log_analytics_workspace defined
    Then it must contain retention_in_days
    And its value must be greater than 30

  Scenario: All resources must have required tags
    Given I have any resource defined
    When it has tags
    Then it must contain tags
    And it must contain deployed_via
    And it must contain Environment

  Scenario: Managed identities must be used for authentication
    Given I have azurerm_virtual_machine defined
    Then it must contain identity
    And it must contain type
    And its value must match SystemAssigned|UserAssigned

  Scenario: Automation accounts must have encryption enabled
    Given I have azurerm_automation_account defined
    When it contains encryption
    Then it must contain key_vault_key_id

  Scenario: Storage accounts must use customer-managed keys
    Given I have azurerm_storage_account defined
    When it contains customer_managed_key
    Then it must contain key_vault_key_id
    And it must contain user_assigned_identity_id
