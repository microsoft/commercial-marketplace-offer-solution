# Sample - Solution Template or Managed Application with Custom Script Extension

This sample demonstrates how to build a solution template or managed application Azure Application offer. This sample deploys a Windows Server 2019 VM and runs a custom script extension that writes content to a file. The custom script extension runs a PowerShell script (`WriteText.ps1`) after the VM has been provisioned.

Please refer to the [Microsoft documentation](https://docs.microsoft.com/en-us/azure/marketplace/plan-azure-app-solution-template) for more information about the solution template offer type.

## Get Started

Install the following tools on your development machine:
- Azure CLI: https://docs.microsoft.com/en-us/cli/azure/install-azure-cli

Sign in to your Azure account:
```
az login
```

## Deploy the Sample

In the [scripts](../../../scripts) folder of this repository, you will find the PowerShell scripts you can use to deploy the sample.

If you don't already have an existing storage account, you can create one. Replace "MyResourceGroup" with your own resource group name.
```
az group create --name MyResourceGroup --location westus
az storage account create -n mystorageacct -g MyResourceGroup -l westus --sku Standard_LRS
```

Create a `config.json` from from the template file [config.json.tmpl](../../../scripts/config.json.tmpl) and set the values in the `config.json` file. The `location`, `storageAccountName`, and `storageAccountKey` values are required for the sample to work. You can provide additional parameters in a parameters file to override the default values set in the sample's ARM template. You can find an example of a parameters file ([parameters.json.tmpl](app-contents/parameters.json.tmpl)) in the sample's folder.

Deploy the solution. Replace "MyResourceGroup" with your own resource group name. If you have a parameters file, you can use the `-parametersFile` parameter to specify the file.
```
./package.ps1 -assetsFolder ../marketplace/application/base-image-vm/app-contents -releaseFolder release_01
./devDeploy.ps1 -resourceGroup MyResourceGroup -location westus -assetsFolder ./release_01/assets -parametersFile myparameters.json
```

Cleanup the deployment. Replace "MyResourceGroup" with your own resource group name.
```
az group create --name MyResourceGroup
```


## Modifying the Sample For Your Use Case

You can use this sample as a base for your own solution template offer. Modify the `createUiDefinition.json` and Bicep templates (`mainTemplate.bicep`) to suit your needs.

### Customize the Portal User Interface

The `createUiDefinition.json` file specifies the portal user interface that is displayed to the customer when deploying your solution.

To test the portal interface for your solution, open the [Create UI Definition Sandbox](https://portal.azure.com/?feature.customPortal=false&#blade/Microsoft_Azure_CreateUIDef/SandboxBlade) and replace the empty definition with the contents of your `createUiDefinition.json` file. Select **Preview** and the form you created is displayed.

Please refer to the [Microsoft documentation](https://docs.microsoft.com/en-us/azure/azure-resource-manager/managed-applications/create-uidefinition-elements) for more information on customizing the portal user interface.

### Customize the Bicep Templates

The solution template offer type requires an Azure Resource Manager (ARM) template to specify what resources are deployed. We recommend using Bicep to compose the templates. The packaging script provided in the `scripts` folder of this repository will automatically convert your [Bicep](https://github.com/Azure/bicep) templates into a single ARM template (`mainTemplate.json`).

Please refer to the [Microsoft documentation](https://docs.microsoft.com/en-us/azure/azure-resource-manager/bicep/overview?tabs=bicep) for more information on how to write Bicep templates.

### Customize the Custom Script Extension

This sample runs a simple PowerShell script in the custom script extension. Replace or remove this script and custom script extension as needed. You will need to edit the following files: `mainTemplate.bicep`, `writeTextExtension.bicep` and `WriteText.ps1`.

### Packaging

Once you have finished modifying the files, you can package the solution using the [packaging script](../../../scripts/package.ps1) provided in the `scripts` folder. This will generate a deployment package (`marketplacePackage.zip`) that contains all the files needed for your solution template offer.

```
./package.ps1 -assetsFolder ../marketplace/application/base-image-vm/app-contents -releaseFolder my_st_offer
```

If you have already created an offer in the Azure Marketplace, you can include the offer ID in the command to replace the tracking GUID placeholder in the mainTemplate.json file.

```
./package.ps1 -assetsFolder ../marketplace/application/base-image-vm/app-contents -releaseFolder my_st_offer -offerId ec484fb9-31a0-4332-b6eb-27babe9c9233
```

Please refer to the [Microsoft documentation](https://docs.microsoft.com/en-us/azure/marketplace/plan-azure-app-solution-template#deployment-package) for more information on how to package your solution template offer.

### Create/Update the Azure Application Solution Template & Managed Application Offer

A [script](../../../scripts/solutionTemplateOfferAddUpdate.ps1) is provided in the `scripts` folder of this repository to create the Azure Application (Solution Template and/or Managed Application) offer.

The sample [offer listing config](./listing_config.json) contains 2 plan options:
- Solution Template (`base-image-vm`)
- Managed Application (`base-image-vm-app`)

The offer type that is created refers to the plan configured in the [manifest file](./manifest.yml).

The script will package the solution, create an offer if it does not already exist, create a plan if it does not already exist, and upload the solution package and offer assets (logos). You can also use this script to update the offer or plan.

```
./solutionTemplateOfferAddUpdate.ps1 -assetsFolder ../marketplace/application/base-image-vm
```

Before running the script, you will need to set the following variables in the [configuration file](../../../scripts/config.json):

1. Copy [`config.json.tmpl`](../../../scripts/config.json.tmpl) and create new file named `config.json`.
2. Complete `config.json`:
    * **tenantId**: The tenant ID for the service principal
    * **subscriptionId**: Subscription that will have access to preview versions of the offer and where Azure resources will be deployed to
    * **clientId** and **clientSecret**: Service principal used for calling Partner Center APIs
    * **managedAppPrincipalId**: Service principal that will have access to managed resource group
    * **publisherId**: Your Partner Center publishing account ID

Please refer to the [Microsoft Azure Service Principal documentation](https://docs.microsoft.com/en-us/cli/azure/create-an-azure-service-principal-azure-cli) on more information on how to create a Service Principal.

### Publishing the Azure Application Solution Template Offer
Once the draft offer created in the above step has been reviewed and confirmed, the offer can be submitted for publishing.

To start the publishing process:
```
azpc app publish --name "<offer name>"
```

### Automating with GitHub Workflows

A set of [starter workflows](../../../.github/workflow-templates/) are available for use with this sample. To use them, follow the [instructions](https://docs.github.com/en/actions/using-workflows/using-starter-workflows#using-starter-workflows) in the GitHub documentation.
