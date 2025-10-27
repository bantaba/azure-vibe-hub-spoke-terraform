# Security Enhancements

This directory contains security-related configurations, scripts, and documentation for the Terraform project.

## Structure

- `sast-tools/` - Configuration files for Static Application Security Testing tools
- `scripts/` - Security automation scripts
- `policies/` - Custom security policies and rules
- `reports/` - Security scan reports and documentation

## Tools Integrated

- Checkov - Infrastructure as Code security scanner
- TFSec - Terraform security scanner
- Terrascan - Policy as Code security validation
- Terraform Compliance - BDD-style security testing

## Recent Security Enhancements

### Storage Account Security (December 2024)
- Enhanced network access controls with default deny-all policy
- Disabled public network access and shared access keys by default
- Implemented OAuth authentication enforcement
- Added comprehensive blob protection with versioning and retention policies
- Integrated private endpoint support for secure connectivity

### Key Security Features
- **Zero Trust Network Model**: Default deny with explicit allow rules
- **Identity-Based Access**: Azure AD authentication with disabled shared keys
- **Data Protection**: Blob versioning, change feed, and retention policies
- **Private Connectivity**: Optional private endpoints for network isolation
- **Compliance Ready**: Aligned with CIS Azure Foundations and security baselines

## Usage

Refer to the individual tool documentation in their respective directories for configuration and usage instructions. For storage account security features, see `docs/security/storage-security-enhancements.md`.