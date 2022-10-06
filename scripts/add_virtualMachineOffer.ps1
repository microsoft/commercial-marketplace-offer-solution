# Copyright (c) Microsoft Corporation.
# Licensed under the MIT License.

####################################################################################################
# This script allows you to deploy your virtual machine (VM) offer to Microsoft Partner Center     #
# using the Azure Partner Portal CLI and a custom image. If provided, the offer logos are uploaded #
# to a new container in the storage account and generates the required SAS tokens for each logo.   #
# It then generates a SAS token for the VHD image. The offer is then created using the provided    #
# offer configuration file.                                                                        #
####################################################################################################

Param (
    [Parameter(Mandatory = $True, HelpMessage = "URI of the VHD in your storage account")]
    [String] $vhdUri,
    [Parameter(Mandatory = $True, HelpMessage = "Path to the VM offer listing configuration file")]
    [String] $vmOfferConfigFile,
    [Parameter(Mandatory = $False, HelpMessage = "Path to the offer logos")]
    [String] $logosPath = "",
    [Parameter(Mandatory = $False, HelpMessage = "The name of the storage container where logos will be uploaded")]
    [String] $storageAccountName = "",
    [Parameter(Mandatory = $False, HelpMessage = "The name of the storage container where logos will be uploaded")]
    [String] $storageContainer = ""
)

function Get-ListingConfiguration {
    param (
        [String] $offerListingConfigPath
    )

    # Read listing config
    $offerListing = Get-Content $offerListingConfigPath -Raw | ConvertFrom-Json
    $appPath = Split-Path -Path $offerListingConfigPath

    $config = @{
        offerName = $offerListing.id
        appPath = $appPath
        offerListingConfig = Split-Path -Path $offerListingConfigPath -Leaf
        tempListingConfigFile = Join-Path -Path $appPath -ChildPath "tmp_listing_config.json"
    }

    return $config
}

function Get-SASUri {
    param (
        [String] $uri
    )

    $uriParts = $uri.Split('?')
    if (($uriParts.Length -gt 1) -And ("" -ne $uriParts[1]))
    {
        # URI already has a SAS token
        return $uri
    }

    $uri = $uriParts[0]
    $vhdStorageAccountName = $uri.Split('//')[1].Split('.')[0]
    $connectionString = (az storage account show-connection-string --name $vhdStorageAccountName -o json | ConvertFrom-Json).connectionString

    $start = (((Get-Date).ToUniversalTime()).addDays(-1)).ToString("yyyy-MM-ddTHH:mm:ssZ")
    $end = (((Get-Date).ToUniversalTime()).addDays(60)).ToString("yyyy-MM-ddTHH:mm:ssZ")

    $sas = az storage container generate-sas --connection-string $connectionString --name "system" --permissions rl --start $start --expiry $end -o tsv
    $sasUri = $uri + "?" + $sas

    return $sasUri
}

if (Test-Path -Path $vmOfferConfigFile)
{
  Write-Output "VM Offer Listing Configuration file found. Using it."
}
else
{
  Write-Error "VM Offer Listing Configuration file not found. Please specify the path to the VM offer listing file."
  Exit 1
}

if ("" -ne $logosPath)
{
    if (Test-Path -Path $logosPath)
    {
        Write-Output "Logo path found. Using it."
    }
    else
    {
        Write-Error "Logo path not found. Please specify the path to the logo files."
        Exit 1
    }

    if ("" -eq $storageAccountName)
    {
        Write-Error "Storage account name not specified. Please specify the name of the storage account where the logos will be uploaded."
        Exit 1
    }

    if ("" -eq $storageContainer)
    {
        $storageContainer = "logos"
    }
}

try
{
    Write-Output "Reading configuration files..."
    $config = Get-ListingConfiguration $vmOfferConfigFile

    if ("" -ne $logosPath)
    {
        Write-Output "Uploading logos to $storageContainer in storage account $storageAccountName..."
        ./upload_logos.ps1 -logosPath $logosPath -storageAccountName $storageAccountName -storageContainer $storageContainer -listingConfigFile $vmOfferConfigFile -listingConfigOutputFile $config.tempListingConfigFile
    }
    else
    {
        Write-Output "No logos path specified. Skipping logo upload."
        Copy-Item -Path $vmOfferConfigFile -Destination $config.tempListingConfigFile
    }

    # Use the current execution context to replace the VHD URI variable in the JSON listing config
    Write-Output "Updating offer listing configuration with VHD SAS URI..."
    $vhdSasUri = Get-SASUri $vhdUri
    $offerListingConfigRaw = Get-Content $config.tempListingConfigFile -Raw
    $offerListingConfig = $ExecutionContext.InvokeCommand.ExpandString($offerListingConfigRaw)
    Out-File -InputObject $offerListingConfig -FilePath $config.tempListingConfigFile -Force

    Write-Output "Creating the virtual machine offer..."
    $cliOutput = azpc vm create --name $config.offerName --config-json "tmp_listing_config.json" --app-path $config.appPath

    if (($LASTEXITCODE -ne 0) -or ($cliOutput -contains "ConnectionError")) {
        throw $cliOutput
    }

    Write-Output "Virtual Machine offer successfully created!"
    Exit 0
}
catch
{
    Write-Error "There was an issue creating your virtual machine offer, see below for details:"
    Write-Error $_.ErrorDetails.Message
    Exit 1
}
finally
{
    if (Test-Path -Path $config.tempListingConfigFile)
    {
        Remove-Item -Path $config.tempListingConfigFile
    }

    Exit 0
}