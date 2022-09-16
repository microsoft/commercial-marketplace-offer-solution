# Copyright (c) Microsoft Corporation.
# Licensed under the MIT License.
import json
from pathlib import Path
import sys
import yaml

def main():
    """
    Generate a Partner Center CLI config file from config.json.
    Provide the path to the config.json file as the first argument.
    Provide the path to the output file (Partner Center CLI config file) as the second argument.
    """
    config_path_arg = sys.argv[1]
    output_path_arg = sys.argv[2]

    config_path = Path(config_path_arg)
    output_path = Path(output_path_arg)

    with open(config_path, 'r') as config_file:
        config = json.load(config_file)

        pcConfigs = {
            'tenant_id': config['aad']['tenantId'],
            'azure_preview_subscription': config['azure']['subscriptionId'],
            'aad_id': config['aad']['clientId'],
            'aad_secret': config['aad']['clientSecret'],
            'access_id': config['partnerCenter']['managedAppPrincipalId'],
            'publisherId': config['partnerCenter']['publisherId']
        }

    with open(output_path, 'w') as output_file:
        yaml.dump(pcConfigs, output_file)

if __name__ == '__main__':
    main()