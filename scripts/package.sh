#!/bin/bash

# Copyright (c) Microsoft Corporation.
# Licensed under the MIT License.

current_date=`date +"%Y%m%d%H%M%S"`
assets_folder=${assets_folder}
release_folder=${release_folder:-"release_$current_date"}
offer_id=${offer_id}

while [ $# -gt 0 ]; do
  if [[ $1 == *"--"* ]]; then
    param=$(echo "${1/--/}" | sed "s/-/_/")
    declare $param="$2"
  fi
  shift
done

if [[ ! -d $release_folder ]]; then
  mkdir $release_folder
fi

scripts_folder=$(pwd)
temp_folder="$scripts_folder/$release_folder/assets"
if [[ ! -d $temp_folder ]]; then
  mkdir $temp_folder
fi

pushd $assets_folder > /dev/null
az bicep build --file mainTemplate.bicep --outdir $temp_folder --only-show-errors
popd > /dev/null

pushd $temp_folder > /dev/null
if [[ ! -z $offer_id ]]; then
  main_template_file="mainTemplate.json"
  partner_center_id="pid-${offer_id}-partnercenter"
  mv $main_template_file "$main_template_file.bak"
  cat "$main_template_file.bak" | sed -E "s/pid-[A-z0-9]{8}-[A-z0-9]{4}-[A-z0-9]{4}-[A-z0-9]{4}-[A-z0-9]{12}-partnercenter/$partner_center_id/" > $main_template_file
  rm "$main_template_file.bak"
fi
popd > /dev/null

cp $assets_folder/createUiDefinition.json $temp_folder
cp $assets_folder/*.ps1 $temp_folder

pushd $temp_folder > /dev/null
zip -r ../marketplacePackage.zip . > /dev/null
popd > /dev/null

echo "Release zip file created: $releaseFolder/marketplacePackage.zip"