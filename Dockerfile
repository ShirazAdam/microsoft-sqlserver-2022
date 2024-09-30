#Build for  SQL Server 2022 Developer Edition for WINDOWS on server core 2022 + CU15
#Created by Shiraz Adam
#Based on the work of for Isaac Kramer (tzahik1@gmail.com) SQL SERVER Express 2022 WINDOWS on server core 2022 + CU11
#Based on the work of Tobias Fenster  https://github.com/tfenster/mssql-image/
#But with a twist of using 2 stages of SQL Server Install - 1. SysPrep (with FULL updates of CU) 2.CreatImage
# (normal CU update after server installed didn't work for me when deploying it as a container)
# This version was for SQL Express but I believe the it will also work for Developer/Enterprise versions
#
# You need 3 set-up folders on the host to be ready for the build as seen in the Dockerfile:

# 1. The main SQL Server 2022 developer setup media extracted so that the root SETUP.EXE will be in '\SQLSetupMedia\SQLDEV_x64_ENU\' folder.
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
# --build-arg VERSION=16.0.1000.6 --build-arg TYPE=exp `
# -f Dockerfile.prep.txt ` (or without this line for fileName regular Dockerfile...)
# -t mssqlserver2022-dev-sysprep:2022-win-CU15-v1.0.




#Step 1: Start from base image mcr.microsoft.com/windows/servercore
FROM mcr.microsoft.com/windows/servercore:ltsc2022
RUN echo "Step 1: Start from base image mcr.microsoft.com/windows/servercore"

LABEL maintainer "Shiraz Adam: https://github.com/ShirazAdam/mssql-dev-v2022"


#Step 1.1 define ev and args:
ARG CU="15" 
ARG VERSION="16.0.4541.4"
ARG TYPE="dev"
ARG sa_password

ENV CU=$CU 
ENV VERSION=${VERSION}
ENV sa_password="Vmw0NTY3dmxzaTI1MDAh"
ENV attach_dbs="[]" 
ENV accept_eula="_"
ENV sa_password_path="C:\ProgramData\Docker\secrets\sa-password"

#Step 2: Create temporary directory to hold SQL Server installation files + CU
RUN echo "Step 2: Create temporary directory to hold SQL Server installation files + CU"
RUN powershell -Command (mkdir C:\Temp_SQLDev_Setup)
RUN powershell -Command (mkdir C:\Temp_CU_Setup)

#Step 2.1 because of Strange error on CU install : https://github.com/microsoft/mssql-docker/issues/540
# need to copy ahead missing files to GAC. Missing files (ServerControls) are in self made folder
# that can be created from old installment of Sql server in real PC and searching there the controls files
# as explained in the github issue above
RUN echo 'Step 2.1 because of error on CU install need to copy ahead missing files to GAC'
#COPY '\SQLSetupMedia\CU\CU15\Missing\' C:\Windows\Microsoft.Net\assembly\GAC_MSIL

#Step 3: Copy SQL Server XXXX installation files from the host to the container image
RUN echo 'Step 3: Copy SQL Server XXXX installation files from the host to the container image'
COPY  '\SQLSetupMedia\SQLDEV_x64_ENU\'  C:\Temp_SQLDev_Setup

