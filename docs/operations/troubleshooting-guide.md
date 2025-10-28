# Troubleshooting Guide

## Overview

This comprehensive troubleshooting guide provides solutions for common issues encountered in the Terraform Security Enhancement project. It covers infrastructure problems, security tool issues, CI/CD pipeline failures, and general operational challenges.

## Quick Reference

### Emergency Contacts

| Issue Type | Contact | Response Time |
|------------|---------|---------------|
| **Critical Infrastructure** | devops-emergency@company.com | 15 minutes |
| **Security Incidents** | security-emergency@company.com | 15 minutes |
| **General Issues** | support@company.com | 4 hours |
| **After Hours** | +1-555-ON-CALL | 30 minutes |

### Common Commands

```powershell
# System health check
.\scripts\utils\system-health-check.ps1

# Security scan
.\scripts\security\run-all-scans.ps1

# Terraform validation
terraform validate && terraform plan

# Git status and smart commit
git status && .\scripts\git\smart-commit.ps1 -DryRun
```

## Infrastructure Issues

### 1. Terraform Deployment Failures

#### Issue: Terraform Init Fails

**Symptoms:**
```
Error: Failed to get existing workspaces: storage account not found
Error: Backend initialization required
```

**Diagnosis:**
```powershell
# Check Azure authentication
az account show

# Verify storage account exists
az storage account show --name $storageAccountName --resource-group $resourceGroupName

# Check Terraform backend configuration
Get-Content terraform.tf | Select-String -Pattern "backend"
```

**Solutions:**

**Solution 1: Authentication Issues**
```powershell
# Re-authenticate to Azure
az logout
az login --tenant $tenantId

# Set correct subscription
az account set --subscription $subscriptionId

# Verify permissions
az role assignment list --assignee $(az account show --query user.name -o tsv) --scope "/subscriptions/$subscriptionId"
```

**Solution 2: Backend Storage Issues**
```powershell
# Create storage account if missing
az storage account create --name $storageAccountName --resource-group $resourceGroupName --location $location --sku Standard_LRS

# Create container for state files
az storage container create --name tfstate --account-name $storageAccountName

# Re-initialize Terraform
terraform init -reconfigure
```

**Solution 3: State Lock Issues**
```powershell
# Check for state locks
terraform force-unlock $lockId

# If lock ID unknown, check storage account
az storage blob list --container-name tfstate --account-name $storageAccountName --query "[?contains(name, '.tflock')]"
```

#### Issue: Terraform Plan/Apply Failures

**Symptoms:**
```
Error: Resource already exists
Error: Insufficient permissions
Error: Provider configuration not found
```

**Diagnosis:**
```powershell
# Check resource state
terraform state list
terraform state show $resourceName

# Verify provider configuration
terraform providers

# Check resource group and permissions
az group show --name $resourceGroupName
az role assignment list --scope "/subscriptions/$subscriptionId/resourceGroups/$resourceGroupName"
```

**Solutions:**

**Solution 1: Resource Conflicts**
```powershell
# Import existing resource
terraform import $resourceType.$resourceName $azureResourceId

# Or remove from state if not needed
terraform state rm $resourceType.$resourceName
```

**Solution 2: Permission Issues**
```powershell
# Check current permissions
az role assignment list --assignee $(az account show --query user.name -o tsv)

# Assign required roles
az role assignment create --assignee $principalId --role "Contributor" --scope "/subscriptions/$subscriptionId/resourceGroups/$resourceGroupName"
```

**Solution 3: Provider Version Issues**
```powershell
# Update provider versions
terraform init -upgrade

# Lock provider versions
terraform providers lock -platform=windows_amd64 -platform=linux_amd64
```

### 2. Azure Resource Issues

#### Issue: Storage Account Access Denied

**Symptoms:**
```
Error: This request is not authorized to perform this operation
Status Code: 403 Forbidden
```

