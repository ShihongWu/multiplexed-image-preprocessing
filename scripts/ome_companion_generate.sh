#!/bin/bash

# Load required modules
module load Anaconda3/2024.02-1
eval "$(conda shell.bash hook)"
module load Java/17.0.6

# Activate the virtual environment
conda activate ashlar

# Automatically set the working directory to the current directory
work_dir=$(pwd)

# Define the base path to your script
base_path="path/to/group/directory/mcmicro"

# Define the script path
script_path="${base_path}/multi-ome-xml-single-channel-celldive.py"

# Loop through each directory starting with 'S0' in the current working directory
for dir in "$work_dir"/S0*/; do
    if [[ -d "$dir" ]]; then
        echo "Processing directory: $dir"
        output=$(python "$script_path" "$dir")
        echo "$output"
    fi
done
