# Security Workflow Integration Tests

This directory contains comprehensive integration tests for the security workflows implemented in the Terraform Security Enhancement project.

## Overview

The integration tests validate three main areas:

1. **SAST Tool Integrations** - Tests for Checkov, TFSec, and Terrascan integrations
2. **CI/CD Pipeline Security Gates** - Tests for GitHub Actions, Azure DevOps, and pre-commit hooks
3. **End-to-End Workflow Validation** - Tests for complete security workflows from code to deployment

## Test Files

### Main Test Scripts

- `test-security-workflows.ps1` - Core integration test script for security workflows
- `run-integration-tests.ps1` - Test runner that orchestrates all integration tests
- `test-security-aggregation.ps1` - Tests for security report aggregation functionality

### Configuration Files

- `test-config.json` - Configuration file for integration tests
- `README-integration-tests.md` - This documentation file

## Usage

### Running All Integration Tests

```powershell
# Run all integration tests
.\security\scripts\run-integration-tests.ps1

# Run with specific test suites
.\security\scripts\run-integration-tests.ps1 -RunSASTTests:$false -RunPipelineTests -RunWorkflowTests -RunAggregationTests

# Generate HTML report
.\security\scripts\run-integration-tests.ps1 -ReportFormat "html"
```

### Running Individual Test Suites

```powershell
# Test SAST tool integrations only
.\security\scripts\test-security-workflows.ps1 -TestSASTIntegration -TestCIPipeline:$false -TestEndToEnd:$false

# Test CI/CD pipeline security gates only
.\security\scripts\test-security-workflows.ps1 -TestSASTIntegration:$false -TestCIPipeline -TestEndToEnd:$false

# Test end-to-end workflows only
.\security\scripts\test-security-workflows.ps1 -TestSASTIntegration:$false -TestCIPipeline:$false -TestEndToEnd
```

### Running Security Report Aggregation Tests

```powershell
# Test aggregation functionality
.\security\scripts\test-security-aggregation.ps1

# Test with sample data creation
.\security\scripts\test-security-aggregation.ps1 -CreateSampleData -TestAggregation -TestDashboard -TestTrendAnalysis
```

## Test Categories

### 1. SAST Tool Integration Tests

These tests validate the integration and functionality of Static Application Security Testing (SAST) tools:

- **Checkov Integration**
  - Tool availability and installation
  - Configuration file validation
  - Scan execution and result parsing
  - Issue detection and reporting

- **TFSec Integration**
  - Tool availability and installation
  - Configuration file validation
  - Scan execution and result parsing
  - Issue detection and reporting

- **Terrascan Integration**
  - Tool availability and installation
  - Configuration file validation
  - Scan execution and result parsing
  - Policy validation and compliance checking

- **Unified SAST Execution**
  - Multi-tool orchestration
  - Report aggregation
  - Error handling and recovery

### 2. CI/CD Pipeline Security Gate Tests

These tests validate the security gates implemented in CI/CD pipelines:

- **GitHub Actions Workflow**
  - Workflow file structure validation
  - Required job presence verification
  - Security tool integration validation
  - Security gate logic testing

- **Azure DevOps Pipeline**
  - Pipeline file structure validation
  - Security stage integration
  - Build gate configuration

- **Pre-commit Hooks**
  - Hook installation and configuration
  - Security check integration
  - Local validation workflow

- **Security Gate Logic**
  - Severity-based failure logic
  - Threshold configuration
  - Build failure scenarios

### 3. End-to-End Workflow Tests

These tests validate complete security workflows:

- **Complete Workflow**
  - Code creation and modification
  - Security scan execution
  - Report generation and aggregation
  - Output validation

- **Workflow Integration Points**
  - Script interdependencies
  - Configuration file dependencies
  - Directory structure validation

- **Error Handling and Recovery**
  - Missing tool scenarios
  - Invalid configuration handling
  - File system error recovery

- **Reporting and Notifications**
  - Report format generation
  - Dashboard creation
  - Notification mechanisms

## Test Data

The integration tests create and use test data to validate functionality:

### Test Terraform Files

- Intentionally vulnerable Terraform configurations
- Multiple resource types (storage, network, compute, security)
- Various security issue types for comprehensive testing

### Sample Reports

- Mock SAST tool outputs
- Historical data for trend analysis
- Baseline data for comparison testing

### Test Environment

- Isolated test directories
- Temporary configuration files
- Cleanup mechanisms for test data

## Prerequisites

### Required Tools (for full testing)

- PowerShell 5.0 or later
- Git (for repository operations)
- Terraform (for validation testing)

### Optional Tools (for SAST testing)

- Checkov (Python package)
- TFSec (Go binary)
- Terrascan (Go binary)

**Note:** The integration tests are designed to gracefully handle missing SAST tools and will skip those specific tests while continuing with other validations.

### Required Files and Directories

- `security/scripts/` - Test scripts directory
- `security/sast-tools/` - SAST tool configurations
- `security/reports/` - Report output directory
- `.github/workflows/` - GitHub Actions workflows
- `azure-pipelines*.yml` - Azure DevOps pipelines

## Test Reports

### Report Formats

The integration tests generate reports in multiple formats:

- **JSON** - Machine-readable detailed results
- **HTML** - Human-readable dashboard with charts
- **Console** - Real-time test execution feedback

### Report Contents

- Test execution summary
- Individual test results
- Performance metrics
- Error details and stack traces
- Environment information
- Configuration used

### Report Locations

- `security/reports/integration-test-report-*.json` - JSON reports
- `security/reports/integration-test-report-*.html` - HTML reports
- `security/reports/workflow-test-results-*.json` - Individual workflow test results

## Troubleshooting

### Common Issues

1. **SAST Tools Not Found**
   - Install required tools or use `-RunSASTTests:$false`
   - Check PATH environment variable

2. **Permission Errors**
   - Run PowerShell as Administrator
   - Check file system permissions

3. **Configuration File Missing**
   - Ensure all SAST tool configuration files exist
   - Run setup scripts to create missing configurations

4. **Test Data Cleanup Issues**
   - Manually remove `security/reports/test-data/` directory
   - Check for file locks or permissions

### Debug Mode

Enable verbose output for detailed troubleshooting:

```powershell
.\security\scripts\run-integration-tests.ps1 -Verbose
```

### Manual Cleanup

If automatic cleanup fails:

```powershell
# Remove test data
Remove-Item "security/reports/test-data" -Recurse -Force -ErrorAction SilentlyContinue

# Remove temporary reports
Get-ChildItem "security/reports" -Filter "*test*" | Remove-Item -Force
```

## Contributing

When adding new integration tests:

1. Follow the existing test structure and naming conventions
2. Include both positive and negative test cases
3. Add appropriate error handling and cleanup
4. Update this documentation with new test descriptions
5. Ensure tests can run independently and in combination

## Requirements Coverage

These integration tests fulfill the requirements specified in task 8.3:

- ✅ **SAST Tool Integration Tests** - Comprehensive testing of Checkov, TFSec, and Terrascan integrations
- ✅ **CI/CD Pipeline Security Gate Tests** - Validation of GitHub Actions and Azure DevOps security gates
- ✅ **End-to-End Workflow Validation** - Complete workflow testing from code to security validation

The tests ensure that all security workflows function correctly and integrate properly with the existing infrastructure and tooling.