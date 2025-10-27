configuration GenevaMonitoring
{
    [string]$fileContent = @'
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
    # imports here
    Import-DscResource -ModuleName PSDesiredStateConfiguration
    Import-DscResource -ModuleName ComputerManagementDsc
    
    node localhost
    {
        File GenevaDirectory
        {
            Ensure = 'Present'
            Type = 'Directory'
            DestinationPath = 'C:\Monitoring'            
        }
        File RunAgentFile
        {
            DestinationPath = 'C:\Monitoring\runagentclient.cmd'
            Ensure = 'Present'
            Type = 'File'
            Contents = $fileContent
            DependsOn = '[File]GenevaDirectory'
            
        }

        ScheduledTask StartupScheduledTask
        {
            TaskName           = 'Geneva AzsecPack'
            TaskPath           = '\GenevaMA'
            ActionWorkingPath  = 'C:\Monitoring'
            ActionExecutable   = 'C:\Monitoring\runagentClient.cmd '
            ScheduleType       = 'AtStartup'
            BuiltInAccount	   = 'SYSTEM'
            Enable	           = $true
            Description        = 'Runs the Geneva monitoring agent script on system startup.'
            DependsOn = '[File]RunAgentFile'
        }
    }
}