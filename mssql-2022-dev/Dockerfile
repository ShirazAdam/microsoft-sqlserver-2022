#Build for  SQL Server 2022 Developer Edition for WINDOWS on server core 2022 + CU15
#Created by Shiraz Adam
#Based on the work of for Isaac Kramer (tzahik1@gmail.com) SQL SERVER Express 2022 WINDOWS on server core 2022 + CU11
#Based on the work of Tobias Fenster  https://github.com/tfenster/mssql-image/
#But with a twist of using 2 stages of SQL Server Install - 1. SysPrep (with FULL updates of CU) 2.CreatImage
# (normal CU update after server installed didn't work for me when deploying it as a container)
# This version was for SQL Express but I believe the it will also work for Developer/Enterprise versions
#
# You need 3 set-up folders on the host to be ready for the build as seen in the Dockerfile:

# 1. The main SQL Server 2022 developer setup media extracted so that the root SETUP.EXE will be in '\SQLSetupMedia\SQLServer2022-x64-ENU-Dev\' folder.
# 2. The CU update (in this case CU15) EXE file (don't need to be extacted) in '\SQLSetupMedia\CU\CU15\SQLServer2022-KB5041321-x64.exe'
# 3. Due to strange bug that the servercore 2022 image don't have old server controls (used to be at 1809) you must 
#     have The Missing Server control files/folders - which is a bunch of folders which include old control dll's under 'Missing' folder.
#     as explaind in here:  https://github.com/microsoft/mssql-docker/issues/540.
#    So 4 folders needs to be in the folder '\SQLSetupMedia\CU\CU15\Missing\' to fix this strange bug i mentioned there.
# you can get them from an old sql server installation from the GAC folder.
# For convenience for the public i  uploaded  a zip file with all the folders to just drop it there.
# zip file: OldServerControlsFolders.zip

# How to use after build:
# docker build `
# --build-arg VERSION=16.0.4541.4 --build-arg TYPE=dev `
# -f Dockerfile.prep.txt ` (or without this line for fileName regular Dockerfile...)
# -t mssqlserver-2022-dev:2022-win-CU15-v1.0.


#Step 1.0: Start from base image mcr.microsoft.com/windows/servercore
FROM mcr.microsoft.com/windows/servercore:ltsc2022
RUN echo "Step 1.0: Start from base image mcr.microsoft.com/windows/servercore"
LABEL maintainer "Shiraz Adam: https://github.com/ShirazAdam/mssql-dev-v2022"


#Step 1.1 define ev and args:
RUN echo "Step 1.1 define ev and args"
ARG CU="15" 
ARG VERSION="16.0.4541.4"
ARG TYPE="dev"
ARG sa_password

ENV CU=$CU 
ENV VERSION=${VERSION}
ENV sa_password="Vmw0NTY3dmxzaTI1MDAh"
ENV attach_dbs="[]" 
ENV accept_eula="Y"
ENV sa_password_path="C:\ProgramData\Docker\secrets\sa-password"


#Step 2.0: Create temporary directory to hold SQL Server installation files + CU
RUN echo "Step 2.0: Create temporary directory to hold SQL Server installation files + CU"
RUN powershell -Command (MKDIR 'C:/Temp_SQLDev_Setup')
RUN powershell -Command (MKDIR 'C:/Temp_CU_Setup')

#Step 2.1 because of Strange error on CU install : https://github.com/microsoft/mssql-docker/issues/540
# need to copy ahead missing files to GAC. Missing files (ServerControls) are in self made folder
# that can be created from old installment of Sql server in real PC and searching there the controls files
# as explained in the github issue above
RUN echo 'Step 2.1 because of error on CU install need to copy ahead missing files to GAC'
COPY 'SQLSetupMedia/CU/CU15/Missing/' 'C:/Windows/Microsoft.Net/assembly/GAC_MSIL'


#Step 3.0: Copy SQL Server XXXX installation files from the host to the container image
RUN echo 'Step 3.0: Copy SQL Server XXXX installation files from the host to the container image'
COPY  'SQLSetupMedia/SQLServer2022-x64-ENU-Dev/'  'C:/Temp_SQLDev_Setup'

