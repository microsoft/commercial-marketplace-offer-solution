# Commercial Marketplace Offer Templates
This repository provides an easy way to get started on publishing an offer to the Microsoft [Commercial Marketplace](https://learn.microsoft.com/en-us/azure/marketplace/overview).

Included in this repository are:
- Azure Application and Azure Virtual Machine offer type templates
- GitHub actions and starter workflows to help you get started with automation
- Scripts to help you run common tasks, such as creating a VM image

These templates are designed to be a starting point for your offer and are not intended to be a complete solution. You are free to modify the templates to meet your needs.

## Getting Started

### Step 1: Create a repository
The easiest way to get started is to use the [GitHub Template Repository](https://help.github.com/en/github/creating-cloning-and-archiving-repositories/creating-a-repository-from-a-template) feature to create a new repository from this template. You can also fork or clone this repository and modify the files to meet your needs.

### Step 2: Install Tools

The templates and scripts in this repository use the following tools:
- [Azure CLI](https://docs.microsoft.com/en-us/cli/azure/install-azure-cli?view=azure-cli-latest)
- [Bicep](https://docs.microsoft.com/en-us/azure/azure-resource-manager/bicep/install#azure-cli)
- [Packer](https://www.packer.io/downloads)
- [Azure Partner Center CLI](https://github.com/microsoft/az-partner-center-cli)
- [Pester](https://pester.dev/docs/introduction/installation)
- [PowerShell](https://docs.microsoft.com/en-us/powershell/scripting/install/installing-powershell)
- [Python 3.7+](https://www.python.org/downloads/)

Please refer to the setup scripts for your operating system for easy installation:
- [Linux (Ubuntu/Debian)](setup/linux_ubuntu_debian.sh)
- [Linux (CentOS/RHEL)](setup/linux_centos_rhel.sh)
- [macOS](setup/macos.sh) - installs and uses [Homebrew](https://brew.sh/) to install tools.
- [Windows](setup/windows.ps1) - installs and uses [Chocolatey](https://chocolatey.org/) (default) to install tools. To install without Chocolatey, run `./windows.ps1 -useChocolatey $false`.

### Step 3: Associate an Azure AD application with your Partner Center account

The scripts in this repository use the Partner Center API to create and manage offers. To use the scripts, you must first associate an Azure AD application with your Partner Center account. Follow the instructions in the Commercial Marketplace [documentation](https://learn.microsoft.com/en-us/azure/marketplace/submission-api-onboard) to create an Azure AD application and associate it with your Partner Center account.

### Step 4: Modify Offer Template Files

Use the following offer templates to build your own Commercial Marketplace offerings. Each offer template includes a README file that contains instructions on how to build the offer and modify it for your use case.

### [Solution Template with Custom Script Extension](marketplace/application/base-image-vm/README.md)

This offer template demonstrates how to build a solution template Azure Application offer. This offer deploys a Windows Server 2019 VM and runs a custom script extension that writes content to a file. The custom script extension runs a PowerShell script after the VM has been provisioned.

### [Windows Server 2019 Virtual Machine with Added Tools](marketplace/virtual-machine/basic-windows-vm/README.md)

This offer template demonstrates how to create a Windows Server 2019 virtual machine image with Chocolatey and Microsoft Edge installed. The image can then be used to create an Azure Virtual Machine offer.

### Step 5: Create GitHub Workflows

GitHub [actions](.github/actions/) and [starter workflows](workflow-templates/) are provided to automate the build, test and publish process for Commercial Marketplace offers.

Before using a workflow or action, create a new **actions** repository secret (AZURE_CREDENTIALS) with the following:
```
{
  "clientId": "<Azure AD application client ID>",
  "clientSecret": "<Azure AD application client secret>",
  "subscriptionId": "<Azure subscription ID>",
  "tenantId": "<Azure AD application tenant ID>",
  "resourceManagerEndpointUrl": "https://management.azure.com/"
}
```

For more information on creating a GitHub actions repository secret, see [Creating encrypted secrets for a repository](https://docs.github.com/en/actions/security-guides/encrypted-secrets#creating-encrypted-secrets-for-a-repository).

To use an action, refer to it as follows in your workflow:
```
microsoft/commercial-marketplace-offer-solution/.github/actions/[ACTION DIRECTORY]
```
For example:
```
steps:
  - name: Build and create/update offer
    uses: microsoft/commercial-marketplace-offer-solution/.github/actions/commercial-marketplace
```
Refer to the GitHub documentation for more information on using [starter workflows](https://docs.github.com/en/actions/using-workflows/using-starter-workflows).

## Future Work
This repository is still under development. We are working to add more offer templates and scripts for testing and automation.

## Contribute
Contributions to this repository are welcome. Here's how you can contribute:
- Submit bugs and help us verify fixes.
- Submit feature requests and help us implement them.
- Submit pull requests for bug fixes and features.

Please refer to [Contribution Guidelines](CONTRIBUTING.md) for more details.

## Trademarks

This project may contain trademarks or logos for projects, products, or services. Authorized use of Microsoft trademarks or logos is subject to and must follow [Microsoft's Trademark & Brand Guidelines](https://www.microsoft.com/en-us/legal/intellectualproperty/trademarks/usage/general). Use of Microsoft trademarks or logos in modified versions of this project must not cause confusion or imply Microsoft sponsorship. Any use of third-party trademarks or logos are subject to those third-party's policies.
