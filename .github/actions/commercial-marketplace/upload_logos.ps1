# Copyright (c) Microsoft Corporation.
# Licensed under the MIT License.

####################################################################################################
# This script uploads your logos to a temporary storage container so it can be referenced in the   #
# virtual machine offer listing configuration. The offer logos are uploaded to a new container in  #
# the storage account and generates the required SAS tokens for each logo. It then generates a SAS #
# token for the VHD image.                                                                         #
####################################################################################################

Param (
    [Parameter(Mandatory = $True, HelpMessage = "Path to the offer logos")]
    [String] $logosPath,
    [Parameter(Mandatory = $True, HelpMessage = "Storage connection string")]
    [String] $storageConnectionString,
    [Parameter(Mandatory = $True, HelpMessage = "The path to the listing config file")]
    [String] $listingConfigFile,
    [Parameter(Mandatory = $False, HelpMessage = "Storage container name where logos will be uploaded")]
    [String] $storageContainer = "logos"
)

function Get-Configuration {
    param (
        [String] $connectionString
    )

    # Get storage account name and key from connection string
    $storageParts = $connectionString.Split(';')
    $storageAccountName = $storageParts[1].Split('=',2)[1]
    $storageAccountKey = $storageParts[2].Split('=',2)[1]

    $config = @{
        storageAccountName = $storageAccountName
        storageAccountKey = $storageAccountKey
    }

    return $config
}

if (Test-Path -Path $logosPath)
{
    Write-Output "Logos folder path found. Using it."
}
else
{
    Write-Error "Logos folder path not found. Please specify the path to the logo files."
    Exit 1
}

if (Test-Path -Path $listingConfigFile)
{
    Write-Output "Listing config file found. Using it."
}
else
{
    Write-Error "Listing config file not found. Please specify the path to the listing config file."
    Exit 1
}

try
{
    Write-Output "Getting storage configuration..."
    $config = Get-Configuration $storageConnectionString

    $start = (((Get-Date).ToUniversalTime()).addDays(-1)).ToString("yyyy-MM-ddTHH:mm:ssZ")
    $end = (((Get-Date).ToUniversalTime()).addDays(90)).ToString("yyyy-MM-ddTHH:mm:ssZ")

    Write-Output "Creating a storage container to store the logos..."
    az storage container create --name $storageContainer --account-name $config.storageAccountName --account-key $config.storageAccountKey

    $listingConfig = Get-Content $listingConfigFile -Raw | ConvertFrom-Json

    $sizes = @('small', 'medium', 'large', 'wide')
    foreach ($size in $sizes)
    {
        $logoName = "$size.png"
        $logoPath = Join-Path -Path $logosPath -ChildPath $logoName
        if (Test-Path $logoPath) {
            Write-Output "Uploading $logoName logo to the $storageContainer container..."
            try {
                # Upload the logo to the container
                $logoResponse = az storage blob upload -n $logoName -c $storageContainer -f $logoPath --account-name $config.storageAccountName --account-key $config.storageAccountKey --overwrite $True
            } catch {
                Write-Output "Cleaning up..."
                az storage container delete --name $storageContainer --account-name $config.storageAccountName --account-key $config.storageAccountKey
                Write-Error "There was an issue uploading your logo $logoName, see below for details: $($_.ErrorDetails.Message)"
                Exit 1
            }

            try {
                # Generate the SAS token to access the logo
                $logoSas = az storage blob generate-sas -c $storageContainer -n $logoName --https-only --permissions r --start $start --expiry $end -o tsv --account-name $config.storageAccountName --account-key $config.storageAccountKey
            } catch {
                Write-Output "Cleaning up..."
                az storage container delete --name $storageContainer --account-name $config.storageAccountName --account-key $config.storageAccountKey
                Write-Error "There was an issue creating a SAS token for your logo $logoName, see below for details: $($_.ErrorDetails.Message)"
                Exit 1
            }

            $logoUri = "https://" + $config.storageAccountName + ".blob.core.windows.net/" + $storageContainer + "/" + $logoName + "?" + $logoSas

            $logoKey = "microsoft-azure-marketplace." + $size + "Logo"
            $listingConfig.definition.offer.$logoKey = $logoUri
            Write-Output "::set-output name=smallLogoUri::$logoUri"
            Write-Output "Successfully uploaded $logoName logo."
        }
    }

    $listingConfig | ConvertTo-Json -Depth 10 | Out-File -FilePath $listingConfigFile
}
catch
{
    Write-Error "There was an issue uploading your logos, see below for details: $($_.ErrorDetails.Message)"
    Exit 1
}
