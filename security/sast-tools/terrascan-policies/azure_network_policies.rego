# Azure Network Security Policies
# Custom OPA policies for Azure Network Security Group validation

package accurics

# Policy: Ensure NSG rules have proper descriptions
nsgRuleDescriptions[retVal] {
    resource := input.azurerm_network_security_rule[_]
    not resource.config.description
    
    traverse := "description"
    retVal := {
        "Id": "CUSTOM_AZURE_NETWORK_001",
        "RuleID": "CUSTOM_AZURE_NETWORK_001",
        "Type": "azure",
        "Category": "NETWORKING",
        "Severity": "LOW",
        "Description": "Network Security Group rules should have meaningful descriptions",
        "RuleFile": "azure_network_policies.rego",
        "Resource": sprintf("azurerm_network_security_rule.%s", [resource.name]),
        "ResourceType": "azurerm_network_security_rule",
        "File": resource.source,
        "Line": resource.line,
        "Traverse": traverse,
        "SubCategory": "Standards",
        "Message": sprintf("NSG rule '%s' should have a description", [resource.name]),
        "RecommendedActions": "Add a meaningful description to the NSG rule"
    }
}

nsgRuleDescriptions[retVal] {
    resource := input.azurerm_network_security_rule[_]
    resource.config.description
    resource.config.description[_] == ""
    
    traverse := "description"
    retVal := {
        "Id": "CUSTOM_AZURE_NETWORK_001",
        "RuleID": "CUSTOM_AZURE_NETWORK_001",
        "Type": "azure",
        "Category": "NETWORKING",
        "Severity": "LOW",
        "Description": "Network Security Group rules should have meaningful descriptions",
        "RuleFile": "azure_network_policies.rego",
        "Resource": sprintf("azurerm_network_security_rule.%s", [resource.name]),
        "ResourceType": "azurerm_network_security_rule",
        "File": resource.source,
        "Line": resource.line,
        "Traverse": traverse,
        "SubCategory": "Standards",
        "Message": sprintf("NSG rule '%s' has an empty description", [resource.name]),
        "RecommendedActions": "Add a meaningful description to the NSG rule"
    }
}

# Policy: Ensure NSG rules don't allow unrestricted inbound access
nsgUnrestrictedInbound[retVal] {
    resource := input.azurerm_network_security_rule[_]
    resource.config.direction[_] == "Inbound"
    resource.config.access[_] == "Allow"
    resource.config.source_address_prefix[_] == "*"
    resource.config.destination_port_range[_] == "*"
    
    traverse := "source_address_prefix"
    retVal := {
        "Id": "CUSTOM_AZURE_NETWORK_002",
        "RuleID": "CUSTOM_AZURE_NETWORK_002",
        "Type": "azure",
        "Category": "NETWORKING",
        "Severity": "CRITICAL",
        "Description": "NSG rule should not allow unrestricted inbound access",
        "RuleFile": "azure_network_policies.rego",
        "Resource": sprintf("azurerm_network_security_rule.%s", [resource.name]),
        "ResourceType": "azurerm_network_security_rule",
        "File": resource.source,
        "Line": resource.line,
        "Traverse": traverse,
        "SubCategory": "Standards",
        "Message": sprintf("NSG rule '%s' allows unrestricted inbound access", [resource.name]),
        "RecommendedActions": "Restrict source address prefix and destination port range"
    }
}

# Policy: Ensure NSG rules don't allow SSH from internet
nsgSshFromInternet[retVal] {
    resource := input.azurerm_network_security_rule[_]
    resource.config.direction[_] == "Inbound"
    resource.config.access[_] == "Allow"
    resource.config.source_address_prefix[_] == "*"
    
    # Check for SSH port (22)
    ssh_ports := ["22", "ssh"]
    port := resource.config.destination_port_range[_]
    port == ssh_ports[_]
    
    traverse := "destination_port_range"
    retVal := {
        "Id": "CUSTOM_AZURE_NETWORK_003",
        "RuleID": "CUSTOM_AZURE_NETWORK_003",
        "Type": "azure",
        "Category": "NETWORKING",
        "Severity": "CRITICAL",
        "Description": "NSG rule should not allow SSH access from internet",
        "RuleFile": "azure_network_policies.rego",
        "Resource": sprintf("azurerm_network_security_rule.%s", [resource.name]),
        "ResourceType": "azurerm_network_security_rule",
        "File": resource.source,
        "Line": resource.line,
        "Traverse": traverse,
        "SubCategory": "Standards",
        "Message": sprintf("NSG rule '%s' allows SSH access from internet", [resource.name]),
        "RecommendedActions": "Restrict SSH access to specific IP ranges or use bastion host"
    }
}

