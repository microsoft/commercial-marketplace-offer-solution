# Copyright (c) Microsoft Corporation.
# Licensed under the MIT License.

####################################################################################################
# Use this script to publish a Commercial Marketplace offer using the Product Ingestion API.       #
# This script can be used to publish to preview or live.                                           #
####################################################################################################

Param (
    [Parameter(Mandatory = $True, HelpMessage = "Product external ID")]
    [String] $productExternalId,
    [Parameter(Mandatory = $False, HelpMessage = "Target type: preview or live")]
    [String] $targetType = "preview"
)

$baseUrl = "https://graph.microsoft.com/rp/product-ingestion"
$configureBaseUrl = "$baseUrl/configure"
$configureSchema = "https://product-ingestion.azureedge.net/schema/configure/2022-03-01-preview2"

function GetHeaders {
    $token = az account get-access-token --resource=https://graph.microsoft.com --query accessToken --output tsv
    $requestHeaders = @{Authorization="Bearer $token"}
    return $requestHeaders
}

function GetProductDurableId {
    param (
        [String] $productExternalId
    )

    $headers = GetHeaders
    $response = Invoke-WebRequest -Method GET -Headers $headers -Uri "$baseUrl/product?externalId=$productExternalId" -ContentType "application/json" -UseBasicParsing
    if ($response.StatusCode -eq 200)
    {
        $content = $response.Content | ConvertFrom-Json
        if ($content.value.length -gt 0)
        {
            return $content.value[0].id
        }
    }

    return ""
}

function GetConfigureJobStatus {
    param (
        [String] $jobId
    )

    $headers = GetHeaders
    $response = Invoke-WebRequest -Method GET -Headers $headers -Uri "$configureBaseUrl/$jobId/status" -ContentType "application/json" -UseBasicParsing
    return $response
}

function GetConfigureJobDetail {
    param (
        [String] $jobId
    )

    $headers = GetHeaders
    $response = Invoke-WebRequest -Method GET -Headers $headers -Uri "$configureBaseUrl/$jobId" -ContentType "application/json" -UseBasicParsing
    return $response
}

function WaitForJobComplete {
    param (
        [String] $jobId
    )

    $headers = GetHeaders
    $jobResult = ""
    $maxRetries = 5
    $retries = 0
    while ($retries -lt $maxRetries) {
        $response = GetConfigureJobStatus -jobId $jobId
        if ($response.StatusCode -eq 200)
        {
            $content = $response.Content | ConvertFrom-Json
            if ($content.jobStatus -eq "completed")
            {
                $jobResult = $content.jobResult
                break
            }

            $sleepSeconds = [System.Math]::Pow(2, $retries)
            Start-Sleep -Seconds $sleepSeconds
        }

        $retries++
    }

    return $jobResult
}

function PostConfigure {
    param (
        [String] $configureSchema,
        $resources
    )

    $body = @{
        "`$schema" = $configureSchema
        "resources" = $resources
    } | ConvertTo-Json -Depth 10

    $headers = GetHeaders
    $response = Invoke-WebRequest -Method POST -Headers $headers -Uri $configureBaseUrl -Body $body -ContentType "application/json" -UseBasicParsing
    if ($response.StatusCode -eq 202)
    {
        $content = $response.Content | ConvertFrom-Json
        $jobId = $content.jobId
        $jobResult = WaitForJobComplete -jobId $jobId

        if ($jobResult -ne "succeeded")
        {
            $response = GetConfigureJobStatus -jobId $jobId
            if ($response.StatusCode -eq 200)
            {
                $content = $response.Content | ConvertFrom-Json
                $errorCode = $content.errors[0].code
                $errorMessage = $content.errors[0].message

                throw "Code: $errorCode. Message: $errorMessage"
            }
        }
    }
    else
    {
        throw "Status code: $($response.StatusCode)"
    }
}

function Publish {
    param (
        [String] $configureSchema,
        [String] $productDurableId,
        [String] $targetType
    )

    $submission = @{
        "`$schema" = "https://product-ingestion.azureedge.net/schema/submission/2022-03-01-preview2"
        "product" = $productDurableId
        "target" = @{
            "targetType" = $targetType
        }
    }
    $resources = @($submission)

    PostConfigure -configureSchema $configureSchema -resources $resources
}

if ($targetType -eq "")
{
    Write-Error "Target type is required. Please provide one of the following values: preview, live."
    Exit 1
}

if ($targetType -ne "preview" -and $targetType -ne "live")
{
    Write-Error "Invalid target type provided. Please provide one of the following values: preview, live."
    Exit 1
}

try
{
    Write-Output "Checking for existing product with external ID: $productExternalId"
    $productDurableId = GetProductDurableId -productExternalId $productExternalId
    if ($productDurableId -eq "")
    {
        throw "Unable to publish to $targetType. Product with external ID $productExternalId not found."
    }
    else
    {
        Write-Output "Product $productExternalId found: $productDurableId. Publishing to $targetType."
        Publish -configureSchema $configureSchema -productDurableId $productDurableId -targetType $targetType
    }
}
catch
{
    Write-Error "There was an issue publishing your product to preview: $($_.Exception.Message)"
    Exit 1
}
