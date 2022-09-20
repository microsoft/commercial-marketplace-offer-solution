#!/bin/bash
set -e

# Copyright (c) Microsoft Corporation.
# Licensed under the MIT License.

####################################################################################################
# This script installs the following tools in your Mac OS machine:                                 #
# - Azure CLI                                                                                      #
# - Bicep                                                                                          #
# - Packer                                                                                         #
# - Partner Center CLI                                                                             #
# - Pester                                                                                         #
# - PowerShell                                                                                     #
####################################################################################################

# Provide a path for the Python virtual environment
venvPath="${1}"

# Install Azure CLI
echo "Installing Azure CLI..."
curl -sL https://aka.ms/InstallAzureCLIDeb | sudo bash

# Install Bicep
echo "Installing Bicep..."
az bicep install

# Install Packer
echo "Installing Packer..."
curl -fsSL https://apt.releases.hashicorp.com/gpg | sudo apt-key add -
sudo apt-add-repository "deb [arch=amd64] https://apt.releases.hashicorp.com $(lsb_release -cs) main"
sudo apt-get update && sudo apt-get install packer

# Install PowerShell
if pwsh -Version; then
    echo "PowerShell is already installed."
else
    # Install PowerShell
    echo "Installing PowerShell..."
    # Download package
    curl -L https://github.com/PowerShell/PowerShell/releases/download/v7.2.4/powershell-lts_7.2.4-1.deb_amd64.deb -o powershell-lts_7.2.4-1.deb_amd64.deb
    # Install the downloaded package
    sudo dpkg -i powershell-lts_7.2.4-1.deb_amd64.deb
    # Resolve missing dependencies and finish the install (if necessary)
    sudo apt-get install -f
fi

# Install Pester
echo "Installing Pester..."
pwsh -Command "Install-Module -Name Pester -Force -SkipPublisherCheck"
pwsh -Command "Import-Module Pester -Passthru"

# Install Partner Center CLI
if [[ "$(python3 --version)" =~ "Python 3" ]]; then
    echo "Installing Partner Center CLI..."
    if [[ -z $venvPath ]]; then
        pip install --upgrade pip
        pip install pyOpenSSL --upgrade
        pip install az-partner-center-cli
    else
        echo "Creating new virtual environment at $venvPath..."
        sudo apt-get install python3-venv -y
        python3 -m venv $venvPath
        echo "Activating virtual environment at $venvPath..."
        source $venvPath/bin/activate
        if [[ $VIRTUAL_ENV =~ $venvPath ]]; then
            echo "Installing Partner Center CLI in $venvPath..."
            pip install --upgrade pip
            pip install az-partner-center-cli
            deactivate
        fi
    fi
else
    echo "Please install Python 3.7 or higher to install the Partner Center CLI."
fi