#Step 3.1: Download CU15 installation file from the internet
RUN powershell -command ( \
    $url = 'https://download.microsoft.com/download/9/6/8/96819b0c-c8fb-4b44-91b5-c97015bbda9f/SQLServer2022-KB5041321-x64.exe' \
    $path = '\SQLSetupMedia\CU\CU15\SQLServer2022-KB5041321-x64.exe' \    
    if (-not(Test-Path -path $path)) { \
        Write-Host 'File does not exist. Now downloading CU$($CU).' \
        Invoke-WebRequest -Uri $url -OutFile $path \
    } \
    else { \
        Write-Host 'File exists. There''s no need to download CU$($CU) again.' \
    }

#Step 3.2: Copy CU  XXXX installation .EXE file from the host to the container image to another folder
RUN echo 'Step 3.2: Copy CU  XXXX installation .EXE file from the host to the container image'
COPY '\SQLSetupMedia\CU\CU15\SQLServer2022-KB5041321-x64.exe' C:\Temp_CU_Setup

#Step 3.3 check size of setup media directory in container -should be  652431336 (622M)
RUN echo 'Step 3.3 check size of setup media directory in container -should be  652431336 (622M)'
WORKDIR  C:\Temp_SQLDev_Setup
RUN powershell -Command "(ls -r | measure -sum Length)"
# RUN powershell -Command "(Get-ChildItem -Recurse | Measure-Object -Sum Length)"
#back to origin
WORKDIR /


#Step 3.4 setup PowerShell for  error messages and user
RUN echo 'Step 3.4 setup PowerShell for error messages and user'
SHELL ["powershell", "-Command", "$ErrorActionPreference = 'Stop'; $ProgressPreference = 'SilentlyContinue';"]
USER ContainerAdministrator


#Step 3.5 get chocolatey to install 7zip and sqlpackage
RUN echo 'Step 3.5 get chocolatey to install 7zip and sqlpackage'
RUN $ProgressPreference = 'SilentlyContinue'; \
    Invoke-Expression ((New-Object System.Net.WebClient).DownloadString('https://chocolatey.org/install.ps1')); \
    choco feature enable -n allowGlobalConfirmation; \
    choco install --no-progress --limit-output 7zip sqlpackage; \
     # Setup and use the Chocolatey helpers
    Import-Module "${ENV:ChocolateyInstall}\helpers\chocolateyProfile.psm1"; \
    Update-SessionEnvironment;
    # Import-Module "$env:ChocolateyInstall\helpers\chocolateyProfile.psm1" - didn't worked for me here \
    # refreshenv;      - didn't worked for me here

#Step 4: Install SQL Server Developer SysPrep (Only Prepare Image with FULL UPDATES) via command line inside powershell
RUN echo 'Step 4: Install SQL Server Developer SysPrep (Only Prepare Image with FULL UPDATES) via command line inside powershell'
RUN     .\Temp_SQLDev_Setup\SETUP.exe /q /ACTION=PrepareImage   \
        /INSTANCEID=MSSQLDEV  \
        /IACCEPTSQLSERVERLICENSETERMS /SUPPRESSPRIVACYSTATEMENTNOTICE /IACCEPTPYTHONLICENSETERMS \
        /IACCEPTROPENLICENSETERMS  \
        /INDICATEPROGRESS \
        # /SECURITYMODE=SQL /SQLSVCACCOUNT="NT AUTHORITY\NETWORK SERVICE" \
        #   /SQLSVCACCOUNT='NT AUTHORITY\NETWORK SERVICE' \
        # /SECURITYMODE=SQL /SAPWD=$sa_password /SQLSVCACCOUNT="NT AUTHORITY\NETWORK SERVICE" \
        # /SQLSYSADMINACCOUNTS='BUILTIN\ADMINISTRATORS'  \
        #  /UPDATEENABLED=True /UpdateSource='C:\Temp_CU_Setup\SQLServer2022-KB5041321-x64.exe' \
         /UPDATEENABLED=True /UpdateSource='C:\Temp_CU_Setup' \
        # /FEATURES=SQLEngine; \
        #  SQL= Installs the SQL Server Database Engine, Replication, Fulltext, and Data Quality Server.
        #  SQLEngine= Installs Only the SQL Server Database Engine.
        /FEATURES=SQL; \
        #test without delete - remove if nessacery: \
        # remove-item -recurse -force c:\Temp_SQLDev_Setup -ErrorAction SilentlyContinue; \
    }
        # Few tests here:
        # or:
        # /FEATURES=SQL,AS,IS \
        # /AGTSVCACCOUNT="NT AUTHORITY\System"  
    
#Step 4.5 Install SQL Server Developer 'Complete Image' AFTER SysPrep Stage above via command line inside powershell
RUN echo 'Step 4.5 Install SQL Server Developer 'Complete Image' AFTER SysPrep Stage via command line inside powershell'
RUN mkdir 'C:\databases';

RUN     .\Temp_SQLDev_Setup\SETUP.exe /q /ACTION=CompleteImage /INSTANCEID=MSSQLDEV \
        /IACCEPTSQLSERVERLICENSETERMS /SUPPRESSPRIVACYSTATEMENTNOTICE /IACCEPTPYTHONLICENSETERMS \
        /IACCEPTROPENLICENSETERMS  \
        /INDICATEPROGRESS \
        /INSTANCENAME=MSSQLDEV  /INSTANCEID=MSSQLDEV \
        # /SECURITYMODE=SQL /SQLSVCACCOUNT="NT AUTHORITY\NETWORK SERVICE" \
        # The password here we are inserting is NOT IMPORTANT because we change it at docker run (container) \
        # so you can enter here anything but must be SOMETHING, otherwise it won't work. \
        /SECURITYMODE=SQL /SAPWD='blaBlaBlaPass1!' /SQLSVCACCOUNT='NT AUTHORITY\NETWORK SERVICE' \
        # /SECURITYMODE=SQL /SAPWD=$sa_password /SQLSVCACCOUNT="NT AUTHORITY\NETWORK SERVICE" \
        /AGTSVCACCOUNT='NT AUTHORITY\NETWORK SERVICE' \
        /SQLSYSADMINACCOUNTS='BUILTIN\ADMINISTRATORS' \
        /TCPENABLED=1 /NPENABLED=1    \
        # /FEATURES=SQLEngine \
        # /FEATURES=SQL; \
        /SQLUSERDBDIR='C:\databases' /SQLUSERDBLOGDIR='C:\databases'; \ 
        #test without delete - remove if nessacery:
        #clean up install media file to reduce container size
        remove-item -recurse -force c:\Temp_SQLDev_Setup -ErrorAction SilentlyContinue; \
        remove-item -recurse -force c:\Temp_CU_Setup -ErrorAction SilentlyContinue; \
    }
        # or:
        # /FEATURES=SQL,AS,IS \
        # /AGTSVCACCOUNT="NT AUTHORITY\System"  

