# Storage Account Troubleshooting Guide

## Overview

This guide provides troubleshooting procedures for common issues with the enhanced storage account module.

## Common Issues and Solutions

### 1. Access Denied Errors

#### Symptom
```
Error: This request is not authorized to perform this operation
Status Code: 403 Forbidden
```

#### Possible Causes and Solutions

**Network Access Restrictions**
- **Cause**: Client IP not in allowed ranges or public access disabled
- **Solution**: 
  ```bash
  # Check current network rules
  az storage account show --name <storage-account> --resource-group <rg> --query networkRuleSet
  
  # Add your IP to allowed ranges (temporary fix)
  az storage account network-rule add --account-name <storage-account> --resource-group <rg> --ip-address <your-ip>
  ```

**Authentication Method**
- **Cause**: Using shared access keys when they're disabled
- **Solution**: Use Azure AD authentication
  ```bash
  # Login with Azure AD
  az login
  
  # Access storage with AD authentication
  az storage blob list --account-name <storage-account> --container-name <container> --auth-mode login
  ```

**Insufficient Permissions**
- **Cause**: User lacks required RBAC permissions
- **Solution**: Assign appropriate storage roles
  ```bash
  # Assign Storage Blob Data Contributor role
  az role assignment create --assignee <user-principal-name> --role "Storage Blob Data Contributor" --scope "/subscriptions/<subscription-id>/resourceGroups/<rg>/providers/Microsoft.Storage/storageAccounts/<storage-account>"
  ```

### 2. Private Endpoint Connectivity Issues

#### Symptom
```
Error: Could not resolve hostname '<storage-account>.blob.core.windows.net'
```

#### Troubleshooting Steps

1. **Verify Private Endpoint Status**
   ```bash
   # Check private endpoint state
   az network private-endpoint show --name <pe-name> --resource-group <rg> --query provisioningState
   
   # List private endpoints
   az network private-endpoint list --resource-group <rg> --query "[].{Name:name, State:provisioningState}"
   ```

2. **Check DNS Configuration**
   ```bash
   # Verify DNS resolution
   nslookup <storage-account>.blob.core.windows.net
   
   # Check private DNS zone records
   az network private-dns record-set a list --zone-name privatelink.blob.core.windows.net --resource-group <rg>
   ```

3. **Validate Network Connectivity**
   ```bash
   # Test connectivity from VM in the same VNet
   telnet <private-ip> 443
   
   # Check route table
   az network route-table route list --route-table-name <route-table> --resource-group <rg>
   ```

### 3. Terraform Deployment Issues

#### Issue: Storage Account Name Validation Error
```
Error: Storage account name must be 3-24 characters, lowercase letters and numbers only
```

**Solution**: Update variable validation
```hcl
variable "sa_name" {
  validation {
    condition     = can(regex("^[a-z0-9]{3,24}$", var.sa_name))
    error_message = "Storage account name must be 3-24 characters, lowercase letters and numbers only."
  }
}
```

#### Issue: Network Rules Configuration Error
```
Error: network_rules can only be specified when public_network_access_enabled is true
```

**Solution**: Ensure consistent network configuration
```hcl
# Either enable public access with rules
public_network_access_enabled = true
network_rules_enabled = true

# Or disable public access completely
public_network_access_enabled = false
network_rules_enabled = false
```

#### Issue: Private Endpoint Subnet Conflict
```
Error: Subnet is already in use by another private endpoint
```

**Solution**: Use dedicated subnet or different subnet
```hcl
# Create dedicated private endpoint subnet
resource "azurerm_subnet" "private_endpoints" {
  name                 = "snet-private-endpoints"
  resource_group_name  = var.resource_group_name
  virtual_network_name = var.virtual_network_name
  address_prefixes     = ["10.0.10.0/24"]
  
  private_endpoint_network_policies_enabled = false
}
```

### 4. Performance Issues

#### Symptom
Slow storage operations or timeouts

#### Troubleshooting Steps

1. **Check Storage Account Tier**
   ```bash
   az storage account show --name <storage-account> --resource-group <rg> --query "{Tier:sku.tier, Kind:kind}"
   ```

2. **Monitor Storage Metrics**
   ```bash
   # Check storage metrics
   az monitor metrics list --resource "/subscriptions/<subscription-id>/resourceGroups/<rg>/providers/Microsoft.Storage/storageAccounts/<storage-account>" --metric "Transactions"
   ```

3. **Verify Network Path**
   - For private endpoints: Ensure traffic routes through private network
   - For public access: Check for network latency issues

### 5. Compliance and Security Scan Failures

#### Checkov Failures

