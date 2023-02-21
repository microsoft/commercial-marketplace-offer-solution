#!/bin/bash

if [ -z "$resourceGroup" ]; then
    resourceGroup=$0
    storageAccount=$1
    artifactContainer=$2
    location=$4
fi

az group show \
    --name "$resourceGroup" 2>/dev/null \
|| az group create \
    --name "$resourceGroup" \
    --location "$location" \
|| exit 1

az storage account show \
    --name "$storageAccount" \
    --resource-group "$resourceGroup" 2>/dev/null \
|| az storage account create \
    --name "$storageAccount" \
    --resource-group "$resourceGroup" \
|| exit 1

accountKey=$(az storage account keys list -g "$resourceGroup" -n "$storageAccount" | jq .[0].value)

az storage container show \
    --only-show-errors \
    --account-name "$storageAccount" \
    --account-key "$accountKey" \
    --name "$artifactContainer" 2>/dev/null \
|| az storage container create \
    --only-show-errors \
    --account-name "$storageAccount" \
    --account-key "$accountKey" \
    --name "$artifactContainer" \
|| exit 1

az storage container show \
    --only-show-errors \
    --account-name "$storageAccount" \
    --account-key "$accountKey" \
    --name "$artifactContainer" 2>/dev/null \
|| az storage container create \
    --only-show-errors \
    --account-name "$storageAccount" \
    --account-key "$accountKey" \
    --name "$artifactContainer" \
|| exit 1
