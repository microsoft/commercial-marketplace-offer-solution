# Copyright (c) Microsoft Corporation.
# Licensed under the MIT License.

Param (
  [Parameter(Mandatory = $True, HelpMessage = "Path to solution assets folder")]
  [String] $assetsFolder,
  [Parameter(Mandatory = $False, HelpMessage = "Path to the config file")]
  [String] $configFile = "config.json",
  [Parameter(Mandatory = $False, HelpMessage = "Path to offer manifest YAML file")]
  [String] $manifestFile = ""
)

function Get-OfferGuid {
  param (
    [String] $response
  )

  $result = $response | ConvertFrom-Json

  if ($null -eq $result.id)
  {
    # Create command return something else. Check for GUID format. If empty or format is not correct, throw exception.
    if (("" -eq $result) -or ($result -notmatch '^[A-z0-9]{8}-[A-z0-9]{4}-[A-z0-9]{4}-[A-z0-9]{4}-[A-z0-9]{12}$'))
    {
      throw "Invalid offer GUID"; return
    }
    else
    {
      return $result
    }
  }

   # Create command successfully returned the offer object so get the GUID from it.
  return $result.id
}

if (Test-Path $assetsFolder) {
  Write-Output "Assets folder found. Using it."
}
else {
    Write-Error "Please provide a valid assets folder path."
    Exit 1
}

if (Test-Path -Path $configFile)
{
  Write-Output "Config file found. Using it."
}
else
{
  Write-Error "Config file not found. Please specify the path to the config file."
  Exit 1
}

$scriptFolder = Get-Item .

# Resolve path for config and manifest files
$configFilePath = Resolve-Path $configFile
$manifestYmlPath = "manifest.yml"
if ("" -ne $manifestFile)
{
  Write-Output "Using manifest file: $manifestFile"
  $manifestYmlPath = Resolve-Path $manifestFile
}

Set-Location $assetsFolder

# Read manifest.yml
$manifestJsonPath = "convertedManifest.json"
python $scriptFolder/helpers/convertYamlToJson.py $manifestYmlPath $manifestJsonPath
$manifest = Get-Content $manifestJsonPath -Raw | ConvertFrom-Json
$offerName = $manifest.name
$planName = $manifest.plan_name
Remove-Item $manifestJsonPath -Force

# Create offer and pipe results to a file. The CLI does not write to the correct streams.
Write-Output "Creating offer $offerName..."
$createResultFile = "create_result.json"
&{azpc st create --update --name $offerName --config-json $manifest.json_listing_config --app-path $manifest.app_path} *> $createResultFile

# Parse results from offer creation command
try
{
  $resultFileContents = Get-Content $createResultFile -Raw
  $offerId = Get-OfferGuid $resultFileContents
  Write-Output "Successfully created or updated offer $offerName."
}
catch
{
  Write-Error "Failed to create the offer $offerName."
  Write-Error $_.Exception.Message
  exit 1
}
finally
{
  Remove-Item $createResultFile
}

# Package solution
Write-Output "Packaging solution for offer $offerName..."
Set-Location $scriptFolder
$releaseFolder = "release_" + (get-date).ToString("MMddyyhhmmss")
./package.ps1 -assetsFolder "$assetsFolder/app-contents" -releaseFolder $releaseFolder -offerId $offerId
Copy-Item -Path "$releaseFolder/marketplacePackage.zip" -Destination $assetsFolder -Force
Remove-Item -Path $releaseFolder -Recurse -Force

# Create plan
Set-Location $assetsFolder
Write-Output "Creating plan $planName for offer $offerName..."
&{azpc $offerType plan create --update --name $offerName --plan-name $planName --config-json $manifest.json_listing_config --app-path $manifest.app_path} *> $createResultFile
Write-Output "Plan $planName for offer $offerName created or updated."

# Clean up
Remove-Item $createResultFile
Remove-Item "marketplacePackage.zip"

Set-Location $scriptFolder

Exit 0