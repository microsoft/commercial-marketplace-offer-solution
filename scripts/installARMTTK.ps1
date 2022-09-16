# Copyright (c) Microsoft Corporation.
# Licensed under the MIT License.

####################################################################################################
# This script downloads and installs the ARM Template Toolkit if it is not already installed.      #
####################################################################################################
Param (
    [Parameter(Mandatory = $False, HelpMessage = "Folder where ARM TTK will be installed")]
    [String] $installFolder = "."
)

# Validate input parameter
if (-not(Test-Path $installFolder)) {
    Write-Error "Please provide a valid install folder path."
    Exit 1
}

$currentFolderPath = Get-Item .

function Import-ARMTTKModule {
    Set-Location $installFolder

    Write-Output "Importing ARM TTK module..."
    Set-Location ".\arm-template-toolkit\arm-ttk"
    Import-Module .\arm-ttk.psd1
    Write-Output "Import complete."
}

if (Test-Path -Path "$installFolder\arm-template-toolkit")
{
    Write-Output "ARM TTK already downloaded. Skipping download."
    Import-ARMTTKModule
    Set-Location $currentFolderPath
}
else
{
    Set-Location $installFolder

    $armttkUrl = "https://aka.ms/arm-ttk-latest"
    $unzipFolder = "arm-template-toolkit"
    $zipFile = "$unzipFolder.zip"

    try
    {
        Write-Output "Downloading ARM TTK..."
        Invoke-WebRequest -Uri $armttkUrl -OutFile $zipFile
        Expand-Archive -LiteralPath $zipFile
        Remove-Item $zipFile

        Write-Output "Importing ARM TTK module..."
        Set-Location ".\$unzipFolder\arm-ttk"
        Import-Module .\arm-ttk.psd1

        Write-Output "Installation complete."
    }
    catch
    {
        Write-Error "There was a problem installing ARM TTK. Cleaning up..."

        if (Test-Path -Path $zipFile)
        {
            Remove-Item $zipFile
        }

        if (Test-Path -Path $unzipFolder)
        {
            Remove-Item $unzipFolder -Recurse -Force
        }

        throw $_.Exception.Message
    }
    finally
    {
        Set-Location $currentFolderPath
    }
}