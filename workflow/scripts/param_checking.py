import yaml
import pandas as pd
import os.path
import sys

# Check if the config_template.yaml has been created in the parent directory
config_created = os.path.isfile("config.yaml")
if config_created:
    # Load the two config files
    with open('config.yaml', 'r') as file:
        user_set_config = yaml.safe_load(file)
    with open('config_template.yaml', 'r') as file:
        config_template = yaml.safe_load(file)
        
    # Use pandas to normalize the yaml file so they are into json
    user_set_config_df = pd.json_normalize(user_set_config, sep='.')
    config_template_df = pd.json_normalize(config_template, sep='.')
    
    # Check if any column in the config_template that is not in the user_set_config
    missing_columns = set(config_template_df.columns) - set(user_set_config_df.columns)
    
    if not missing_columns:
        print("Config file checked and success.")
        sys.exit(0)
    else:
        print("The following parameters are missing in the user_set_config file:")
        for i, param in enumerate(missing_columns, 1):
            print(f"    {i}. {param}")
        sys.exit(1)
else:
    print("Please make sure to create a config.yaml file under workflow directory before running the pipeline.")
    sys.exit(1)