**Diagnosis:**
```powershell
# Check storage account configuration
az storage account show --name $storageAccountName --resource-group $resourceGroupName --query "{PublicAccess:publicNetworkAccess, SharedKeyAccess:allowSharedKeyAccess}"

# Check network rules
az storage account show --name $storageAccountName --resource-group $resourceGroupName --query networkRuleSet

# Check RBAC assignments
az role assignment list --scope "/subscriptions/$subscriptionId/resourceGroups/$resourceGroupName/providers/Microsoft.Storage/storageAccounts/$storageAccountName"
```

**Solutions:**

**Solution 1: Network Access Issues**
```powershell
# Add current IP to allowed list (temporary)
$currentIp = (Invoke-WebRequest -Uri "https://ipinfo.io/ip").Content.Trim()
az storage account network-rule add --account-name $storageAccountName --resource-group $resourceGroupName --ip-address $currentIp

# Or enable public access temporarily
az storage account update --name $storageAccountName --resource-group $resourceGroupName --public-network-access Enabled
```

**Solution 2: Authentication Method Issues**
```powershell
# Use Azure AD authentication instead of shared keys
az storage blob list --account-name $storageAccountName --container-name $containerName --auth-mode login

# Assign Storage Blob Data Contributor role
az role assignment create --assignee $(az account show --query user.name -o tsv) --role "Storage Blob Data Contributor" --scope "/subscriptions/$subscriptionId/resourceGroups/$resourceGroupName/providers/Microsoft.Storage/storageAccounts/$storageAccountName"
```

#### Issue: Key Vault Access Denied

**Symptoms:**
```
Error: The user, group or application does not have secrets get permission
Error: Key Vault not found or access denied
```

**Diagnosis:**
```powershell
# Check Key Vault existence and permissions
az keyvault show --name $keyVaultName --resource-group $resourceGroupName

# Check access policies
az keyvault show --name $keyVaultName --query "properties.accessPolicies[].{ObjectId:objectId, Permissions:permissions}"

# Check RBAC assignments
az role assignment list --scope "/subscriptions/$subscriptionId/resourceGroups/$resourceGroupName/providers/Microsoft.KeyVault/vaults/$keyVaultName"
```

**Solutions:**

**Solution 1: Access Policy Issues**
```powershell
# Add access policy for current user
$currentUserId = az ad signed-in-user show --query objectId -o tsv
az keyvault set-policy --name $keyVaultName --object-id $currentUserId --secret-permissions get list set delete

# Add access policy for service principal
az keyvault set-policy --name $keyVaultName --spn $servicePrincipalId --secret-permissions get list
```

**Solution 2: RBAC Issues**
```powershell
# Assign Key Vault Secrets User role
az role assignment create --assignee $(az account show --query user.name -o tsv) --role "Key Vault Secrets User" --scope "/subscriptions/$subscriptionId/resourceGroups/$resourceGroupName/providers/Microsoft.KeyVault/vaults/$keyVaultName"
```

### 3. Network Connectivity Issues

#### Issue: Private Endpoint Connectivity

**Symptoms:**
```
Error: Could not resolve hostname
Error: Connection timeout
Error: SSL handshake failed
```

**Diagnosis:**
```powershell
# Check private endpoint status
az network private-endpoint show --name $privateEndpointName --resource-group $resourceGroupName --query provisioningState

# Check DNS resolution
nslookup $storageAccountName.blob.core.windows.net

# Check private DNS zone
az network private-dns zone show --name "privatelink.blob.core.windows.net" --resource-group $resourceGroupName
```

**Solutions:**

**Solution 1: DNS Configuration Issues**
```powershell
# Check private DNS zone records
az network private-dns record-set a list --zone-name "privatelink.blob.core.windows.net" --resource-group $resourceGroupName

# Link VNet to private DNS zone
az network private-dns link vnet create --zone-name "privatelink.blob.core.windows.net" --resource-group $resourceGroupName --name "vnet-link" --virtual-network $vnetName --registration-enabled false
```

