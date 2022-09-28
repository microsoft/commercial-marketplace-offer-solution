# Copyright (c) Microsoft Corporation.
# Licensed under the MIT License.

####################################################################################################
# This script can be used to initialize your Azure DevOps pipelines.                               #
# It creates the following:                                                                        #
#   Azure Key Vault and populates secrets from config.json                                         #
#   AzureRM service connection                                                                     #
#   (Optional) Variable group to store Key Vault details                                           #
#   Pipelines folder to store pipelines                                                            #
#   Pipelines for all samples                                                                      #
# IMPORTANT! A config.json file is needed to run this script. Please use the template provided.    #
####################################################################################################
Param (
  [Parameter(Mandatory = $True, HelpMessage = "Azure Key Vault name that will store the secrets")]
  [String] $keyVaultName,
  [Parameter(Mandatory = $False, HelpMessage = "Azure Key Vault resource group name")]
  [String] $keyVaultRGName = "azmp-rg",
  [Parameter(Mandatory = $False, HelpMessage = "Pipeline folder path")]
  [String] $pipelineFolderPath = "azmp",
  [Parameter(Mandatory = $False, HelpMessage = "Path to the config file")]
  [String] $configFile = "config.json",
  [Parameter(Mandatory = $False, HelpMessage = "Use Azure Key Vault for secrets")]
  [String] $useKeyVault = $False
)

if (Test-Path -Path $configFile)
{
  Write-Output "Config file found. Using it."
}
else
{
  Write-Error "Config file not found. Please specify the path to the config file."
  Exit 1
}

$configFilePath = Resolve-Path $configFile
$config = Get-Content $configFilePath -Raw | ConvertFrom-Json

if ("" -eq $config.azureDevOps.project || "" -eq $config.azureDevOps.organization)
{
  Write-Error "Please specify the Azure DevOps project and organization in the config file."
  Exit 1
}

$subscriptionId = $config.azure.subscriptionId

Write-Output "Setting subscription ID to $subscriptionId..."
az account set -s $subscriptionId

az group create --name $keyVaultRGName --location $config.azure.location
if (az keyvault show --name $keyVaultName --resource-group $keyVaultRGName) {
    Write-Output "Azure Key Vault $keyVaultName already exists. Moving on."
} else {
    Write-Output "Creating an Azure Key Vault $keyVaultName in $keyVaultRGName..."
    az keyvault create --name $keyVaultName --resource-group $keyVaultRGName
    Write-Output "Azure Key Vault $keyVaultName created."
}

Write-Output "Adding secrets to Azure Key Vault..."
foreach ($obj in $config.PSObject.Properties) {
    foreach ($secret in $obj.value.PSObject.Properties) {
        $secretName = $obj.Name + "-" + $secret.Name
        az keyvault secret set --name $secretName --value $secret.Value --vault-name $keyVaultName
    }
}

# Configure default organization and project
Write-Output "Configuring default organization and project..."
az devops configure --defaults project="${config.azureDevOps.project}" organization="${config.azureDevOps.organization}"

if ("" -ne $config.azureDevOps.serviceConnectionPrincipalId && "" -ne $config.azureDevOps.serviceConnectionPrincipalKey)
{
  Write-Output "Creating Azure Resource Manager service connection..."
  $subscriptionName = az account show -s $subscriptionId -o json | ConvertFrom-Json | Select-Object -ExpandProperty name
  $Env:AZURE_DEVOPS_EXT_AZURE_RM_SERVICE_PRINCIPAL_KEY="${config.azureDevOps.serviceConnectionPrincipalKey}" | az devops service-endpoint azurerm create --azure-rm-service-principal-id $config.azureDevOps.serviceConnectionPrincipalId --azure-rm-subscription-id $subscriptionId --azure-rm-subscription-name "$subscriptionName" --azure-rm-tenant-id $config.aad.tenantId --name "$subscriptionName"
}
else
{
  Write-Output "Skipping creation of Azure Resource Manager service connection."
}

if ($False -eq $useKeyVault)
{
  Write-Warning "Create a variable group and link the key vault to it. For more information, see the Microsoft documentation at https://docs.microsoft.com/en-us/azure/devops/pipelines/library/variable-groups?view=azure-devops&tabs=yaml#link-secrets-from-an-azure-key-vault."
}
else
{
  Write-Output "Create variable group..."
  az pipelines variable-group create --name "AZMP Variables" --authorize false --variables keyVaultName=$keyVaultName subscriptionId=$subscriptionId
}

Write-Output "Adding pipeline folder path ($pipelineFolderPath) and pipelines..."
az pipelines folder create --path $pipelineFolderPath --description "Pipelines for creating and publishing Azure Marketplace offers"
az pipelines create --name "AZMP Solution Template PR" --description "Solution template offer PR build and test" --folder-path $pipelineFolderPath --repository "AGCI-Marketplace-Scripts" --branch "main" --yml-path "marketplace/application/base-image-vm/solutiontemplate.pr.yml"
az pipelines create --name "AZMP Solution Template RC" --description "Solution template offer release candidate" --folder-path $pipelineFolderPath --repository "AGCI-Marketplace-Scripts" --branch "main" --yml-path "marketplace/application/base-image-vm/solutiontemplate.publish.yml"
az pipelines create --name "AZMP Virtual Machine PR" --description "Virtual machine offer PR build and test" --folder-path $pipelineFolderPath --repository "AGCI-Marketplace-Scripts" --branch "main" --yml-path "createVmOffer.yml"
az pipelines create --name "AZMP Virtual Machine RC" --description "Virtual machine offer PR build and test" --folder-path $pipelineFolderPath --repository "AGCI-Marketplace-Scripts" --branch "main" --yml-path "publishVmOffer.yml"