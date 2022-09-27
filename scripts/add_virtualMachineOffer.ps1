# Copyright (c) Microsoft Corporation.
# Licensed under the MIT License.

####################################################################################################
# This script allows you to deploy your virtual machine (VM) offer to Microsoft Partner Center     #
# using the Azure Partner Portal CLI using a custom image.                                         #
# The offer logos are uploaded to a new container in the storage account and generates the         #
# required SAS tokens for each logo. It then generates a SAS token for the VHD image.              #
# The offer is then created using the offer configuration files.                                   #
#                                                                                                  #
# IMPORTANT! The following files are required to run this script.                                  #
# Please use the templates provided:                                                               #
#   - config.json                                                                                  #
#   - partnerCenterConfig.yml                                                                      #
####################################################################################################

Param (
    [Parameter(Mandatory = $True, HelpMessage = "URI of the VHD in your storage account")]
    [String] $vhdUri,
    [Parameter(Mandatory = $True, HelpMessage = "Path to the config file")]
    [String] $configFile = "config.json",
    [Parameter(Mandatory = $True, HelpMessage = "Path to the VM offer listing configuration file")]
    [String] $vmOfferConfigFile,
    [Parameter(Mandatory = $True, HelpMessage = "Path to the offer logos")]
    [String] $logoPath
)

function Get-Configuration {
    param (
        [String] $configJsonPath,
        [String] $offerListingConfigPath,
        [String] $logoPath
    )
    # Read configuration
    $configJson = Get-Content $configJsonPath -Raw | ConvertFrom-Json
    $offerListing = Get-Content $offerListingConfigPath -Raw | ConvertFrom-Json

    $storageAccountName = $configJson.azure.storageAccountName
    $storageAccountKey = $configJson.azure.storageAccountKey

    $config = @{
        storageAccountName = $storageAccountName
        storageAccountKey = $storageAccountKey
        logos = @{
            small = "$logoPath/small.png"
            medium = "$logoPath/medium.png"
            large = "$logoPath/large.png"
            wide = "$logoPath/wide.png"
        }
        offerName = $offerListing.id
        appPath = Split-Path -Path $offerListingConfigPath
        offerListingConfig = Split-Path -Path $offerListingConfigPath -Leaf
    }

    return $config
}

if (Test-Path -Path $configFile)
{
  Write-Output "Config file found. Using it."
}
else
{
  Write-Error "Config file not found. Please specify the path to the config file."
  Exit 1
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

if (Test-Path -Path $logoPath)
{
  Write-Output "Logo path found. Using it."
}
else
{
  Write-Error "Logo path not found. Please specify the path to the logo files."
  Exit 1
}

Write-Output "Reading configuration files..."
$config = Get-Configuration $configFile $vmOfferConfigFile $logoPath

# Generate config.yml file
$configYmlPath = "config.yml"
Write-Output "Generating Partner Center CLI config file: $configYmlPath..."
python ./helpers/generatePCYaml.py $configFile $configYmlPath

$logoContainerName = "logos"
$start = (((Get-Date).ToUniversalTime()).addDays(-1)).ToString("yyyy-MM-ddTHH:mm:ssZ")
$end = (((Get-Date).ToUniversalTime()).addYears(1)).ToString("yyyy-MM-ddTHH:mm:ssZ")

Write-Output "Creating a storage container to store the logos..."

$containerResponse = az storage container create --name $logoContainerName --account-name $config.storageAccountName --account-key $config.storageAccountKey | ConvertFrom-Json

if ($containerResponse.created) {
    Write-Output "Logo storage container successfully created..."

    Write-Output "Uploading the logos to the $logoContainerName container..."
    $logos = $config.logos

    # Iterate over all of the logos and upload them to the container
    foreach ($logo in $logos.GetEnumerator()) {
        $logoName = $logo.Name
        $logoPath = $logo.Value

        if (Test-Path $logoPath) {
            try {
                # Create the logo in the container
                $logoResponse = az storage blob upload -n $logoName -c logos -f $logoPath --account-name $config.storageAccountName --account-key $config.storageAccountKey
            } catch {
                Write-Output "Cleaning up..."
                az storage container delete --name $logoContainerName --account-name $config.storageAccountName --account-key $config.storageAccountKey
                Write-Error "There was an issue creating your logo $logoName, see below for details: " + $_.ErrorDetails.Message
                exit
            }

            try {
                # Generate the SAS token to access the logo
                $logoSas = az storage blob generate-sas -c $logoContainerName -n $logoName --https-only --permissions r --start $start --expiry $end -o tsv --account-name $config.storageAccountName --account-key $config.storageAccountKey
            } catch {
                Write-Output "Cleaning up..."
                az storage container delete --name $logoContainerName --account-name $config.storageAccountName --account-key $config.storageAccountKey
                Write-Error "There was an issue creating a SAS token for your logo $logoName, see below for details: " + $_.ErrorDetails.Message
                exit
            }

            $logoUri = "https://" + $config.storageAccountName + ".blob.core.windows.net/" + $logoContainerName + "/" + $logoName + "?" + $logoSas
            Write-Output "Successfully uploaded $logoName logo."
        } else {
            # If the logo path does not exist, skip it
            $logo.Value = ""
        }

        # Create a dynamic variable for each logo path
        New-Variable -Name "$($logoName)LogoPath" -Value $logoUri -Force
    }
} else {
    Write-Error ("There was an issue creating the $logoContainerName container, see below for details: $($_.ErrorDetails.Message)")
    exit 1
}

Write-Output "Getting VHD SAS token..."
$vhdSas = az storage container generate-sas --account-name $config.storageAccountName --account-key $config.storageAccountKey --name "system" --permissions rl --start $start --expiry $end -o tsv
$vhdUri = $vhdUri + "?" + $vhdSas

Write-Output "Updating offer listing configuration with VHD and logo URIs..."
$offerListingConfigPath = Join-Path -Path $config.appPath -ChildPath $config.offerListingConfig
$offerListingConfigRaw = Get-Content $offerListingConfigPath -Raw

# Use the current execution context to replace the VHD and logo URI variables in the JSON listing config
$offerListingConfig = $ExecutionContext.InvokeCommand.ExpandString($offerListingConfigRaw)

# Create a new version of the JSON listing config
$parsedOfferListingConfigFile = "parsed_" + $config.offerListingConfig
$parsedOfferListingConfigPath = Join-Path -Path $config.appPath -ChildPath $parsedOfferListingConfigFile

Out-File -InputObject $offerListingConfig -FilePath $parsedOfferListingConfigPath -Force

try {
    Write-Output "Creating the virtual machine offer..."
    $cliOutput = azpc vm create --name $config.offerName --config-yml $configYmlPath --config-json $parsedOfferListingConfigFile --app-path $config.appPath

    if (($LASTEXITCODE -ne 0) -or ($cliOutput -contains "ConnectionError")) {
        throw $cliOutput
    }

    Write-Output "Virtual Machine offer successfully created!"
    exit 0
} catch {
    Write-Error "There was an issue creating your virtual machine offer, see below for details:"
    Write-Error $_.ErrorDetails.Message
    exit 1
} finally {
    Write-Output "Cleaning up..."
    az storage container delete --name $logoContainerName --account-name $config.storageAccountName --account-key $config.storageAccountKey
    Remove-Item $configYmlPath
    exit 0
}