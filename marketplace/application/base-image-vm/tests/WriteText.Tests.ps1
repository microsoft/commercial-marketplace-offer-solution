# Copyright (c) Microsoft Corporation.
# Licensed under the MIT License.

BeforeAll {
    Set-Location app-contents
}

Describe 'WriteText' {
    It 'Given no parameters, it sets default content on default file' {
        ./WriteText.ps1

        $content = Get-Content -Path "C:\MyFile.txt"
        $content | Should -Be "MyContent"

        Remove-Item "C:\MyFile.txt"
    }

    It 'Given filename, it sets default content on specified file' {
        ./WriteText.ps1 -fileName "testfile"

        $content = Get-Content -Path "C:\testfile.txt"
        $content | Should -Be "MyContent"

        Remove-Item "C:\testfile.txt"
    }

    It 'Given content, it sets content on default file' {
        ./WriteText.ps1 -fileContent "testcontent"

        $content = Get-Content -Path "C:\MyFile.txt"
        $content | Should -Be "testcontent"

        Remove-Item "C:\MyFile.txt"
    }

    It 'Given filename and content, it sets content on specified file' {
        ./WriteText.ps1 -fileName "testfile" -fileContent "testcontent"

        $content = Get-Content -Path "C:\testfile.txt"
        $content | Should -Be "testcontent"

        Remove-Item "C:\testfile.txt"
    }
}

AfterAll {
    Set-Location ..
}
