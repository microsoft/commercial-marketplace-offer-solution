# Copyright (c) Microsoft Corporation.
# Licensed under the MIT License.

####################################################################################################
# This helper script pulls the storage account name out of the provided connection string          #
####################################################################################################
param (
    [String] $connectionString
)

$acctName = ""
$bla = $connectionString.Split(";")
foreach ($item in $bla) {
    $kv = ([String]$item).Split("=")
    if ($kv[0] -eq "AccountName") {
        $acctName = $kv[1]
        break
    }
}

Write-Output $acctName