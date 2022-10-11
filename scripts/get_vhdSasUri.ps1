# Copyright (c) Microsoft Corporation.
# Licensed under the MIT License.

####################################################################################################
# This script allows you to generate a SAS URI for your VHD URI.                                   #
####################################################################################################

Param (
    [Parameter(Mandatory = $True, HelpMessage = "URI of the VHD in your storage account")]
    [String] $uri,
    [Parameter(Mandatory = $False, HelpMessage = "SAS start timestamp")]
    [String] $start = (((Get-Date).ToUniversalTime()).addDays(-1)).ToString("yyyy-MM-ddTHH:mm:ssZ"),
    [Parameter(Mandatory = $False, HelpMessage = "SAS expiry timestamp")]
    [String] $end = (((Get-Date).ToUniversalTime()).addDays(60)).ToString("yyyy-MM-ddTHH:mm:ssZ")
)

try
{
    $uriParts = $uri.Split('?')
    if (($uriParts.Length -gt 1) -And ("" -ne $uriParts[1]))
    {
        # URI already has a SAS token
        return $uri
    }

    $uri = $uriParts[0]
    $vhdStorageAccountName = $uri.Split('//')[1].Split('.')[0]
    $connectionString = (az storage account show-connection-string --name $vhdStorageAccountName -o json | ConvertFrom-Json).connectionString

    $sas = az storage container generate-sas --connection-string $connectionString --name "system" --permissions rl --start $start --expiry $end -o tsv
    $sasUri = $uri + "?" + $sas
    return $sasUri
}
catch
{
    Write-Error "There was a problem generating the SAS URI. Please check the URI and try again."
    Exit 1
}
