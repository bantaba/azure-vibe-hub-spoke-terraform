<#
.SYNOPSIS
A brief description of the function or script. 

.DESCRIPTION
Installs a ADDS.
#	https://github.com/dsccommunity/ActiveDirectoryDsc	/ https://github.com/dsccommunity/ActiveDirectoryDsc/wiki

.PARAMETER ComputerName
The description of a parameter. Add a .PARAMETER keyword for each parameter in the function or
script syntax.

.EXAMPLE
HelpSample -ComputerName localhost

#>

Configuration Basic
{
	# param(
    #     # [Parameter(Mandatory)]
	# 	# [ValidateNotNullorEmpty()]
	# 	# [ValidateSet($true, $false)]
	# 	# $password = 'ThisIsAPlaintextPassword' | ConvertTo-SecureString -asPlainText -Force

	# 	# [Parameter(Mandatory)]
	# 	# [ValidateSet($true, $false)]
	# 	[ValidateNotNullorEmpty()]
	# 	[string]$username = 'contoso\Administrator',

	# 	# [Parameter(Mandatory)]
	# 	# [ValidateSet($true, $false)]
	# 	[ValidateNotNullorEmpty()]
	# 	[PSCredential] $domainCred = New-Object System.Management.Automation.PSCredential($username,$password)
		
	# 	# [Parameter(Mandatory)]
	# 	# [ValidateSet($true, $false)]
	# 	[ValidateNotNullorEmpty()]
	# 	[string]$domainDN = 'njongon.gbl'
	# )

	$password = 'ThisIsAPlaintextPassword' | ConvertTo-SecureString -asPlainText -Force
	$username = 'gon\Administrator'
	[PSCredential] $domainCred = New-Object System.Management.Automation.PSCredential($username,$password)
	$domainDN = 'njongon.gbl'
	
	# Import required modules	
    Import-DscResource -ModuleName 'PSDesiredStateConfiguration'
	Import-DScResource -ModuleName 'ComputerManagementDsc'
	Import-DscResource -ModuleName 'ActiveDirectoryDsc'	
	
	@{
		AllNodes = @(
			@{
				NodeName = 'localhost'
				PSDscAllowPlainTextPassword = $true
			}
		)
	}

	Node 'Localhost'
	{
	    Computer NewComputerName
        {
            Name = 'WUS3DC01'
        }       	
		
		WindowsFeature ADDSInstall
		{
			Ensure = 'Present'
			Name = 'AD-Domain-Services'
			DependsOn = '[Computer]NewComputerName'
		}
		WindowsFeature ADDSTools
		{
			Ensure = 'Present'
			Name = 'RSAT-ADDS'
		}
		WindowsFeature InstallRSAT-AD-PowerShell
		{
			Ensure = 'Present'
			Name = 'RSAT-AD-PowerShell'
		}	

		ADDomain Njongon
        {
            DomainName                    = 'Njongon'
            Credential                    = $domainCred
            SafemodeAdministratorPassword = $domainCred
			ForestMode                    = 'WinThreshold'
			DependsOn 					  = '[WindowsFeature]ADDSInstall'
        }

		WaitForADDomain Njongon
        {
            DomainName           = 'Njongon'
			WaitTimeout          = 600
			RestartCount         = 2
            PsDscRunAsCredential = $domainCred
        }

		ADOrganizationalUnit Groups
        {
            Name                            = 'Groups'
            Path                            = $domainDN
            ProtectedFromAccidentalDeletion = $true
            Description                     = 'TopLevel OU'
            Ensure                          = 'Present'
        }

		ADOrganizationalUnit ResourceGroups
        {
            Name                            = 'ResourceGroups'
            Path                            = "OU=Groups,$domainDN"
            ProtectedFromAccidentalDeletion = $true
            Description                     = 'ResourceGroups OU'
            Ensure                          = 'Present'
			DependsOn 						= '[ADOrganizationalUnit]Groups'
        }

		ADOrganizationalUnit RoleGroups
        {
            Name                            = 'RoleGroups'
            Path                            = "OU=Groups,$domainDN"
            ProtectedFromAccidentalDeletion = $true
            Description                     = 'RoleGroups OU'
            Ensure                          = 'Present'
			DependsOn 						= '[ADOrganizationalUnit]Groups'
        }

		ADOrganizationalUnit UnmanagedGroups
        {
            Name                            = 'UnmanagedGroups'
            Path                            = "OU=Groups,$domainDN"
            ProtectedFromAccidentalDeletion = $true
            Description                     = 'UnmanagedGroups OU'
            Ensure                          = 'Present'
			DependsOn 						= '[ADOrganizationalUnit]Groups'
        } 
		# End Groups Subgroup

		ADOrganizationalUnit Scanvenge
        {
            Name                            = 'Scanvenge'
            Path                            = $domainDN
            ProtectedFromAccidentalDeletion = $true
            Description                     = 'TopLevel OU'
            Ensure                          = 'Present'
        }
		
		ADOrganizationalUnit 'ServerBuild'
        {
            Name                            = 'ServerBuild'
            Path                            = '$domainDN'
            ProtectedFromAccidentalDeletion = $true
            Description                     = 'New ServerBuild OU'
			Ensure                          = 'Present'
		}
		ADOrganizationalUnit 'Servers'
        {
            Name                            = 'Servers'
            Path                            = '$domainDN'
            ProtectedFromAccidentalDeletion = $true
            Description                     = 'TopLevel Servers OU'
            Ensure                          = 'Present'
        }
		ADOrganizationalUnit 'ISS'
        {
            Name                            = 'ISS'
            Path                            = 'OU=Servers,$domainDN'
            ProtectedFromAccidentalDeletion = $true
            Description                     = 'Administration OU'
			Ensure                          = 'Present'
			DependsOn 						= '[ADOrganizationalUnit]Servers'
		}
		ADOrganizationalUnit 'WEB'
        {
            Name                            = 'WEB'
            Path                            = 'OU=ISS,OU=Servers,$domainDN'
            ProtectedFromAccidentalDeletion = $true
            Description                     = 'WEB OU'
			Ensure                          = 'Present'
			DependsOn 						= '[ADOrganizationalUnit]ISS'
		}
		ADOrganizationalUnit 'LSD'
        {
            Name                            = 'LSD'
            Path                            = 'OU=Servers,$domainDN'
            ProtectedFromAccidentalDeletion = $true
            Description                     = 'Administration OU'
			Ensure                          = 'Present'
			DependsOn 						= '[ADOrganizationalUnit]Servers'
		}
		ADOrganizationalUnit 'ServiceAccounts'
        {
            Name                            = 'ServiceAccounts'
            Path                            = '$domainDN'
            ProtectedFromAccidentalDeletion = $true
            Description                     = 'ServiceAccounts OU'
			Ensure                          = 'Present'
		}
		ADOrganizationalUnit 'Staging'
        {
            Name                            = 'Staging'
            Path                            = '$domainDN'
            ProtectedFromAccidentalDeletion = $true
            Description                     = 'Staging OU'
			Ensure                          = 'Present'
		}		
		ADOrganizationalUnit 'UserAccountss'
        {
            Name                            = 'Users'
            Path                            = '$domainDN'
            ProtectedFromAccidentalDeletion = $true
            Description                     = 'Users OU'
			Ensure                          = 'Present'
		}
		ADOrganizationalUnit 'StaleUsers'
        {
            Name                            = 'StaleUsers'
            Path                            = '$domainDN'
            ProtectedFromAccidentalDeletion = $true
            Description                     = 'Servers OU'
			Ensure                          = 'Present'
		}
	}
}