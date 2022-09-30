# Copyright (c) Microsoft Corporation.
# Licensed under the MIT License.
Param (
    [String] $DNSname
)
$DNSNameRegex = '^[a-zA-Z0-9]{1}[a-zA-Z0-9\-\._]{0,78}[a-zA-Z0-9_]{1}$'

# Validate input parameter
if ($DNSName -notmatch $DNSNameRegex) {
    Write-Error "Please provide a valid DNS Name."
    Exit 1
}

Invoke-WebRequest https://raw.githubusercontent.com/Azure/azure-quickstart-templates/master/demos/vm-winrm-windows/ConfigureWinRM.ps1 -OutFile C:/tmp/ConfigureWinRM.ps1
Invoke-WebRequest https://github.com/Azure/azure-quickstart-templates/raw/master/demos/vm-winrm-windows/makecert.exe -OutFile C:/tmp/makecert.exe
Invoke-WebRequest https://raw.githubusercontent.com/Azure/azure-quickstart-templates/master/demos/vm-winrm-windows/winrmconf.cmd -OutFile C:/tmp/winrmconf.cmd
cd C:/tmp
./ConfigureWinRM.ps1 $DNSName