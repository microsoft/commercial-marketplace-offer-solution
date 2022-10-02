#!/bin/bash

# Copyright (c) Microsoft Corporation.
# Licensed under the MIT License.

assets_folder=${assets_folder}
config_file=${config_file:-"config.json"}
manifest_file=${manifest_file}
postfix=${postfix}
cleanup=${cleanup:-"true"}

while [ $# -gt 0 ]; do
  if [[ $1 == *"--"* ]]; then
    param=$(echo "${1/--/}" | sed "s/-/_/")
    declare $param="$2"
  fi
  shift
done

get_offer_id() {
  local offer=$1
  local offer_str=$(echo $offer | tr -d \")
  if [[ $offer_str =~ ^[A-z0-9]{8}-[A-z0-9]{4}-[A-z0-9]{4}-[A-z0-9]{4}-[A-z0-9]{12}$ ]]; then
    echo $offer_str
  else
    echo $offer | jq -r '.id'
  fi
}

if [[ -z $assets_folder ]]; then
  echo "Please specify the assets folder."
  exit 1
fi

if [[ -f $config_file ]]; then
  echo "Config file found. Using it."
else
  echo "Config file not found. Please specify the path to the config file."
  exit 1
fi

if [[ -z $manifest_file ]]; then
  manifest_file="${assets_folder}/manifest.yml"
else
  echo "Using manifest file: $manifest_file"
fi

# Generate config.yml file
config_yaml_path="${assets_folder}/config.yml"
echo "Generating Partner Center CLI config file at $config_yaml_path"
python helpers/generatePCYaml.py $config_file $config_yaml_path

# Read manifest.yml
manifest_json_path="${assets_folder}/converted_manifest.json"
python helpers/convertYamlToJson.py $manifest_file $manifest_json_path
offer_name=$(cat $manifest_json_path | jq -r '.name')
plan_name=$(cat $manifest_json_path | jq -r '.plan_name')
json_listing_config=$(cat $manifest_json_path | jq -r '.json_listing_config')
app_path=$(cat $manifest_json_path | jq -r '.app_path')
rm $manifest_json_path

if [[ ! -z $postfix ]]; then
  offer_name="${offer_name}_${postfix}"
fi

# Create or update offer
pushd $assets_folder > /dev/null

# Get Reseller Configuration
echo "Setting reseller configuration for offer $offer_name..."
reseller_config=$(cat $json_listing_config | jq -r '.resell.resellerChannelState')
if [[ $reseller_config -eq "null" ]]; then
  reseller_config="Disabled"
fi
export RESELLER_CHANNEL=$reseller_config

echo "Creating offer $offer_name..."
create_response=$(azpc st create --update --name $offer_name --config-json $json_listing_config --app-path $app_path)

status=$?
if [[ status -ne 0 ]]; then
  echo "Failed to create offer $offer_name"
  rm $config_yaml_path
  exit 1
fi

offer_id=$(get_offer_id "$create_response")
echo "Successfully created/updated offer $offer_name with id $offer_id."
popd > /dev/null

# Package solution
echo "Packaging solution for offer $offer_name..."
current_date=`date +"%Y%m%d%H%M%S"`
release_folder="release_$current_date"
./package.sh --assets-folder "$assets_folder/app-contents" --release-folder $release_folder --offer-id $offer_id
mv -f "$release_folder/marketplacePackage.zip" $assets_folder
rm -rf $release_folder

pushd $assets_folder > /dev/null
# Create or update plan
echo "Creating plan $plan_name for offer $offer_name..."
azpc st plan create --update --name $offer_name --plan-name $plan_name --config-json $json_listing_config --app-path $app_path

status=$?
if [[ status -eq 0 ]]; then
  echo "Plan $plan_name for offer $offer_name created or updated."
else
  echo "Failed to create plan $plan_name"
fi

popd > /dev/null

# Cleanup
if [[ $cleanup == "true" ]]; then
  echo "Cleaning up..."
  rm $config_yaml_path
  rm "$assets_folder/marketplacePackage.zip"
fi
