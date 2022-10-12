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
    [Parameter(Mandatory = $True, HelpMessage = "The name of storage account where logos will be uploaded")]
    [String] $storageAccountName,
    [Parameter(Mandatory = $True, HelpMessage = "The path to the VM listing config file")]
    [String] $listingConfigFile,
    [Parameter(Mandatory = $False, HelpMessage = "The name of the storage container where logos will be uploaded")]
    [String] $storageContainer = "logos",
    [Parameter(Mandatory = $False, HelpMessage = "The path to the VM listing config output file")]
    [String] $listingConfigOutputFile = ""
)

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

if ($listingConfigOutputFile -eq "")
{
    $listingConfigOutputFile = $listingConfigFile
}

try
{
    Write-Output "Creating a storage container to store the logos..."
    $connectionString = (az storage account show-connection-string --name $storageAccountName -o json | ConvertFrom-Json).connectionString
    az storage container create --name $storageContainer --connection-string $connectionString

    $start = (((Get-Date).ToUniversalTime()).addDays(-1)).ToString("yyyy-MM-ddTHH:mm:ssZ")
    $end = (((Get-Date).ToUniversalTime()).addDays(90)).ToString("yyyy-MM-ddTHH:mm:ssZ")

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
                az storage blob upload -n $logoName -c $storageContainer -f $logoPath --connection-string $connectionString --overwrite $True
            } catch {
                Write-Error "There was an issue uploading your logo $logoName, see below for details: $($_.ErrorDetails.Message)"
                Exit 1
            }

            try {
                # Generate the SAS token to access the logo
                $logoSas = az storage blob generate-sas -c $storageContainer -n $logoName --connection-string $connectionString --https-only --permissions r --start $start --expiry $end -o tsv
            } catch {
                Write-Error "There was an issue creating a SAS token for your logo $logoName, see below for details: $($_.ErrorDetails.Message)"
                Exit 1
            }

            $logoUri = "https://" + $storageAccountName + ".blob.core.windows.net/" + $storageContainer + "/" + $logoName + "?" + $logoSas

            $logoKey = "microsoft-azure-marketplace." + $size + "Logo"
            $variableName = $size + "LogoUri"
            $listingConfig.definition.offer.$logoKey = $logoUri
            Write-Output "::set-output name=$variableName::$logoUri"
            Write-Output "Successfully uploaded $logoName logo."
        }
    }

    $listingConfig | ConvertTo-Json -Depth 10 | Out-File -FilePath $listingConfigOutputFile
}
catch
{
    Write-Error "There was an issue uploading your logos, see below for details: $($_.ErrorDetails.Message)"
    Exit 1
}
