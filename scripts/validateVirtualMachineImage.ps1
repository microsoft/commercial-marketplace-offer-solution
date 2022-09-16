# Copyright (c) Microsoft Corporation.
# Licensed under the MIT License.

####################################################################################################
# This script allows you to validate the virtual machine image created using `imageBuild.ps1`      #
# It will create an image and virtual machine in a temporary resource group, and will use this to  #
# run a set of validations to ensure that the image created meets the latest Azure Marketplace     #
# publishing requirements. Upon completion, the resource group is deleted, and the test results    #
# are output to the console, and exported to a JSON file.                                          #
#                                                                                                  #
# IMPORTANT! A config.json file is needed to run this script. Please use the template provided.    #
####################################################################################################
Param (
    [Parameter(Mandatory = $True, HelpMessage = "URI of the VHD in your Azure storage account")]
    [String] $vhdUri,
    [Parameter(Mandatory = $True, HelpMessage = "Configuration JSON file")]
    [String] $configJsonFile
)
# Read configuration
function Get-Configuration {
    param (
        [String] $configJsonPath
    )
    # Read configuration
    $configJson = Get-Content $configJsonPath -Raw | ConvertFrom-Json

    $config = @{
        storageAccountName =  $configJson.azure.storageAccountName
        tenantId = $configJson.aad.tenantId
        clientId = $configJson.aad.clientId
        clientSecret = $configJson.aad.clientSecret
        region = $configJson.azure.location
        adminUser = "azureadmin"
        adminPassword = $configJson.azure.adminPassword
        resourceGroup = "tempValidateImage"
        companyName = "Contoso"
        imageName = "validateImage"
        vmName = "validateVM"
        dnsName = "validateimagedns" +  ((Get-Date).ToUniversalTime()).ToString("yyyMMddhhmmss")
    }

    return $config
}

# Create & configure virtual machine
function Deploy-VirtualMachineResources {
    param (
        [String] $vhdUri,
        [HashTable] $config
    )
    try {
        # Create image from VHD URI
        az image create -g $config.resourceGroup -n $config.imageName --os-type Windows --storage-sku Standard_LRS --source $vhdUri

    } catch {
        Throw "There was an issue creating the virtual machine image. See details: $($_.ErrorDetails.Message)"
    }

    try {
        # Create the virtual machine using the new image
        $vmConfig = az vm create -g $config.resourceGroup -n $config.vmName --image $config.imageName --size Standard_D2_v3 --public-ip-sku Standard --admin-username $config.adminUser --admin-password $config.adminPassword --nsg validateImageNsg --public-ip-address-dns-name $config.dnsName

    } catch {
        Throw "There was an issue creating the virtual machine. See details: $($_.ErrorDetails.Message)"
    }

    try {
        # Open port 5986 (SSH)
        az vm open-port -g $config.resourceGroup -n $config.vmName --port 5986 --priority 100

        # Get the complete DNS name
        $dnsName = ($vmConfig | ConvertFrom-Json).fqdns

        # Configure the virtual machine to allow the validation API to access it
        az vm run-command invoke  --command-id RunPowerShellScript --name $config.vmName -g $config.resourceGroup --scripts "@configureValidationVm.ps1" --parameters "DNSname=$dnsName"

    } catch {
        Throw "There was an issue configuring the virtual machine. See details: $($_.ErrorDetails.Message)"
    }
}

function Remove-ResourceGroup {
    param (
        [String] $resoureceGroup
    )
    az group delete -n $resoureceGroup --yes
}

# Validate input parameters
if (Test-Path -Path $configJsonFile)
{
  Write-Output "Config file found. Using it."
}
else
{
  Write-Error "Config file not found. Please specify the path to the config file."
  Exit 1
}

Write-Output "Getting the configuration..."
$config = Get-Configuration $configJsonFile

try {
    Write-Output "Creating temporary resource group..."
    az group create -l $config.region -n $config.resourceGroup

} catch {
    Write-Error $_.ErrorDetails.Message
    Exit 1
}

try {
    Write-Output "Creating the image and virtual machine..."
    Deploy-VirtualMachineResources -vhdUri $vhdUri -config $config

} catch {
    # Clean up
    Remove-ResourceGroup $config.resourceGroup

    Write-Error $_.ErrorDetails.Message
    Exit 1
}

# Get authentication token
try {
    Write-Output "Getting the authentication token..."
    $resource = "https://management.core.windows.net"
    $token = .'./helpers/getAuthenticationToken.ps1' -tenantId $config.tenantId -clientId $config.clientId -clientSecret $config.clientSecret -resource $resource

} catch {
    Write-Error "There was an issue getting the authentication token. See details: $($_.ErrorDetails.Message)"

    # Clean up
    Remove-ResourceGroup $config.resourceGroup
    Exit 1
}

$headers = @{ "Authorization" = "Bearer $token" }
# Get the complete DNS name
$dnsName = az vm show -g $config.resourceGroup -n $config.vmName -d --query fqdns -o tsv

$body = @{
   "DNSName" = $dnsName
   "UserName" = $config.adminUser
   "Password" = $config.adminPassword
   "OS" = "Windows"
   "PortNo" = "5986"
   "CompanyName" = $config.companyName
   "AppId" = $config.clientId
   "TenantId" = $config.tenantId
} | ConvertTo-Json

$uri = "https://isvapp.azurewebsites.net/selftest-vm"

Write-Output "Running the validation..."
try {
    $response = Invoke-WebRequest -Method "Post" -Uri $uri -Body $body -ContentType "application/json" -Headers $headers -UseBasicParsing

} catch {
    # Clean up
    Remove-ResourceGroup $config.resourceGroup

    Write-Error "There was an issue validating the virtual machine. See details: $($_.ErrorDetails.Message)"
    Exit 1
}

$resVar = $response | ConvertFrom-Json
$actualresult = $resVar.Response | ConvertFrom-Json

If ($actualresult.TestResult -eq "Pass") {
    $outputFilename = "validateVmImageResults_pass_" + ((Get-Date).ToUniversalTime()).ToString("yyyMMddhhmmss") + ".json"
} Else {
    $outputFilename = "validateVmImageResults_fail_" + ((Get-Date).ToUniversalTime()).ToString("yyyMMddhhmmss") + ".json"
}

# Write the test results to a file
Out-File -InputObject ($actualresult | ConvertTo-Json) -FilePath $outputFilename

Write-Output "`nValidation results..."
Write-Output "OSName: $($actualresult.OSName)"
Write-Output "OSVersion: $($actualresult.OSVersion)"
Write-Output "Overall Test Result: $($actualresult.TestResult)`n"
Write-Output "Please see '$($outputFilename)' for the results of specific tests."

Write-Output "Cleaning up..."
Remove-ResourceGroup $config.resourceGroup