#Step 3.1: Download CU15 installation file from the internet
RUN powershell $path = 'SQLSetupMedia\CU\CU15\SQLServer2022-KB5041321-x64.exe'; \
    if (-not(Test-Path -path $path)) { \
        echo 'File does not exist. Now downloading CU$($CU).' \
        Invoke-WebRequest -Uri 'https://download.microsoft.com/download/9/6/8/96819b0c-c8fb-4b44-91b5-c97015bbda9f/SQLServer2022-KB5041321-x64.exe' -OutFile $path \
    } \
    else { \
        echo 'File exists. There is no need to download CU$($CU) again.' \
    }

#Step 3.2: Copy CU  XXXX installation .EXE file from the host to the container image to another folder
RUN echo 'Step 3.2: Copy CU  XXXX installation .EXE file from the host to the container image'
COPY 'SQLSetupMedia/CU/CU15/SQLServer2022-KB5041321-x64.exe' 'C:/Temp_CU_Setup'

#Step 3.3 check size of setup media directory in container -should be  652431336 (622M)
RUN echo 'Step 3.3 check size of setup media directory in container -should be  652431336 (622M)'
WORKDIR  'C:/Temp_SQLDev_Setup'
RUN powershell -Command "(ls -r | measure -sum Length)"
WORKDIR '/'

#Step 3.4 setup PowerShell for  error messages and user
RUN echo 'Step 3.4 setup PowerShell for error messages and user'
SHELL ["powershell", "-Command", "$ErrorActionPreference = 'Stop'; $ProgressPreference = 'SilentlyContinue';"]
USER ContainerAdministrator


#Step 4.0: Install SQL Server Developer SysPrep (Only Prepare Image with FULL UPDATES) via command line inside powershell
RUN echo 'Step 4.0: Install SQL Server Developer SysPrep (Only Prepare Image with FULL UPDATES) via command line inside powershell'
RUN     .\Temp_SQLDev_Setup\SETUP.exe /q /ACTION=PrepareImage   \
        /INSTANCEID=MSSQLDEV  \
        /IACCEPTSQLSERVERLICENSETERMS /SUPPRESSPRIVACYSTATEMENTNOTICE /IACCEPTPYTHONLICENSETERMS \
        /IACCEPTROPENLICENSETERMS  \
        /INDICATEPROGRESS \
         /UPDATEENABLED=True /UpdateSource='C:/Temp_CU_Setup' \
        /FEATURES=SQL;
    
#Step 4.1 Install SQL Server Developer 'Complete Image' AFTER SysPrep Stage above via command line inside powershell
RUN echo 'Step 4.1 Install SQL Server Developer ''Complete Image'' AFTER SysPrep Stage via command line inside powershell'
RUN mkdir 'C:/databases';

RUN .\Temp_SQLDev_Setup\SETUP.exe /q /ACTION=CompleteImage /INSTANCEID=MSSQLDEV \
    /IACCEPTSQLSERVERLICENSETERMS /SUPPRESSPRIVACYSTATEMENTNOTICE /IACCEPTPYTHONLICENSETERMS \
    /IACCEPTROPENLICENSETERMS  \
    /INDICATEPROGRESS \
    /INSTANCENAME=MSSQLDEV  /INSTANCEID=MSSQLDEV \
    /SECURITYMODE=SQL /SAPWD='blaBlaBlaPass1!' /SQLSVCACCOUNT='NT AUTHORITY\NETWORK SERVICE' \
    /AGTSVCACCOUNT='NT AUTHORITY\NETWORK SERVICE' \
    /SQLSYSADMINACCOUNTS='BUILTIN\ADMINISTRATORS' \
    /TCPENABLED=1 /NPENABLED=1    \
    /SQLUSERDBDIR='C:/databases' /SQLUSERDBLOGDIR='C:/databases'; \ 
    remove-item -recurse -force c:\Temp_SQLDev_Setup -ErrorAction SilentlyContinue; \
    remove-item -recurse -force c:\Temp_CU_Setup -ErrorAction SilentlyContinue;


