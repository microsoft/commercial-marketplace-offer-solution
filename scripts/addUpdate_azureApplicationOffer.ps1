# Copyright (c) Microsoft Corporation.
# Licensed under the MIT License.

Param (
    [Parameter(Mandatory = $True, HelpMessage = "Offer Type: st or ma")]
    [String] $offerType,
    [Parameter(Mandatory = $True, HelpMessage = "Path to solution assets folder")]
    [String] $assetsFolder,
    [Parameter(Mandatory = $True, HelpMessage = "The name of the offer to create or update")]
    [String] $offerName,
    [Parameter(Mandatory = $True, HelpMessage = "The name of the plan to create or update")]
    [String] $planName
)

if ($offerType -ne "st" -and $offerType -ne "ma")
{
    Write-Error "Invalid offer type entered. Please specify the offer type as st or ma."
    Exit 1
}

if (Test-Path -Path $assetsFolder)
{
    Write-Output "Assets folder found. Using it."
}
else
{
    Write-Error "Please provide a valid assets folder path."
    Exit 1
}

$workingDirectory = Get-Item .
$listingConfigFile = "listing_config.json"
$releaseFolder = "release_" + (get-date).ToString("MMddyyhhmmss")

try
{
    # Package solution
    Write-Output "Packaging solution for offer $offerName..."
    ./package.ps1 -assetsFolder "$assetsFolder/app-contents" -releaseFolder $releaseFolder
    Copy-Item -Path "$releaseFolder/marketplacePackage.zip" -Destination $assetsFolder -Force
    Remove-Item -Path $releaseFolder -Recurse -Force

    Set-Location $assetsFolder

    # Get Reseller Configuration
    Write-Output "Setting reseller configuration for offer $offerName..."
    $listingConfig = Get-Content $listingConfigFile -Raw | ConvertFrom-Json
    $resellerConfig = $listingConfig.resell.resellerChannelState
    if ($null -eq $resellerConfig)
    {
        $resellerConfig = "Disabled"
    }
    $env:RESELLER_CHANNEL = $resellerConfig

    # Create offer
    Write-Output "Creating offer $offerName..."
    azpc $offerType create --update --name $offerName --config-json $listingConfigFile --app-path "."
    Write-Output "Offer $offerName created or updated."

    # Create plan
    Write-Output "Creating plan $planName for offer $offerName..."
    azpc $offerType plan create --update --name $offerName --plan-name $planName --config-json $listingConfigFile --app-path "."
    Write-Output "Plan $planName for offer $offerName created or updated."

    # Clean up
    Remove-Item "marketplacePackage.zip"
    Exit 0
}
catch
{
    Write-Output "There was a problem creating or updating the offer $offerName."
    Exit 1
}
finally
{
    Set-Location $workingDirectory

    if (Test-Path -Path $releaseFolder)
    {
        Remove-Item -Path $releaseFolder -Recurse -Force
    }

    $marketplaceZipPath = Join-Path -Path $assetsFolder -ChildPath "marketplacePackage.zip"
    if (Test-Path -Path $marketplaceZipPath)
    {
        Remove-Item -Path $marketplaceZipPath -Force
    }
}
