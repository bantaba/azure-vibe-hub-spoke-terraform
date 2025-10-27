# Project Structure

## Root Directory Layout

```
├── .git/                    # Git version control
├── .kiro/                   # Kiro AI assistant configuration
├── docs/                    # Project documentation
├── scripts/                 # Automation and utility scripts
├── security/                # Security tools and configurations
└── src/                     # Terraform source code
```

## Source Code Organization (`src/`)

```
src/
├── main.tf                  # Primary infrastructure definitions
├── provider.tf              # Provider configurations
├── variables.tf             # Variable definitions and locals
├── terraform.tf             # Terraform and provider version constraints
├── output.tf                # Output definitions
└── modules/                 # Reusable Terraform modules
    ├── authorization/       # RBAC and role assignments
    ├── automation/          # Azure Automation Account
    ├── compute/             # Virtual machines and availability sets
    ├── monitoring/          # Log Analytics and monitoring
    ├── network/             # Networking components (VNet, NSG, Bastion)
    ├── resourceGroup/       # Resource group management
    ├── Security/            # Key Vault, managed identities, secrets
    └── Storage/             # Storage accounts and containers
```

## Documentation Structure (`docs/`)

- `security/` - Security policies and procedures
- `setup/` - Installation and configuration guides
- `operations/` - Operational procedures and troubleshooting
- `changelog/` - Version history and change tracking

## Scripts Organization (`scripts/`)

- `git/` - Git workflow automation
- `security/` - Security scanning and validation
- `ci-cd/` - CI/CD pipeline configurations
- `utils/` - General utility scripts

## Module Architecture

### Module Naming Convention
- Use descriptive folder names matching Azure service categories
- Group related resources within logical modules
- Maintain consistent input/output variable naming

### Module Dependencies
- Core infrastructure modules (networking, security) are deployed first
- Compute resources depend on networking and security modules
- Monitoring and logging modules integrate across all resources

## File Naming Standards

- Use lowercase with underscores for Terraform files
- PowerShell scripts use `.ps1` extension
- Documentation uses `.md` extension
- Follow Azure resource abbreviations in variable definitions

## Tagging Strategy

All resources must include standardized tags:
- `deployed_via`: "Terraform"
- `owner`: Resource owner
- `Team`: Team responsible
- `Environment`: Terraform workspace name
- `DeployedOn`: Deployment timestamp