#Step 5 - Finished  Basic setup, now configure SERVICES and Registry Values
RUN echo 'Step 5: Finished  Basic setup, now configure SERVICES and Registry Values'
RUN $SqlServiceName = 'MSSQL$MSSQLDEV'; \
    $VerbosePreference = 'continue'; \
    $WarningPreference = 'continue'; \
    $DebugPreference = 'continue'; \
    Write-Host 'Information'; \
    Write-Verbose ''; \
    Write-Warning ''; \
    Write-Debug ''; \
    While (!(get-service $SqlServiceName -ErrorAction Continue)) { Start-Sleep -Seconds 5 } ; \
    Stop-Service $SqlServiceName ; \
    $databaseFolder = 'c:/databases'; \
    New-Item -Path  $databaseFolder -ItemType Directory -Force; \
    $SqlWriterServiceName = 'SQLWriter'; \
    $SqlBrowserServiceName = 'SQLBrowser'; \
    Set-Service $SqlServiceName -startuptype automatic ; \
    Set-Service $SqlWriterServiceName -startuptype manual ; \
    Stop-Service $SqlWriterServiceName; \
    Set-Service $SqlBrowserServiceName -startuptype manual ; \
    Stop-Service $SqlBrowserServiceName; \
    $SqlTelemetryName = 'SQLTELEMETRY$MSSQLDEV'; \
    Set-Service $SqlTelemetryName -startuptype manual ; \
    Stop-Service $SqlTelemetryName; \
    $version = [System.Version]::Parse($env:VERSION); \
    $id = ('mssql' + $version.Major + '.MSSQLSERVER'); \
    New-Item -path ('HKLM:\SOFTWARE\Microsoft\Microsoft SQL Server\' + $id + '\'); \
    New-Item -path ('HKLM:\SOFTWARE\Microsoft\Microsoft SQL Server\' + $id + '\MSSQLServer\'); \
    New-Item -path ('HKLM:\SOFTWARE\Microsoft\Microsoft SQL Server\' + $id + '\MSSQLServer\SuperSocketNetLib\'); \
    New-Item -path ('HKLM:\SOFTWARE\Microsoft\Microsoft SQL Server\' + $id + '\MSSQLServer\SuperSocketNetLib\Tcp\'); \
    New-Item -path ('HKLM:\SOFTWARE\Microsoft\Microsoft SQL Server\' + $id + '\MSSQLServer\SuperSocketNetLib\Tcp\IPAll'); \
    Set-itemproperty -path ('HKLM:\software\microsoft\microsoft sql server\' + $id + '\mssqlserver\supersocketnetlib\tcp\ipall') -name tcpdynamicports -value '' ; \
    Set-itemproperty -path ('HKLM:\software\microsoft\microsoft sql server\' + $id + '\mssqlserver\supersocketnetlib\tcp\ipall') -name tcpdynamicports -value '' ; \
    Set-itemproperty -path ('HKLM:\software\microsoft\microsoft sql server\' + $id + '\mssqlserver\supersocketnetlib\tcp\ipall') -name tcpport -value 1433 ; \
    Set-itemproperty -path ('HKLM:\software\microsoft\microsoft sql server\' + $id + '\mssqlserver') -name LoginMode -value 2; 
    # not needed anymore , set it above at  /SQLUSERDBDIR='C:\databases' /SQLUSERDBLOGDIR='C:\databases'; \ 
    # Set-itemproperty -path ('HKLM:\software\microsoft\microsoft sql server\' + $id + '\mssqlserver') -name DefaultData -value $databaseFolder; \
    # Set-itemproperty -path ('HKLM:\software\microsoft\microsoft sql server\' + $id + '\mssqlserver') -name DefaultLog -value $databaseFolder;


#Step 6: Set and create working directory for script execution
RUN echo 'Step 6: Set and create working directory for script execution at C:\Temp_Scripts'
WORKDIR C:/Temp_Scripts


#Step 7: Copy Start.ps1 to image on scripts directory
RUN echo 'Step 7: Copy Start.ps1 to image on scripts directory'
COPY start.ps1 C:/Temp_Scripts


#Step 8: Run PowerShell script Start.ps1, passing inside the script  the -ACCEPT_EULA parameter with a value of Y
# and $sa_password to create/change sa password
# and json strcuture to attach_dbs
# BUT ACTUALLY we don't inserting these values here , but in Docker-compose.yaml file ore in docker run command
RUN echo 'Step 8: Run PowerShell script Start.ps1, passing inside the script  the -ACCEPT_EULA parameter with \
 a value of Y etc'
CMD .\start.ps1