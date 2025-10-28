# Tagging Standards and Guidelines

## Overview

This document outlines the standardized tagging conventions used across all Azure resources in the Terraform infrastructure project. Consistent tagging enables better resource management, cost tracking, compliance, and operational visibility.

## Tagging Standards

### Naming Convention
All tag keys must follow these rules:
- Use lowercase letters only
- Use underscores (_) to separate words
- No spaces, hyphens, or special characters
- Maximum length of 50 characters per key
- Maximum length of 256 characters per value

### Validation
The `default_tags` variable includes validation to enforce naming standards:
```hcl
validation {
  condition = alltrue([
    for key in keys(var.default_tags) : can(regex("^[a-z_]+$", key))
  ])
  error_message = "Tag keys must use lowercase letters and underscores only."
}
```

## Required Tags

All resources must include these mandatory tags:

### Core Infrastructure Tags
```hcl
default_tags = {
  deployed_via = "terraform"           # Deployment method
  owner        = "team-name"           # Resource owner
  team         = "infrastructure"      # Responsible team
  contact      = "team@company.com"    # Contact information
  cost_center  = "12345"              # Cost allocation
  organization = "it"                  # Business unit
  repository   = "repo-name"          # Source repository
}
```

### Automatic Tags
These tags are automatically added by the Terraform configuration:
```hcl
common_tags = merge(var.default_tags, {
  environment   = var.environment      # Environment (dev/staging/prod)
  project       = var.project_name     # Project identifier
  deployed_on   = formatdate("YYYY-MM-DD", timestamp())  # Deployment date
  terraform_ws  = terraform.workspace  # Terraform workspace
})
```

## Tag Definitions

### deployed_via
- **Purpose**: Identifies the deployment method
- **Values**: `terraform`, `arm`, `manual`, `script`
- **Example**: `deployed_via = "terraform"`

### owner
- **Purpose**: Identifies the resource owner or primary contact
- **Format**: Team name or individual identifier
- **Example**: `owner = "platform-team"`

### team
- **Purpose**: Identifies the team responsible for the resource
- **Format**: Lowercase team name with underscores
- **Example**: `team = "infrastructure_ops"`

### contact
- **Purpose**: Contact information for the responsible team
- **Format**: Email address or team alias
- **Example**: `contact = "infra-team@company.com"`

### cost_center
- **Purpose**: Cost allocation and billing tracking
- **Format**: Numeric cost center code
- **Example**: `cost_center = "85513"`

### organization
- **Purpose**: Business unit or organizational division
- **Format**: Lowercase organization name
- **Example**: `organization = "gaming"`

### repository
- **Purpose**: Source code repository reference
- **Format**: Repository name or URL
- **Example**: `repository = "azure-hubspoke-terraform"`

### environment
- **Purpose**: Deployment environment identifier
- **Values**: `dev`, `staging`, `prod`
- **Example**: `environment = "prod"`

### project
- **Purpose**: Project or application identifier
- **Format**: Lowercase project name
- **Example**: `project = "hubspoke"`

## Environment-Specific Tagging

### Development Environment
```hcl
dev_tags = {
  deployed_via = "terraform"
  owner        = "dev-team"
  team         = "development"
  contact      = "dev-team@company.com"
  cost_center  = "12345"
  organization = "engineering"
  repository   = "azure-dev-infrastructure"
  environment  = "dev"
  project      = "hubspoke"
}
```

### Production Environment
```hcl
prod_tags = {
  deployed_via = "terraform"
  owner        = "platform-team"
  team         = "platform_engineering"
  contact      = "platform@company.com"
  cost_center  = "67890"
  organization = "it"
  repository   = "azure-prod-infrastructure"
  environment  = "prod"
  project      = "hubspoke"
  compliance   = "required"
  backup       = "daily"
}
```

## Security and Compliance Tags

### Security Classification
```hcl
security_tags = {
  classification = "confidential"      # public, internal, confidential, restricted
  data_type     = "pii"               # pii, financial, healthcare, general
  compliance    = "soc2_pci_hipaa"    # Compliance requirements
}
```

