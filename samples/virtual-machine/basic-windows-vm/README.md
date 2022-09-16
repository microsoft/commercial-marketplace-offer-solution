# Sample - Virtual Machine Offer using Windows Server 2019 Virtual Machine Image with Added Tools

This sample demonstrates how to create a Windows Server 2019 virtual machine image with Chocolatey and Microsoft Edge installed. The image can then be used to create an Azure Virtual Machine offer using the Azure Partner Center CLI.

## Get Started

Follow the set-up instructions [here](../../../README.md) to install all of the required dependencies.

Sign in using the Azure CLI and if you don't already have an existing storage account, you can create one. Replace "MyResourceGroup" with your own resource group name.
```
az login
az group create --name MyResourceGroup --location westus
az storage account create -n mystorageacct -g MyResourceGroup -l westus --sku Standard_LRS
```

## Deploy the Sample Locally

In the [scripts](../../../scripts) folder of this repository, you will find the PowerShell scripts you can use to deploy the VM offer sample.

### Create Configuration Files
There are a couple of configuration files that are required for the following steps.
1. Copy [`config.json.tmpl`](../../../scripts/config.json.tmpl) and create new file `config.json`.
2. Complete `config.json`.
    * **tenantId**: Who will publish the offer
    * **subscriptionId**: Who will be the preview audience
    * **clientId** and **clientSecret**: Service principal used for calling partner API
    * **managedAppPrincipalId**: Service principal will have access to managed resource group
    * **publisherId**: The Partner Center publishing account ID
    * **location**: What region will the Azure resources be deployed to
    * **adminPassword**: The admin password for the virtual machine configuration
    * **storageAccountName**: The name of the storage account created above
    * **storageAccountKey**: One of the access keys of the storage account created above


#### config.json
```json
{
  "aad": {
    "tenantId": "<Azure Tenant ID>",
    "clientId": "<Service Principal ID>",
    "clientSecret": "<Service Principal Secret>"
  },
  "partnerCenter": {
    "managedAppPrincipalId": "<Service Principal ID>",
    "publisherId": "<Partner Center Publisher ID>"
  },
  "azure": {
    "subscriptionId": "<Azure Subscription>",
    "location": "<Azure Region>",
    "adminPassword": "<Admin Password>",
    "storageAccountName": "<Azure Storage Name>",
    "storageAccountKey": "<Azure Storage Access Key>"
  }
}
```

