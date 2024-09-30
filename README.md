# MS SQL Server container image version 2022 + CU15 Build version 16.0.4145.4
An **unofficial**, **unsupported** and **in no way connected to Microsoft** container image for MS SQL Server

~~Resulting container images can be found at the Docker hub ([MS SQL Developer Edition](https://hub.docker.com/r/tobiasfenster/mssql-server-dev-unsupported/tags?page=1&ordering=last_updated) / [MS SQL Express](https://hub.docker.com/r/tobiasfenster/mssql-server-exp-unsupported/tags?page=1&ordering=last_updated))~~ **Update:** I was told by Microsoft that sharing the images on the Docker hub violates the EULA, so I had to remove them.

More background and instructions for usage in [this blog post](https://tobiasfenster.io/ms-sql-server-in-windows-containers)

# Update 30/09/2024:
This version was updated and modified to support Microsoft SQL Server 2022 Developer Edition (https://download.microsoft.com/download/c/c/9/cc9c6797-383c-4b24-8920-dc057c1de9d3/SQL2022-SSEI-Dev.exe).
This version will update the container to Cumulative Update 15 (CU15) build version 16.0.4145.4 (https://download.microsoft.com/download/9/6/8/96819b0c-c8fb-4b44-91b5-c97015bbda9f/SQLServer2022-KB5041321-x64.exe)

# Update 02.07.2024:
This version was updated by me, Isaac Kramer based on the work of Tobias.
This version update the container to Sql Server 2022 + Comulative Update 11 (CU11) Build version 16.0.4105.2
for WINDOWS(!) container.

The steps for build are explaind in the Dockerfile.

You need 3 setup folders on the host to be ready for the build as seen in the Dockerfile:

1. The main SQL Server 2022 Developer setup media extracted so that the root SETUP.EXE will be in 'SQLSetupMedia\SQLDEV_x64_ENU\' folder.
2. The CU update (in this case CU15) EXE file (don't need to be extacted) in '\SQLSetupMedia\CU\CU15\SQLServer2022-KB5041321-x64.exe'
3. Due to strange bug that the servercore 2022 image don't have old server controls (used to be at 1809) you must have The Missing Server control files/folders - which is a bunch of folders which include old control dll's under 'Missing' folder. Explained over at https://github.com/microsoft/mssql-docker/issues/540. 4 subfolders need to be in the folder '\SQLSetupMedia\CU\CU15\Missing\' to fix this strange bug i mentioned there.
you can get them from an old SQL Server installation from the GAC folder.
For convenience, I've uploaded a zip file with all the folders which you can just drop it there. Please look at the zip file 'OldServerControlsFolders.zip'

SQL Server 2022 Developer for Windows container build 16.0.4145.4. This should also work for other editions of SQL Server.
<br/>
Cheers.
