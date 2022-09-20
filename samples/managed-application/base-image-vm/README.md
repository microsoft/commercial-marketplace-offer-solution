# Sample - Managed Application with Custom Script Extension

This sample demonstrates how to build a managed application Azure Application offer. This sample deploys a Windows Server 2019 VM and runs a custom script extension that writes content to a file. The custom script extension runs a PowerShell script (`WriteText.ps1`) after the VM has been provisioned.

Please refer to the [Microsoft documentation](https://learn.microsoft.com/en-us/azure/marketplace/plan-azure-app-managed-app) for more information about the managed application offer type.

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
./package.ps1 -assetsFolder ../samples/managed-application/base-image-vm/app-contents -releaseFolder release_01
./devDeploy.ps1 -resourceGroup MyResourceGroup -assetsFolder ./release_01/assets -parametersFile myparameters.json
```

Cleanup the deployment. Replace "MyResourceGroup" with your own resource group name.
```
az group create --name MyResourceGroup
```

## Create and publish the Managed Application offer using Azure DevOps
A simpler approach to deploying your samples is to use the pre-built Azure DevOps pipeline files. These pipelines will manage the managed application offer creation, as well as publishing.

1. Fork the [repository](https://dev.azure.com/AZGlobal/Azure%20Global%20CAT%20Engineering/_git/AGCI-Marketplace-Scripts).
2. [Create a Service Principal](https://docs.microsoft.com/en-us/cli/azure/create-an-azure-service-principal-azure-cli) so that the pipeline can have access to your Azure and Partner Center resources.
3. [Create an Azure Key Vault](https://docs.microsoft.com/en-us/azure/key-vault/general/quick-create-portal) to store your Azure and Partner Center secrets. Ensure that your Service Principal has access to the Key Vault.
4. Create a variable group in Azure DevOps for your secrets. Be sure to enable "Link secrets from an Azure key vault as variables".
5. [Create the pipeline](https://docs.microsoft.com/en-us/azure/devops/pipelines/create-first-pipeline?view=azure-devops&tabs=java%2Ctfs-2018-2%2Cbrowser) in Azure DevOps:
    * Create a new pipeline to create the managed application offer, selecting the existing YAML pipeline file [managedapplication.pr.yml](managedapplication.pr.yml).
        * Replace the variables group value with your variable group name.
        * Save your changes.
    * Create a new pipeline to publish your managed application offer, selecting the existing YAML pipeline file [managedapplication.publish.yml](managedapplication.publish.yml).
        * Replace the variables group value with your variable group name.
        * Save your changes.
6. [Create a branch policy](https://docs.microsoft.com/en-us/azure/devops/pipelines/release/deploy-pull-request-builds?view=azure-devops#set-up-branch-policy-for-azure-repos) on the branch of your forked repository so that the managed application offer creation pipeline will be triggered when a pull request is created, and the publish pipeline is triggered on merge into `main`.
6. Make a change to the managed application sample files, commit the change, and raise a pull request.
7. Merge the pull request into the `main` branch.

## Modifying the Sample For Your Use Case

You can use this sample as a base for your own managed application offer. Modify the `createUiDefinition.json` and Bicep templates (`mainTemplate.bicep`) to suit your needs.

### Customize the Portal User Interface

The `createUiDefinition.json` file specifies the portal user interface that is displayed to the customer when deploying your solution.

To test the portal interface for your solution, open the [Create UI Definition Sandbox](https://portal.azure.com/?feature.customPortal=false&#blade/Microsoft_Azure_CreateUIDef/SandboxBlade) and replace the empty definition with the contents of your `createUiDefinition.json` file. Select **Preview** and the form you created is displayed.

Please refer to the [Microsoft documentation](https://docs.microsoft.com/en-us/azure/azure-resource-manager/managed-applications/create-uidefinition-elements) for more information on customizing the portal user interface.

### Customize the Bicep Templates

The managed application offer type requires an Azure Resource Manager (ARM) template to specify what resources are deployed. We recommend using Bicep to compose the templates. The packaging script provided in the `scripts` folder of this repository will automatically convert your [Bicep](https://github.com/Azure/bicep) templates into a single ARM template (`mainTemplate.json`).

Please refer to the [Microsoft documentation](https://docs.microsoft.com/en-us/azure/azure-resource-manager/bicep/overview?tabs=bicep) for more information on how to write Bicep templates.

### Customize the Custom Script Extension

This sample runs a simple PowerShell script in the custom script extension. Replace or remove this script and custom script extension as needed. You will need to edit the following files: `mainTemplate.bicep`, `writeTextExtension.bicep` and `WriteText.ps1`.

### Packaging

Once you have finished modifying the files, you can package the solution using the [packaging script](../../../scripts/package.ps1) provided in the `scripts` folder. This will generate a deployment package (`marketplacePackage.zip`) that contains all the files needed for your managed application offer.

```
./package.ps1 -assetsFolder ../samples/managed-application/base-image-vm/app-contents -releaseFolder my_st_offer
```

If you have already created an offer in the Azure Marketplace, you can include the offer ID in the command to replace the tracking GUID placeholder in the mainTemplate.json file.

```
./package.ps1 -assetsFolder ../samples/managed-application/base-image-vm/app-contents -releaseFolder my_st_offer -offerId ec484fb9-31a0-4332-b6eb-27babe9c9233
```

Please refer to the [Microsoft documentation](https://learn.microsoft.com/en-us/azure/marketplace/plan-azure-app-managed-app#deployment-package) for more information on how to package your managed application offer.

### Create/Update the Azure Application Managed Application Offer

A [script](../../../scripts/solutionTemplateOfferAddUpdate.ps1) is provided in the `scripts` folder of this repository to create the Azure Application Managed Application offer. The script will package the solution, create an offer if it does not already exist, create a plan if it does not already exist, and upload the solution package and offer assets (logos). You can also use this script to update the offer or plan.

```
./solutionTemplateOfferAddUpdate.ps1 -assetsFolder ../samples/managed-application/base-image-vm
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

### Publishing the Azure Application Managed Application Offer
Once the draft offer created in the above step has been reviewed and confirmed, the offer can be submitted for publishing.

To start the publishing process:
```
./solutionTemplateOfferPublish.ps1 -manifestFile ../samples/managed-application/base-image-vm/manifest.yml
```