**Solution 2: Network Security Group Issues**
```powershell
# Check NSG rules
az network nsg show --name $nsgName --resource-group $resourceGroupName --query "securityRules[].{Name:name, Priority:priority, Access:access, Direction:direction}"

# Add rule to allow private endpoint traffic
az network nsg rule create --resource-group $resourceGroupName --nsg-name $nsgName --name "AllowPrivateEndpoint" --priority 100 --source-address-prefixes "VirtualNetwork" --destination-address-prefixes "VirtualNetwork" --destination-port-ranges 443 --access Allow --protocol Tcp
```

## Security Tool Issues

### 1. SAST Tool Failures

#### Issue: Checkov Scan Failures

**Symptoms:**
```
Error: No such file or directory
Error: Failed to parse Terraform files
ModuleNotFoundError: No module named 'checkov'
```

**Diagnosis:**
```powershell
# Check Checkov installation
checkov --version

# Check Python environment
python --version
pip list | Select-String checkov

# Check file permissions and paths
Get-ChildItem src -Recurse -Filter "*.tf" | Select-Object FullName, Length
```

**Solutions:**

**Solution 1: Installation Issues**
```powershell
# Reinstall Checkov
pip uninstall checkov -y
pip install checkov --upgrade

# Verify installation
checkov --version
checkov --help
```

**Solution 2: Configuration Issues**
```powershell
# Check Checkov configuration
Get-Content security\sast-tools\checkov.yaml

# Run with verbose output
checkov -d src --framework terraform --verbose

# Skip specific checks if needed
checkov -d src --framework terraform --skip-check CKV_AZURE_1,CKV_AZURE_2
```

**Solution 3: File Path Issues**
```powershell
# Use absolute paths
$srcPath = Resolve-Path "src"
checkov -d $srcPath --framework terraform

# Check for special characters in paths
Get-ChildItem src -Recurse | Where-Object {$_.Name -match '[^\w\-\.]'}
```

#### Issue: TFSec Scan Failures

**Symptoms:**
```
Error: tfsec is not recognized as an internal or external command
Error: Failed to load Terraform files
Error: No Terraform files found
```

**Diagnosis:**
```powershell
# Check TFSec installation
tfsec --version

# Check PATH environment variable
$env:PATH -split ';' | Select-String tfsec

# Check Terraform files
Get-ChildItem src -Recurse -Filter "*.tf" | Measure-Object
```

**Solutions:**

**Solution 1: Installation Issues**
```powershell
# Download and install TFSec
$tfsecUrl = "https://github.com/aquasecurity/tfsec/releases/latest/download/tfsec-windows-amd64.exe"
Invoke-WebRequest -Uri $tfsecUrl -OutFile "C:\tools\tfsec.exe"

# Add to PATH
$env:PATH += ";C:\tools"
[Environment]::SetEnvironmentVariable("PATH", $env:PATH, "User")
```

**Solution 2: Configuration Issues**
```powershell
# Run with specific configuration
tfsec src --config-file security\sast-tools\tfsec.json

# Exclude specific checks
tfsec src --exclude-downloaded-modules --exclude aws-*
```

#### Issue: Terrascan Failures

**Symptoms:**
```
Error: terrascan command not found
Error: Failed to initialize policy engine
Error: No policies found
```

**Diagnosis:**
```powershell
# Check Terrascan installation
terrascan version

# Check policy configuration
Get-Content security\sast-tools\terrascan-config.toml

# Check policy files
Get-ChildItem security\policies -Recurse
```

**Solutions:**

**Solution 1: Installation Issues**
```powershell
# Install Terrascan using Go (if Go is installed)
go install github.com/tenable/terrascan/cmd/terrascan@latest

# Or download binary
$terrascanUrl = "https://github.com/tenable/terrascan/releases/latest/download/terrascan_Windows_x86_64.tar.gz"
# Extract and install
```

**Solution 2: Policy Issues**
```powershell
# Initialize policies
terrascan init

# Use specific policy path
terrascan scan -t terraform -d src --policy-path security\policies

# Update policies
terrascan init --policy-path security\policies
```