**CKV_AZURE_33: Ensure Storage logging is enabled**
```hcl
# Add diagnostic settings
resource "azurerm_monitor_diagnostic_setting" "storage_logs" {
  name               = "storage-diagnostics"
  target_resource_id = azurerm_storage_account.sa.id
  log_analytics_workspace_id = var.log_analytics_workspace_id

  enabled_log {
    category = "StorageRead"
  }
  
  enabled_log {
    category = "StorageWrite"
  }
  
  enabled_log {
    category = "StorageDelete"
  }
}
```

**CKV_AZURE_35: Ensure default network access rule for Storage Accounts is set to deny**
```hcl
# Already implemented in enhanced module
network_rules {
  default_action = "Deny"
  bypass         = ["AzureServices", "Logging", "Metrics"]
}
```

#### TFSec Failures

**azure-storage-use-secure-tls-policy**
```hcl
# Ensure minimum TLS version
min_tls_version = "TLS1_2"
```

**azure-storage-no-public-access**
```hcl
# Disable public access
public_network_access_enabled = false
allow_nested_items_to_be_public = false
```

## Diagnostic Commands

### Storage Account Information
```bash
# Get storage account details
az storage account show --name <storage-account> --resource-group <rg>

# Check access keys status
az storage account show --name <storage-account> --resource-group <rg> --query allowSharedKeyAccess

# List storage account keys (if enabled)
az storage account keys list --account-name <storage-account> --resource-group <rg>
```

### Network Configuration
```bash
# Check network rules
az storage account show --name <storage-account> --resource-group <rg> --query networkRuleSet

# List private endpoints
az network private-endpoint list --resource-group <rg>

# Check private endpoint connections
az storage account private-endpoint-connection list --account-name <storage-account> --resource-group <rg>
```

### Security Configuration
```bash
# Check encryption settings
az storage account show --name <storage-account> --resource-group <rg> --query "{InfraEncryption:encryption.requireInfrastructureEncryption, KeySource:encryption.keySource}"

# Verify blob properties
az storage account blob-service-properties show --account-name <storage-account> --resource-group <rg>

# Check HTTPS enforcement
az storage account show --name <storage-account> --resource-group <rg> --query supportsHttpsTrafficOnly
```

## Monitoring and Alerting

### Key Metrics to Monitor
- **Availability**: Storage account uptime and response times
- **Transactions**: Request volume and error rates
- **Capacity**: Storage usage and limits
- **Network**: Ingress/egress traffic patterns

### Recommended Alerts
```bash
# Create alert for failed authentication attempts
az monitor metrics alert create \
  --name "Storage-Auth-Failures" \
  --resource-group <rg> \
  --scopes "/subscriptions/<subscription-id>/resourceGroups/<rg>/providers/Microsoft.Storage/storageAccounts/<storage-account>" \
  --condition "count 'Transactions' where ResponseType includes 'ClientAccountRequestThrottled' > 10" \
  --window-size 5m \
  --evaluation-frequency 1m
```

## Emergency Procedures

### Restore Access in Emergency
1. **Temporary Public Access** (if absolutely necessary):
   ```bash
   az storage account update --name <storage-account> --resource-group <rg> --allow-blob-public-access true --public-network-access Enabled
   ```

2. **Add Emergency IP Range**:
   ```bash
   az storage account network-rule add --account-name <storage-account> --resource-group <rg> --ip-address <emergency-ip>
   ```

3. **Enable Shared Access Keys** (temporary):
   ```bash
   az storage account update --name <storage-account> --resource-group <rg> --allow-shared-key-access true
   ```

**Important**: Revert emergency changes as soon as the issue is resolved.

### Data Recovery
1. **Restore from Soft Delete**:
   ```bash
   # List deleted blobs
   az storage blob list --account-name <storage-account> --container-name <container> --include-deleted
   
   # Undelete blob
   az storage blob undelete --account-name <storage-account> --container-name <container> --name <blob-name>
   ```

2. **Restore from Blob Versions**:
   ```bash
   # List blob versions
   az storage blob list --account-name <storage-account> --container-name <container> --include-versions
   
   # Copy specific version
   az storage blob copy start --source-account-name <storage-account> --source-container <container> --source-blob <blob-name> --source-blob-version <version-id> --destination-account-name <storage-account> --destination-container <container> --destination-blob <restored-blob-name>
   ```

## Contact Information

For escalation of storage-related issues:
- **DevOps Team**: devops@company.com
- **Security Team**: security@company.com
- **Azure Support**: Create support ticket in Azure portal

## Last Updated
December 2024 - Enhanced storage troubleshooting procedures