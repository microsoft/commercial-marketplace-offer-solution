# Solution Template using Virtual Machine offer image

This offer template demonstrates how to build a solution template Azure Application offer. This offer deploys a virtual machine using an existing virtual machine offer image.

Please refer to the [Microsoft documentation](https://learn.microsoft.com/en-us/azure/marketplace/plan-azure-app-solution-template) for more information about the Solution Template Azure Application offer type.

## Prerequisites

A Virtual Machine offer is required for this template, and can be deployed and managed using the [virtual machine offer template](../../virtual-machine/basic-windows-vm/README.md) in this repository. The virtual machine offer must be published to preview or live. 

## Step 1: Install dependencies

Install the following tools on your development machine:
- Azure CLI: https://docs.microsoft.com/en-us/cli/azure/install-azure-cli

## Step 2: Login to Azure

Sign in using the Azure CLI:
```
az login
```

## Step 3: Modify the template for your use case

You can use this template as a base for your own solution template offer. Modify the `createUiDefinition.json` and Bicep templates (`mainTemplate.bicep`) to suit your needs.

### Customize the Portal User Interface

The `createUiDefinition.json` file specifies the portal user interface that is displayed to the customer when deploying your solution.

To test the portal interface for your solution, open the [Create UI Definition Sandbox](https://portal.azure.com/?feature.customPortal=false&#blade/Microsoft_Azure_CreateUIDef/SandboxBlade) and replace the empty definition with the contents of your `createUiDefinition.json` file. Select **Preview** and the form you created is displayed.

Please refer to the [Microsoft documentation](https://docs.microsoft.com/en-us/azure/azure-resource-manager/managed-applications/create-uidefinition-elements) for more information on customizing the portal user interface.

### Customize the Bicep Templates

The Azure Application offer type requires an Azure Resource Manager (ARM) template to specify what resources are deployed. We recommend using Bicep to compose the templates. The packaging scripts ([PowerShell](../../../scripts/package.ps1), [Shell](../../../scripts/package.sh)) provided in the `scripts` folder of this repository will automatically convert your [Bicep](https://github.com/Azure/bicep) templates into a single ARM template (`mainTemplate.json`).

The virtual machine offer details will need to be configured in the Bicep template. If the virtual machine offer is still in preview, ensure you append `-preview` to the offer name.

Please refer to the [Microsoft documentation](https://docs.microsoft.com/en-us/azure/azure-resource-manager/bicep/overview?tabs=bicep) for more information on how to write Bicep templates.

## Step 4: Test the ARM template

In the [scripts](../../../scripts) folder of this repository, you will find the PowerShell scripts you can use to deploy the offer.

1. If you don't already have an existing storage account, you can create one. Replace "MyResourceGroup" with your own resource group name.
```
az group create --name MyResourceGroup --location westus
az storage account create -n mystorageacct -g MyResourceGroup -l westus --sku Standard_LRS
```

2. Set parameters in a parameters file to override the default values set in the template's ARM template. You can find an example of a parameters file ([parameters.json.tmpl](app-contents/parameters.json.tmpl)) in the `app-contents` folder.

3. Deploy the solution. Replace "MyResourceGroup" with your own resource group name. If you have a parameters file, you can use the `-parametersFile` parameter to specify the file.
```
./package.ps1 -assetsFolder ../marketplace/application/base-image-vm/app-contents -releaseFolder release_01
./devDeploy.ps1 -resourceGroup MyResourceGroup -location westus -assetsFolder ./release_01/assets -parametersFile myparameters.json -storageAccountName mystorageacct
```

4. Cleanup the deployment. Replace "MyResourceGroup" with your own resource group name.
```
az group create --name MyResourceGroup
```

## Step 5: Prepare the offer

Update the [listing configuration file](listing_config.json) (`listing.json`) with the information about your offer.

## Step 6: Create the Offer

A [script](../../../scripts/addUpdate_azureApplicationOffer.ps1) is provided in the `scripts` folder of this repository to create the Solution Template Azure Application offer.

The script will package the solution, create an offer if it does not already exist, create a plan if it does not already exist, and upload the solution package and offer assets (logos). You can also use this script to update the offer or plan. Replace the offer name and plan name with your own values.

```
./addUpdate_azureApplicationOffer.ps1 -offerType st -assetsFolder ../marketplace/application/vm-offer-image -offerName contoso-app -planName vm-offer-image
```

## Step 7: Publishing the offer
Once the draft offer created in the above step has been reviewed and confirmed, the offer can be submitted for publishing.

To start the publishing process:
```
azpc app publish --name contoso-app
```
