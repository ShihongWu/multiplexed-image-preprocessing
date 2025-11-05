#!/bin/bash

# === DEFAULTS ===
partition="long"
cpus=30

# === ARGUMENT PARSING ===
while [[ $# -gt 0 ]]; do
  case $1 in
    --dir)
      workdir="$2"
      shift 2
      ;;
    --job-name)
      job_name="$2"
      shift 2
      ;;
    --partition)
      partition="$2"
      shift 2
      ;;
    --cpus)
      cpus="$2"
      shift 2
      ;;
    *)
      echo "❌ Unknown option: $1"
      exit 1
      ;;
  esac
done

# === VALIDATION ===
if [[ -z "$workdir" ]]; then
  echo "❌ Please provide a working directory using --dir"
  exit 1
fi

workdir=$(realpath "$workdir")
job_name=${job_name:-$(basename "$workdir")}

# === GENERATE SLURM JOB SCRIPT ===
cat <<EOF > submit_mcmicro_${job_name}.slurm
#!/bin/bash
#SBATCH -A your_project_name.prj # ← Replace this with your BMRC project name
#SBATCH -J ${job_name}_mcmicro
#SBATCH -o ${job_name}_mcmicro-%j.out
#SBATCH -e ${job_name}_mcmicro-%j.err
#SBATCH -p $partition
#SBATCH -c $cpus
#SBATCH -D $workdir

echo "------------------------------------------------"
echo "Run on host: \$(hostname)"
echo "Username: \$(whoami)"
echo "Started at: \$(date)"
echo "Working Dir: $workdir"
echo "Job Name: $job_name"
echo "Partition: $partition"
echo "CPU cores: $cpus"
echo "------------------------------------------------"

module load Nextflow/24.04.2

nextflow run labsyspharm/mcmicro \\
  --in "$workdir" \\
  -profile singularity \\
  -c path/to/group/directory/mcmicro/custom.config
EOF

# === SUBMIT JOB ===
sbatch submit_mcmicro_${job_name}.slurm
