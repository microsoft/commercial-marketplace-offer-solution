// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License.
@description('Resource location.')
param location string = resourceGroup().location

@description('Virtual machine size.')
param vmSize string = 'Standard_D2s_v3'

@description('Virtual machine name.')
param vmName string = 'basicwinvm'

@description('The administrator username for the VM.')
param adminUsername string = 'myadmin'

@metadata({
  type: 'password'
  description: 'The administrator password for the VM.'
})
@secure()
param adminPassword string

@description('File name.')
param fileName string = 'MyFile'

@description('File content.')
param fileContent string = 'MyContent'

@description('Virtual network name.')
param vnetName string = 'basicwinvm-vnet'

@description('Address prefix of the virtual network.')
param vnetARPrefixes array = [
  '10.0.0.0/16'
]

@description('Virtual network is new or existing.')
param vnetNewOrExisting string = 'new'

@description('Resource group of the virtual network.')
param vnetRGName string = resourceGroup().name

@description('Subnet name.')
param subNetName string = 'basic-win-subnet'

@description('Subnet prefix of the virtual network.')
param subNetARPrefix string = '10.0.0.0/24'

@description('Unique public IP address name.')
param publicIpName string = 'basicwinvm-ip'

@description('Unique DNS public IP attached the virtual machine.')
param publicIpDns string = 'basicwinvm-${uniqueString(resourceGroup().id)}'

@description('Public IP allocation method.')
param publicIpAllocationMethod string = 'Dynamic'

@description('Public IP SKU.')
@allowed([
  'Basic'
  'Standard'
])
param publicIpSku string = 'Basic'

@description('Public IP new or existing or none?')
param publicIpNewOrExisting string = 'new'

@description('Resource group of the public IP address.')
param publicIpRGName string = resourceGroup().name

@description('Tags by resource.')
param outTagsByResource object = {}

@description('The base URI where artifacts required by this template are located including a trailing \'/\'')
param _artifactsLocation string = deployment().properties.templateLink.uri

@description('The sasToken required to access _artifactsLocation.')
@secure()
param _artifactsLocationSasToken string = ''

var vmImage = {
  publisher: 'MicrosoftWindowsServer'
  offer: 'WindowsServer'
  sku: '2019-Datacenter'
  version: 'latest'
}

var vmName_var = vmName
var ipconfName = '${vmName_var}-ipconf'
var nicName_var = '${vmName_var}-nic'
var nsgName_var = '${vmName_var}-nsg'

var tags_var = {
  offer: 'Sample Basic Windows 2019 VM'
}

var publicIpId = {
  new: resourceId('Microsoft.Network/publicIPAddresses', publicIpName)
  existing: resourceId(publicIpRGName, 'Microsoft.Network/publicIPAddresses', publicIpName)
  none: ''
}[publicIpNewOrExisting]

resource partnercenter 'Microsoft.Resources/deployments@2021-04-01' = {
  name: 'pid-xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx-partnercenter'
  properties: {
    mode: 'Incremental'
    template: {
      '$schema': 'https://schema.management.azure.com/schemas/2015-01-01/deploymentTemplate.json#'
      contentVersion: '1.0.0.0'
      resources: []
    }
  }
}

resource publicIp 'Microsoft.Network/publicIPAddresses@2021-03-01' = if (publicIpNewOrExisting == 'new') {
  name: publicIpName
  sku: {
    name: publicIpSku
  }
  location: location
  properties: {
    publicIPAllocationMethod: publicIpAllocationMethod
    dnsSettings: {
      domainNameLabel: publicIpDns
    }
  }
  tags: (contains(outTagsByResource, 'Microsoft.Network/publicIPAddresses') ? union(tags_var, outTagsByResource['Microsoft.Network/publicIPAddresses']) : tags_var)
}

resource nsg 'Microsoft.Network/networkSecurityGroups@2021-03-01' = {
  name: nsgName_var
  location: location
  properties: {
    securityRules: [
      {
        name: 'RDP'
        properties: {
          priority: 1010
          protocol: '*'
          access: 'Allow'
          direction: 'Inbound'
          sourceAddressPrefix: '*'
          sourcePortRange: '*'
          destinationAddressPrefix: '*'
          destinationPortRange: '3389'
        }
      }
    ]
  }
}

resource vnet 'Microsoft.Network/virtualNetworks@2021-03-01' = if (vnetNewOrExisting == 'new') {
  name: vnetName
  location: location
  properties: {
    addressSpace: {
      addressPrefixes: [
        first(vnetARPrefixes)
      ]
    }
    subnets: [
      {
        name: subNetName
        properties: {
          addressPrefix: subNetARPrefix
        }
      }
    ]
  }
  tags: (contains(outTagsByResource, 'Microsoft.Network/virtualNetworks') ? union(tags_var, outTagsByResource['Microsoft.Network/virtualNetworks']) : tags_var)
}

resource subnet 'Microsoft.Network/virtualNetworks/subnets@2022-01-01' existing = {
  name: '${vnetName}/${subNetName}'
  scope: resourceGroup(vnetRGName)
}

resource nic 'Microsoft.Network/networkInterfaces@2021-03-01' = {
  name: nicName_var
  location: location
  dependsOn: [
    vnet
  ]
  properties: {
    enableAcceleratedNetworking: true
    ipConfigurations: [
      {
        name: ipconfName
        properties: union({
            subnet: {
              id: subnet.id
            }
          }, {
            privateIPAllocationMethod: 'Dynamic'
          }, (!empty(publicIpId)) ? {
            publicIPAddress: {
              id: publicIpId
            }
          } : {})
      }
    ]
    networkSecurityGroup: {
      id: nsg.id
    }
  }
  tags: (contains(outTagsByResource, 'Microsoft.Network/networkInterfaces') ? union(tags_var, outTagsByResource['Microsoft.Network/networkInterfaces']) : tags_var)
}

resource virtualMachine 'Microsoft.Compute/virtualMachines@2021-03-01' = {
  name: vmName_var
  location: location
  properties: {
    hardwareProfile: {
      vmSize: vmSize
    }
    storageProfile: {
      imageReference: vmImage
      osDisk: {
        name: '${vmName_var}-osdisk'
        createOption: 'FromImage'
        caching: 'ReadWrite'
        diskSizeGB: 128
        managedDisk: {
          storageAccountType: 'Standard_LRS'
        }
      }
    }
    osProfile: {
      computerName: vmName_var
      adminUsername: adminUsername
      adminPassword: adminPassword
    }
    networkProfile: {
      networkInterfaces: [
        {
          id: nic.id
        }
      ]
    }
  }
  tags: (contains(outTagsByResource, 'Microsoft.Compute/virtualMachines') ? union(tags_var, outTagsByResource['Microsoft.Compute/virtualMachines']) : tags_var)
}

module writeText './writeTextExtension.bicep' = {
  name: 'runWriteText'
  params: {
    _artifactsLocation: _artifactsLocation
    _artifactsLocationSasToken: _artifactsLocationSasToken
    location: location
    vmName: vmName_var
    fileName: fileName
    fileContent: fileContent
  }
  dependsOn: [
    virtualMachine
  ]
}

output hostName string = (!empty(publicIpId) ? reference(publicIpId, '2021-03-01').dnsSettings.fqdn : '')
output username string = adminUsername
output ipAddress string = (!empty(publicIpId) ? publicIpId : '')
