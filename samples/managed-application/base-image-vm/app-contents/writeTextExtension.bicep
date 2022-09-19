// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License.
param _artifactsLocation         string = deployment().properties.templateLink.uri
@secure()
param _artifactsLocationSasToken string = ''
param location                   string = resourceGroup().location
param vmName                     string = 'basicwinvm'
param fileName                   string = 'MyFile'
param fileContent                string = 'MyContent'

var writeTextParams = '-fileName \'${fileName}\' -fileContent \'${fileContent}\''

resource virtualMachine_writeTextExtension 'Microsoft.Compute/virtualMachines/extensions@2021-11-01' = {
  name      : '${vmName}/CustomScriptExtension-WriteText'
  location  : location
  properties: {
    publisher              : 'Microsoft.Compute'
    type                   : 'CustomScriptExtension'
    typeHandlerVersion     : '1.10'
    autoUpgradeMinorVersion: true
    settings: {
      fileUris: [
        uri(_artifactsLocation, 'WriteText.ps1${_artifactsLocationSasToken}')
      ]
      commandToExecute: 'powershell -ExecutionPolicy Unrestricted -NoProfile -NonInteractive -command "./WriteText.ps1 ${writeTextParams}"'
    }
  }
}

output id string = virtualMachine_writeTextExtension.id
