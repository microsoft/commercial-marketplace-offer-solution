# Copyright (c) Microsoft Corporation.
# Licensed under the MIT License.

####################################################################################################
# This script installs the following tools in your Windows machine:                                #
# - Azure CLI                                                                                      #
# - Bicep                                                                                          #
# - Packer                                                                                         #
# - Partner Center CLI                                                                             #
# - Pester                                                                                         #
# - Python 3                                                                                       #
# - Chocolatey (optional)                                                                          #
####################################################################################################
Param (
    [Parameter(Mandatory = $True, HelpMessage = "Specific Python virtual environment path")]
    [string] $venvPath,
    [Parameter(Mandatory = $False, HelpMessage = "Install tools using Chocolatey")]
    [bool] $useChocolatey = $True
)

# Validate input parameters
if (-not(Test-Path $venvPath)) {
    Write-Error "Please provide a valid venv path."
    Exit 1
}

$currentDirectory = Get-Location

function Install-Chocolatey {
    if (-not(Get-Command choco -ErrorAction SilentlyContinue)) {
        Write-Output "Installing Chocolatey..."
        Set-ExecutionPolicy Bypass -Scope Process -Force; [System.Net.ServicePointManager]::SecurityProtocol = [System.Net.ServicePointManager]::SecurityProtocol -bor 3072; iex ((New-Object System.Net.WebClient).DownloadString('https://community.chocolatey.org/install.ps1'))
        Write-Output "Chocolatey installed successfully."
    }
}

function Install-AzureCLI {
    Write-Output "Installing Azure CLI..."
    if ($useChocolatey)
    {
        choco install azure-cli -y
    }
    else
    {
        Invoke-WebRequest -Uri https://aka.ms/installazurecliwindows -OutFile .\AzureCLI.msi; Start-Process msiexec.exe -Wait -ArgumentList '/I AzureCLI.msi /quiet'; rm .\AzureCLI.msi;
    }
    Write-Output "Azure CLI installed successfully."
}

function Install-Bicep {
    Write-Output "Installing Bicep..."
    Start-Process powershell.exe -Wait -ArgumentList 'az bicep install'
    Write-Output "Bicep installed successfully."
}

function Install-Packer {
    Write-Output "Installing Packer..."
    if ($useChocolatey)
    {
        choco install packer -y
        Write-Output "Packer installed successfully."
    }
    else
    {
        if (Test-Path -Path "C:\Program Files\Packer\packer.exe")
        {
            Write-Output "Packer already installed."
        }
        else
        {
            $packerDownloadUri = "https://releases.hashicorp.com/packer/1.8.0/packer_1.8.0_windows_386.zip"
            if ("AMD64" -eq $Env:PROCESSOR_ARCHITECTURE)
            {
                $packerDownloadUri = "https://releases.hashicorp.com/packer/1.8.0/packer_1.8.0_windows_amd64.zip"
            }

            Invoke-WebRequest -Uri $packerDownloadUri -OutFile Packer.zip
            Expand-Archive -LiteralPath Packer.zip -DestinationPath "C:\Program Files\Packer"
            Remove-Item Packer.zip

            Write-Warning "Packer is installed to C:\Program Files\Packer. Please update your PATH environment variable to include this directory. For more information, see https://stackoverflow.com/questions/1618280/where-can-i-set-path-to-make-exe-on-windows."
        }
    }
}

function Install-Pester {
    Write-Output "Installing Pester..."
    if ($useChocolatey)
    {
        choco install Pester -y
    }
    else
    {
        Install-PackageProvider -Name NuGet -Force
        Install-Module -Name Pester -Force -SkipPublisherCheck
        Import-Module Pester -Passthru
    }
    Write-Output "Pester installed and imported successfully."
}

function Install-Python {
    $pythonVersion = py -V
    if (-not $?)
    {
        Write-Output "Installing Python 3..."
        if ($useChocolatey)
        {
            choco install python -y
        }
        else
        {
            $pythonDownloadUri = "https://www.python.org/ftp/python/3.10.4/python-3.10.4-amd64.exe"
            Invoke-WebRequest -Uri $pythonDownloadUri -OutFile "python-3.10.4-amd64.exe"
            $exePath = Get-Item "python-3.10.4-amd64.exe"
            Start-Process -Wait -PassThru -NoNewWindow -FilePath $exePath -ArgumentList "/quiet InstallAllUsers=0 PrependPath=1 Include_test=0"
            Remove-Item -Path "python-3.10.4-amd64.exe"
        }
    }
    else
    {
        Write-Output "$pythonVersion is installed."
    }
}

function Install-PartnerCenterCLI {
    try
    {
        Write-Output "Creating new virtual environment at $venvPath..."
        py -m venv $venvPath
        Write-Output "Activating virtual environment at $venvPath..."
        Set-Location $venvPath\Scripts
        .\Activate.ps1
        Write-Output "Installing Partner Center CLI in $venvPath..."
        pip install az-partner-center-cli
        deactivate
        Set-Location $currentDirectory
        Write-Output "Partner Center CLI installed successfully."
    }
    catch
    {
        Write-Output "There was a problem installing the Partner Center CLI. The CLI requires Python 3.7+ to be installed."
    }
}

if ($useChocolatey)
{
    Install-Chocolatey
}

Install-AzureCLI
Install-Bicep
Install-Packer
Install-Pester
Install-Python
Install-PartnerCenterCLI

Write-Warning "Setup tools installed. Please restart PowerShell to begin using the installed tools."