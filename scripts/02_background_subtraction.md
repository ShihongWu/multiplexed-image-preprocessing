# Background Subtraction Guide for CellDIVE Data (BMRC / MCMICRO)

This guide describes how to perform background subtraction on CellDIVE multiplexed imaging data using MCMICRO. This step follows successful ASHLAR stitching and involves configuring background subtraction parameters, generating a markers.csv file, and submitting a background-only MCMICRO job.

⸻

## 📁 Step 1 — Prepare Background Subtraction Parameters

Copy the background-only workflow configuration file to your mcmicro working folder:
```bash
cp /path/to/multiplexed-image-preprocessing/scripts/params_for_bs.yml path/to/group/directory/mcmicro/
```
* You only need to do this one time

### navigate to your working directory with your imaging data
```bash
cp path/to/group/directory/mcmicro/params_for_bs.yml ./params.yml
```

This instructs MCMICRO to run only the background subtraction module.

⸻

## 🧬 Step 2 — Generate markers.csv

This script parses round_*.xml files from each S###_* folder to produce a markers.csv file compatible with MCMICRO.

Copy the generate_markers_csv.py to your mcmicro working folder
```bash
cp /path/to/multiplexed-image-preprocessing/scripts/generate_markers_csv.py path/to/group/directory/mcmicro/
```

Activate environment and run:
```bash
conda activate ashlar
```

navigate to your working directory with image files
```bash
python path/to/group/directory/mcmicro/generate_markers_csv.py \
  --root ./ \
  --out ./markers.csv
```

📄 What generate_markers_csv.py does:
	•	Parses each cycle folder (e.g., S001_*, S002_*, etc.)
	•	Extracts channel metadata from round_*.xml files
	•	Automatically assigns appropriate marker names and backgrounds (e.g., autofluorescence, bleach corrections)
	•	Writes the markers.csv needed for MCMICRO

✅ Once complete, confirm that:
	•	The file markers.csv is present
	•	The values make sense for your imaging rounds

⸻

## 🧹 Step 3 — Clean Up Raw S* Files (Optional)

If markers.csv is correctly generated and you have validated ASHLAR stitching, you may delete the original S###_* folders to save space:
```bash
rm -rf S0*/
```

⚠️ Only do this if you are sure the .ome.tif and markers.csv are correct.

⸻

## ⚙️ Step 4 — Submit MCMICRO Background-Only Pipeline

Use the wrapper script to generate and submit a SLURM job for background subtraction only:

Copy the run_mcmicro_bs.sh to your mcmicro working folder
```bash
cp /path/to/multiplexed-image-preprocessing/scripts/run_mcmicro_bs.sh path/to/group/directory/mcmicro/
```
* check the .sh file to make nacessary changes

```bash
bash /gpfs3/well/immune-rep/users/tma392/python/run_mcmicro_bs.sh \
  --dir path/to/working_dir \
  --partition long \
  --cpus 40
```

This script creates and submits a SLURM job named submit_mcmicro_<sample>.slurm.