#!/bin/bash

# Copyright (c) Microsoft Corporation.
# Licensed under the MIT License.

config_yaml=${config_yaml:-"config.yml"}
offer_config=${offer_config}
offer_type=${offer_type}
notification_emails=${notification_emails}

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

if [[ $offer_type == "vm" ]]; then
  offer_name=$(cat $offer_config | jq -r '.id')
  config_json=$(basename $offer_config)
  app_path=$(dirname $offer_config)

  azpc vm publish --name $offer_name --app-path $app_path --config-yml $config_yaml --config-json $config_json --notification-emails $notification_emails
else
  # Read manifest.yml
  manifest_json_path="converted_manifest.json"
  python helpers/convertYamlToJson.py $offer_config $manifest_json_path
  offer_name=$(cat $manifest_json_path | jq -r '.name')
  rm $manifest_json_path

  # Publish offer
  echo "Publishing offer ($offer_type) $offer_name..."
  azpc $offer_type publish --name $offer_name --config-yml $config_yaml || exit 1
  echo "Done."
fi
