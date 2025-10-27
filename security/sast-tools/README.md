# SAST Tools Configuration

This directory contains configuration files and custom policies for Static Application Security Testing (SAST) tools used in the Terraform security enhancement project.

## Overview

The project integrates three main SAST tools:

- **Checkov**: Infrastructure-as-code security scanner with custom Python policies
- **TFSec**: Terraform-specific security scanner with YAML configuration
- **Terrascan**: Policy-as-code security validation using Open Policy Agent (OPA)

## Directory Structure

```
security/sast-tools/
├── .checkov.yaml                    # Checkov configuration file
├── .tfsec.yml                       # TFSec configuration file
├── .terrascan_config.toml           # Terrascan configuration file
├── README.md                        # This file
├── checkov-policies/                # Custom Checkov policies (Python)
│   ├── azure_storage_custom.py      # Storage Account security policies
│   └── azure_keyvault_custom.py     # Key Vault security policies
├── tfsec-rules/                     # Custom TFSec rules (JSON)
│   └── azure_custom_rules.json      # Azure-specific custom rules
└── terrascan-policies/              # Custom Terrascan policies (OPA/Rego)
    ├── azure_storage_policies.rego  # Storage Account OPA policies
    ├── azure_keyvault_policies.rego # Key Vault OPA policies
    └── azure_network_policies.rego  # Network Security Group OPA policies
```

## Tool Configurations

### Checkov Configuration

**File**: `.checkov.yaml`

Key features:
- Azure-specific security checks enabled
- Custom policies directory configured
- Multiple output formats (CLI, JSON, JUnit, SARIF)
- Hard fail on CRITICAL and HIGH severity issues
- Baseline comparison support

**Custom Policies**: Located in `checkov-policies/`
- Storage Account encryption and network restrictions
- Key Vault access policy validation
- Required tagging enforcement

### TFSec Configuration

**File**: `.tfsec.yml`

Key features:
- Azure best practices rules
- Custom severity overrides
- Multiple output formats
- Custom rules directory support
- Terraform version constraints

**Custom Rules**: Located in `tfsec-rules/azure_custom_rules.json`
- Customer-managed key validation
- Network access restrictions
- RBAC least privilege checks

### Terrascan Configuration

**File**: `.terrascan_config.toml`

Key features:
- OPA policy-as-code validation
- Azure cloud provider focus
- Custom policy directory
- Multiple output formats
- Severity-based filtering

**Custom Policies**: Located in `terrascan-policies/`
- Comprehensive Azure resource validation
- Network security enforcement
- Identity and access management checks

## Installation

### Prerequisites

- Python 3.7+ (for Checkov)
- PowerShell 5.1+ or PowerShell Core 7+
- Internet connection for tool downloads

### Install All Tools

Run the unified installation script:

```powershell
.\security\scripts\install-all-sast-tools.ps1
```

### Install Individual Tools

```powershell
# Install Checkov
.\security\scripts\install-checkov.ps1

# Install TFSec
.\security\scripts\install-tfsec.ps1

# Install Terrascan
.\security\scripts\install-terrascan.ps1
```

## Usage

### Run All SAST Tools

Use the unified execution script:

```powershell
.\security\scripts\run-sast-scan.ps1
```

Options:
- `-FailOnHigh`: Fail build on HIGH severity issues (default: true)
- `-FailOnCritical`: Fail build on CRITICAL severity issues (default: true)
- `-Verbose`: Enable verbose output
- `-SkipCheckov`: Skip Checkov scan
- `-SkipTFSec`: Skip TFSec scan
- `-SkipTerrascan`: Skip Terrascan scan

### Run Individual Tools

```powershell
# Run Checkov
checkov --config-file security/sast-tools/.checkov.yaml

# Run TFSec
tfsec --config-file security/sast-tools/.tfsec.yml src/

# Run Terrascan
terrascan scan --config-path security/sast-tools/.terrascan_config.toml
```

## Reports

All scan reports are saved to `security/reports/`:

- `checkov-report.json` - Checkov scan results
- `checkov-junit.xml` - Checkov JUnit format
- `checkov-sarif.json` - Checkov SARIF format
- `tfsec-report.json` - TFSec scan results
- `tfsec-sarif.json` - TFSec SARIF format
- `tfsec-junit.xml` - TFSec JUnit format
- `results.json` - Terrascan scan results
- `unified-sast-report.json` - Aggregated results from all tools

## Custom Policy Development

### Adding Checkov Policies

1. Create a new Python file in `checkov-policies/`
2. Implement custom checks extending `BaseResourceCheck`
3. Register the checks at the end of the file
4. Update `.checkov.yaml` if needed

Example:
```python
from checkov.terraform.checks.resource.base_resource_check import BaseResourceCheck

class MyCustomCheck(BaseResourceCheck):
    def __init__(self):
        name = "My custom security check"
        id = "CKV_AZURE_CUSTOM_X"
        # ... implementation
```

### Adding TFSec Rules

1. Edit `tfsec-rules/azure_custom_rules.json`
2. Add new rule objects with appropriate conditions
3. Update `.tfsec.yml` configuration if needed

### Adding Terrascan Policies

1. Create new `.rego` files in `terrascan-policies/`
2. Implement OPA policies using Rego language
3. Follow the `accurics` package naming convention
4. Update `.terrascan_config.toml` if needed

## CI/CD Integration

The SAST tools are designed to integrate with CI/CD pipelines:

- **Exit Codes**: Tools return non-zero exit codes on security issues
- **Report Formats**: Multiple formats supported (JSON, SARIF, JUnit)
- **Severity Filtering**: Configure which severity levels fail builds
- **Baseline Support**: Compare against previous scan results

## Troubleshooting

### Common Issues

1. **Tool Not Found**: Ensure tools are installed and in PATH
2. **Configuration Errors**: Validate YAML/TOML syntax
3. **Custom Policy Errors**: Check Python/Rego syntax
4. **Permission Issues**: Run PowerShell as Administrator if needed

### Debug Mode

Enable verbose output for troubleshooting:

```powershell
.\security\scripts\run-sast-scan.ps1 -Verbose
```

### Log Files

Check individual tool outputs in the reports directory for detailed error information.

## Security Considerations

- Keep SAST tools updated to latest versions
- Review and validate custom policies regularly
- Monitor for new Azure security best practices
- Integrate with security incident response procedures

## Contributing

When adding new policies or configurations:

1. Test thoroughly with sample Terraform code
2. Document the purpose and requirements
3. Follow existing naming conventions
4. Update this README with new features
5. Consider backward compatibility

## References

- [Checkov Documentation](https://www.checkov.io/1.Welcome/Quick%20Start.html)
- [TFSec Documentation](https://aquasecurity.github.io/tfsec/)
- [Terrascan Documentation](https://runterrascan.io/docs/)
- [Azure Security Best Practices](https://docs.microsoft.com/en-us/azure/security/)
- [Open Policy Agent (OPA)](https://www.openpolicyagent.org/docs/latest/)