#!/bin/bash
set -e
cp workflow/config.yaml workflow/_config.yaml
git restore workflow/config.yaml
git pull origin snakemake-workflow
mv workflow/_config.yaml workflow/config.yaml
conda remove -n hitmap-snakemake --all

while true; do
    echo "Which machine are you using to run the pipeline? (Please type the number)"
    echo "1. M1,2,3 Chip"
    echo "2. Linux or Intel Chip Mac"
    read -p "Enter your choice: " module_choice
    
    case $module_choice in
        1)
            echo "Setting up pipeline for M1,2,3 Chip Mac..."
            bash snakemake_setup_arm64.sh
            ;;
        2)
            echo "Setting up pipeline for Linux or Intel Chip Mac..."
            bash snakemake_setup_x64.sh
            ;;
        *)
            echo "Invalid option. Please enter 1 or 2."
            continue
            ;;
    esac
    break
done