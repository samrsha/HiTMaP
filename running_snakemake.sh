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

# get the name of the .ibd file and copy/link the corresponding ID folder
ibd_file_name=$(basename data/*.ibd .ibd)

# # ------------------------------ Ask for config file name ------------------------------
# while true; do
#     read -p "Please specify the config file name under the workflow folder (if you are not sure, put config_template): " config_name
#     if [[ ! $config_name =~ \ |\' ]]; then
#         if [ -f "$config_name" ]; then
#             echo "Config file found: $config_name"
#             break
#         else
#             echo "The specified config file does not exist under the workflow folder. Please try again."
#         fi
#     else
#         echo "Please specify the correct config file name without spaces."
#     fi
# done
echo "Please check if you have all the correct parameters for the config.yaml file under the workflow directory, e.g., Datafile name; Fasta file name. [Press any key to continue.]"
echo "[Press any key to continue.]"
read -n 1 -s -r -p ""

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
            # snakemake --cores $cores "data/Summary\ folder/protein_index.csv"
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
mkdir data/Output/$folder_name
cp -r "data/Summary folder" "data/Output/$folder_name/Summary folder"
cp -r "data/${ibd_file_name} ID" "data/Output/$folder_name/${ibd_file_name} ID"
cp "config.yaml" "data/Output/$folder_name/config_${folder_name}.yaml"


# (cp -rl "data/Summary folder" "data/Output/$folder_name/" || cp -r "data/Summary folder" "data/Output/$folder_name/Summary folder") 2> /dev/null
# (cp -rl "data/${ibd_file_name} ID" "data/Output/$folder_name/${ibd_file_name} ID" || cp -r "data/${ibd_file_name} ID" "data/Output/$folder_name") 2> /dev/null
# (cp -l "config.yaml" "data/Output/$folder_name/config_${folder_name}.yaml" || cp "config.yaml" "data/Output/$folder_name/config_${folder_name}.yaml") 2> /dev/null