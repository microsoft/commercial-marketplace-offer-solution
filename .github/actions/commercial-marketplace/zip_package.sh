#!/bin/bash

# Copyright (c) Microsoft Corporation.
# Licensed under the MIT License.

current_date=`date +"%Y%m%d%H%M%S"`
contents_folder=${contents_folder}
output_file=${output_file:-"marketplacePackage.zip"}

while [ $# -gt 0 ]; do
  if [[ $1 == *"--"* ]]; then
    param=$(echo "${1/--/}" | sed "s/-/_/")
    declare $param="$2"
  fi
  shift
done

if [[ -z "$contents_folder" ]]; then
  echo "Please specify the path to the app contents folder, example '--contents-folder my-app/app-contents'"
  exit 1
fi

temp_folder="temp_$current_date"
if [[ ! -d $temp_folder ]]; then
  mkdir $temp_folder
fi

az bicep build --file $contents_folder/mainTemplate.bicep --outdir $temp_folder --only-show-errors || exit 1

cp $contents_folder/* $temp_folder
rm $temp_folder/*.bicep > /dev/null
rm $temp_folder/*.tmpl > /dev/null

zip_full_path="$(cd "$(dirname "${output_file}")" && pwd)/$(basename "${output_file}")"
cd $temp_folder
zip -r $zip_full_path . > /dev/null
cd ..

rm -rf $temp_folder

echo "Release zip file created: $zip_full_path"
