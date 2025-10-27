Configuration DC
{
<#
    .SYNOPSIS
        
        https://github.com/dsccommunity/SqlServerDsc/wiki
        Creates the base SQL server configuration requisites
    .DESCRIPTION
        Below creates Directories, cNtfsPermissionEntry DSC resource to assign NTFS permissions....
    .Parameter nameHere
    .Example
#>

#region vars
        [string]$genevaRunAgentFileContent = @'
set MONITORING_DATA_DIRECTORY=C:\Monitoring\Data
set MONITORING_TENANT=xgoTools
set MONITORING_ROLE=Other
set MONITORING_ROLE_INSTANCE=%COMPUTERNAME% 

set MONITORING_GCS_ACCOUNT=xsotoolssemdmwarm      
set MONITORING_GCS_NAMESPACE=xsotoolssemdmwarm

set MONITORING_GCS_ENVIRONMENT=DiagnosticsProd
set MONITORING_GCS_REGION=West US
set MONITORING_CONFIG_VERSION=1.0

set MONITORING_GCS_CERTSTORE=LOCAL_MACHINE\MY
set MONITORING_GCS_THUMBPRINT=A31A3FFF60D269A7C3D32778B7535523F5EEEE27
'@
    [pscredential]$domainCred = Get-AutomationPSCredential -Name "DomainAdmin"
    [pscredential]$DefaultUserPwd  = Get-AutomationPSCredential -Name "DefaultUserPwd"
    [string]$DomainName = Get-AutomationVariable -Name "DomainName"
    [string]$DomainDN = Get-AutomationVariable -Name "DomainDN"
	[string]$GenevaBaseDirectory   = "C:\Monitoring"
    [string]$GenevaFilePath        = "C:\Monitoring\runagentclient.cmd"
#endregion vars    
	# Import required modules	
    Import-DscResource -ModuleName 'PSDesiredStateConfiguration'
	Import-DScResource -ModuleName 'ComputerManagementDsc'
	Import-DscResource -ModuleName 'ActiveDirectoryDsc'	
	

	Node 'Localhost'
	{   
        Registry DisableServerManagerAtLogon {
            Key = 'HKEY_LOCAL_MACHINE\Software\Microsoft\ServerManager'
            ValueName = 'DoNotOpenServerManagerAtLogon'
            ValueData = '1'
            ValueType = 'Dword'
            Ensure = 'Present'
        } 
        
    #region Geneva Mon 
        File GenevaDirectory
        {
            Ensure = 'Present'
            Type = 'Directory'
            DestinationPath = $GenevaBaseDirectory            
        }
        
        File RunAgentFile
        {
            DestinationPath = $GenevaFilePath
            Ensure = 'Present'
            Type = 'File'
            Contents = $genevaRunAgentFileContent
            DependsOn = '[File]GenevaDirectory'
            
        }

        ScheduledTask GenevaAzsecPackScheduledTaskStartup
        {
            TaskName           = 'GenevaAzsecPack'
            TaskPath           = '\GenevaMonitoringAgent'
            ActionWorkingPath  = $GenevaBaseDirectory
            ActionExecutable   = $GenevaFilePath
            ScheduleType       = 'AtStartup'
            BuiltInAccount	   = 'SYSTEM'
            Enable	           = $true
            Ensure             = 'Present'
            Description        = 'Creates scheduled task to start the Geneva monitoring agent'
            DependsOn          = '[File]RunAgentFile'
        }       
    #endregion Geneva
		
		WindowsFeature ADDSInstall
		{
			Ensure = 'Present'
			Name = 'AD-Domain-Services'
		}
		WindowsFeature ADDSTools
		{
			Ensure = 'Present'
			Name = 'RSAT-ADDS'
			DependsOn = '[WindowsFeature]ADDSInstall'
		}
		WindowsFeature InstallRSAT-AD-PowerShell
		{
			Ensure = 'Present'
			Name = 'RSAT-AD-PowerShell'
		}	

		ADDomain $DomainName
        {
            DomainName                    = $DomainName
            Credential                    = $domainCred
            SafemodeAdministratorPassword = $domainCred
            DomainMode                    = 'WinThreshold'
			ForestMode                    = 'WinThreshold'
            # DatabasePath = 'C:\NTDS'
            # LogPath = 'C:\NTDS' 
            # SysvolPath = "C:\SYSVOL"
			DependsOn 					  = '[WindowsFeature]ADDSInstall'
        }

		WaitForADDomain $DomainName
        {
            DomainName           = $DomainName
			WaitTimeout          = 600
			RestartCount         = 2
            WaitForValidCredentials = $false
            # Credential          = 'NT AUTHORITY\SYSTEM'
            PsDscRunAsCredential = $domainCred
			DependsOn 					  = "[ADDomain]$DomainName"
        }
        
		ADOrganizationalUnit Scanvenge
        {
            Name                            = 'Scanvenge'
            Path                            = $domainDN
            ProtectedFromAccidentalDeletion = $true
            Description                     = 'TopLevel OU'
            Ensure                          = 'Present'
        }
        
		ADOrganizationalUnit ServiceAccounts
        {
            Name                            = 'ServiceAccounts'
            Path                            = $domainDN
            ProtectedFromAccidentalDeletion = $true
            Description                     = 'ServiceAccounts OU'
			Ensure                          = 'Present'
		}

		ADOrganizationalUnit Staging
        {
            Name                            = 'Staging'
            Path                            = $domainDN
            ProtectedFromAccidentalDeletion = $true
            Description                     = 'Staging OU'
			Ensure                          = 'Present'
		}	

		ADOrganizationalUnit UserAccounts
        {
            Name                            = 'UserAccounts'
            Path                            = $domainDN
            ProtectedFromAccidentalDeletion = $true
            Description                     = 'Users TopLevel OU'
			Ensure                          = 'Present'
		}

		ADOrganizationalUnit StaleUsers
        {
            Name                            = 'StaleUsers'
            Path                            = $domainDN
            ProtectedFromAccidentalDeletion = $true
            Description                     = 'Servers TopLevel OU'
			Ensure                          = 'Present'
		}

    #region Groups n sub OU        
		ADOrganizationalUnit Groups
        {
            Name                            = 'Groups'
            Path                            = $domainDN
            ProtectedFromAccidentalDeletion = $true
            Description                     = 'Groups TopLevel OU'
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
    #endregion End Groups Subgroup

    #region ServerBuild
        ADOrganizationalUnit ServerBuild
        {
            Name                            = 'ServerBuild'
            Path                            = $domainDN
            ProtectedFromAccidentalDeletion = $true
            Description                     = 'New ServerBuild OU'
			Ensure                          = 'Present'
		}
		
		ADOrganizationalUnit Build
        {
            Name                            = 'Build'
            Path                            = "OU=ServerBuild,$domainDN"
            ProtectedFromAccidentalDeletion = $true
            Description                     = 'New Build OU'
			Ensure                          = 'Present'
			DependsOn 						= '[ADOrganizationalUnit]ServerBuild'
		}
		
		ADOrganizationalUnit Decomm
        {
            Name                            = 'Decomm'
            Path                            = "OU=ServerBuild,$domainDN"
            ProtectedFromAccidentalDeletion = $true
            Description                     = 'Decomm OU'
			Ensure                          = 'Present'
			DependsOn 						= '[ADOrganizationalUnit]ServerBuild'
		}
		
		ADOrganizationalUnit Inventory
        {
            Name                            = 'Inventory'
            Path                            = "OU=ServerBuild,$domainDN"
            ProtectedFromAccidentalDeletion = $true
            Description                     = 'Inventory OU'
			Ensure                          = 'Present'
			DependsOn 						= '[ADOrganizationalUnit]ServerBuild'
		}
		
		ADOrganizationalUnit PreDeploy
        {
            Name                            = 'PreDeploy'
            Path                            = "OU=ServerBuild,$domainDN"
            ProtectedFromAccidentalDeletion = $true
            Description                     = 'PreDeploy OU'
			Ensure                          = 'Present'
			DependsOn 						= '[ADOrganizationalUnit]ServerBuild'
		}
		
		ADOrganizationalUnit Quarantine
        {
            Name                            = 'Quarantine'
            Path                            = "OU=ServerBuild,$domainDN"
            ProtectedFromAccidentalDeletion = $true
            Description                     = 'Quarantine OU'
			Ensure                          = 'Present'
			DependsOn 						= '[ADOrganizationalUnit]ServerBuild'
		}
    #endregion ServerBuild

    #region Servers
        ADOrganizationalUnit Servers
        {
            Name                            = 'Servers'
            Path                            = $domainDN
            ProtectedFromAccidentalDeletion = $true
            Description                     = 'TopLevel Servers OU'
            Ensure                          = 'Present'
        }

        ADOrganizationalUnit AP
        {
            Name                            = 'AP'
            Path                            = "OU=Servers,$domainDN"
            ProtectedFromAccidentalDeletion = $true
            Description                     = 'AutoPilot Managed OU'
            Ensure                          = 'Present'
            DependsOn 						= '[ADOrganizationalUnit]Servers'
        }

        ADOrganizationalUnit HVA
        {
            Name                            = 'HVA'
            Path                            = "OU=Servers,$domainDN"
            ProtectedFromAccidentalDeletion = $true
            Description                     = 'HVA OU'
            Ensure                          = 'Present'
            DependsOn 						= '[ADOrganizationalUnit]Servers'
        }

        ADOrganizationalUnit LSD
        {
            Name                            = 'LSD'
            Path                            = "OU=Servers,$domainDN"
            ProtectedFromAccidentalDeletion = $true
            Description                     = 'LSD OU'
            Ensure                          = 'Present'
            DependsOn 						= '[ADOrganizationalUnit]Servers'
        }

        ADOrganizationalUnit Other
        {
            Name                            = 'Other'
            Path                            = "OU=LSD,OU=Servers,$domainDN"
            ProtectedFromAccidentalDeletion = $true
            Description                     = 'Other OU'
            Ensure                          = 'Present'
            DependsOn 						= '[ADOrganizationalUnit]LSD'
        }

        ADOrganizationalUnit LSDSYS
        {
            Name                            = 'LSDSYS'
            Path                            = "OU=Other,OU=LSD,OU=Servers,$domainDN"
            ProtectedFromAccidentalDeletion = $true
            Description                     = 'LSDSYS OU'
            Ensure                          = 'Present'
            DependsOn 						= '[ADOrganizationalUnit]Other'
        }

        ADOrganizationalUnit Quincy
        {
            Name                            = 'Quincy'
            Path                            = "OU=Servers,$domainDN"
            ProtectedFromAccidentalDeletion = $true
            Description                     = 'Quincy OU'
            Ensure                          = 'Present'
            DependsOn 						= '[ADOrganizationalUnit]Servers'
        }

        ADOrganizationalUnit APT
        {
            Name                            = 'APT'
            Path                            = "OU=Quincy,OU=Servers,$domainDN"
            ProtectedFromAccidentalDeletion = $true
            Description                     = 'APT OU'
            Ensure                          = 'Present'
            DependsOn 						= '[ADOrganizationalUnit]Quincy'
        }

        ADOrganizationalUnit APCR
        {
            Name                            = 'APCR'
            Path                            = "OU=APT,OU=Quincy,OU=Servers,$domainDN"
            ProtectedFromAccidentalDeletion = $true
            Description                     = 'APCR OU'
            Ensure                          = 'Present'
            DependsOn 						= '[ADOrganizationalUnit]APT'
        }

        ADOrganizationalUnit Servers-LSD
        {
            Name                            = 'LSD'
            Path                            = "OU=Quincy,OU=Servers,$domainDN"
            ProtectedFromAccidentalDeletion = $true
            Description                     = 'LSD OU'
            Ensure                          = 'Present'
            DependsOn 						= '[ADOrganizationalUnit]Quincy'
        }

        ADOrganizationalUnit XDEP
        {
            Name                            = 'XDEP'
            Path                            = "OU=LSD,OU=Quincy,OU=Servers,$domainDN"
            ProtectedFromAccidentalDeletion = $true
            Description                     = 'XDEP OU'
            Ensure                          = 'Present'
            DependsOn 						= '[ADOrganizationalUnit]Servers-LSD'
        }

        ADOrganizationalUnit LSD-INH
        {
            Name                            = 'INH'
            Path                            = "OU=LSD,OU=Quincy,OU=Servers,$domainDN"
            ProtectedFromAccidentalDeletion = $true
            Description                     = 'INH OU'
            Ensure                          = 'Present'
            DependsOn 						= '[ADOrganizationalUnit]Servers-LSD'
        }

        ADOrganizationalUnit LSD-UPLD
        {
            Name                            = 'UPLD'
            Path                            = "OU=INH,OU=LSD,OU=Quincy,OU=Servers,$domainDN"
            ProtectedFromAccidentalDeletion = $true
            Description                     = 'UPLD OU'
            Ensure                          = 'Present'
            DependsOn 						= '[ADOrganizationalUnit]LSD-INH'
        }

        ADOrganizationalUnit SBG
        {
            Name                            = 'SBG'
            Path                            = "OU=Quincy,OU=Servers,$domainDN"
            ProtectedFromAccidentalDeletion = $true
            Description                     = 'SBG OU'
            Ensure                          = 'Present'
            DependsOn 						= '[ADOrganizationalUnit]Quincy'
        }

        ADOrganizationalUnit SBG-SQL
        {
            Name                            = 'SQL'
            Path                            = "OU=SBG,OU=Quincy,OU=Servers,$domainDN"
            ProtectedFromAccidentalDeletion = $true
            Description                     = 'SQL OU'
            Ensure                          = 'Present'
            DependsOn 						= '[ADOrganizationalUnit]SBG'
        }

        ADOrganizationalUnit UST
        {
            Name                            = 'UST'
            Path                            = "OU=Quincy,OU=Servers,$domainDN"
            ProtectedFromAccidentalDeletion = $true
            Description                     = 'UST OU'
            Ensure                          = 'Present'
            DependsOn 						= '[ADOrganizationalUnit]Quincy'
        }

        ADOrganizationalUnit UST-IIS
        {
            Name                            = 'IIS'
            Path                            = "OU=UST,OU=Quincy,OU=Servers,$domainDN"
            ProtectedFromAccidentalDeletion = $true
            Description                     = 'UST IIS OU'
            Ensure                          = 'Present'
            DependsOn 						= '[ADOrganizationalUnit]UST'
        }

        ADOrganizationalUnit UST-INH
        {
            Name                            = 'INH'
            Path                            = "OU=UST,OU=Quincy,OU=Servers,$domainDN"
            ProtectedFromAccidentalDeletion = $true
            Description                     = 'UST INH OU'
            Ensure                          = 'Present'
            DependsOn 						= '[ADOrganizationalUnit]UST'
        }

        ADOrganizationalUnit UST-SQL
        {
            Name                            = 'SQL'
            Path                            = "OU=UST,OU=Quincy,OU=Servers,$domainDN"
            ProtectedFromAccidentalDeletion = $true
            Description                     = 'UST SQL OU'
            Ensure                          = 'Present'
            DependsOn 						= '[ADOrganizationalUnit]UST'
        }

        ADOrganizationalUnit XBC
        {
            Name                            = 'XBC'
            Path                            = "OU=Quincy,OU=Servers,$domainDN"
            ProtectedFromAccidentalDeletion = $true
            Description                     = 'XBC OU'
            Ensure                          = 'Present'
            DependsOn 						= '[ADOrganizationalUnit]Quincy'
        }

        ADOrganizationalUnit XBC-IIS
        {
            Name                            = 'IIS'
            Path                            = "OU=XBC,OU=Quincy,OU=Servers,$domainDN"
            ProtectedFromAccidentalDeletion = $true
            Description                     = 'XBC IIS OU'
            Ensure                          = 'Present'
            DependsOn 						= '[ADOrganizationalUnit]XBC'
        }

        ADOrganizationalUnit XBC-INH
        {
            Name                            = 'INH'
            Path                            = "OU=XBC,OU=Quincy,OU=Servers,$domainDN"
            ProtectedFromAccidentalDeletion = $true
            Description                     = 'XBC INH OU'
            Ensure                          = 'Present'
            DependsOn 						= '[ADOrganizationalUnit]XBC'
        }

        ADOrganizationalUnit XBL
        {
            Name                            = 'XBL'
            Path                            = "OU=Quincy,OU=Servers,$domainDN"
            ProtectedFromAccidentalDeletion = $true
            Description                     = 'XBL OU'
            Ensure                          = 'Present'
            DependsOn 						= '[ADOrganizationalUnit]Quincy'
        }

        ADOrganizationalUnit XBL-IIS
        {
            Name                            = 'IIS'
            Path                            = "OU=XBL,OU=Quincy,OU=Servers,$domainDN"
            ProtectedFromAccidentalDeletion = $true
            Description                     = 'XBL IIS OU'
            Ensure                          = 'Present'
            DependsOn 						= '[ADOrganizationalUnit]XBL'
        }

        ADOrganizationalUnit XBL-INH
        {
            Name                            = 'INH'
            Path                            = "OU=XBL,OU=Quincy,OU=Servers,$domainDN"
            ProtectedFromAccidentalDeletion = $true
            Description                     = 'XBL INH OU'
            Ensure                          = 'Present'
            DependsOn 						= '[ADOrganizationalUnit]XBL'
        }

        ADOrganizationalUnit TOOL
        {
            Name                            = 'TOOL'
            Path                            = "OU=INH,OU=XBL,OU=Quincy,OU=Servers,$domainDN"
            ProtectedFromAccidentalDeletion = $true
            Description                     = 'XBL INH TOOL OU'
            Ensure                          = 'Present'
            DependsOn 						= '[ADOrganizationalUnit]XBL-INH'
        }

        ADOrganizationalUnit XNA
        {
            Name                            = 'XNA'
            Path                            = "OU=Quincy,OU=Servers,$domainDN"
            ProtectedFromAccidentalDeletion = $true
            Description                     = 'XNA OU'
            Ensure                          = 'Present'
            DependsOn 						= '[ADOrganizationalUnit]Quincy'
        }

        ADOrganizationalUnit XNA-SQL
        {
            Name                            = 'SQL'
            Path                            = "OU=XNA,OU=Quincy,OU=Servers,$domainDN"
            ProtectedFromAccidentalDeletion = $true
            Description                     = 'XNA SQL OU'
            Ensure                          = 'Present'
            DependsOn 						= '[ADOrganizationalUnit]XNA'
        }

        ADOrganizationalUnit XNA-INH
        {
            Name                            = 'INH'
            Path                            = "OU=XNA,OU=Quincy,OU=Servers,$domainDN"
            ProtectedFromAccidentalDeletion = $true
            Description                     = 'XNA INH OU'
            Ensure                          = 'Present'
            DependsOn 						= '[ADOrganizationalUnit]XNA'
        }

        ADOrganizationalUnit ISS
        {
            Name                            = 'ISS'
            Path                            = "OU=Servers,$domainDN"
            ProtectedFromAccidentalDeletion = $true
            Description                     = 'ISS OU'
            Ensure                          = 'Present'
            DependsOn 						= '[ADOrganizationalUnit]Servers'
        }

        ADOrganizationalUnit WEB
        {
            Name                            = 'WEB'
            Path                            = "OU=ISS,OU=Servers,$domainDN"
            ProtectedFromAccidentalDeletion = $true
            Description                     = 'WEB OU'
            Ensure                          = 'Present'
            DependsOn 						= '[ADOrganizationalUnit]ISS'
        }

        ADOrganizationalUnit XKMS
        {
            Name                            = 'XKMS'
            Path                            = "OU=WEB,OU=ISS,OU=Servers,$domainDN"
            ProtectedFromAccidentalDeletion = $true
            Description                     = 'WEB OU'
            Ensure                          = 'Present'
            DependsOn 						= '[ADOrganizationalUnit]WEB'
        }	

        ADOrganizationalUnit DB
        {
            Name                            = 'DB'
            Path                            = "OU=ISS,OU=Servers,$domainDN"
            ProtectedFromAccidentalDeletion = $true
            Description                     = 'DB OU'
            Ensure                          = 'Present'
            DependsOn 						= '[ADOrganizationalUnit]ISS'
        }	

        ADOrganizationalUnit ISS-SBG
        {
            Name                            = 'SBG'
            Path                            = "OU=DB,OU=ISS,OU=Servers,$domainDN"
            ProtectedFromAccidentalDeletion = $true
            Description                     = 'SBG OU'
            Ensure                          = 'Present'
            DependsOn 						= '[ADOrganizationalUnit]DB'
        }	
            
        ADOrganizationalUnit ISS-XBL
        {
            Name                            = 'XBL'
            Path                            = "OU=DB,OU=ISS,OU=Servers,$domainDN"
            ProtectedFromAccidentalDeletion = $true
            Description                     = 'XBL OU'
            Ensure                          = 'Present'
            DependsOn 						= '[ADOrganizationalUnit]DB'
        }	
    #endregion Servers

    #region ResourceGroups
        ADGroup XSO-Transport-From_CorpNet_All-RW
        {
            GroupName   = 'XSO-Transport-From_CorpNet_All-RW'
            GroupScope  = 'DomainLocal'
            Category    = 'Security'
            Path        = "OU=ResourceGroups,OU=Groups,$domainDN"
            Description = "XSO-Transport-From_CorpNet_All-RW"
            Ensure      = 'Present'
            DependsOn   = '[ADOrganizationalUnit]ResourceGroups'
        }

        ADGroup All-CorpTransport-All-RW
        {
            GroupName   = 'All-CorpTransport-All-RW'
            GroupScope  = 'DomainLocal'
            Category    = 'Security'
            Path        = "OU=ResourceGroups,OU=Groups,$domainDN"
            Description = 'All-CorpTransport-All-RW group'
            Ensure      = 'Present'
            DependsOn   = '[ADOrganizationalUnit]ResourceGroups'
        }

        ADGroup XSO-Transport-To_CorpNet_All-RW
        {
            GroupName   = 'XSO-Transport-To_CorpNet_All-RW'
            GroupScope  = 'DomainLocal'
            Category    = 'Security'
            Path        = "OU=ResourceGroups,OU=Groups,$domainDN"
            Description = 'XSO-Transport-To_CorpNet_All-RW group'
            Ensure      = 'Present'
            DependsOn   = '[ADOrganizationalUnit]ResourceGroups'
        }
    #endregion ResourceGroups

    #region RoleGroups
        ADGroup ALL-365-ServiceAccounts
        {
            GroupName   = 'ALL-365-ServiceAccounts'
            GroupScope  = 'DomainLocal'
            Category    = 'Security'
            Path        = "OU=RoleGroups,OU=Groups,$domainDN"
            Description = 'ALL-365-ServiceAccounts group'
            Ensure      = 'Present'
            DependsOn   = '[ADOrganizationalUnit]RoleGroups'
        }
    #endregion RoleGroups

    #region User acct.
        ADUser 'jamano\anberens'
        {
            GivenName  = 'Annika'
            Surname    = 'Berens'
            DisplayName = 'Annika Berens'
            UserName   = 'anberens'
            Password   = $DefaultUserPwd
            UserPrincipalName = "anberens@$DomainName"
            Department = 'Sales'
            JobTitle   = 'Consultant'
            Division = 'Sales n Marketing'
            ChangePasswordAtLogon = $true
            Enabled = $true
            DomainName = $DomainName
            Path       = "OU=UserAccounts,$domainDN"
            DependsOn  = '[ADOrganizationalUnit]UserAccounts'
            Ensure     = 'Present'
        }
        
        ADUser 'jamano\dajansen'
        {
            GivenName  = 'Dankhard'
            Surname    = 'Jansen'
            DisplayName = 'Dankhard Jansen'
            UserName   = 'dajansen'
            Password   = $DefaultUserPwd
            UserPrincipalName = "dajansen@$DomainName"
            Department = 'Planning'
            JobTitle   = 'Manager'
            Division = 'Civil Enginnering'
            ChangePasswordAtLogon = $true
            Enabled = $true
            DomainName = $DomainName
            Path       = "OU=UserAccounts,$domainDN"
            DependsOn  = '[ADOrganizationalUnit]UserAccounts'
            Ensure     = 'Present'
        }
        
        ADUser 'jamano\hakastner'
        {
            GivenName  = 'Hanfried'
            Surname    = 'Kastner'
            DisplayName = 'Hanfried Kastner'
            UserName   = 'hakastner'
            Password   = $DefaultUserPwd
            UserPrincipalName = "hakastner@$DomainName"
            Department = 'IT'
            JobTitle   = 'Technician'
            Division = 'Engineering'
            ChangePasswordAtLogon = $true
            Enabled = $true
            DomainName = $DomainName
            Path       = "OU=UserAccounts,$domainDN"
            DependsOn  = '[ADOrganizationalUnit]UserAccounts'
            Ensure     = 'Present'
        }
        
        ADUser 'jamano\ulscholten'
        {
            GivenName  = 'Ulwin'
            Surname    = 'Scholten'
            DisplayName = 'Ulwin Scholten'
            UserName   = 'ulscholten'
            Department = 'Consulting'
            JobTitle   = 'Manager'
            Division = 'Engineering'
            Password   = $DefaultUserPwd
            UserPrincipalName = "ulscholten@$DomainName"
            ChangePasswordAtLogon = $true
            Enabled = $true
            DomainName = $DomainName
            Path       = "OU=UserAccounts,$domainDN"
            DependsOn  = '[ADOrganizationalUnit]UserAccounts'
            Ensure     = 'Present'
        }

    #endregion User acct.
	}	
}

        
    #region set static IP n DNS
        # NetIPInterface DisableDhcp
        # {
        #     InterfaceAlias = 'Ethernet'
        #     AddressFamily  = 'IPv4'
        #     Dhcp           = 'Disabled'
        # }

        # IPAddress NewIPv4Address
        # {
        #     IPAddress      = '172.16.10.4'
        #     InterfaceAlias = 'Ethernet'
        #     AddressFamily  = 'IPV4'
        # }

        # DnsServerAddress PrimaryAndSecondary
        # {
        #     Address        = '172.16.10.4' #,'10.0.0.40'
        #     InterfaceAlias = 'Ethernet'
        #     AddressFamily  = 'IPv4'
        #     Validate       = $true
        # }

    #endregion IP n DNS

