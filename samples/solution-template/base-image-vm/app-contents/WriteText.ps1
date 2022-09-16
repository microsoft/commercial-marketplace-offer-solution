# Copyright (c) Microsoft Corporation. All rights reserved.
# Licensed under the MIT License.
Param (
    [String] $fileName = "MyFile",
    [String] $fileContent = "MyContent"
)

Set-Location -Path "C:\"
Set-Content "$fileName.txt" $fileContent