### 2. CI/CD Pipeline Issues

#### Issue: GitHub Actions Failures

**Symptoms:**
```
Error: Authentication failed
Error: Workflow run failed
Error: Action not found
```

**Diagnosis:**
```powershell
# Check workflow file syntax
Get-Content .github\workflows\security-scan.yml | ConvertFrom-Yaml

# Check repository secrets
# (Must be done in GitHub UI)

# Check action logs
# (Must be done in GitHub UI)
```

**Solutions:**

**Solution 1: Authentication Issues**
```yaml
# Update GitHub secrets with correct values
# AZURE_CLIENT_ID
# AZURE_CLIENT_SECRET
# AZURE_SUBSCRIPTION_ID
# AZURE_TENANT_ID
```

**Solution 2: Workflow Configuration Issues**
```yaml
# Fix workflow syntax
name: Security Scan
on:
  push:
    branches: [main]
  pull_request:
    branches: [main]

jobs:
  security-scan:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v3
      - name: Run Security Scan
        run: |
          pip install checkov
          checkov -d src --framework terraform
```

#### Issue: Azure DevOps Pipeline Failures

**Symptoms:**
```
Error: Pipeline not found
Error: Agent job failed
Error: Task not found
```

**Diagnosis:**
```powershell
# Check pipeline YAML syntax
Get-Content azure-pipelines.yml

# Check service connection
# (Must be done in Azure DevOps UI)

# Check agent pool availability
# (Must be done in Azure DevOps UI)
```

**Solutions:**

**Solution 1: Service Connection Issues**
```yaml
# Update service connection configuration
# Ensure service principal has correct permissions
# Verify subscription and tenant IDs
```

**Solution 2: Agent Issues**
```yaml
# Use Microsoft-hosted agents
pool:
  vmImage: 'ubuntu-latest'

# Or specify specific agent pool
pool:
  name: 'Default'
```

## Git and Version Control Issues

### 1. Git Operation Failures

#### Issue: Smart Commit Script Failures

**Symptoms:**
```
Error: Not a git repository
Error: PowerShell execution policy
Error: Git command not found
```

**Diagnosis:**
```powershell
# Check git repository status
git status

# Check PowerShell execution policy
Get-ExecutionPolicy

# Check git installation
git --version

# Check script permissions
Get-ChildItem scripts\git\smart-commit.ps1 | Select-Object Mode, Name
```

**Solutions:**

**Solution 1: Git Repository Issues**
```powershell
# Initialize git repository if needed
git init
git remote add origin $repositoryUrl

# Check repository integrity
git fsck --full
```

**Solution 2: PowerShell Execution Policy**
```powershell
# Set execution policy for current user
Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope CurrentUser

# Or bypass for specific script
PowerShell -ExecutionPolicy Bypass -File scripts\git\smart-commit.ps1
```

**Solution 3: Git Configuration Issues**
```powershell
# Configure git user
git config --global user.name "Your Name"
git config --global user.email "your.email@company.com"

# Check git configuration
git config --list
```

#### Issue: Merge Conflicts

**Symptoms:**
```
Error: Automatic merge failed
CONFLICT (content): Merge conflict in file.tf
```

**Diagnosis:**
```powershell
# Check conflict status
git status

# View conflicted files
git diff --name-only --diff-filter=U

# View conflict details
git diff $conflictedFile
```

**Solutions:**

**Solution 1: Manual Resolution**
```powershell
# Edit conflicted files to resolve conflicts
code $conflictedFile

# Mark as resolved
git add $conflictedFile

# Complete merge
git commit -m "resolve: merge conflict in $conflictedFile"
```

**Solution 2: Use Merge Tools**
```powershell
# Configure merge tool
git config --global merge.tool vscode
git config --global mergetool.vscode.cmd 'code --wait $MERGED'

# Launch merge tool
git mergetool $conflictedFile
```

### 2. Repository Management Issues

#### Issue: Large File Problems

