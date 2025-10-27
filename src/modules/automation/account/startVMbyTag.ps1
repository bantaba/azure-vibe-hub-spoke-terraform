

# Ensures you do not inherit an AzContext in your runbook
Disable-AzContextAutosave -Scope Process

# Connect to Azure with system-assigned managed identity $objID
$AzureContext = (Connect-AzAccount -Identity).context

$AzureContext.Subscription.Name

Write-Output "Retrieving all VMs under scope:"
$azVMs = Get-AzVM | Where-Object {$_.Tags.Values -eq '_test_'}

foreach ($vm in $azVMs) {
    Write-Output "${vm.name} in resource group ${vm.ResourceGroupName}"
}

$azVMSS = Get-AzVmss | Where-Object {$_.Tags.Values -eq 'test'}
Write-Output "Retrieving all VMSS under scope: ${azVMSS.Name}"

## Start VMs Write-Output "Starting "
Write-Output "Starting VMs"
$azVMs | Start-AzVM -ErrorAction Continue
Write-Output "${azVMs.ProvisioningState} ${azvms.Name}"


$azVMSS | Start-AzVM -ErrorAction Continue
Write-Output "${azVMSS.Name}  ${azVMSS.ProvisioningState}"

# foreach ($vm in $azVMs) {
#     if ($vm.ProvisioningState -eq 'Stopped') {
#         Write-Output "Checking ${vm.name} provisioning state status: ${vm.ProvisioningState}"
#         Write-Output "Starting ${vm.name}..." 
#         Start-AzVM -Name $vm.Name -ResourceGroupName $vm.ResourceGroupName -NoWait -ErrorAction SilentlyContinue
#         <# Action to perform if the condition is true #>
#         # Stop-AzVM -Name $vm.Name -NoWait -ErrorAction SilentlyContinue -WhatIf -ResourceGroupName $vm.ResourceGroupName
#     }
# }