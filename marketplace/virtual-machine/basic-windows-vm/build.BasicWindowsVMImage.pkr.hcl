# Copyright (c) Microsoft Corporation. All rights reserved.
# Licensed under the MIT License.
build {

  sources = ["source.azure-arm.windowsvhd"]

  # Install tools
  provisioner "powershell" {
    inline = [
      "Set-ItemProperty -Path HKLM:\\SYSTEM\\CurrentControlSet\\Services\\Audiosrv -Name Start -Value 00000002",
      "Write-Output 'TASK COMPLETED: Audio enabled'",

      "Set-ExecutionPolicy Bypass -Scope Process -Force; [System.Net.ServicePointManager]::SecurityProtocol = [System.Net.ServicePointManager]::SecurityProtocol -bor 3072; iex ((New-Object System.Net.WebClient).DownloadString('https://community.chocolatey.org/install.ps1'))",
      "Write-Output 'TASK COMPLETED: Chocolatey installed'",

      "choco install -y 7zip",
      "choco install -y microsoft-edge",
      "choco install -y Pester",
      "Write-Output 'TASK COMPLETED: Chocolatey packages installed...'",

      "New-Item -ItemType 'directory' -Path 'C:\\LGPO'",
      "$client = new-object System.Net.WebClient",
      "$client.DownloadFile('${var.dlink_lgpo_tool}','C:\\LGPO\\LGPO.zip')",
      "7z x 'C:\\LGPO\\LGPO.zip' -oC:\\LGPO\\",
      "Add-Content 'C:\\LGPO\\GPUPolicies-Add.txt' \"Computer`r`nSOFTWARE\\Policies\\Microsoft\\Windows\\Server\\ServerManager`r`nDoNotOpenAtLogon`r`nDWORD:1`r`n\"",
      "C:\\LGPO\\LGPO_30\\LGPO.exe /t 'C:\\LGPO\\GPUPolicies-Add.txt'",
      "Remove-Item -Path 'C:\\LGPO' -Recurse -Force",
      "Write-Output 'TASK COMPLETED: GPU policies configured...'",
    ]
  }

  # Upload test file to VM
  provisioner "file" {
    source = "tests/validateImage.ps1"
    destination = "/tmp/"
  }

  # Install Pester and run the test suite
  provisioner "powershell" {
    inline = [
      "Import-Module Pester",
      "$config = [PesterConfiguration]::Default",
      "$config.Run.Path = '/tmp/validateImage.ps1'",
      "$config.TestResult.Enabled = $true",
      "Invoke-Pester -Configuration $config",
      "Write-Output 'TASK COMPLETED: Pester tests invoked...'",
    ]
  }

  # Clean up Pester and temporary files
  provisioner "powershell" {
    inline = [
      "choco uninstall -y Pester",
      "if (Test-Path '/tmp/validateImage.ps1') {Remove-Item '/tmp/validateImage.ps1'}",
      "Write-Output 'TASK COMPLETED: Pester clean up completed...'"
    ]
  }

  # Restart VM
  provisioner "windows-restart" {
    restart_check_command = "powershell -command \"& {Write-Output 'Packer Build VM restarted'}\""
  }

  # Sysprep
  provisioner "powershell" {
    inline = [
      "while ((Get-Service RdAgent).Status -ne 'Running') { Start-Sleep -s 5 }",
      "while ((Get-Service WindowsAzureGuestAgent).Status -ne 'Running') { Start-Sleep -s 5 }",
      "& $env:SystemRoot\\System32\\Sysprep\\Sysprep.exe /oobe /generalize /mode:vm /quiet /quit",
      "while($true) { $imageState = Get-ItemProperty HKLM:\\SOFTWARE\\Microsoft\\Windows\\CurrentVersion\\Setup\\State | Select ImageState; if($imageState.ImageState -ne 'IMAGE_STATE_GENERALIZE_RESEAL_TO_OOBE') { Write-Output $imageState.ImageState; Start-Sleep -s 10  } else { break } }"
    ]
  }
}
