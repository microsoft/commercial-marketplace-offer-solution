# Commercial Marketplace Samples and Scripts
This repository contains a set of samples and scripts that can be used a starting point for customers to build their own Azure Marketplace offerings.

## Prerequisites
The samples and scripts in this repository uses the following tools:
- [Azure CLI](https://docs.microsoft.com/en-us/cli/azure/install-azure-cli?view=azure-cli-latest)
- [Bicep](https://docs.microsoft.com/en-us/azure/azure-resource-manager/bicep/install#azure-cli)
- [Packer](https://www.packer.io/downloads)
- Azure Partner Center CLI
- [Pester](https://pester.dev/docs/introduction/installation)
- [PowerShell](https://docs.microsoft.com/en-us/powershell/scripting/install/installing-powershell)
- [Python 3.7+](https://www.python.org/downloads/)

Please refer to the setup scripts for your operating system for easy installation:
- [Linux (Ubuntu/Debian)](setup/linux_ubuntu_debian.sh)
- [Linux (CentOS/RHEL)](setup/linux_centos_rhel.sh)
- [macOS](setup/macos.sh) - installs and uses [Homebrew](https://brew.sh/) to install tools.
- [Windows](setup/windows.ps1) - installs and uses [Chocolatey](https://chocolatey.org/) (default) to install tools. To install without Chocolatey, run `./windows.ps1 -useChocolatey $false`.

### Azure Partner Center CLI Installation

The Azure Partner Center CLI requires Python 3.7+ to be installed. Please [download](https://www.python.org/downloads/) the appropriate version of Python and install it on your system. Once Python is installed, create a virtual environment ([venv](https://docs.python.org/3/library/venv.html), [Anaconda](https://www.anaconda.com/)) and install the following packages:

```
pip install --upgrade pip
pip install az-partner-center-cli
```

Here's an example using `venv`:

```
python3 -m venv my_env
source my_env/bin/activate

pip install --upgrade pip
pip install az-partner-center-cli

# to deactivate
deactivate
```

## Samples
Use the following samples to build your own Azure Marketplace offerings. Each sample includes a README file that contains instructions on how to build the sample and modify it for your use case.

### [Solution Template with Custom Script Extension](marketplace/application/base-image-vm/README.md)

This sample demonstrates how to build a solution template Azure Application offer. This sample deploys a Windows Server 2019 VM and runs a custom script extension that writes content to a file. The custom script extension runs a PowerShell script after the VM has been provisioned.

### [Windows Server 2019 Virtual Machine with Added Tools](marketplace/virtual-machine/basic-windows-vm/README.md)

This sample demonstrates how to create a Windows Server 2019 virtual machine image with Chocolatey and Microsoft Edge installed. The image can then be used to create an Azure Virtual Machine offer.

## Automation

GitHub [actions](.github/actions/) and [starter workflows](.github/workflow-templates/) are provided to automate the build, test and publish process for Azure Marketplace offers. To use an action, refer to it as follows in your workflow:
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

### Future Work
This repository is still under development. We are working to add more scripts for testing and automation.

## Contribute
Contributions to this repository are welcome. Here's how you can contribute:
- Submit bugs and help us verify fixes.
- Submit feature requests and help us implement them.
- Submit pull requests for bug fixes and features.

Please refer to [Contribution Guidelines](CONTRIBUTING.md) for more details.

## Trademarks

This project may contain trademarks or logos for projects, products, or services. Authorized use of Microsoft trademarks or logos is subject to and must follow [Microsoft's Trademark & Brand Guidelines](https://www.microsoft.com/en-us/legal/intellectualproperty/trademarks/usage/general). Use of Microsoft trademarks or logos in modified versions of this project must not cause confusion or imply Microsoft sponsorship. Any use of third-party trademarks or logos are subject to those third-party's policies.