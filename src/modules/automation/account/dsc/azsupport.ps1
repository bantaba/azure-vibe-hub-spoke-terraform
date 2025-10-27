Configuration DC
{
    [CmdletBinding()]
    param (
        # [Parameter(Mandatory)]
        [string]$FQDN= "njongon.gbl",
        # [Parameter(Mandatory)]
        [PSCredential]$DomainAdminstratorUserName,
        # [Parameter(Mandatory)]
        [PSCredential]$AdmintratorUserPwd,
        [Int]$RetryCount=5,
        [Int]$RetryIntervalSec=30
        
    )
    $domainCred = Get-AutomationPSCredential -Name "DomainAdmin"
    $DomainName = Get-AutomationVariable -Name "DomainName"
    
    
    # Import required modules
    Import-DscResource -ModuleName 'PSDesiredStateConfiguration'
    Import-DScResource -ModuleName 'ComputerManagementDsc'
    Import-DscResource -ModuleName 'ActiveDirectoryDsc'    
    Node "Localhost"
    {
                       
        
        ADDomain $DomainName
        {
            DomainName                    = $DomainName
            Credential                    = $domainCred
            SafemodeAdministratorPassword = $domainCred
            ForestMode                    = 'WinThreshold'
    
        }    
    }
}