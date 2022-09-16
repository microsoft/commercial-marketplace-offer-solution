# Copyright (c) Microsoft Corporation.
# Licensed under the MIT License.
import sys
import json
import yaml

def main():
    yaml_path = sys.argv[1]
    json_path = sys.argv[2]
    with open(yaml_path, 'r') as yaml_file, open(json_path, 'w') as json_file:
        yaml_object = yaml.safe_load(yaml_file)
        json.dump(yaml_object, json_file)

if __name__ == '__main__':
    main()