# Copyright (c) Microsoft Corporation.
# Licensed under the MIT License.

####################################################################################################
# This script deploys your Solution Template offer to your logged in Azure subscription.           #
# IMPORTANT! Log into your Azure account:                                                          #
#   az login                                                                                       #
#   az account set -s <SUBSCRIPTION ID>                                                            #
####################################################################################################
Param (
    [Parameter(Mandatory = $True, HelpMessage = "Path to solution assets folder")]
    [String] $assetsFolder
)

function Get-Password {
    $TokenSet = @{
        Upper = [Char[]]'ABCDEFGHIJKLMNOPQRSTUVWXYZ'
        Lower = [Char[]]'abcdefghijklmnopqrstuvwxyz'
        Number = [Char[]]'0123456789'
        Symbol = [Char[]]'~!@#$%^&*_-+=`|\(){}[]:;"''<>,.?/'
    }

    $UpperSet = Get-Random -Count 5 -InputObject $TokenSet.Upper
    $LowerSet = Get-Random -Count 5 -InputObject $TokenSet.Lower
    $NumberSet = Get-Random -Count 5 -InputObject $TokenSet.Number
    $SymbolSet = Get-Random -Count 5 -InputObject $TokenSet.Symbol

    $StringSet = $UpperSet + $LowerSet + $NumberSet + $SymbolSet
    $password = (Get-Random -Count 15 -InputObject $StringSet) -join ''

    return $password
}

$workingDirectory = Get-Item .
$subscriptionId = az account show --query id
$releaseFolder = ("test_" + (get-date).ToString("MMddyyhhmmss"))
$resourceGroup = ("test_" + (get-date).ToString("MMddyyhhmmss") + "_rg")
$storageAccountName = ("sa" + (get-date).ToString("MMddyyhhmmss"))
$location = "westus"

$appContentsFolder = Resolve-Path "$assetsFolder/app-contents"
$parametersFile = "parameters.json"

try
{
    # Generate parameters
    $parameters = Get-Content -Path "$appContentsFolder/parameters.json.tmpl" -Raw | ConvertFrom-Json
    $parameters.adminPassword.value = Get-Password

    # Create storate account
    Write-Output "Deploying storage account to Azure subscription $subscriptionId..."
    az group create --name $resourceGroup --location $location
    az storage account create -n $storageAccountName -g $resourceGroup -l $location --sku Standard_LRS

    Set-Location ../../../scripts

    # Generate parameters.json
    Set-Content -Path $parametersFile -Value ($parameters | ConvertTo-Json -Depth 100)

    # Package and deploy the solution
    Write-Output "Deploying resources to Azure subscription $subscriptionId..."
    ./package.ps1 -assetsFolder $appContentsFolder -releaseFolder $releaseFolder
    ./devDeploy.ps1 -resourceGroup $resourceGroup -location $location -assetsFolder "$releaseFolder/assets" -parametersFile $parametersFile -storageAccountName $storageAccountName

    $deployments = az deployment group list --resource-group $resourceGroup  | ConvertFrom-Json
    $deployments | ForEach-Object {
        $deployment = $_
        if ($deployment.properties.provisioningState -ne "Succeeded")
        {
            throw "Deployment $deployment.name failed with error: $($deployment.properties.error.details[0].message)"
        }
    }
}
catch
{
    Write-Error $_.Exception.Message
    Exit 1
}
finally
{
    # Clean up
    Write-Output "Cleaning up resources..."
    Remove-Item -Path $parametersFile
    Remove-Item -Path $releaseFolder -Recurse
    az group delete --name $resourceGroup -y

    Set-Location $workingDirectory
}
