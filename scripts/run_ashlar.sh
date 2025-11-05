#!/bin/bash

### --- SLURM CONFIGURATION ---
#SBATCH -A your_project_name.prj # ← Replace this with your BMRC project name
#SBATCH -J ashlar_stitch_merge
#SBATCH -o ashlar_stitch_merge-%j.out
#SBATCH -e ashlar_stitch_merge-%j.err
#SBATCH -p short
#SBATCH -c 30

### --- USER CONFIGURABLE PARAMETERS ---
# Allow passing custom values
working_dir=${1:-$(pwd)}          # Default to current directory
partition=${2:-short}            # Default partition
cpus=${3:-30}                    # Default CPU cores

### --- DYNAMIC JOB SETUP ---
job_name=$(basename "$working_dir")
cd "$working_dir" || { echo "❌ Failed to access directory: $working_dir"; exit 1; }

# Echo useful debug info
echo "------------------------------------------------"
echo "🏁 Starting Ashlar Stitching Job"
echo "📍 Working Directory: $working_dir"
echo "📝 Job Name: $job_name"
echo "🧠 Partition: $partition"
echo "🧮 CPU cores: $cpus"
echo "------------------------------------------------"

### --- MODULE & ENVIRONMENT SETUP ---
module load Anaconda3/2024.02-1
module load Java/17.0.6
eval "$(conda shell.bash hook)"
conda activate ashlar

### --- OUTPUT DIRECTORY SETUP ---
mkdir -p "$working_dir/registration"
echo "📁 Output folder ensured: registration/"

### --- FIND INPUT OME COMPANION FILES ---
companion_files=$(find "$working_dir" -type f -name "*.companion.ome" | sort)
if [ -z "$companion_files" ]; then
    echo "❌ No companion.ome files found. Exiting."
    exit 1
fi

### --- RUN ASHLAR ---
echo "🚀 Running ashlar..."
ashlar $companion_files --flip-y -o "$working_dir/registration/${job_name}.ome.tif"

if [ $? -eq 0 ]; then
    echo "✅ Ashlar stitching complete: registration/${job_name}.ome.tif"
else
    echo "❌ Ashlar stitching failed."
    exit 1
fi