# Policy: Ensure NSG rules don't allow RDP from internet
nsgRdpFromInternet[retVal] {
    resource := input.azurerm_network_security_rule[_]
    resource.config.direction[_] == "Inbound"
    resource.config.access[_] == "Allow"
    resource.config.source_address_prefix[_] == "*"
    
    # Check for RDP port (3389)
    rdp_ports := ["3389", "rdp"]
    port := resource.config.destination_port_range[_]
    port == rdp_ports[_]
    
    traverse := "destination_port_range"
    retVal := {
        "Id": "CUSTOM_AZURE_NETWORK_004",
        "RuleID": "CUSTOM_AZURE_NETWORK_004",
        "Type": "azure",
        "Category": "NETWORKING",
        "Severity": "CRITICAL",
        "Description": "NSG rule should not allow RDP access from internet",
        "RuleFile": "azure_network_policies.rego",
        "Resource": sprintf("azurerm_network_security_rule.%s", [resource.name]),
        "ResourceType": "azurerm_network_security_rule",
        "File": resource.source,
        "Line": resource.line,
        "Traverse": traverse,
        "SubCategory": "Standards",
        "Message": sprintf("NSG rule '%s' allows RDP access from internet", [resource.name]),
        "RecommendedActions": "Restrict RDP access to specific IP ranges or use bastion host"
    }
}

# Policy: Ensure NSG has required tags
nsgRequiredTags[retVal] {
    resource := input.azurerm_network_security_group[_]
    required_tags := ["deployed_via", "owner", "Team", "Environment"]
    
    missing_tag := required_tags[_]
    not resource.config.tags[missing_tag]
    
    traverse := sprintf("tags.%s", [missing_tag])
    retVal := {
        "Id": "CUSTOM_AZURE_NETWORK_005",
        "RuleID": "CUSTOM_AZURE_NETWORK_005",
        "Type": "azure",
        "Category": "IDENTITY AND ACCESS MANAGEMENT",
        "Severity": "LOW",
        "Description": "Network Security Group should have required project tags",
        "RuleFile": "azure_network_policies.rego",
        "Resource": sprintf("azurerm_network_security_group.%s", [resource.name]),
        "ResourceType": "azurerm_network_security_group",
        "File": resource.source,
        "Line": resource.line,
        "Traverse": traverse,
        "SubCategory": "Standards",
        "Message": sprintf("NSG '%s' is missing required tag '%s'", [resource.name, missing_tag]),
        "RecommendedActions": sprintf("Add tag '%s' to the Network Security Group", [missing_tag])
    }
}

# Policy: Ensure NSG rules have appropriate priority values
nsgRulePriority[retVal] {
    resource := input.azurerm_network_security_rule[_]
    priority := to_number(resource.config.priority[_])
    
    # Priority should be between 100 and 4096, and not use default ranges
    priority < 100
    
    traverse := "priority"
    retVal := {
        "Id": "CUSTOM_AZURE_NETWORK_006",
        "RuleID": "CUSTOM_AZURE_NETWORK_006",
        "Type": "azure",
        "Category": "NETWORKING",
        "Severity": "MEDIUM",
        "Description": "NSG rule priority should be within valid range (100-4096)",
        "RuleFile": "azure_network_policies.rego",
        "Resource": sprintf("azurerm_network_security_rule.%s", [resource.name]),
        "ResourceType": "azurerm_network_security_rule",
        "File": resource.source,
        "Line": resource.line,
        "Traverse": traverse,
        "SubCategory": "Standards",
        "Message": sprintf("NSG rule '%s' has invalid priority %d", [resource.name, priority]),
        "RecommendedActions": "Set priority between 100 and 4096"
    }
}