### Backup and Retention
```hcl
backup_tags = {
  backup        = "daily"             # Backup frequency
  retention     = "90_days"           # Retention period
  recovery_tier = "standard"          # Recovery requirements
}
```

## Module-Specific Tagging

### Storage Account Tags
```hcl
storage_tags = {
  service_type  = "storage"
  access_tier   = "hot"
  replication   = "lrs"
  encryption    = "enabled"
}
```

### Network Tags
```hcl
network_tags = {
  service_type = "network"
  network_tier = "hub"              # hub, spoke, dmz
  traffic_type = "internal"         # internal, external, dmz
}
```

### Compute Tags
```hcl
compute_tags = {
  service_type = "compute"
  vm_size      = "standard_d2s_v3"
  os_type      = "windows"
  patch_group  = "group_a"
}
```

## Tag Usage Examples

### Resource Group Tagging
```hcl
resource "azurerm_resource_group" "main" {
  name     = "rg-hubspoke-prod-wus3"
  location = "West US 3"
  
  tags = merge(local.common_tags, {
    service_type = "resource_group"
    purpose      = "core_infrastructure"
  })
}
```

### Storage Account Tagging
```hcl
resource "azurerm_storage_account" "main" {
  name                = "sthubspokeprodwus3001"
  resource_group_name = azurerm_resource_group.main.name
  location           = azurerm_resource_group.main.location
  
  tags = merge(local.common_tags, {
    service_type = "storage"
    access_tier  = "hot"
    purpose      = "application_data"
  })
}
```

## Tag Governance

### Validation Rules
1. All tag keys must pass regex validation: `^[a-z_]+$`
2. Required tags must be present on all resources
3. Tag values must not contain sensitive information
4. Cost center tags must be valid organizational codes

### Monitoring and Compliance
- Use Azure Policy to enforce tagging standards
- Monitor tag compliance through Azure Resource Graph
- Generate cost reports based on tag values
- Audit tag usage for governance compliance

### Tag Lifecycle Management
- Review and update tags quarterly
- Remove obsolete tags during resource updates
- Maintain tag documentation with infrastructure changes
- Validate tag consistency across environments

## Troubleshooting

### Common Tagging Issues

**Tag key validation errors**
```
Error: Tag keys must use lowercase letters and underscores only
```
**Solution**: Update tag keys to use lowercase and underscores:
- `Team` → `team`
- `CostCenter` → `cost_center`
- `Organization` → `organization`

**Missing required tags**
```
Error: Required tag 'deployed_via' is missing
```
**Solution**: Ensure all required tags are included in the `default_tags` variable.

**Tag value length exceeded**
```
Error: Tag value exceeds maximum length of 256 characters
```
**Solution**: Shorten tag values or use abbreviations for long descriptions.

### Validation Commands

```bash
# Validate Terraform configuration
terraform validate

# Check tag compliance
az resource list --query "[?tags.deployed_via=='terraform']"

# Generate tag report
az resource list --query "[].{Name:name, Tags:tags}" --output table
```

## Migration from Legacy Tags

### Legacy Tag Mapping
| Legacy Tag | New Tag | Notes |
|------------|---------|-------|
| `deployed_vai` | `deployed_via` | Fixed typo |
| `Team` | `team` | Lowercase |
| `Contact` | `contact` | Lowercase |
| `CostCenter` | `cost_center` | Lowercase with underscore |
| `Organization` | `organization` | Lowercase |
| `Repo` | `repository` | Full word, lowercase |

### Migration Steps
1. Update `variables.tf` with new tag structure
2. Update all module references to use new tags
3. Update documentation and examples
4. Apply changes with `terraform apply`
5. Verify tag compliance across all resources

## Best Practices

### Tag Design
- Keep tag keys short but descriptive
- Use consistent naming across all resources
- Avoid sensitive information in tag values
- Plan for future tag requirements

### Implementation
- Use locals to merge common tags with resource-specific tags
- Validate tag formats in variable definitions
- Document tag purposes and allowed values
- Automate tag compliance checking

### Maintenance
- Regular tag audits and cleanup
- Update documentation with tag changes
- Monitor tag usage and costs
- Train team members on tagging standards

## Last Updated
December 2024 - Initial tagging standards documentation