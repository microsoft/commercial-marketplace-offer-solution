# Copyright (c) Microsoft Corporation.
# Licensed under the MIT License.

Describe "VM offer image validation" {
    Context "Policy configurations" {
        It "should have audio enabled" {
            (Get-ItemProperty -Path HKLM:\\SYSTEM\\CurrentControlSet\\Services\\Audiosrv).Start | Should -Be 2
        }

        # TODO: Complete this test
        It "should have updated the startup policy for ServerManager" -Skip {

        }
    }

    Context "Chocolatey installations" {
        BeforeAll {
            $packages = choco list --local-only --id-only
        }

        It "should have Chocolatey installed" {
            $packages | Should -Contain "chocolatey"
        }

        It "should have 7zip installed via Chocolatey" {
            $packages | Should -Contain "7zip"
        }

        It "should have Microsoft Edge installed via Chocolatey" {
            $packages | Should -Contain "microsoft-edge"
        }
    }
}