# Terraform Compliance Policy-as-Code Tests

This directory contains BDD-style policy tests for Terraform infrastructure using [Terraform Compliance](https://terraform-compliance.com/).

## Overview

Terraform Compliance is a lightweight, security and compliance-focused test framework against Terraform to enable negative testing capability for your infrastructure-as-code.

### Key Features

- **BDD-Style Tests**: Write tests in Gherkin syntax (Given-When-Then)
- **Policy-as-Code**: Define security and compliance policies as executable tests
- **Terraform Native**: Works directly with Terraform plan files
- **No Agent Required**: Runs locally or in CI/CD pipelines
- **Extensible**: Easy to add new policies and scenarios

## Installation

Install Terraform Compliance using the provided script:

```powershell
.\security\scripts\install-terraform-compliance.ps1
```

Or install manually with pip:

```bash
pip install --upgrade terraform-compliance
```

## Policy Files

### azure_security.feature
Security best practices for Azure resources:
- Storage account HTTPS and TLS requirements
- Key Vault security configurations
- Virtual machine encryption
- Network Security Group rules
- Managed identity usage
- Customer-managed encryption keys

### network_security.feature
Network security controls:
- DDoS protection
- Network Security Groups
- Application Gateway WAF
- Azure Bastion deployment
- Private endpoints
- VPN and ExpressRoute encryption
- Network Watcher and flow logs

### compliance.feature
Compliance and governance requirements:
- Resource naming conventions
- Approved Azure regions
- Diagnostic settings and retention
- Backup policies
- Soft delete and purge protection
- Auditing and threat detection
- Azure Policy assignments
- Management locks

## Usage

### Run All Policy Tests

```powershell
.\security\scripts\run-terraform-compliance.ps1
```

## Examples

### Basic Policy Test Execution

```powershell
# Run all policy tests with default settings
.\security\scripts\run-terraform-compliance.ps1
```

### Run Specific Feature File

```powershell
.\security\scripts\run-terraform-compliance.ps1 -Features "azure_security.feature"
```

### Use Existing Terraform Plan

```powershell
.\security\scripts\run-terraform-compliance.ps1 -PlanFile "path/to/tfplan.json" -GeneratePlan:$false
```

### Verbose Output

```powershell
.\security\scripts\run-terraform-compliance.ps1 -Verbose
```

## Writing Policy Tests

### Basic Structure

```gherkin
Feature: Feature Name
  As a [role]
  I want to [action]
  So that [benefit]

  Scenario: Scenario description
    Given I have [resource_type] defined
    Then it must contain [attribute]
    And its value must be [expected_value]
```

### Common Patterns

#### Check for Required Attribute

```gherkin
Scenario: Resource must have required attribute
  Given I have azurerm_storage_account defined
  Then it must contain enable_https_traffic_only
  And its value must be true
```

#### Check Attribute Value

```gherkin
Scenario: Attribute must have specific value
  Given I have azurerm_storage_account defined
  When it contains min_tls_version
  Then its value must be TLS1_2
```

#### Check for Nested Attributes

```gherkin
Scenario: Nested attribute validation
  Given I have azurerm_storage_account defined
  When it contains network_rules
  Then it must contain default_action
  And its value must be Deny
```

#### Conditional Checks

```gherkin
Scenario: Conditional validation
  Given I have azurerm_network_security_rule defined
  When it contains direction
  And its value is Inbound
  When it contains access
  And its value is Allow
  Then it must not contain source_address_prefix
  Or its value must not be *
```

#### Pattern Matching

```gherkin
Scenario: Value must match pattern
  Given I have azurerm_resource_group defined
  Then it must contain name
  And its value must match ^rg-[a-z0-9-]+$
```

#### Numeric Comparisons

```gherkin
Scenario: Value must be greater than threshold
  Given I have azurerm_log_analytics_workspace defined
  Then it must contain retention_in_days
  And its value must be greater than 30
```

#### Resource Relationships

```gherkin
Scenario: Related resources must exist
  Given I have azurerm_virtual_network defined
  Then I have azurerm_bastion_host defined
```

## Integration with CI/CD

### GitHub Actions

```yaml
- name: Run Terraform Compliance
  run: |
    pip install terraform-compliance
    terraform-compliance -f security/policies/ -p tfplan.json
```

### Azure DevOps

```yaml
- task: PowerShell@2
  displayName: 'Run Terraform Compliance'
  inputs:
    filePath: 'security/scripts/run-terraform-compliance.ps1'
    arguments: '-FailOnError'
```

## Best Practices

1. **Organize by Domain**: Group related policies in separate feature files
2. **Use Descriptive Names**: Make scenario names clear and specific
3. **Test One Thing**: Each scenario should test a single policy
4. **Add Context**: Use feature descriptions to explain the purpose
5. **Keep It Simple**: Start with basic checks and add complexity as needed
6. **Regular Updates**: Review and update policies as requirements change
7. **Version Control**: Track policy changes alongside infrastructure code

## Troubleshooting

### Common Issues

**Issue**: `terraform-compliance: command not found`
**Solution**: Install using `pip install terraform-compliance`

**Issue**: `No resources found in plan`
**Solution**: Ensure Terraform plan contains resources (not just data sources)

**Issue**: `Scenario fails unexpectedly`
**Solution**: Use `-Verbose` flag to see detailed test output

**Issue**: `Plan file not found`
**Solution**: Generate plan first or specify correct path with `-PlanFile`

## Resources

- [Terraform Compliance Documentation](https://terraform-compliance.com/)
- [Gherkin Syntax Reference](https://cucumber.io/docs/gherkin/reference/)
- [Azure Security Best Practices](https://docs.microsoft.com/en-us/azure/security/fundamentals/best-practices-and-patterns)
- [CIS Azure Foundations Benchmark](https://www.cisecurity.org/benchmark/azure)

## Contributing

To add new policies:

1. Create or edit a `.feature` file in this directory
2. Follow the Gherkin syntax and existing patterns
3. Test the policy against sample Terraform code
4. Document the policy purpose and requirements
5. Update this README if adding new feature files

## Policy Maintenance

- Review policies quarterly for relevance
- Update policies when Azure best practices change
- Add policies for new Azure services as adopted
- Remove or deprecate policies for retired services
- Keep policies aligned with organizational security standards
