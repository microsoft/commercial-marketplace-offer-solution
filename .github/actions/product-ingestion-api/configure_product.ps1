# Copyright (c) Microsoft Corporation.
# Licensed under the MIT License.

####################################################################################################
# Use this script to configure a Commercial Marketplace offer using the Product Ingestion API.     #
# This script can be used to create a new offer or update an existing offer.                       #
####################################################################################################

Param (
    [Parameter(Mandatory = $True, HelpMessage = "The path to the VM listing config file")]
    [String] $productConfigurationFile
)

$baseUrl = "https://graph.microsoft.com/rp/product-ingestion"
$configureBaseUrl = "$baseUrl/configure"
$productId = ""
$planId = ""

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

function GetPlanDurableId {
    param (
        [String] $productDurableId,
        [String] $planExternalId
    )

    $headers = GetHeaders
    $response = Invoke-WebRequest -Method GET -Headers $headers -Uri "$baseUrl/plan?product=$productDurableId&externalId=$planExternalId" -ContentType "application/json" -UseBasicParsing
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

function GetProductListingDurableId {
    param (
        [String] $productDurableId
    )

    $headers = GetHeaders
    $response = Invoke-WebRequest -Method GET -Headers $headers -Uri "$baseUrl/resource-tree/$productDurableId" -ContentType "application/json" -UseBasicParsing
    if ($response.StatusCode -eq 200)
    {
        $content = $response.Content | ConvertFrom-Json
        foreach ($resource in $content.resources)
        {
            if ($resource.'$schema'.StartsWith("https://product-ingestion.azureedge.net/schema/listing/"))
            {
                return $resource.id
            }
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

function CreateProduct {
    param (
        [String] $configureSchema,
        $productConfiguration
    )

    $body = @{
        "`$schema" = $configureSchema
        "resources" = @(
            @{
                "`$schema" = $productConfiguration.'$schema'
                "identity" = @{
                    "externalId" = $productConfiguration.identity.externalId
                }
                "type" = $productConfiguration.type
                "alias" = $productConfiguration.alias
            }
        )
    } | ConvertTo-Json -Depth 5

    $headers = GetHeaders
    $response = Invoke-WebRequest -Method POST -Headers $headers -Uri $configureBaseUrl -Body $body -ContentType "application/json" -UseBasicParsing
    if ($response.StatusCode -eq 202)
    {
        $content = $response.Content | ConvertFrom-Json
        $jobId = $content.jobId
        $jobResult = WaitForJobComplete -jobId $jobId

        if ($jobResult -eq "succeeded")
        {
            $response = GetConfigureJobDetail -jobId $jobId
            if ($response.StatusCode -eq 200)
            {
                $content = $response.Content | ConvertFrom-Json
                return $content.resources[0].id
            }
        }
        else
        {
            $response = GetConfigureJobStatus -jobId $jobId
            if ($response.StatusCode -eq 200)
            {
                $content = $response.Content | ConvertFrom-Json
                $errorCode = $content.errors[0].code
                $errorMessage = $content.errors[0].message

                throw "There was an issue creating the product. Code: $errorCode. Message: $errorMessage"
            }
        }
    }
    else
    {
        throw "There was an issue creating the product. Status code: $($response.StatusCode)"
    }
}

function CreatePlan {
    param (
        [String] $configureSchema,
        [String] $productDurableId,
        $planConfiguration
    )

    $body = @{
        "`$schema" = $configureSchema
        "resources" = @(
            @{
                "`$schema" = $planConfiguration.'$schema'
                "identity" = @{
                    "externalId" = $planConfiguration.identity.externalId
                }
                "alias" = $planConfiguration.alias
                "azureRegions" = $planConfiguration.azureRegions
                "product" = $productDurableId
            }
        )
    } | ConvertTo-Json -Depth 5

    $headers = GetHeaders
    $response = Invoke-WebRequest -Method POST -Headers $headers -Uri $configureBaseUrl -Body $body -ContentType "application/json" -UseBasicParsing
    if ($response.StatusCode -eq 202)
    {
        $content = $response.Content | ConvertFrom-Json
        $jobId = $content.jobId
        $jobResult = WaitForJobComplete -jobId $jobId

        if ($jobResult -eq "succeeded")
        {
            $response = GetConfigureJobDetail -jobId $jobId
            if ($response.StatusCode -eq 200)
            {
                $content = $response.Content | ConvertFrom-Json
                return $content.resources[0].id
            }
        }
        else
        {
            $response = GetConfigureJobStatus -jobId $jobId
            if ($response.StatusCode -eq 200)
            {
                $content = $response.Content | ConvertFrom-Json
                $errorCode = $content.errors[0].code
                $errorMessage = $content.errors[0].message

                throw "There was an issue creating the plan. Code: $errorCode. Message: $errorMessage"
            }
        }
    }
    else
    {
        throw "There was an issue creating the plan. Status code: $($response.StatusCode)"
    }
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

function UpdateProduct {
    param (
        [String] $configureSchema,
        [String] $productDurableId,
        $productResources
    )

    $productListingDurableId = GetProductListingDurableId -productDurableId $productDurableId

    foreach ($resource in $productResources)
    {
        $resource | Add-Member -Name "product" -value $productDurableId -MemberType NoteProperty

        if ($resource.'$schema'.StartsWith("https://product-ingestion.azureedge.net/schema/listing-asset/"))
        {
            $resource | Add-Member -Name "listing" -value $productListingDurableId -MemberType NoteProperty
        }
    }

    PostConfigure -configureSchema $configureSchema -resources $productResources
}

function UpdatePlan {
    param (
        [String] $configureSchema,
        [String] $productDurableId,
        [String] $planDurableId,
        $planResources
    )

    foreach ($resource in $planResources)
    {
        $resource | Add-Member -Name "product" -value $productDurableId -MemberType NoteProperty
        $resource | Add-Member -Name "plan" -value $planDurableId -MemberType NoteProperty
    }

    PostConfigure -configureSchema $configureSchema -resources $planResources
}

if (Test-Path -Path $productConfigurationFile)
{
    Write-Output "Product configuration file found. Using it."
}
else
{
    Write-Error "Product configuration file not found. Please specify the path to the product configuration file."
    Exit 1
}

try
{
    $configuration = Get-Content $productConfigurationFile -Raw | ConvertFrom-Json
    $externalId = $configuration.product.identity.externalId

    Write-Output "Checking for existing product with external ID: $externalId"
    $productDurableId = GetProductDurableId -productExternalId $externalId
    if ($productDurableId -eq "")
    {
        Write-Output "Creating new product: $externalId"
        $productDurableId = CreateProduct -configureSchema $configuration.'$schema' -productConfiguration $configuration.product
        Write-Output "Product $externalId has ID $productDurableId"

        # Update product details
        UpdateProduct -configureSchema $configuration.'$schema' -productDurableId $productDurableId -productResources $configuration.product.resources
        Write-Output "Product $externalId updated."

        foreach ($plan in $configuration.plans)
        {
            $planExternalId = $plan.identity.externalId
            Write-Output "Creating new plan: $planExternalId"
            $planDurableId = CreatePlan -configureSchema $configuration.'$schema' -productDurableId $productDurableId -planConfiguration $plan
            Write-Output "Plan $planExternalId has ID $planDurableId"

            # Update plan details
            UpdatePlan -configureSchema $configuration.'$schema' -productDurableId $productDurableId -planDurableId $planDurableId -planResources $plan.resources
            Write-Output "Plan $planExternalId updated."
        }
    }
    else
    {
        Write-Output "Product $externalId already exists. Updating product and plan details."

        # Update product details
        UpdateProduct -configureSchema $configuration.'$schema' -productDurableId $productDurableId -productResources $configuration.product.resources
        Write-Output "Product $externalId updated."

        foreach ($plan in $configuration.plans)
        {
            $planExternalId = $plan.identity.externalId
            $planDurableId = GetPlanDurableId -productDurableId $productDurableId -planExternalId $planExternalId
            if ($planDurableId -eq "")
            {
                Write-Output "Creating new plan: $planExternalId"
                $planDurableId = CreatePlan -configureSchema $configuration.'$schema' -productDurableId $productDurableId -planConfiguration $plan
                Write-Output "Plan $planExternalId has ID $planDurableId"
            }

            # Update plan details
            Write-Output "Updating details for plan $planExternalId."
            UpdatePlan -configureSchema $configuration.'$schema' -productDurableId $productDurableId -planDurableId $planDurableId -planResources $plan.resources
            Write-Output "Plan $planExternalId updated."
        }
    }
}
catch
{
    Write-Error "There was an issue configuring your product: $($_.Exception.Message)"
    Exit 1
}
