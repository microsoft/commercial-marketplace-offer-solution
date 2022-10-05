# Virtual Machine Offer using Windows Server 2019 Virtual Machine Image with Added Tools

This offer template demonstrates how to create a Windows Server 2019 virtual machine image with Chocolatey and Microsoft Edge installed. The image can then be used to create an Azure Virtual Machine offer using the Azure Partner Center CLI.

Please refer to the [Microsoft documentation](https://learn.microsoft.com/en-us/azure/marketplace/marketplace-virtual-machines) for more information about the Virtual Machine offer type.

## Step 1: Install Tools

Follow the set-up instructions [here](../../../README.md) to install all of the required dependencies.

Sign in to your Azure account:
```
az login
```

## Step 2: Modify the Template For Your Use Case

You can use this template as a base for your own virtual machine offer. Modify the noted files below to suit your needs.

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


## Step 3: Create the virtual machine image

In the [scripts](../../../scripts) folder of this repository, you will find the PowerShell scripts you can use to create a virtual machine image.

1. If you don't already have an existing storage account, you can create one. Replace "MyResourceGroup" with your own resource group name.
```
az group create --name MyResourceGroup --location westus
az storage account create -n mystorageacct -g MyResourceGroup -l westus --sku Standard_LRS
```

2. Update the [variables.pkr.json](variables.pkr.json) to match your newly created storage account and resource group. You can also modify any of the other variables in the file to fit your need.

3. Build the image. Once the script has completed successfully, it will output the URI the VHD created in the storage account. Take a copy of the URI for the following steps.
```
./build_virtualMachineImage.ps1 -assetsFolder ../marketplace/virtual-machine/basic-windows-vm
```

## Step 4: Test the virtual machine image

1. Create a temporary resource group. Replace "MyVmResourceGroup" with your own resource group name.
```
az group create --name MyVmResourceGroup --location westus
```

2. Create an image using the VHD URI. Replace "MyVmResourceGroup" with your own resource group name. Replace "VHD URI" with the URI saved from the previous steps.
```
az image create -g MyVmResourceGroup -n MyImage --os-type Windows --storage-sku Standard_LRS --source "VHD URI>"
```

3. Create a virtual machine from the image created. Replace "MyVmResourceGroup" with your own resource group name.
```
az vm create -g MyVmResourceGroup -n MyVm --image MyImage --size Standard_D2_v3 --public-ip-sku Standard --admin-username azureuser --admin-password 'YOUR_PASSWORD' --nsg MyNSG --nsg-rule RDP
```

4. Manually verify the virtual machine is configured as expected.

5. Clean up the resources. Replace "MyVmResourceGroup" with your own resource group name.
```
az group delete -n MyVmResourceGroup
```

## Step 5: Prepare the Offer

Before creating a virtual machine offer using the custom image created above, it must be validated to ensure the image meets all of the Azure Marketplace publishing requirements.

Replace "VHD URI" with the URI saved from the previous steps.
```
./validate_virtualMachineImage.ps1 -vhdUri "VHD URI" -configJsonFile config.json
```

Please refer to the [Microsoft documentation](https://docs.microsoft.com/en-us/azure/marketplace/azure-vm-image-test) on more information about validating your virtual machine image.


### Create a Virtual Machine Offer

A [script](../../../scripts/add_virtualMachineOffer.ps1) is provided in the `scripts` folder of this repository to create the Virtual Machine offer.

The script will create an offer if it does not already exist, create a plan if it does not already exist (using the supplied VHD URI) and upload the offer assets (logos).

During the execution of the script, dynamic variables are parsed into the [offer listing config](vmOfferConfig.json), and the script exports an updated copy (`parsed_vmOfferConfig.json`). The exported copy will contain the URIs (including the Shared Access Signatures) of the VHD image and the uploaded offer logos.

Replace "VHD URI" with the URI saved from the previous steps.

```
./add_virtualMachineOffer.ps1 -vhdUri "VHD URI" -configFile config.json -vmOfferConfig ../marketplace/virtual-machine/basic-windows-vm/vmOfferConfig.json -logoPath ../marketplace/virtual-machine/basic-windows-vm/logos
```

Before running the script, you will need to set the following variables in the [configuration file](../../../scripts/config.json) and [offer listing config](vmOfferConfig.json):

1. Copy [`config.json.tmpl`](../../../scripts/config.json.tmpl) and create new file `config.json`.
2. Complete `config.json`.
    * **tenantId**: Who will publish the offer
    * **subscriptionId**: Who will be the preview audience
    * **clientId** and **clientSecret**: Service principal used for calling partner API
    * **managedAppPrincipalId**: Service principal will have access to managed resource group
    * **publisherId**: The Partner Center publishing account ID
    * **location**: What region will the Azure resources be deployed to
    * **adminPassword**: The admin password for the virtual machine configuration
    * **storageAccountResourceGroup**: The resource group of the storage account created above
    * **storageAccountName**: The name of the storage account created above
    * **storageAccountKey**: One of the access keys of the storage account created above
3. Update the publisher (`publisherId`) in [`vmOfferConfig.json`](vmOfferConfig.json).

Please refer to the [Microsoft documentation](https://docs.microsoft.com/en-us/cli/azure/create-an-azure-service-principal-azure-cli) on more information on how to create a Service Principal.


### Publishing a Virtual Machine Offer
Once the draft offer created in the above step has been reviewed and confirmed, the offer can be submitted for publishing.

To start the publishing process:
```
azpc vm publish --name "<Offer Name>" --app-path ../marketplace/virtual-machine/basic-windows-vm --config-json parsed_vmOfferConfig.json --notification-emails "<Email Address/es>"
```
