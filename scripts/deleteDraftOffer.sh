#!/bin/bash

# Copyright (c) Microsoft Corporation.
# Licensed under the MIT License.

config_yaml=${config_yaml:-"config.yml"}
offer_config=${offer_config}
offer_type=${offer_type}
postfix=${postfix}

while [ $# -gt 0 ]; do
  if [[ $1 == *"--"* ]]; then
    param=$(echo "${1/--/}" | sed "s/-/_/")
    declare $param="$2"
  fi
  shift
done

if [[ -z $offer_type ]]; then
  echo "Please specify the offer type (--offer-type)."
  exit 1
fi

if [[ -z $offer_config ]]; then
  echo "Please specify the path to the offer's config file (--offer-config-file)."
  exit 1
fi

offer_name=""
if [[ $offer_type == "vm" ]]; then
  offer_name=$(cat $offer_config | jq -r '.id')
elif [[ $offer_type == "st" ]]; then
  # Read manifest.yml
  manifest_json_path="converted_manifest.json"
  python helpers/convertYamlToJson.py $offer_config $manifest_json_path
  offer_name=$(cat $manifest_json_path | jq -r '.name')
  rm $manifest_json_path
fi

if [[ -z $offer_name ]]; then
  echo "Failed to read offer name from $offer_config."
  exit 1
fi

if [[ ! -z $postfix ]]; then
  offer_name="${offer_name}_${postfix}"
fi

# Delete offer draft
echo "Deleting offer ($offer_type) $offer_name..."
azpc $offer_type delete --name $offer_name --config-yml $config_yaml || exit 1
echo "Done."