**Symptoms:**
```
Error: File size exceeds limit
Warning: Large files detected
Error: Push rejected due to file size
```

**Diagnosis:**
```powershell
# Find large files
Get-ChildItem -Recurse | Where-Object {$_.Length -gt 50MB} | Select-Object FullName, @{Name="SizeMB";Expression={[math]::Round($_.Length/1MB,2)}}

# Check git history for large files
git rev-list --objects --all | git cat-file --batch-check='%(objecttype) %(objectname) %(objectsize) %(rest)' | Where-Object {$_ -match '^blob'} | Sort-Object {[int]($_ -split ' ')[2]} -Descending | Select-Object -First 10
```

**Solutions:**

**Solution 1: Remove Large Files**
```powershell
# Remove large files from repository
git rm $largeFile
git commit -m "remove: large file $largeFile"

# Remove from history (use with caution)
git filter-branch --force --index-filter "git rm --cached --ignore-unmatch $largeFile" --prune-empty --tag-name-filter cat -- --all
```

**Solution 2: Use Git LFS**
```powershell
# Install Git LFS
git lfs install

# Track large file types
git lfs track "*.zip"
git lfs track "*.tar.gz"

# Add .gitattributes
git add .gitattributes
git commit -m "add: Git LFS tracking"
```

## Performance Issues

### 1. Slow Operations

#### Issue: Terraform Operations Slow

**Symptoms:**
- Terraform plan takes excessive time
- Apply operations timeout
- State refresh is slow

**Diagnosis:**
```powershell
# Enable Terraform debug logging
$env:TF_LOG = "DEBUG"
terraform plan

# Check state file size
Get-ChildItem terraform.tfstate | Select-Object Name, @{Name="SizeMB";Expression={[math]::Round($_.Length/1MB,2)}}

# Check provider performance
terraform providers
```

**Solutions:**

**Solution 1: Optimize State Management**
```powershell
# Use remote state with locking
# Configure in terraform.tf:
terraform {
  backend "azurerm" {
    resource_group_name  = "rg-terraform-state"
    storage_account_name = "stterraformstate"
    container_name       = "tfstate"
    key                  = "terraform.tfstate"
  }
}
```

**Solution 2: Parallelize Operations**
```powershell
# Increase parallelism
terraform plan -parallelism=20
terraform apply -parallelism=20

# Use targeted operations
terraform plan -target=module.storage
terraform apply -target=module.storage
```

#### Issue: Security Scans Slow

**Symptoms:**
- SAST tools take excessive time
- CI/CD pipelines timeout
- Local scans are slow

**Diagnosis:**
```powershell
# Measure scan times
Measure-Command { checkov -d src --framework terraform }
Measure-Command { tfsec src }

# Check file count and size
Get-ChildItem src -Recurse -Filter "*.tf" | Measure-Object -Property Length -Sum | Select-Object Count, @{Name="TotalSizeMB";Expression={[math]::Round($_.Sum/1MB,2)}}
```

**Solutions:**

**Solution 1: Optimize Scan Configuration**
```powershell
# Use specific checks only
checkov -d src --framework terraform --check CKV_AZURE_*

# Exclude unnecessary files
checkov -d src --framework terraform --skip-path .terraform

# Use parallel processing
tfsec src --concurrency-limit 4
```

**Solution 2: Incremental Scanning**
```powershell
# Scan only changed files
$changedFiles = git diff --name-only HEAD~1 HEAD | Where-Object {$_ -match '\.tf$'}
foreach ($file in $changedFiles) {
    checkov -f $file --framework terraform
}
```

## Monitoring and Alerting Issues

### 1. Missing Alerts

#### Issue: No Security Alerts

**Symptoms:**
- Expected security alerts not received
- Monitoring dashboard shows no data
- Alert rules not triggering

**Diagnosis:**
```powershell
# Check Azure Monitor alert rules
az monitor alert list --resource-group $resourceGroupName

# Check Log Analytics workspace
az monitor log-analytics workspace show --resource-group $resourceGroupName --workspace-name $workspaceName

# Test alert conditions
az monitor metrics list --resource $resourceId --metric "Transactions"
```

