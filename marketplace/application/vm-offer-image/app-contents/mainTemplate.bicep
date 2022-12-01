// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License.
@description('Resource location.')
param location string = resourceGroup().location

@description('Virtual machine size.')
param vmSize string = 'Standard_D2_v4'

@description('Virtual machine name.')
param vmName string = 'contosowinvm'

@description('The administrator username for the VM.')
param adminUsername string = 'myadmin'

@metadata({
  type: 'password'
  description: 'The administrator password for the VM.'
})
@secure()
param adminPassword string

@description('Virtual network name.')
param vnetName string = 'contosowinvm-vnet'

@description('Address prefix of the virtual network.')
param vnetARPrefixes array = [
  '10.0.0.0/16'
]

@description('Virtual network is new or existing.')
param vnetNewOrExisting string = 'new'

@description('Resource group of the virtual network.')
param vnetRGName string = resourceGroup().name

@description('Subnet name.')
param subNetName string = 'contoso-win-subnet'

@description('Subnet prefix of the virtual network.')
param subNetARPrefix string = '10.0.0.0/24'

@description('Unique public IP address name.')
param publicIpName string = 'contosowinvm-ip'

@description('Unique DNS public IP attached the virtual machine.')
param publicIpDns string = 'contosowinvm-${uniqueString(resourceGroup().id)}'

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

param vmOfferPublisher string = 'contoso'
param vmOfferName string = 'contoso-vm-preview'
param vmOfferPlanName string = 'contososkuidentifier'
param vmOfferPlanVersion string = '1.0.0'

var vmImage = {
  publisher: vmOfferPublisher
  offer: vmOfferName
  sku: vmOfferPlanName
  version: vmOfferPlanVersion
}

var vmPlan = {
  publisher: vmOfferPublisher
  product: vmOfferName
  name: vmOfferPlanName
}

var ipconfName = '${vmName}-ipconf'
var nicName = '${vmName}-nic'
var nsgName = '${vmName}-nsg'
var osDiskName = '${vmName}-osdisk'

var tags = {
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
  tags: (contains(outTagsByResource, 'Microsoft.Network/publicIPAddresses') ? union(tags, outTagsByResource['Microsoft.Network/publicIPAddresses']) : tags)
}

resource nsg 'Microsoft.Network/networkSecurityGroups@2021-03-01' = {
  name: nsgName
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
  tags: (contains(outTagsByResource, 'Microsoft.Network/virtualNetworks') ? union(tags, outTagsByResource['Microsoft.Network/virtualNetworks']) : tags)
}

resource subnet 'Microsoft.Network/virtualNetworks/subnets@2022-01-01' existing = {
  name: '${vnetName}/${subNetName}'
  scope: resourceGroup(vnetRGName)
}

resource nic 'Microsoft.Network/networkInterfaces@2021-03-01' = {
  name: nicName
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
  tags: (contains(outTagsByResource, 'Microsoft.Network/networkInterfaces') ? union(tags, outTagsByResource['Microsoft.Network/networkInterfaces']) : tags)
}

resource virtualMachine 'Microsoft.Compute/virtualMachines@2021-03-01' = {
  name: vmName
  location: location
  plan: vmPlan
  properties: {
    hardwareProfile: {
      vmSize: vmSize
    }
    storageProfile: {
      imageReference: vmImage
      osDisk: {
        name: osDiskName
        createOption: 'FromImage'
        caching: 'ReadWrite'
        diskSizeGB: 128
        managedDisk: {
          storageAccountType: 'Standard_LRS'
        }
      }
    }
    osProfile: {
      computerName: vmName
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
  tags: (contains(outTagsByResource, 'Microsoft.Compute/virtualMachines') ? union(tags, outTagsByResource['Microsoft.Compute/virtualMachines']) : tags)
}

output hostName string = (!empty(publicIpId) ? reference(publicIpId, '2021-03-01').dnsSettings.fqdn : '')
output username string = adminUsername
output ipAddress string = (!empty(publicIpId) ? publicIpId : '')
