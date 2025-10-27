[CmdletBinding()]
param(
  $workspace
)

$getWorkspace = (terraform workspace list | Select-String "$workspace")

Write-Output "Current Workspaces: $getWorkspace \n EnvironmentName: $workspace \n"

if ( $getWorkspace -match $workspace ) {
  Write-Host "Switching to workspace $workspace"
  terraform workspace select $workspace
}
else {
  Write-Output "Create new workspace $workspace"  
  terraform workspace new $workspace
}