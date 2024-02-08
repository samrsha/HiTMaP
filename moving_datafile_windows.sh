#!/bin/bash
set -e
read -p "Are you using Windows System? (yes/no): " using_win

if [ "$using_win" = "yes" ]; then
    cd workflow

    if ! command -v unzip &> /dev/null; then
        echo "unzip could not be found. Installing unzip..."
        sudo apt-get update && sudo apt-get install -y unzip
    fi

    read -p "Enter the name of the data folder (without .zip extension): " data_folder

    read -p "Is the data folder ziped? (yes/no): " is_ziped

    if [ "$is_ziped" = "yes" ]; then
        if [ -f "${data_folder}.zip" ]; then
            unzip "${data_folder}.zip"
            rm -rf "${data_folder}.zip" __MACOSX

            # Check and remove rubish file if it exists
            if [ -f "${data_folder}.zip:Zone.Identifier" ]; then
                rm -rf "${data_folder}.zip:Zone.Identifier"
            fi

            if [ -f "${data_folder}/.DS_Store" ]; then
                rm -rf "${data_folder}/.DS_Store"
            fi

        else
            echo "The file ${data_folder}.zip does not exist."
            exit 1
        fi
    else
        echo "Skipping unzip since the data folder is not ziped."
    fi
else
    echo "You should only need to run this script when moving data folder or unzip data folder on Windows machine."
fi

