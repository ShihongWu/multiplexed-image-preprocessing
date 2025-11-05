# Ashlar Adaptation for CellDIVE on BMRC

This guide describes how to adapt and run the **ASHLAR stitching and registration tool** on **CellDIVE multiplexed imaging data** within the BMRC cluster environment.

---

## 📄 Required Input Files

* **S0*** image files from CellDIVE output
* `.companion.ome` files for each cycle (generated in Step 1.1)

All commands assume you are working from your main project directory (e.g. `path/to/group/directory/mcmicro/`).

---

## ⚙️ Step 0 — Build the `ashlar` Conda Environment

Before running the scripts, create the environment for stitching and metadata generation:

```bash
module load Anaconda3/2024.02-1
eval "$(conda shell.bash hook)"

conda create -n ashlar python=3.11
conda activate ashlar

# Install dependencies
conda install -y -c conda-forge numpy scipy matplotlib networkx \
  scikit-image scikit-learn tifffile zarr pyjnius blessed

# Install Ashlar
pip install ashlar==1.17.0
```

---

## 📦 Step 1 — Organize Required Scripts

Place the following two files into your project folder:

```
path/to/group/directory/mcmicro/
├── multi-ome-xml-single-channel-celldive.py
├── ome_companion_generate.sh
```

Ensure that:

* You edit the variable `base_path` in `ome_companion_generate.sh` to match the above path.

---

## ⚙️ Step 1.1 — Generate OME-Companion Files

The CellDIVE S0* TIFF images must be converted to include metadata using an OME-Companion file generator script.
Run the following inside your data directory:

```bash
srun -p himem --cpus-per-task 10 --pty bash \
  bash path/to/group/directory/mcmicro/ome_companion_generate.sh
```

This will generate `.companion.ome` metadata files for each cycle.

---

## ⚙️ Step 1.2 — Run ASHLAR for Stitching and Registration

1. Copy the stitching script to your working folder:

```bash
cp /path/to/multiplexed-image-preprocessing/scripts/run_ashlar.sh path/to/group/directory/mcmicro/
```
* In the run_ashlar.sh, #SBATCH -A your_project_name.prj  # ← Replace this with your BMRC project name

2. Submit the job:

```bash
sbatch path/to/group/directory/mcmicro/run_ashlar.sh /your/data/folder short 30
```

* `/your/data/folder` = folder with `.companion.ome` files 
* `short` = SLURM partition
* `30` = number of CPU cores requested; change accordingly

---