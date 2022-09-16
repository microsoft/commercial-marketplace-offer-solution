#!/bin/bash
set -e

# Copyright (c) Microsoft Corporation.
# Licensed under the MIT License.

####################################################################################################
# This script installs the following tools in your Mac OS machine:                                 #
# - Azure CLI                                                                                      #
# - Bicep                                                                                          #
# - Homebrew                                                                                       #
# - Packer                                                                                         #
# - Partner Center CLI                                                                             #
# - Pester                                                                                         #
# - PowerShell                                                                                     #
####################################################################################################

# Provide a path for the Python virtual environment
venvPath="${1:-myEnv}"

# Install Homebrew
which brew
if [[ $? != 0 ]] ; then
    echo "Installing Homebrew..."
    /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
else
    echo "Updating Homebrew..."
    brew update
fi

# Install Azure CLI
echo "Installing Azure CLI..."
brew install azure-cli

# Install Bicep
echo "Installing Bicep..."
az bicep install

# Install Packer
echo "Installing Packer..."
brew tap hashicorp/tap
brew install hashicorp/tap/packer

# Install PowerShell
echo "Installing PowerShell..."
brew install powershell/tap/powershell

# Install Pester
echo "Installing Pester..."
pwsh -Command "Install-Module -Name Pester -Force -SkipPublisherCheck"
pwsh -Command "Import-Module Pester -Passthru"

# Install Partner Center CLI
if [[ "$(python3 -V)" =~ "Python 3" ]]; then
    echo "Installing Partner Center CLI..."
    echo "Creating new virtual environment at $venvPath..."
    python3 -m venv $venvPath
    echo "Activating virtual environment at $venvPath..."
    source $venvPath/bin/activate
    if [[ $VIRTUAL_ENV =~ $venvPath ]]; then
        echo "Installing Partner Center CLI in $venvPath..."
        pip install --upgrade pip
        pip install az-partner-center-cli
        deactivate
    fi
else
    echo "Please install Python 3.7 or higher to install the Partner Center CLI."
fi