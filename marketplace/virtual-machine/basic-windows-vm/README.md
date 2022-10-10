# Virtual Machine Offer using Windows Server 2019 Virtual Machine Image with Added Tools

This offer template demonstrates how to create a Windows Server 2019 virtual machine image with Chocolatey and Microsoft Edge installed. The image can then be used to create an Azure Virtual Machine offer using the Azure Partner Center CLI.

Please refer to the [Microsoft documentation](https://learn.microsoft.com/en-us/azure/marketplace/marketplace-virtual-machines) for more information about the Azure Virtual Machine offer type.

## Step 1: Install dependencies

Follow the set-up instructions [here](../../../README.md) to install all of the required dependencies.

## Step 2: Login to Azure

Sign in using the Azure CLI and if you don't already have an existing storage account, you can create one. Replace "MyResourceGroup" with your own resource group name.
```
az login
az group create --name MyResourceGroup --location westus
az storage account create -n mystorageacct -g MyResourceGroup -l westus --sku Standard_LRS
```

## Step 3: Add config.yml file

To run the Azure Portal CLI commands for virtual machine offers, you will need to create a `config.yml` in the `scripts` directory. You can create a copy from the [config.yml.tmpl](../../../scripts/config.yml.tmpl) template file and fill in the following values:
- aad_id: the client ID of the Azure AD application associated with your Partner Center account
- aad_secret: the client secret of the Azure AD application associated with your Partner Center account
- tenant_id: the tenant ID of the Azure AD application associated with your Partner Center account

## Step 4: Modify the template for your use case
You can use this offer template as a base for your own VM offer. Modify the noted files below to suit your needs.

### Customize the Packer templates
HCL2 Packer templates have been used to describe how your image should be set up and configured.

The builder template (`build.BasicWindowsVMImage.pkr.hcl`) defines what tools and customizations are to be installed as part of the image.
The source template (`source.windowsvhd.pkr.hcl`) defines the configuration for the image.

Please refer to the [Hashicorp Packer documentation](https://www.packer.io/docs/templates/hcl_templates) for more information on how to write HCL2 Packer templates.

### Customize the Virtual Machine offer
The [listing_config.json](listing_config.json) is the listing configuration that defines how the Virtual Machine offer and plans will be set up in Microsoft Partner Center.

Some of the properties available for customization are: publisher ID, offer descriptions, [categories](https://learn.microsoft.com/en-us/azure/marketplace/cloud-partner-portal-api-creating-offer#azure-marketplace-categories), terms & conditions, private preview audience. The configuration of multiple plans and their regions, availability, technical configuration and pricing can also be updated.

Within the listing configuration, there are some dynamic variables embedded to simplify the process for management of the offer logos and the VHD image URI for a plan. These can be changed, however they have been added in to simplify the process and are managed within the virtual machine offer creation script.

Please refer to the [Microsoft documentation](https://docs.microsoft.com/en-us/azure/marketplace/cloud-partner-portal-api-setting-price) for more information on the different pricing models for virtual machine offers.

### Update the tests for your use case
[Pester](https://pester.dev/), a Powershell testing framework, has been used to verify the image configuration. The tests are executed during the Packer build, before the VHD is created. If the tests do not pass, the image will not be created in Azure.

If changes are made to the build Packer template (`build.BasicWindowsVMImage.pkr.hcl`), the tests ([`validateImage.ps1`](tests/validateImage.ps1)) may also require changes to pass.

Please refer to the [Pester documentation](https://pester.dev/docs/quick-start) for more information on how to write Pester tests.

## Step 5: Create the virtual machine image
Update the [variables.pkr.json](variables.pkr.json) to match your newly created storage account and resource group. You can also modify any of the other variables in the file to fit your need.

Build the image and get the VHD URI by running the following command:
```
./build_virtualMachineImage.ps1 -templateDirectory ../marketplace/virtual-machine/basic-windows-vm
```

Once the script has completed successfully, it will output the SAS URI of the VHD created in the storage account. Take a copy of the URI for the next step.

## Step 6: Validate the virtual machine image
Before creating a virtual machine offer using the image created in the step above, we need to run it through a validation process to ensure that the image meets all of the Azure Marketplace publishing requirements. The VHD URI returned in the previous step will be required.

In the `scripts` directory, run:
```
./validate_virtualMachineImage.ps1 -vhdUri "<VHD URI>" -location westus
```

Please refer to the [Microsoft documentation](https://docs.microsoft.com/en-us/azure/marketplace/azure-vm-image-test) on more information about validating your virtual machine image.

### Manually Verifying the Image

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

## Step 7: Create the virtual machine offer
Before we create the virtual machine offer, we need to update the `publisherId` in the [offer listing config](listing_config.json). Once updated, we can create the virtual machine offer, using the VHD URI returned from the **Create the virtual machine image** step.

In the `scripts` directory, run:
```
./add_virtualMachineOffer.ps1 -vhdUri "<VHD URI>" -vmOfferConfigFile ../marketplace/virtual-machine/basic-windows-vm/listing_config.json -logosPath ../marketplace/virtual-machine/basic-windows-vm/logos -storageAccountName mystorageacct
```

During the execution of this script, dynamic variables will be parsed into the `listing_config.json` file, and the script exports the updated copy (`tmp_listing_config.json`). The exported copy will contain the URIs (including the Shared Access Signatures) of the VHD image and the uploaded offer logo images.

Once the script has completed successfully, a draft virtual machine offer will have been created in [Microsoft Partner Center](https://partner.microsoft.com/en-us/dashboard/marketplace-offers/overview).

## Step 8: Publishing a Virtual Machine Offer
Once the draft offer created in the above step has been reviewed and confirmed, the offer can be submitted for publishing.

To start the publishing process:
```
azpc vm publish --name "<Offer Name>" --app-path ../marketplace/virtual-machine/basic-windows-vm --config-json listing_config.json --notification-emails "<Email Address/es>"
```
