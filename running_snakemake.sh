#!/bin/bash
eval "$(conda shell.bash hook)"
cd workflow
conda activate hitmap-snakemake

# this function is created to run the snakemake command but with error handling, detecting the IncompleteFilesException
run_snakemake() {
    local snakemake_command="snakemake --cores $cores $1"
    eval $snakemake_command

    # Check if Snakemake failed
    if [ $? -ne 0 ]; then
        echo "Snakemake encountered an error. Attempting to rerun with --rerun-incomplete..."
        eval $snakemake_command --rerun-incomplete
    fi
}

# ------------------------------ Checking if the user created their config file correctly ------------------------------
echo "Checking if workflow/config.yaml created correctly..."
python -W ignore scripts/param_checking.py
script_exit_status=$?
if [ $script_exit_status -eq 1 ]; then
    exit 1
fi

# ------------------------------ Ask for the number of cores and validate input ------------------------------
while true; do
    read -p "How many cores would you like to set for Snakemake? " cores
    if [[ $cores =~ ^[0-9]+$ ]]; then
        break
    else
        echo "Please enter a valid number."
    fi
done

# ------------------------------ Ask for output folder name and validate ------------------------------
while true; do
    read -p "Please specify the folder name to save the output for this run (no spaces): " folder_name
    if [[ ! $folder_name =~ \ |\' ]]; then
        mkdir -p data/Output
        if [ -d "data/Output/$folder_name" ]; then
            echo "This folder name already exists. Please choose another one."
        else
            break
        fi
    else
        echo "Please do not include spaces in the folder name."
    fi
done
echo
# get the name of the .ibd file and copy/link the corresponding ID folder
ibd_file_name=$(basename data/*.ibd .ibd)

# ------------------------------ Ask which module to run and validate ------------------------------
while true; do
    echo "Which module would you like to run? (Please type the number)"
    echo "1. Reference database generation"
    echo "2. Peak picking + peptide & protein scoring"
    echo "3. Image rendering"
    read -p "Enter your choice: " module_choice
    
    case $module_choice in
        1)
            echo "Snakemake pipeline starts now..."
            run_snakemake "data/Summary\ folder/protein_index.csv"
            ;;
        2)
            echo "Snakemake pipeline starts now..."
            run_snakemake "data/$ibd_file_name\ ID/Peptide_region_file.csv"
            ;;
        3)
            echo "Snakemake pipeline starts now..."
            run_snakemake "data/Summary\ folder/Protein_feature_list_trimmed.csv"
            ;;
        *)
            echo "Invalid option. Please enter 1, 2, or 3."
            continue
            ;;
    esac
    break
done

# ------------------------------ Copy or link results + config to the output folder ------------------------------
mkdir -p data/Output/$folder_name
cp "config.yaml" "data/Output/$folder_name/config_${folder_name}.yaml"
for name in data/*; do
    if [[ ! $name == *.ibd && ! $name == *.imzML && ! $name == *.fasta && $name != "data/Output" ]]; then
        cp -r "$name" "data/Output/$folder_name/"
    fi
done

# (cp -rl "data/Summary folder" "data/Output/$folder_name/" || cp -r "data/Summary folder" "data/Output/$folder_name/Summary folder") 2> /dev/null
# (cp -rl "data/${ibd_file_name} ID" "data/Output/$folder_name/${ibd_file_name} ID" || cp -r "data/${ibd_file_name} ID" "data/Output/$folder_name") 2> /dev/null
# (cp -l "config.yaml" "data/Output/$folder_name/config_${folder_name}.yaml" || cp "config.yaml" "data/Output/$folder_name/config_${folder_name}.yaml") 2> /dev/null