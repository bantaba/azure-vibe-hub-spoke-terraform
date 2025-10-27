

# Ensures you do not inherit an AzContext in your runbook
Disable-AzContextAutosave -Scope Process

# Connect to Azure with system-assigned managed identity $objID
# $AzureContext = (Connect-AzAccount -Identity -AccountId $identity).context
$AzureContext = (Connect-AzAccount -Identity).context

Write-Output "Account ID of current context: " $AzureContext.Account.Id
Write-Output "Account Type of current context: " $AzureContext.Account.Type
Write-Output "Account TenantMap of current context: " $AzureContext.Account.TenantMap
Write-Output "Account ExtendedProperties of current context: " $AzureContext.Account.ExtendedProperties
## Get the Azure VM ScaleSets with tags matching the value 'Test'
$azVMSS = Get-AzVmss | Where-Object {$_.Tags.Environment -eq 'test'}

## Start VM ScaleSets Write-Output "Starting "
$azVMSS | Start-AzVM -ErrorAction Continue
Write-Output $azVMSS.ProvisioningState