Please refer to the [Microsoft documentation](https://docs.microsoft.com/en-us/cli/azure/create-an-azure-service-principal-azure-cli) on more information on how to create a Service Principal.

### Creating the Virtual Machine Image
Update the [variables.pkr.json](variables.pkr.json) to match your newly created storage account and resource group. You can also modify any of the other variables in the file to fit your need.

Build the image.
```
./imageBuild.ps1 -assetsFolder ../samples/virtual-machine/basic-windows-vm
```

Once the script has completed successfully, it will output the URI the VHD created in the storage account. Take a copy of the URI for the following step.

### Validating the Virtual Machine Image
Before creating a virtual machine offer using the image created in the step above, we need to run it through a validation process to ensure that the image meets all of the Azure Marketplace publishing requirements. The VHD URI returned in the previous step will be required.

```
.\validateVmImage.ps1 -vhdUri "<VHD URI>" -configJsonFile config.json
```

Please refer to the [Microsoft documentation](https://docs.microsoft.com/en-us/azure/marketplace/azure-vm-image-test) on more information about validating your virtual machine image.

### Creating a Virtual Machine Offer
Create the virtual machine offer, using the VHD URI returned from the **Creating the Virtual Machine Image** step.

```
.\vmOfferAdd.ps1 -vhdUri "<VHD URI>" -configFile config.json -vmOfferConfig ../samples/virtual-machine/basic-windows-vm/vmOfferConfig.json -logoPath ../samples/virtual-machine/basic-windows-vm/logos
```

During the execution of this script, dynamic variables will be parsed into the `vmOfferConfig.json` file, and the script exports the updated copy (`parsed_vmOfferConfig.json`). The exported copy will contain the URIs (including the Shared Access Signatures) of the VHD image and the uploaded offer logo images.

Once the script has completed successfully, a draft virtual machine offer will have been created in [Microsoft Partner Center](https://partner.microsoft.com/en-us/dashboard/marketplace-offers/overview).

### Publishing a Virtual Machine Offer
Once the draft offer created in the above step has been reviewed and confirmed, the offer can be submitted for publishing.

To start the publishing process:
```
.\vmOfferPublish.ps1 -configFile config.json -vmOfferConfigFile ..\samples\virtual-machine\basic-windows-vm\vmOfferConfig.json -notificationEmails -notificationEmails "<Email Address/es>"
```


## Deploy the Sample using Azure DevOps
A simpler approach to deploying your samples is to use the pre-built Azure DevOps pipeline files. These pipelines will manage the virtual machine image and offer creation, as well as publishing.

1. Fork the [repository](https://dev.azure.com/AZGlobal/Azure%20Global%20CAT%20Engineering/_git/AGCI-Marketplace-Scripts).
2. [Create a Service Principal](https://docs.microsoft.com/en-us/cli/azure/create-an-azure-service-principal-azure-cli) so that the pipeline can have access to your Azure and Partner Center resources.
3. [Create an Azure Key Vault](https://docs.microsoft.com/en-us/azure/key-vault/general/quick-create-portal) to store your Azure and Partner Center secrets. Ensure that your Service Principal has access to the Key Vault.
4. [Create a Service Connection](https://docs.microsoft.com/en-us/azure/devops/pipelines/library/service-endpoints?view=azure-devops&tabs=yaml) in Azure DevOps and connect it to your newly created Service Principal.
5. Create a variable group in Azure DevOps for your secrets. Be sure to enable "Link secrets from an Azure key vault as variables".
6. [Create the pipeline](https://docs.microsoft.com/en-us/azure/devops/pipelines/create-first-pipeline?view=azure-devops&tabs=java%2Ctfs-2018-2%2Cbrowser) in Azure DevOps:
    * Create a new pipeline to create the virtual machine offer, selecting the existing YAML pipeline file [createVmOffer.yml](../../../createVmOffer.yml).
        * Replace the `serviceConnection` value with your newly created Service Connection name.
        * Replace the variables group value with your variable group name.
        * Save your changes.
    * Create a new pipeline to publish your virtual machine offer, selecting the existing YAML pipeline file [publishVmOffer.yml](../../../publishVmOffer.yml).
        * Replace the `serviceConnection` value with your Service Connection name.
        * Replace the variables group value with your variable group name.
        * Save your changes.
7. [Create a branch policy](https://docs.microsoft.com/en-us/azure/devops/pipelines/release/deploy-pull-request-builds?view=azure-devops#set-up-branch-policy-for-azure-repos) on the branch of your forked repository so that the virtual machine image and offer creation pipeline will be triggered when a pull request is created, and the publish pipeline is triggered on merge into `main`.
8. Make a change to the virtual machine sample files, commit the change, and raise a pull request.
9. Merge the pull request into the `main` branch.


## Modifying the Sample For Your Use Case

You can use this sample as a base for your own VM offer. Modify the noted files below to suit your needs.

### Customize the Packer templates

HCL2 Packer templates have been used to describe how your image should be set up and configured.

The builder template (`build.BasicWindowsVMImage.pkr.hcl`) defines what tools and customizations are to be installed as part of the image.
The source template (`source.windowsvhd.pkr.hcl`) defines the configuration for the image.

Please refer to the [Hashicorp Packer documentation](https://www.packer.io/docs/templates/hcl_templates) for more information on how to write HCL2 Packer templates.

### Customize the Virtual Machine Offer

The [vmOfferConfig.json](./vmOfferConfig.json) is the listing configuration that defines how the Virtual Machine offer and plans will be set up in Microsoft Partner Center.
Some of the properties available for customization are offer descriptions, categories, terms & conditions, private preview audience. The configuration of multiple plans and their regions, availability, technical configuration and pricing can also be updated.
Within the listing configuration, there are some dynamic variables embedded to simplify the process for management of the offer logos and the VHD image URI for a plan. These can be changed, however they have been added in to simplify the process and are managed within the virtual machine offer creation script.

Please refer to the [Microsoft documentation](https://docs.microsoft.com/en-us/azure/marketplace/cloud-partner-portal-api-setting-price) for more information on the different pricing models for virtual machine offers.

### Update the Tests For Your Use Case

[Pester](https://pester.dev/), a Powershell testing framework, has been used to verify the image configuration. The tests are executed during the Packer build, before the VHD is created. If the tests do not pass, the image will not be created in Azure.

If changes are made to the build Packer template (`build.BasicWindowsVMImage.pkr.hcl`), the tests ([`validateImage.ps1`](tests\validateImage.ps1)) may also require changes to pass.

Please refer to the [Pester documentation](https://pester.dev/docs/quick-start) for more information on how to write Pester tests.

## Manually Verifying the Image

During the build of the image, a suite of tests are run to ensure that the VM the image is built from, is configured correctly.

To manually verify the image, create a VM from the managed image.
```
az group create --name MyVmResourceGroup --location westus
az image create -g MyVmResourceGroup -n MyImage --os-type Windows --storage-sku Standard_LRS --source <VHD URI>
az vm create -g MyVmResourceGroup -n MyVm --image MyImage --size Standard_D2_v3 --public-ip-sku Standard --admin-username azureuser --admin-password 'YOUR_PASSWORD' --nsg MyNSG --nsg-rule RDP
```

Clean up the resources by deleting the VM resource group:
```
az group delete -n MyVmResourceGroup
```