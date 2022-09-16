# Copyright (c) Microsoft Corporation.
# Licensed under the MIT License.

Param (
  [Parameter(Mandatory = $True, HelpMessage = "Path to solution assets folder")]
  [String] $assetsFolder,
  [Parameter(Mandatory = $False, HelpMessage = "Path to release folder where zip file will be generated")]
  [String] $releaseFolder = ("release_" + (get-date).ToString("MMddyyhhmmss")),
  [Parameter(Mandatory = $False, HelpMessage = "Offer ID to set in the ARM template")]
  [String] $offerId = ""
)

# Validate input parameters
if (-not(Test-Path $assetsFolder)) {
    Write-Error "Please provide a valid assets folder path."
    Exit 1
}

$scriptFolder = Get-Item .

New-Item -Path $releaseFolder -ItemType directory -Force
New-Item -Path "$releaseFolder\assets" -ItemType directory -Force
$tempFolderPath = Get-Item "$releaseFolder\assets"

Set-Location $assetsFolder
$assetsFolderPath = Get-Item .

az bicep build --file mainTemplate.bicep --outdir $tempFolderPath --only-show-errors

Set-Location $tempFolderPath

if ("" -ne $offerId)
{
  # Replace Offer ID in mainTemplate.json
  $mainTemplateFile = "mainTemplate.json"
  $partnerCenterId = "pid-$offerId-partnercenter"
  ((Get-Content $mainTemplateFile) -Replace 'pid-[A-z0-9]{8}-[A-z0-9]{4}-[A-z0-9]{4}-[A-z0-9]{4}-[A-z0-9]{12}-partnercenter', $partnerCenterId) | Out-File -Force $mainTemplateFile
}

Copy-Item "$assetsFolderPath\createUiDefinition.json"
Copy-Item "$assetsFolderPath\*.ps1"

Set-Location "..\"
Compress-Archive -Update -Path "assets\createUiDefinition.json" -DestinationPath "marketplacePackage.zip"
Compress-Archive -Update -Path "assets\mainTemplate.json" -DestinationPath "marketplacePackage.zip"
Compress-Archive -Update -Path "assets\*.ps1" -DestinationPath "marketplacePackage.zip"

Set-Location $scriptFolder

Write-Output "Release zip file created: $releaseFolder\marketplacePackage.zip"