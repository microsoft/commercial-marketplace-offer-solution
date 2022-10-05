# Copyright (c) Microsoft Corporation.
# Licensed under the MIT License.

####################################################################################################
# This script builds out the custom VM image and stores the VHD image in the specified storage     #
# account. The VHD SAS URI is then generated and returned.                                         #
####################################################################################################

Param (
    [Parameter(Mandatory = $True, HelpMessage = "Path to Packer template directory")]
    [String] $templateDirectory
)

# Validate Packer template folder exists
if (-not(Test-Path $templateDirectory)) {
    Write-Error "Please provide a valid Packer template directory path."
    Exit 1
}

$workingDirectory = Get-Item .

Set-Location $templateDirectory

try {
    Write-Output "Creating VHD using packer..."
    $output = packer -machine-readable build .

    # Get the VHD URI from the packer script output
    $uri =  ($output[-1].Split('\n') | Where-Object { $_ -like '*OSDiskUri:*'}).split(' ')[-1]

    if ($uri)
    {
        Write-Output "VHD build complete. VHD URI: $uri"
        Write-Output "Generating SAS URL for VHD..."
        $storageAccountName = $uri.Split('//')[1].Split('.')[0]
        $connectionString = (az storage account show-connection-string --name $storageAccountName -o json | ConvertFrom-Json).connectionString

        $start = (((Get-Date).ToUniversalTime()).addDays(-1)).ToString("yyyy-MM-ddTHH:mm:ssZ")
        $end = (((Get-Date).ToUniversalTime()).addDays(60)).ToString("yyyy-MM-ddTHH:mm:ssZ")

        $sas = az storage container generate-sas --connection-string $connectionString --name "system" --permissions rl --start $start --expiry $end -o tsv
        $sasUri = $uri + "?" + $sas

        $vhdObject = New-Object PSObject -Property @{
            Uri                 = $uri
            SasUri              = $sasUri
            StorageAccountName  = $storageAccountName
        }

        return $vhdObject
    }
    else
    {
        throw [System.Exception]
    }
}
catch
{
    $logFilename = "buildError_" + ((Get-Date).ToUniversalTime()).ToString("yyMMddTHHmmss") + '.log'
    Out-File -InputObject $output -Path $logFilename
    Write-Error "Build failed or produced no artifacts. See log file ($logFilename) for details."
}
finally
{
    Set-Location $workingDirectory
}
