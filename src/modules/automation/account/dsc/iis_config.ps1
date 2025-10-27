configuration WebServerConfiguration
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
        [string]$GenevaBaseDirectory   = "C:\Monitoring"
        [string]$GenevaFilePath        = "C:\Monitoring\runagentclient.cmd"
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
set MONITORING_GCS_THUMBPRINT=2D94A7EAD2370870BCA6BC72B66563EB10A14D24
'@
    # imports here
    Import-DscResource -ModuleName PSDesiredStateConfiguration
    Import-DscResource -ModuleName ComputerManagementDsc
    
    node localhost
    {
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
            ActionWorkingPath  = 'C:\Monitoring'
            ActionExecutable   = 'C:\Monitoring\runagentClient.cmd'
            ScheduleType       = 'AtStartup'
            BuiltInAccount	   = 'SYSTEM'
            Enable	           = $true
            Ensure             = 'Present'
            Description        = 'Creates scheduled task to start the Geneva monitoring agent'
            DependsOn          = '[File]RunAgentFile'
        }

        #iis role installation
        WindowsFeature WebServer
        {
            Name = "Web-Server"
            Ensure = "Present"
        }

        WindowsFeature ManagementTools
        {
            Name = "Web-Mgmt-Tools"
            Ensure = "Present"
        }

        WindowsFeature DefaultDoc
        {
            Name = "Web-Default-Doc"
            Ensure = "Present"
        }
        
        Registry DisableServerManagerAtLogon {
            Key = 'HKLM\Software\Microsoft\ServerManager'
            ValueName = 'DoNotOpenServerManagerAtLogon'
            ValueData = '1'
            ValueType = 'Dword'
            Ensure = 'Present'
        }        
    }
}