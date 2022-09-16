# Copyright (c) Microsoft Corporation.
# Licensed under the MIT License.

####################################################################################################
# This script downloads and installs the ARM Template Toolkit if it is not already installed.      #
####################################################################################################
Param (
    [Parameter(Mandatory = $True, HelpMessage = "Path to solution template assets folder")]
    [String] $assetsFolder,
    [Parameter(Mandatory = $False, HelpMessage = "Output results to NUnitXml file")]
    [boolean] $outputNUnitXml = $False,
    [Parameter(Mandatory = $False, HelpMessage = "Folder where ARM TTK is installed. If not found, ARM TTK will be installed")]
    [String] $armTTKFolder = "."
)

# Validate input parameters
if (-not(Test-Path $assetsFolder)) {
    Write-Error "Please provide a valid assets folder path."
    Exit 1
}

$assetsFolderPath = Resolve-Path $assetsFolder

$errorCount = 0
try
{
    Write-Output "Installing ARM TTK..."
    ./installARMTTK.ps1 $armTTKFolder

    Write-Output "Generating ARM templates from Bicep templates..."
    $tempFolder = ("temp_" + (get-date).ToString("MMddyyhhmmss"))
    New-Item -Path $tempFolder -ItemType directory -Force
    $tempFolderPath = Get-Item $tempFolder

    Write-Output $assetsFolderPath
    az bicep build --file "$assetsFolderPath/mainTemplate.bicep" --outdir $tempFolderPath --only-show-errors

    Copy-Item "$assetsFolderPath/createUiDefinition.json" $tempFolderPath

    Write-Output "Validating Azure Marketplace package at $tempFolder"
    $armttkScript = "armttk.ps1"
    Set-Content -Path $armttkScript -Value "Test-AzTemplate -TemplatePath $tempFolder -Pester -Skip Secure-Params-In-Nested-Deployments"
    Write-Output (Get-Content -Path $armttkScript)

    if ($outputNUnitXml)
    {
        Invoke-Pester -Script ./$armttkScript -OutputFormat NUnitXml -OutputFile armttk.xml
    }
    else
    {
        $results = Invoke-Pester -Script ./$armttkScript -PassThru
        $errorCount = $results.FailedCount
        if ($errorCount -gt 0)
        {
            Write-Error "Azure Marketplace package validation failed with $errorCount issue(s)."
        }

        Exit $errorCount
    }
}
catch
{
    Write-Error "There was a problem validating the Azure Marketplace package. Exiting."
    Exit 1
}
finally
{
    Write-Output "Cleaning up..."
    Remove-Item armttk.ps1
    Remove-Item $tempFolderPath -Recurse -Force
}