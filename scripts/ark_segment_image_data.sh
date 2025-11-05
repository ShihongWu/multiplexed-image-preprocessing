#!/bin/bash
#SBATCH -A your_project_name.prj
#SBATCH -J ark_quant
#SBATCH -o ark_quant-%j.out
#SBATCH -e ark_quant-%j.err
#SBATCH -p long
#SBATCH -c 30

# Set working directory
#SBATCH -D /full/path/to/parent/of/

# Environment setup
module load Anaconda3/2024.02-1
eval "$(conda shell.bash hook)"
conda activate ark_env

# Project folder passed as argument
PROJECT_NAME="$1"
WDIR="/full/path/to/parent/of/${PROJECT_NAME}/ark_wdir"

# Run Pixie quantification
python path/to/group/directory/mcmicro/ark_segment_image_data.py \
  --base_dir "$WDIR" \
  --batch_size 5 \
  --nuclear_counts
