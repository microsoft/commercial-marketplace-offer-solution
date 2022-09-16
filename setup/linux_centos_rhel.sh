#!/bin/bash
set -e

# Copyright (c) Microsoft Corporation.
# Licensed under the MIT License.

####################################################################################################
# This script installs the following tools in your Mac OS machine:                                 #
# - Azure CLI                                                                                      #
# - Bicep                                                                                          #
# - Packer                                                                                         #
# - Pester                                                                                         #
# - PowerShell                                                                                     #
####################################################################################################

# Install Azure CLI
sudo rpm --import https://packages.microsoft.com/keys/microsoft.asc
echo "Installing Azure CLI..."
echo -e "[azure-cli]
name=Azure CLI
baseurl=https://packages.microsoft.com/yumrepos/azure-cli
enabled=1
gpgcheck=1
gpgkey=https://packages.microsoft.com/keys/microsoft.asc" | sudo tee /etc/yum.repos.d/azure-cli.repo
sudo yum install -y azure-cli

# Install Bicep
echo "Installing Bicep..."
az bicep install

# Install Packer
echo "Installing Packer..."
sudo yum install -y yum-utils
sudo yum-config-manager --add-repo https://rpm.releases.hashicorp.com/RHEL/hashicorp.repo
sudo yum -y install packer

# Install PowerShell
echo "Installing PowerShell..."
sudo yum install -y https://github.com/PowerShell/PowerShell/releases/download/v7.2.4/powershell-lts-7.2.4-1.rh.x86_64.rpm

# Install Pester
echo "Installing Pester..."
pwsh -Command "Install-Module -Name Pester -Force -SkipPublisherCheck"
pwsh -Command "Import-Module Pester -Passthru"