

# Ensures you do not inherit an AzContext in your runbook
Disable-AzContextAutosave -Scope Process

# Connect to Azure with system-assigned managed identity $objID
# $AzureContext = (Connect-AzAccount -Identity -AccountId $identity).context
$AzureContext = (Connect-AzAccount -Identity).context

Write-Output "Account ID of current context: " $AzureContext.Account.Id
Write-Output "Account Type of current context: " $AzureContext.Account.Type
Write-Output "Account TenantMap of current context: " $AzureContext.Account.TenantMap
Write-Output "Account ExtendedProperties of current context: " $AzureContext.Account.ExtendedProperties
## Get the Azure VMs with tags matching the value 'Test'
$azVMs = Get-AzVM | Where-Object {$_.Tags.Environment -eq 'dev'}


## Start VMs
$azVMS | Start-AzVM -ErrorAction Continue