**Solutions:**

**Solution 1: Configure Alert Rules**
```powershell
# Create security alert rule
az monitor metrics alert create --name "Security-Alert" --resource-group $resourceGroupName --scopes $resourceId --condition "count 'Transactions' where ResponseType includes 'ClientError' > 10" --window-size 5m --evaluation-frequency 1m --action $actionGroupId
```

**Solution 2: Verify Data Collection**
```powershell
# Check diagnostic settings
az monitor diagnostic-settings list --resource $resourceId

# Create diagnostic setting if missing
az monitor diagnostic-settings create --resource $resourceId --name "security-diagnostics" --logs '[{"category":"StorageRead","enabled":true},{"category":"StorageWrite","enabled":true}]' --workspace $workspaceId
```

## Emergency Procedures

### 1. System Recovery

#### Complete System Failure

**Immediate Actions:**
```powershell
# Switch to backup environment
.\scripts\emergency\switch-to-backup.ps1

# Notify stakeholders
.\scripts\emergency\notify-stakeholders.ps1 -Severity "CRITICAL"

# Begin recovery procedures
.\scripts\emergency\begin-recovery.ps1
```

#### Data Recovery

**Backup Restoration:**
```powershell
# List available backups
az backup recoverypoint list --resource-group $resourceGroupName --vault-name $vaultName --container-name $containerName --item-name $itemName

# Restore from backup
az backup restore restore-disks --resource-group $resourceGroupName --vault-name $vaultName --container-name $containerName --item-name $itemName --rp-name $recoveryPointName --storage-account $storageAccountName
```

### 2. Security Breach Response

**Immediate Containment:**
```powershell
# Isolate affected resources
.\scripts\emergency\isolate-resources.ps1 -ResourceGroup $affectedResourceGroup

# Disable compromised accounts
.\scripts\emergency\disable-accounts.ps1 -AccountList $compromisedAccounts

# Enable enhanced monitoring
.\scripts\emergency\enable-enhanced-monitoring.ps1
```

## Escalation Procedures

### 1. Issue Severity Levels

| Severity | Response Time | Escalation Path |
|----------|---------------|-----------------|
| **Critical** | 15 minutes | Immediate → Team Lead → Management |
| **High** | 1 hour | Team Member → Team Lead → Management |
| **Medium** | 4 hours | Team Member → Team Lead |
| **Low** | 24 hours | Team Member |

### 2. Escalation Contacts

```powershell
# Automated escalation
.\scripts\utils\escalate-issue.ps1 -Severity "HIGH" -Description "Terraform deployment failure" -AffectedSystems @("Production", "Security")
```

## Preventive Measures

### 1. Regular Health Checks

**Daily Checks:**
```powershell
# Run comprehensive health check
.\scripts\utils\daily-health-check.ps1

# Verify security posture
.\scripts\security\security-posture-check.ps1

# Check system performance
.\scripts\monitoring\performance-check.ps1
```

### 2. Proactive Monitoring

**Monitoring Setup:**
```powershell
# Configure proactive monitoring
.\scripts\monitoring\setup-proactive-monitoring.ps1

# Set up predictive alerts
.\scripts\monitoring\setup-predictive-alerts.ps1

# Enable trend analysis
.\scripts\monitoring\enable-trend-analysis.ps1
```

## Documentation and Knowledge Base

### 1. Issue Documentation

**Document New Issues:**
```powershell
# Create issue documentation
.\scripts\utils\document-issue.ps1 -IssueType "Terraform" -Description "State lock timeout" -Solution "Force unlock and retry"
```

### 2. Knowledge Sharing

**Team Knowledge Base:**
- Regular troubleshooting sessions
- Issue resolution documentation
- Best practices sharing
- Lessons learned reviews

## Last Updated

December 2024 - Comprehensive troubleshooting guide for Terraform Security Enhancement project