# RUN $SqlServiceName = 'MSSQLSERVER'; `  // if working with developer version - but we WON'T!
#     if ($env:TYPE -eq 'exp') { `
#         $SqlServiceName = 'MSSQL$SQLEXPRESS'; `
#     } `
#Step 5 - Finished  Basic setup, now configure SERVICES and Registry Values
RUN echo 'Step 5: Finished  Basic setup, now configure SERVICES and Registry Values'
RUN  $SqlServiceName = 'MSSQLSERVER'; \
    While (!(get-service $SqlServiceName -ErrorAction SilentlyContinue)) { Start-Sleep -Seconds 5 } ; \
    Stop-Service $SqlServiceName ; \
    $databaseFolder = 'c:\databases'; \
    # mkdir > $null don't throw exception when dir already exist
    # this command creates directory and not return exception if already exist as we create it above
    New-Item -Path  $databaseFolder -ItemType Directory -Force; \
    $SqlWriterServiceName = 'SQLWriter'; \
    $SqlBrowserServiceName = 'SQLBrowser'; \
    Set-Service $SqlServiceName -startuptype automatic ; \
    Set-Service $SqlWriterServiceName -startuptype manual ; \
    Stop-Service $SqlWriterServiceName; \
    Set-Service $SqlBrowserServiceName -startuptype manual ; \
    Stop-Service $SqlBrowserServiceName; \
    $SqlTelemetryName = 'SQLTELEMETRY'; \
    # if ($env:TYPE -eq 'exp') { \
    #     $SqlTelemetryName = 'SQLTELEMETRY$SQLEXPRESS'; \
    # } \
    Set-Service $SqlTelemetryName -startuptype manual ; \
    Stop-Service $SqlTelemetryName; \
    $version = [System.Version]::Parse($env:VERSION); \
    $id = ('mssql' + $version.Major + '.MSSQLSERVER'); \
    # if ($env:TYPE -eq 'exp') { \
    #     $id = ('mssql' + $version.Major + '.SQLEXPRESS'); \
    # } \
    Set-itemproperty -path ('HKLM:\software\microsoft\microsoft sql server\' + $id + '\mssqlserver\supersocketnetlib\tcp\ipall') -name tcpdynamicports -value '' ; \
    Set-itemproperty -path ('HKLM:\software\microsoft\microsoft sql server\' + $id + '\mssqlserver\supersocketnetlib\tcp\ipall') -name tcpdynamicports -value '' ; \
    Set-itemproperty -path ('HKLM:\software\microsoft\microsoft sql server\' + $id + '\mssqlserver\supersocketnetlib\tcp\ipall') -name tcpport -value 1433 ; \
    Set-itemproperty -path ('HKLM:\software\microsoft\microsoft sql server\' + $id + '\mssqlserver') -name LoginMode -value 2; 
    # not needed anymore , set it above at  /SQLUSERDBDIR='C:\databases' /SQLUSERDBLOGDIR='C:\databases'; \ 
    # Set-itemproperty -path ('HKLM:\software\microsoft\microsoft sql server\' + $id + '\mssqlserver') -name DefaultData -value $databaseFolder; \
    # Set-itemproperty -path ('HKLM:\software\microsoft\microsoft sql server\' + $id + '\mssqlserver') -name DefaultLog -value $databaseFolder; 

#Step 6: Set and create working directory for script execution
RUN echo 'Step 6: Set and create working directory for script execution at C:\Temp_Scripts'
WORKDIR C:\Temp_Scripts

#Step 7: Copy Start.ps1 to image on scripts directory
RUN echo 'Step 7: Copy Start.ps1 to image on scripts directory'
COPY start.ps1 C:\Temp_Scripts

#Step 8: Run PowerShell script Start.ps1, passing inside the script  the -ACCEPT_EULA parameter with a value of Y
# and $sa_password to create/change sa password
# and json strcuture to attach_dbs
# BUT ACTUALLY we don't inserting these values here , but in Docker-compose.yaml file ore in docker run command
RUN echo 'Step 8: Run PowerShell script Start.ps1, passing inside the script  the -ACCEPT_EULA parameter with \
 a value of Y etc'
CMD .\start.ps1  


