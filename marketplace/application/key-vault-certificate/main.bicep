//  Parameters
@description('Deployment Location')
param location string = resourceGroup().location

param resourceGroupName string = resourceGroup().name
param name string = 'kvWithCert'
param prefix string = uniqueString(location, resourceGroup().id, deployment().name)
param managedResourceGroupName string = 'mrg'

@description('Name of Certificate (Default certificate is self-signed)')
param certificateName string = 'unreal-cloud-ddc-cert'

@allowed([ 'dev' ])
param publisher string = 'dev'
param publishers object = {
  dev: {
    name: 'preview'
    product: 'key-vault-certificate-temp-preview'
    publisher: 'microsoftcorporation1590077852919'
    version: '0.1.47'
  }
}

// End

//  Variables
var certificateIssuer = 'Subscription-Issuer'
var issuerProvider = 'OneCertV2-PublicCA'
var managedResourceGroupId = '${subscription().id}/resourceGroups/${resourceGroup().name}-${managedResourceGroupName}-${replace(publishers[publisher].version,'.','-')}'
var appName = '${prefix}${name}-${replace(publishers[publisher].version,'.','-')}'
// End

resource kvWithCert 'Microsoft.Solutions/applications@2021-07-01' = {
  location: location
  kind: 'MarketPlace'
  name: appName
  plan: publishers[publisher]
  properties: {
    managedResourceGroupId: managedResourceGroupId
    parameters: {
      location: { value: location }
      certificateName: { value: certificateName }
      certificateIssuer: { value: certificateIssuer }
      issuerProvider: { value: issuerProvider }
    }
    jitAccessPolicy: null
  }
}

output prefix string = prefix
output appName string = appName
