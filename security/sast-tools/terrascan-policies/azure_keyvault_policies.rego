# Azure Key Vault Security Policies
# Custom OPA policies for Azure Key Vault security validation

package accurics

# Policy: Ensure Key Vault has network ACLs configured
keyVaultNetworkAcls[retVal] {
    resource := input.azurerm_key_vault[_]
    not resource.config.network_acls
    
    traverse := "network_acls"
    retVal := {
        "Id": "CUSTOM_AZURE_KEYVAULT_001",
        "RuleID": "CUSTOM_AZURE_KEYVAULT_001",
        "Type": "azure",
        "Category": "NETWORKING",
        "Severity": "HIGH",
        "Description": "Key Vault should have network ACLs configured",
        "RuleFile": "azure_keyvault_policies.rego",
        "Resource": sprintf("azurerm_key_vault.%s", [resource.name]),
        "ResourceType": "azurerm_key_vault",
        "File": resource.source,
        "Line": resource.line,
        "Traverse": traverse,
        "SubCategory": "Standards",
        "Message": sprintf("Key Vault '%s' should have network ACLs configured", [resource.name]),
        "RecommendedActions": "Configure network_acls block with default_action = 'Deny'"
    }
}

keyVaultNetworkAcls[retVal] {
    resource := input.azurerm_key_vault[_]
    resource.config.network_acls
    resource.config.network_acls[_].default_action[_] != "Deny"
    
    traverse := "network_acls[0].default_action"
    retVal := {
        "Id": "CUSTOM_AZURE_KEYVAULT_001",
        "RuleID": "CUSTOM_AZURE_KEYVAULT_001",
        "Type": "azure",
        "Category": "NETWORKING",
        "Severity": "HIGH",
        "Description": "Key Vault network ACLs should deny access by default",
        "RuleFile": "azure_keyvault_policies.rego",
        "Resource": sprintf("azurerm_key_vault.%s", [resource.name]),
        "ResourceType": "azurerm_key_vault",
        "File": resource.source,
        "Line": resource.line,
        "Traverse": traverse,
        "SubCategory": "Standards",
        "Message": sprintf("Key Vault '%s' network ACLs should have default_action = 'Deny'", [resource.name]),
        "RecommendedActions": "Set network_acls.default_action to 'Deny'"
    }
}

# Policy: Ensure Key Vault has purge protection enabled
keyVaultPurgeProtection[retVal] {
    resource := input.azurerm_key_vault[_]
    not resource.config.purge_protection_enabled
    
    traverse := "purge_protection_enabled"
    retVal := {
        "Id": "CUSTOM_AZURE_KEYVAULT_002",
        "RuleID": "CUSTOM_AZURE_KEYVAULT_002",
        "Type": "azure",
        "Category": "DATA PROTECTION",
        "Severity": "HIGH",
        "Description": "Key Vault should have purge protection enabled",
        "RuleFile": "azure_keyvault_policies.rego",
        "Resource": sprintf("azurerm_key_vault.%s", [resource.name]),
        "ResourceType": "azurerm_key_vault",
        "File": resource.source,
        "Line": resource.line,
        "Traverse": traverse,
        "SubCategory": "Standards",
        "Message": sprintf("Key Vault '%s' should have purge protection enabled", [resource.name]),
        "RecommendedActions": "Set purge_protection_enabled = true"
    }
}

keyVaultPurgeProtection[retVal] {
    resource := input.azurerm_key_vault[_]
    resource.config.purge_protection_enabled
    resource.config.purge_protection_enabled[_] != true
    
    traverse := "purge_protection_enabled"
    retVal := {
        "Id": "CUSTOM_AZURE_KEYVAULT_002",
        "RuleID": "CUSTOM_AZURE_KEYVAULT_002",
        "Type": "azure",
        "Category": "DATA PROTECTION",
        "Severity": "HIGH",
        "Description": "Key Vault purge protection should be enabled",
        "RuleFile": "azure_keyvault_policies.rego",
        "Resource": sprintf("azurerm_key_vault.%s", [resource.name]),
        "ResourceType": "azurerm_key_vault",
        "File": resource.source,
        "Line": resource.line,
        "Traverse": traverse,
        "SubCategory": "Standards",
        "Message": sprintf("Key Vault '%s' should have purge_protection_enabled = true", [resource.name]),
        "RecommendedActions": "Set purge_protection_enabled = true"
    }
}

