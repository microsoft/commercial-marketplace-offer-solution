//  Parameters
@description('Deployment Location')
param location string

@description('The base URI where artifacts required by this template are located including a trailing \'/\'')
param _artifactsLocation string = deployment().properties.templateLink.uri

@description('The sasToken required to access _artifactsLocation.')
@secure()
param _artifactsLocationSasToken string = ''

@description('Hostname of Deployment')
param hostname string = 'deploy1.ddc-storage.gaming.azure.com'

@description('Unknown, Self, or {IssuerName} for certificate signing')
param certificateIssuer string = 'Self'

@description('Certificate Issuer Provider')
param issuerProvider string = ''

@description('Running this template requires roleAssignment permission on the Resource Group, which require an Owner role. Set this to false to deploy some of the resources')
param assignRole bool = true

@description('Name of Key Vault resource')
param keyVaultName string = take('ddcKeyVault${uniqueString(resourceGroup().id, subscription().subscriptionId, location)}', 24)

@description('Name of Certificate (Default certificate is self-signed)')
param certificateName string = 'unreal-cloud-ddc-cert'

param managedIdentityPrefix string = 'id-ddc-storage-'

@description('Does the Managed Identity already exists, or should be created')
param useExistingManagedIdentity bool = false

@descriptin('Set to false to deploy from as an ARM template for debugging') 
param isApp bool = true

var _artifactsLocationWithToken = _artifactsLocationSasToken != ''

//  Resources
resource partnercenter 'Microsoft.Resources/deployments@2021-04-01' = {
  name: 'pid-7837dd60-4ba8-419a-a26f-237bbe170773-partnercenter'
  properties: {
    mode: 'Incremental'
    template: {
      '$schema': 'https://schema.management.azure.com/schemas/2015-01-01/deploymentTemplate.json#'
      contentVersion: '1.0.0.0'
      resources: []
    }
  }
}

module keyVault 'modules/keyvault/vaults.bicep' = {
  name: 'keyVault-${uniqueString(location, resourceGroup().id, deployment().name)}'
  params: {
    location: location
    name: take('${location}-${keyVaultName}', 24)
    assignRole: assignRole
  }
}

module kvCert 'modules/keyvault/create-kv-certificate.bicep' = {
  name: 'akvCert-${location}'
  dependsOn: [
    keyVault
  ]
  params: {
    akvName: take('${location}-${keyVaultName}', 24)
    location: location
    certificateName: certificateName
    certificateCommonName: hostname
    issuerName: certificateIssuer
    issuerProvider: issuerProvider
    useExistingManagedIdentity: useExistingManagedIdentity
    managedIdentityName: '${managedIdentityPrefix}${location}'
    rbacRolesNeededOnKV: '00482a5a-887f-4fb3-b363-3b7fe8e74483' // Key Vault Admin
    isApp: isApp
  }
}
// End

@description('Location of required artifacts.')
output _artifactsLocation string = _artifactsLocation

@description('Token for retrieving  required Artifacts from storage.')
output _artifactsLocationWithToken bool = _artifactsLocationWithToken
