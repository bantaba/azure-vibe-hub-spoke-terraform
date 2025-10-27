@REM create dir
@REM set data_Dir= D:\Geneva\localdir
@REM md %data_dir% >NULL

set MONITORING_TENANT=xgoTools
set MONITORING_ROLE=Other
set MONITORING_ROLE_INSTANCE=%COMPUTERNAME% 

set MONITORING_DATA_DIRECTORY=D:\Geneva\localdir

set MONITORING_GCS_ACCOUNT=xsotoolssemdmwarm      
set MONITORING_GCS_NAMESPACE=xsotoolssemdmwarm

set MONITORING_GCS_ENVIRONMENT=DiagnosticsProd

set MONITORING_GCS_REGION=West US

set MONITORING_CONFIG_VERSION=1.0

set MONITORING_GCS_CERTSTORE=LOCAL_MACHINE\MY
set MONITORING_GCS_THUMBPRINT=6A56493B825234243996CCC99B05D682CBABC6D0

@REM For W2K16 ONLY 
set AZSECPACK_PILOT_FEATURES=WDATP

%monAgentClientLocation%\MonAgentClient.exe -useenv -waitForService

REM Use MonAgentClient.exe; instead of MonAgentLauncher.exe, if using the GenevaMonitoring VM extension version of Geneva.  %monAgentClientLocation%\MonAgentLauncher.exe
REM C:\GenevaAgent\MonAgentClient.exe -useenv [-waitForService]         @REM %monAgentClientLocation%\MonAgentClient.exe -useenv [-waitForService] 