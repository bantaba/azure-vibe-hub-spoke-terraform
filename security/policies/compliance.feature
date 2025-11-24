Feature: Compliance and Governance
  As a compliance officer
  I want to ensure infrastructure meets regulatory requirements
  So that we maintain compliance with industry standards

  Scenario: All resources must be in approved Azure regions
    Given I have any resource defined
    When it contains location
    Then its value must match East US|West US|North Europe|West Europe

  Scenario: Resource naming must follow conventions
    Given I have azurerm_resource_group defined
    Then it must contain name
    And its value must match ^rg-[a-z0-9-]+$

  Scenario: Storage account naming must follow conventions
    Given I have azurerm_storage_account defined
    Then it must contain name
    And its value must match ^st[a-z0-9]{3,22}$

  Scenario: Key Vault naming must follow conventions
    Given I have azurerm_key_vault defined
    Then it must contain name
    And its value must match ^kv-[a-z0-9-]+$

  Scenario: Virtual machine naming must follow conventions
    Given I have azurerm_virtual_machine defined
    Then it must contain name
    And its value must match ^vm-[a-z0-9-]+$

  Scenario: Diagnostic settings must be enabled for all resources
    Given I have azurerm_storage_account defined
    Then I have azurerm_monitor_diagnostic_setting defined

  Scenario: Activity logs must be retained for compliance period
    Given I have azurerm_monitor_diagnostic_setting defined
    When it contains log
    Then it must contain retention_policy
    And it must contain days
    And its value must be greater than 90

  Scenario: Backup must be enabled for virtual machines
    Given I have azurerm_virtual_machine defined
    Then I have azurerm_backup_protected_vm defined

  Scenario: Backup retention must meet compliance requirements
    Given I have azurerm_backup_policy_vm defined
    When it contains retention_daily
    Then it must contain count
    And its value must be greater than 30

  Scenario: Soft delete must be enabled for Key Vault
    Given I have azurerm_key_vault defined
    Then it must contain soft_delete_retention_days
    And its value must be greater than 7

  Scenario: Purge protection must be enabled for Key Vault
    Given I have azurerm_key_vault defined
    Then it must contain purge_protection_enabled
    And its value must be true

  Scenario: Storage account must have soft delete enabled for blobs
    Given I have azurerm_storage_account defined
    When it contains blob_properties
    Then it must contain delete_retention_policy
    And it must contain days
    And its value must be greater than 7

  Scenario: SQL databases must have auditing enabled
    Given I have azurerm_mssql_database defined
    Then I have azurerm_mssql_database_extended_auditing_policy defined

  Scenario: SQL databases must have threat detection enabled
    Given I have azurerm_mssql_database defined
    Then I have azurerm_mssql_database_threat_detection_policy defined

  Scenario: Transparent data encryption must be enabled for SQL
    Given I have azurerm_mssql_database defined
    Then I have azurerm_mssql_database_transparent_data_encryption defined

  Scenario: Azure Policy must be assigned to subscriptions
    Given I have azurerm_subscription defined
    Then I have azurerm_policy_assignment defined

  Scenario: Management locks must be applied to critical resources
    Given I have azurerm_resource_group defined
    When it contains tags
    And it contains criticality
    And its value matches high|critical
    Then I have azurerm_management_lock defined
