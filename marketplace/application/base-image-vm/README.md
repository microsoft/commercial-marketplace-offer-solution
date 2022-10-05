# Azure Application with Custom Script Extension

This offer template demonstrates how to build a solution template or managed application Azure Application offer. This offer deploys a Windows Server 2019 VM and runs a custom script extension that writes content to a file. The custom script extension runs a PowerShell script (`WriteText.ps1`) after the VM has been provisioned.

Please refer to the [Microsoft documentation](https://learn.microsoft.com/en-us/azure/marketplace/plan-azure-application-offer) for more information about the Azure Application offer type.

## Step 1: Install dependencies

Install the following tools on your development machine:
- Azure CLI: https://docs.microsoft.com/en-us/cli/azure/install-azure-cli

## Step 2: Login to Azure

Sign in using the Azure CLI:
```
az login
```

## Step 3: Modify the template for your use case

You can use this template as a base for your own solution template or managed application offer. Modify the `createUiDefinition.json` and Bicep templates (`mainTemplate.bicep`) to suit your needs.

### Customize the Portal User Interface

The `createUiDefinition.json` file specifies the portal user interface that is displayed to the customer when deploying your solution.

To test the portal interface for your solution, open the [Create UI Definition Sandbox](https://portal.azure.com/?feature.customPortal=false&#blade/Microsoft_Azure_CreateUIDef/SandboxBlade) and replace the empty definition with the contents of your `createUiDefinition.json` file. Select **Preview** and the form you created is displayed.

Please refer to the [Microsoft documentation](https://docs.microsoft.com/en-us/azure/azure-resource-manager/managed-applications/create-uidefinition-elements) for more information on customizing the portal user interface.

### Customize the Bicep Templates

The Azure Application offer type requires an Azure Resource Manager (ARM) template to specify what resources are deployed. We recommend using Bicep to compose the templates. The packaging scripts ([PowerShell](../../../scripts/package.ps1), [Shell](../../../scripts/package.sh)) provided in the `scripts` folder of this repository will automatically convert your [Bicep](https://github.com/Azure/bicep) templates into a single ARM template (`mainTemplate.json`).

Please refer to the [Microsoft documentation](https://docs.microsoft.com/en-us/azure/azure-resource-manager/bicep/overview?tabs=bicep) for more information on how to write Bicep templates.

### Customize the Custom Script Extension

This offer runs a simple PowerShell script in the custom script extension. Replace or remove this script and custom script extension as needed. You will need to edit the following files: `mainTemplate.bicep`, `writeTextExtension.bicep` and `WriteText.ps1`.

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

A [script](../../../scripts/addUpdate_azureApplicationOffer.ps1) is provided in the `scripts` folder of this repository to create the Azure Application (Solution Template or Managed Application) offer.

The template [offer listing config](./listing_config.json) contains 2 plan options:
- Solution Template (`base-image-vm`)
- Managed Application (`base-image-vm-app`)

The offer type that is created refers to the plan set in the [manifest file](./manifest.yml).

The script will package the solution, create an offer if it does not already exist, create a plan if it does not already exist, and upload the solution package and offer assets (logos). You can also use this script to update the offer or plan. Replace the offer name and plan name with your own values.

```
./addUpdate_azureApplicationOffer.ps1 -offerType "<offer type>" -assetsFolder ../marketplace/application/base-image-vm -offerName contoso-app -planName base-image-vm
```
Where "\<offer type>" has the option of st or ma, for solution template and managed application, respectively.

## Step 7: Publishing the Azure Application Offer
Once the draft offer created in the above step has been reviewed and confirmed, the offer can be submitted for publishing.

To start the publishing process:
```
azpc app publish --name "<offer name>"
```
