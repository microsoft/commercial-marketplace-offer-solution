# Copyright (c) Microsoft Corporation.
# Licensed under the MIT License.

####################################################################################################
# This script allows you to delete the VHD from your storage account.                              #
####################################################################################################

Param (
    [Parameter(Mandatory = $True, HelpMessage = "URI of the VHD in your storage account")]
    [String] $vhdUri
)

function Get-ConnectionString {
    param (
        [String] $uri
    )

    $noSasUri = $uri.Split('?')[0]
    $storageAccountName = $noSasUri.Split('//')[1].Split('.')[0]
    $connectionString = (az storage account show-connection-string --name $storageAccountName -o json | ConvertFrom-Json).connectionString

    return $connectionString
}

try
{
    Write-Output "Deleting VHD at $vhdUri..."
    $connString = Get-ConnectionString $vhdUri

    $blobName = $vhdUri.Split('/system/')[1]
    $blobJsonName = $blobName.Replace('.vhd', '.json').Replace('-osDisk', '-vmTemplate')
    az storage blob delete -c system -n "$blobName" --connection-string $connString
    az storage blob delete -c system -n "$blobJsonName" --connection-string $connString

    Write-Output "VHD successfully deleted."
    Exit 0
}
catch
{
    Write-Error "There was an issue deleting the VHD from your storage account."
    Exit 1
}
