# Azure Storage Account Security Policies
# Custom OPA policies for Azure Storage Account security validation

package accurics

# Policy: Ensure Storage Account uses customer-managed keys
storageAccountCustomerManagedKey[retVal] {
    resource := input.azurerm_storage_account[_]
    not resource.config.customer_managed_key
    
    traverse := "customer_managed_key"
    retVal := {
        "Id": "CUSTOM_AZURE_STORAGE_001",
        "RuleID": "CUSTOM_AZURE_STORAGE_001", 
        "Type": "azure",
        "Category": "DATA PROTECTION",
        "Severity": "HIGH",
        "Description": "Storage Account should use customer-managed keys for encryption",
        "RuleFile": "azure_storage_policies.rego",
        "Resource": sprintf("azurerm_storage_account.%s", [resource.name]),
        "ResourceType": "azurerm_storage_account",
        "File": resource.source,
        "Line": resource.line,
        "Traverse": traverse,
        "SubCategory": "Standards",
        "Message": sprintf("Storage Account '%s' should use customer-managed keys for encryption", [resource.name]),
        "RecommendedActions": "Configure customer_managed_key block with key_vault_key_id"
    }
}

# Policy: Ensure Storage Account has network access restrictions
storageAccountNetworkRestrictions[retVal] {
    resource := input.azurerm_storage_account[_]
    not resource.config.network_rules
    
    traverse := "network_rules"
    retVal := {
        "Id": "CUSTOM_AZURE_STORAGE_002",
        "RuleID": "CUSTOM_AZURE_STORAGE_002",
        "Type": "azure", 
        "Category": "NETWORKING",
        "Severity": "HIGH",
        "Description": "Storage Account should have network access restrictions configured",
        "RuleFile": "azure_storage_policies.rego",
        "Resource": sprintf("azurerm_storage_account.%s", [resource.name]),
        "ResourceType": "azurerm_storage_account", 
        "File": resource.source,
        "Line": resource.line,
        "Traverse": traverse,
        "SubCategory": "Standards",
        "Message": sprintf("Storage Account '%s' should have network access restrictions", [resource.name]),
        "RecommendedActions": "Configure network_rules block with default_action = 'Deny'"
    }
}

storageAccountNetworkRestrictions[retVal] {
    resource := input.azurerm_storage_account[_]
    resource.config.network_rules
    resource.config.network_rules[_].default_action[_] != "Deny"
    
    traverse := "network_rules[0].default_action"
    retVal := {
        "Id": "CUSTOM_AZURE_STORAGE_002",
        "RuleID": "CUSTOM_AZURE_STORAGE_002",
        "Type": "azure",
        "Category": "NETWORKING", 
        "Severity": "HIGH",
        "Description": "Storage Account network rules should deny access by default",
        "RuleFile": "azure_storage_policies.rego",
        "Resource": sprintf("azurerm_storage_account.%s", [resource.name]),
        "ResourceType": "azurerm_storage_account",
        "File": resource.source,
        "Line": resource.line,
        "Traverse": traverse,
        "SubCategory": "Standards",
        "Message": sprintf("Storage Account '%s' network rules should have default_action = 'Deny'", [resource.name]),
        "RecommendedActions": "Set network_rules.default_action to 'Deny'"
    }
}

# Policy: Ensure Storage Account has required tags
storageAccountRequiredTags[retVal] {
    resource := input.azurerm_storage_account[_]
    required_tags := ["deployed_via", "owner", "Team", "Environment"]
    
    missing_tag := required_tags[_]
    not resource.config.tags[missing_tag]
    
    traverse := sprintf("tags.%s", [missing_tag])
    retVal := {
        "Id": "CUSTOM_AZURE_STORAGE_003",
        "RuleID": "CUSTOM_AZURE_STORAGE_003",
        "Type": "azure",
        "Category": "IDENTITY AND ACCESS MANAGEMENT",
        "Severity": "LOW", 
        "Description": "Storage Account should have required project tags",
        "RuleFile": "azure_storage_policies.rego",
        "Resource": sprintf("azurerm_storage_account.%s", [resource.name]),
        "ResourceType": "azurerm_storage_account",
        "File": resource.source,
        "Line": resource.line,
        "Traverse": traverse,
        "SubCategory": "Standards",
        "Message": sprintf("Storage Account '%s' is missing required tag '%s'", [resource.name, missing_tag]),
        "RecommendedActions": sprintf("Add tag '%s' to the storage account", [missing_tag])
    }
}

# Policy: Ensure Storage Account enables blob versioning
storageAccountBlobVersioning[retVal] {
    resource := input.azurerm_storage_account[_]
    not resource.config.blob_properties
    
    traverse := "blob_properties"
    retVal := {
        "Id": "CUSTOM_AZURE_STORAGE_004",
        "RuleID": "CUSTOM_AZURE_STORAGE_004",
        "Type": "azure",
        "Category": "DATA PROTECTION",
        "Severity": "MEDIUM",
        "Description": "Storage Account should have blob properties configured for data protection",
        "RuleFile": "azure_storage_policies.rego", 
        "Resource": sprintf("azurerm_storage_account.%s", [resource.name]),
        "ResourceType": "azurerm_storage_account",
        "File": resource.source,
        "Line": resource.line,
        "Traverse": traverse,
        "SubCategory": "Standards",
        "Message": sprintf("Storage Account '%s' should have blob properties configured", [resource.name]),
        "RecommendedActions": "Configure blob_properties block with versioning_enabled = true"
    }
}