# Copyright (c) Microsoft Corporation.
# Licensed under the MIT License.

####################################################################################################
# This script generates a config.yml from your Azure credentials object.                           #
####################################################################################################

Param (
    [Parameter(Mandatory = $True, HelpMessage = "Output file path")]
    [String] $outFile = "config.yml"
)

$connectionObject = $env:AZURE_CREDENTIALS | ConvertFrom-Json
$contents = @"
aad_id: $($connectionObject.clientId)
aad_secret: $($connectionObject.clientSecret)
tenant_id: $($connectionObject.tenantId)
"@
$contents.ToString() | Out-File -FilePath $outFile -Encoding utf8 -Force
