# Copyright (c) Microsoft Corporation.
# Licensed under the MIT License.

####################################################################################################
# This helper script retreives the authentication token for the provided resource that can be used #
# to access the Partner Center and Cloud Partner Portal APIs.                                      #
####################################################################################################
param (
    [String] $tenantId,
    [String] $clientId,
    [String] $clientSecret,
    [String] $resource
)

$tokenUri = "https://login.microsoftonline.com/$tenantId/oauth2/token"
$body = @{
    "resource" = $resource
    "grant_type" = "client_credentials"
    "client_id" = $clientId
    "client_secret" = $clientSecret
}

try {
    $response = Invoke-RestMethod -Method "Post" -Uri $tokenUri -Body $body

    if($response.access_token) {
            Write-Output $response.access_token
        } else {
            throw [System.Exception] "Authentication token was unable to be retrieved, please try again."
        }

} catch {
    throw [System.Exception] ("There was an issue generating the authentication token, see below for details: " + $_.ErrorDetails.Message)
    exit
}