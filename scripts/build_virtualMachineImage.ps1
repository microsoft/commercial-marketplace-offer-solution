# Copyright (c) Microsoft Corporation.
# Licensed under the MIT License.

####################################################################################################
# This script allows you to create a Windows Server 2019 virtual machine image.                    #
# A packer script builds out the custom VM image and stores the VHD image in the provided storage  #
# account. A managed image is then created in the provided storage account, ready for use.         #
####################################################################################################

Param (
    [Parameter(Mandatory = $True, HelpMessage = "Path to solution assets folder")]
    [String] $assetsFolder,
    [Parameter(HelpMessage = "Is this script running from an Azure Devops Pipeline? ('False' by default)")]
    [Boolean] $isADOPipeline = $False
)

# Validate input parameter
if (-not(Test-Path $assetsFolder)) {
    Write-Error "Please provide a valid assets folder path."
    Exit 1
}

$scriptFolder = Get-Item .

Set-Location $assetsFolder

try {
    Write-Output 'Creating VHD using packer...'
    $output = packer -machine-readable build .

    # Get the VHD URI from the packer script output
    $uri =  ($output[-1].Split('\n') | Where-Object { $_ -like '*OSDiskUri:*'}).split(' ')[-1]

    if ($uri)
    {
        Write-Output "VHD build complete: $uri"

        # If run in Azure Devops Pipeline, set the output variable
        if ($isADOPipeline) {
            Write-Output("##vso[task.setvariable variable=vhdUri;isOutput=true]$uri")
        }

        return $uri

    } else
    {
        throw [System.Exception]
    }

} catch
{
    if ($isADOPipeline) {
        Write-Error "Build failed or produced no artifacts. See details below: $output"
    } else {
        $logFilename = "buildError_" + ((Get-Date).ToUniversalTime()).ToString("yyMMddTHHmmss") + '.log'
        Out-File -InputObject $output -Path $logFilename
        Write-Error "Build failed or produced no artifacts. See log file ($logFilename) for details."
    }

}
finally
{
    Set-Location $scriptFolder
}