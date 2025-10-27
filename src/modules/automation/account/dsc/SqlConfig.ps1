<#
    .SYNOPSIS        
        This PoSh script configures pre-reqs for SQL server host
        https://github.com/dsccommunity/SqlServerDsc/wiki
        Creates the base SQL server configuration requisites
    .DESCRIPTION
        Below creates Directories, cNtfsPermissionEntry DSC resource to assign NTFS permissions....
    .Parameter nameHere
    .Example
#>

Configuration SQLConfig {

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
        [string]$GenevaBaseDirectory   = "C:\Monitoring"
        [string]$GenevaFilePath        = "C:\Monitoring\runagentclient.cmd"
        [string]$bakPath     = 'E:\MSSQL\BAK'
        [string]$archivePath = 'E:\MSSQL\BAK\Archive'
        [string]$tranPath    = 'E:\MSSQL\TRAN'
        [string]$difPath     = 'E:\MSSQL\DIF'
        [string]$dataPath    = 'H:\MSSQL\DATA'
        [string]$logsPath    = 'O:\MSSQL\DATA'
        [string]$tempPath    = 'T:\MSSQL\DATA'
#endregion vars    
    
    
    Import-DscResource -ModuleName PSDesiredStateConfiguration
    Import-DscResource -ModuleName ComputerManagementDsc
    Import-DscResource -ModuleName cNtfsAccessControl

    Node "localhost"
    {
    #region Geneva monitoring 
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

    #region set registry
        Registry DisableServerManagerAtLogon {
            Key = 'HKLM\Software\Microsoft\ServerManager'
            ValueName = 'DoNotOpenServerManagerAtLogon'
            ValueData = '1'
            ValueType = 'Dword'
            Ensure = 'Present'
        }

        Registry Sql_Disable_UAC_Settings { # Disable UAC
            Key = 'HKLM\Software\Microsoft\Windows\CurrentVersion\Policies\System'
            ValueName = 'EnableLUA'
            ValueData = '0'
            ValueType = 'Dword'
            Ensure = 'Present'
        }

        Registry ProcessorScheduling {
            Key = 'HKLM\System\CurrentControlSet\Control\PriorityControl'
            ValueName = 'Win32PrioritySeparation'
            ValueData = '24'
            ValueType = 'Dword'
            Ensure = 'Present'
        }

        Registry PerformanceVisualEffects {
            Key = 'HKLM\Software\Microsoft\Windows\CurrentVersion\Explorer\VisualEffects'
            ValueName = 'VisualFXSetting'
            ValueData = '2'
            ValueType = 'Dword'
            Ensure = 'Present'
        }

        Registry DisableIPv6 {
            Key = 'HKLM\SYSTEM\CurrentControlSet\Services\Tcpip6\Parameters'
            ValueName = 'DisabledComponents'
            ValueData = '0xff'
            ValueType = 'Dword'
            Ensure = 'Present'
        }

        Registry T1117 {
            Key = 'HKLM\SOFTWARE\Microsoft\Microsoft SQL Server\MSSQL16.MSSQLSERVER\MSSQLServer\Parameters'
            ValueName = 'SQLArg3'
            ValueData = '0'
            ValueType = 'Dword'
            Ensure = 'Present'
        }

        Registry T1222 {
            Key = 'HKLM\SOFTWARE\Microsoft\Microsoft SQL Server\MSSQL16.MSSQLSERVER\MSSQLServer\Parameters'
            ValueName = 'SQLArg4'
            ValueData = '-T1222'
            ValueType = 'Dword'
            Ensure = 'Present'
        }

        Registry T1204 {
            Key = 'HKLM\SOFTWARE\Microsoft\Microsoft SQL Server\MSSQL16.MSSQLSERVER\MSSQLServer\Parameters'
            ValueName = 'SQLArg5'
            ValueData = '-T1204'
            ValueType = 'Dword'
            Ensure = 'Present'
        }
    #endregion registry

    #region Directories N Shares
        File Bak {
            Type = 'Directory'
            DestinationPath = $bakPath
            Ensure = 'Present'
        }

        File Archive {
            Type = 'Directory'
            DependsOn = '[File]Bak'
            DestinationPath = $archivePath
            Ensure = 'Present'
        }

        File Tran {
            Type = 'Directory'
            DestinationPath = $tranPath
            Ensure = 'Present'
        }

        File Dif {
            Type = 'Directory'
            DestinationPath = $difPath
            Ensure = 'Present'
        }

        File Data {
            Type = 'Directory'
            DestinationPath = $dataPath
            Ensure = 'Present'
        }

        File Logs {
            Type = 'Directory'
            DestinationPath = $logsPath
            Ensure = 'Present'
        }
        File Temp {
            Type = 'Directory'
            DestinationPath = $tempPath
            Ensure = 'Present'
        }

        # Create Net Share and perms
        SmbShare 'bakShare' {
            Name         = 'BAK'
            Path         = $bakPath
            FullAccess   = @('NETWORK SERVICE', 'Administrators')
            ChangeAccess = @()
            ReadAccess   = @('EVERYONE')
            NoAccess     = @()
            Description = 'DB backups'
            ConcurrentUserLimit = 0
            EncryptData = $false
            FolderEnumerationMode = 'AccessBased'
            CachingMode = 'None'
            Ensure = 'Present'
            
        }

        # Assign Folder Perms - #Bak
        cNtfsPermissionEntry bakFolder {
            Ensure = 'Present'
            Path = $bakPath
            Principal = 'NETWORK SERVICE'
            AccessControlInformation = @(
                cNtfsAccessControlInformation {
                    AccessControlType = 'Allow'
                    FileSystemRights = 'FullControl'
                    Inheritance = 'ThisFolderSubfoldersAndFiles'
                    NoPropagateInherit = $false                    
                }          
            )
            DependsOn = '[File]Bak'
        }

        # Assign Folder Perms - #Archive
        cNtfsPermissionEntry bakArchiveFolder {
            Ensure = 'Present'
            Path = $archivePath
            Principal = 'NETWORK SERVICE'
            AccessControlInformation = @(
                cNtfsAccessControlInformation {
                    AccessControlType = 'Allow'
                    FileSystemRights = 'FullControl'
                    Inheritance = 'ThisFolderSubfoldersAndFiles'
                    NoPropagateInherit = $false                    
                }          
            )
            DependsOn = '[File]Archive'
        }

        # Assign Folder Perms - #DIF
        cNtfsPermissionEntry DifFolder {
            Ensure = 'Present'
            Path = $difPath  
            Principal = 'NETWORK SERVICE'
            AccessControlInformation = @(
                cNtfsAccessControlInformation {
                    AccessControlType = 'Allow'
                    FileSystemRights = 'FullControl'
                    Inheritance = 'ThisFolderSubfoldersAndFiles'
                    NoPropagateInherit = $false                    
                }          
            )
            DependsOn = '[File]Dif'
        }

        # Assign Folder Perms - #Data
        cNtfsPermissionEntry DataFolder {
            Ensure = 'Present'
            Path = $dataPath 
            Principal = 'NETWORK SERVICE'
            AccessControlInformation = @(
                cNtfsAccessControlInformation {
                    AccessControlType = 'Allow'
                    FileSystemRights = 'FullControl'
                    Inheritance = 'ThisFolderSubfoldersAndFiles'
                    NoPropagateInherit = $false                    
                }          
            )
            DependsOn = '[File]Data'
        }

        # Assign Folder Perms - #Logs
        cNtfsPermissionEntry LogsFolder {
            Ensure = 'Present'
            Path = $logsPath
            Principal = 'NETWORK SERVICE'
            AccessControlInformation = @(
                cNtfsAccessControlInformation {
                    AccessControlType = 'Allow'
                    FileSystemRights = 'FullControl'
                    Inheritance = 'ThisFolderSubfoldersAndFiles'
                    NoPropagateInherit = $false                    
                }          
            )
            DependsOn = '[File]Logs'
        }

        # Assign Folder Perms - #Temp
        cNtfsPermissionEntry TempFolder {
            Ensure = 'Present'
            Path = $tempPath
            Principal = 'NETWORK SERVICE'
            AccessControlInformation = @(
                cNtfsAccessControlInformation {
                    AccessControlType = 'Allow'
                    FileSystemRights = 'FullControl'
                    Inheritance = 'ThisFolderSubfoldersAndFiles'
                    NoPropagateInherit = $false                    
                }          
            )
            DependsOn = '[File]Temp'
        }
    #endregion Directories N Shares
        
        #Configure Failover clustering 
        WindowsFeature FailOverClustering {
            Ensure = 'Present'
            Name = 'Failover-Clustering'
            IncludeAllSubFeature = $true
        }

        WindowsFeature FailOverClusteringTools {
            Ensure = 'Present'
            Name = 'RSAT-Clustering'
            IncludeAllSubFeature = $true
        }

    #region Configure SQL Services startups
        Service IntegrationServices {
            Name = 'MsDtsServer120'
            State = 'Stopped'
            StartupType = 'Disabled'            
        }
        
        Service DisableFullText  {
            Name = 'MSSQLFDLauncher'
            State = 'Stopped'
            StartupType = 'Disabled'            
        }
        
        Service DisableAnalysisServices  {
            Name = 'MSSQLServerOLAPService'
            State = 'Stopped'
            StartupType = 'Disabled'            
        }
        
        Service SQL-Acct  {#Set the SQL Service account
            Name = 'MSSQLSERVER'
            BuiltInAccount = 'NetworkService'
            State = 'Running'
            StartupType = 'Automatic'            
        }
        
        Service SQLServerAgent  { #Set SQL Server Agent to automatic
            Name = 'SQLSERVERAGENT'
            BuiltInAccount = 'NetworkService'
            State = 'Running'
            StartupType = 'Automatic'            
        }
    #endregion SQL services
    }
}