# Policy: Ensure Key Vault access policies follow least privilege
keyVaultAccessPolicyLeastPrivilege[retVal] {
    resource := input.azurerm_key_vault_access_policy[_]
    excessive_permissions := ["*", "all"]
    
    # Check key permissions
    resource.config.key_permissions
    perm := resource.config.key_permissions[_][_]
    lower(perm) == excessive_permissions[_]
    
    traverse := "key_permissions"
    retVal := {
        "Id": "CUSTOM_AZURE_KEYVAULT_003",
        "RuleID": "CUSTOM_AZURE_KEYVAULT_003",
        "Type": "azure",
        "Category": "IDENTITY AND ACCESS MANAGEMENT",
        "Severity": "MEDIUM",
        "Description": "Key Vault access policy should not grant excessive key permissions",
        "RuleFile": "azure_keyvault_policies.rego",
        "Resource": sprintf("azurerm_key_vault_access_policy.%s", [resource.name]),
        "ResourceType": "azurerm_key_vault_access_policy",
        "File": resource.source,
        "Line": resource.line,
        "Traverse": traverse,
        "SubCategory": "Standards",
        "Message": sprintf("Key Vault access policy '%s' grants excessive key permissions", [resource.name]),
        "RecommendedActions": "Replace wildcard permissions with specific required permissions"
    }
}

keyVaultAccessPolicyLeastPrivilege[retVal] {
    resource := input.azurerm_key_vault_access_policy[_]
    excessive_permissions := ["*", "all"]
    
    # Check secret permissions
    resource.config.secret_permissions
    perm := resource.config.secret_permissions[_][_]
    lower(perm) == excessive_permissions[_]
    
    traverse := "secret_permissions"
    retVal := {
        "Id": "CUSTOM_AZURE_KEYVAULT_003",
        "RuleID": "CUSTOM_AZURE_KEYVAULT_003",
        "Type": "azure",
        "Category": "IDENTITY AND ACCESS MANAGEMENT",
        "Severity": "MEDIUM",
        "Description": "Key Vault access policy should not grant excessive secret permissions",
        "RuleFile": "azure_keyvault_policies.rego",
        "Resource": sprintf("azurerm_key_vault_access_policy.%s", [resource.name]),
        "ResourceType": "azurerm_key_vault_access_policy",
        "File": resource.source,
        "Line": resource.line,
        "Traverse": traverse,
        "SubCategory": "Standards",
        "Message": sprintf("Key Vault access policy '%s' grants excessive secret permissions", [resource.name]),
        "RecommendedActions": "Replace wildcard permissions with specific required permissions"
    }
}

# Policy: Ensure Key Vault has required tags
keyVaultRequiredTags[retVal] {
    resource := input.azurerm_key_vault[_]
    required_tags := ["deployed_via", "owner", "Team", "Environment"]
    
    missing_tag := required_tags[_]
    not resource.config.tags[missing_tag]
    
    traverse := sprintf("tags.%s", [missing_tag])
    retVal := {
        "Id": "CUSTOM_AZURE_KEYVAULT_004",
        "RuleID": "CUSTOM_AZURE_KEYVAULT_004",
        "Type": "azure",
        "Category": "IDENTITY AND ACCESS MANAGEMENT",
        "Severity": "LOW",
        "Description": "Key Vault should have required project tags",
        "RuleFile": "azure_keyvault_policies.rego",
        "Resource": sprintf("azurerm_key_vault.%s", [resource.name]),
        "ResourceType": "azurerm_key_vault",
        "File": resource.source,
        "Line": resource.line,
        "Traverse": traverse,
        "SubCategory": "Standards",
        "Message": sprintf("Key Vault '%s' is missing required tag '%s'", [resource.name, missing_tag]),
        "RecommendedActions": sprintf("Add tag '%s' to the Key Vault", [missing_tag])
    }
}