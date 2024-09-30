<#
This script will help to address errors such as those below below when trying to build Windows container images with certain verions of SQL Server
This occurs with SQL 2016, 2017 as well as SQL 2022 if updates are included in the build
This script is specific to SQL 2022 and will extract the needed files from the a CU update without needing to install the update anywhere
The files will be packaged in a tar file that can be added to the image build
For 2016/2017, WizardFrameworkLite is also required and the missing files can be taken from the installation media
#>

<#
03/16/2023 09:11:46.863 [13296]: Detailed info about C:\Windows\Microsoft.Net\assembly\GAC_MSIL\Microsoft.NetEnterpriseServers.ExceptionMessageBox.resources\v4.0_16.0.0.0_de_89845dcd8080cc91
03/16/2023 09:11:46.863 [13296]: 	File attributes: ffffffff
03/16/2023 09:11:46.864 [13296]: 	Security info:
MSI (s) (F0:84) [09:11:46:865]: Assembly Error:The system cannot find the file specified.

03/16/2023 15:21:31.098 [6976]: Detailed info about C:\Windows\Microsoft.Net\assembly\GAC_MSIL\Microsoft.SqlServer.CustomControls.resources\v4.0_16.0.0.0_de_89845dcd8080cc91
03/16/2023 15:21:31.098 [6976]: 	File attributes: ffffffff
03/16/2023 15:21:31.098 [6976]: 	Security info:
MSI (s) (40:90) [15:21:31:100]: Assembly Error:The system cannot find the file specified.
#>

##
## Run the CU installer to extract the setup files, leave the setup window as-is (do not proceed or cancel) until this script is done
## Update the $cuname and $extracted_to_path variables below, then run this script
## Once this script is done, you can complete or cancel the SQL update installer
## The Dockerfile should contain a copy and add commands to copy and extract the tar file into the container's c:\windows folder
## Example: My docker build folder has a "build" sub-folder with the SQL installer, CU update file and tar file and my Dockerfile has these commands:
# COPY build /build/
# ADD build/assembly_CU12.tar C:/
#
## The tar file contents look like this (note the relative path), but with additional files/folders for the other languages and DLLs

<#
C:\> tar -tf assembly_CU12.tar
Windows/Microsoft.Net/
Windows/Microsoft.Net/assembly/
Windows/Microsoft.Net/assembly/GAC_MSIL/
Windows/Microsoft.Net/assembly/GAC_MSIL/Microsoft.NetEnterpriseServers.ExceptionMessageBox.resources/
Windows/Microsoft.Net/assembly/GAC_MSIL/Microsoft.SqlServer.CustomControls.resources/
Windows/Microsoft.Net/assembly/GAC_MSIL/Microsoft.SqlServer.CustomControls.resources/v4.0_16.0.0.0_de_89845dcd8080cc91/
Windows/Microsoft.Net/assembly/GAC_MSIL/Microsoft.SqlServer.CustomControls.resources/v4.0_16.0.0.0_de_89845dcd8080cc91/Microsoft.Sqlserver.CustomControls.Resources.dll
....
#>

Clear-Host
## Update these two variables
$cuname = "CU15"
$extracted_to_path = "C:\c4d360c0e0e01d0bee37842e9d" # Path where the updated has extracted itself when the .exe is run

$ErrorActionPreference = "Stop"
$dest_folder = "C:\sql_$($cuname)_$((New-Guid).Guid)"
$ss_msi_path = "$extracted_to_path\1033_ENU_LP\x64\Setup\SQLSUPPORT.MSI"

if (Test-Path $dest_folder) {
    $null = Remove-Item -Path $dest_folder -Recurse -Force
}
$null = New-Item -ItemType Directory -Path $dest_folder

# The msiexec command is asynchronous, prompt user to continue when it's done
Invoke-Expression "msiexec.exe /quiet /qn /a $ss_msi_path /qb TARGETDIR=`"$dest_folder`""
$null = Read-Host -Prompt "Press a key when extraction is done"

$prefix = "v4.0_16.0.0.0_"
$suffix = "_89845dcd8080cc91"

$srcfolder = "$dest_folder\Windows\Gac"
$destfolder_ne = "$dest_folder\Windows\Microsoft.Net\assembly\GAC_MSIL\Microsoft.NetEnterpriseServers.ExceptionMessageBox.resources"
$destfolder_cc = "$dest_folder\Windows\Microsoft.Net\assembly\GAC_MSIL\Microsoft.SqlServer.CustomControls.resources"

foreach ($lang_folder in $(Get-ChildItem $srcfolder -Directory)) {
    $lang = $lang_folder.Name
    $newfolder_ne = "$destfolder_ne\$prefix$lang$suffix"
    $newfolder_cc = "$destfolder_cc\$prefix$lang$suffix"
    $null = New-Item -ItemType Directory -Path $newfolder_ne -ErrorAction SilentlyContinue
    $null = New-Item -ItemType Directory -Path $newfolder_cc -ErrorAction SilentlyContinue
    $null = Copy-Item "$srcfolder\$lang\Microsoft.NetEnterpriseServers.ExceptionMessageBox.Resources.dll" $newfolder_ne -ErrorAction SilentlyContinue
    $null = Copy-Item "$srcfolder\$lang\Microsoft.Sqlserver.CustomControls.Resources.dll" $newfolder_cc -ErrorAction SilentlyContinue
}
$pushd = (Get-Location).Path
Set-Location $dest_folder
Remove-Item -Path "c:\assembly_$cuname.tar" -Force -ErrorAction SilentlyContinue
Invoke-Expression "tar -cf c:\assembly_$cuname.tar Windows\Microsoft.Net"
Write-Host "Created c:\assembly_$cuname.tar. Copy the file and update the Dockerfile with the latest CU name. Remove $dest_folder after validation"
Set-Location $pushd