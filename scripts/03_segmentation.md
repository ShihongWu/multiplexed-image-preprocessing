# Step 3: Segmentation with Mesmer

This step describes how to perform whole-cell and nuclear segmentation using Mesmer models within the MCMICRO￼ framework, adapted for CellDIVE image data.

---

## Overview

## Step 3.1 – Preparations
Before we start running the main bash script, we need to do the following preparations:

Copy the segmentation workflow configuration file to your mcmicro working folder:

```bash
cp /path/to/multiplexed-image-preprocessing/scripts/params_for_*_seg.yml path/to/group/directory/mcmicro/
```
* You only need to do this one time

```bash
cp path/to/multiplexed-image-preprocessing/scripts/pyramid_assemble.py path/to/group/directory/mcmicro/ 
```
* You only need to do this one time

```bash
cp path/to/multiplexed-image-preprocessing/scripts/run_mcmicro_segmentation_with_mesmer.sh path/to/group/directory/mcmicro/ 
```
* You only need to do this one time
* Then edit the path inside run_mcmicro_segmentation_with_mesmer.sh accordingly

## Step 3.2 – Running Segmentation

Segmentation is automated using a custom bash script:

```bash
sbatch path/to/group/directory/mcmicro/run_mcmicro_segmentation_with_mesmer.sh \
  /path/to/working_dir \
  --membrane-channels "1 3 5" \
  --start-from 1
```

✅ You must update --membrane-channels to reflect your chosen channels for whole-cell segmentation after inspecting background-subtracted images.


## Script Summary

The SLURM script performs the following steps:

SLURM Setup

#SBATCH -A your_project_name.prj \
#SBATCH -J mcmicro_pipeline \
#SBATCH -o mcmicro_pipeline-%j.out \
#SBATCH -e mcmicro_pipeline-%j.err \
#SBATCH -p short \
#SBATCH -c 30 \

Parameters
	•	--membrane-channels: Channels to use for whole-cell segmentation
	•	--start-from: Which step to start from (default = 1)
	•	$1: Working directory path

Environment Setup
	•	Loads Anaconda3 and Java
	•	Activates ashlar conda environment
	•	Uses Nextflow to run the MCMICRO pipeline

⸻

Pipeline Steps

Step 1: Size Check and Direct Run
	•	Checks if input image size < 25,000 × 25,000 pixels
	•	If so: runs direct segmentation with whole-cell and nuclear Mesmer models
	•	Saves to:
	•	ark_wdir/segmentation/deepcell_output/fov0_whole_cell.tiff
	•	ark_wdir/segmentation/deepcell_output/fov0_nuclear.tiff

Step 2: Channel Separation and Tiling
	•	Uses separate_channel_tile_up_image.py to tile large background image by channel

Step 3: OME-TIFF Assembly
	•	Uses pyramid_assemble.py to combine tiles into OME-TIFFs
	•	Creates folders like for_seg/fov0/

Step 4–6: Whole-cell Segmentation
	•	Copies params.yml (membrane-specified)
	•	Runs MCMICRO on each FOV
	•	Moves whole-cell outputs to ark_wdir/segmentation/deepcell_output/

Step 7–9: Nuclear Segmentation
	•	Replaces params.yml with nuclear-specific config
	•	Reruns MCMICRO
	•	Moves nuclear outputs to ark_wdir/segmentation/deepcell_output/

Step 10: Per-marker Channel Renaming
	•	Matches each tile to its marker name using markers_bs.csv
	•	Renames and moves into ark_wdir/image_data/fov{n}/

Step 11: Cleanup
	•	Deletes intermediate folders: for_seg, work/

⸻

Output Structure

ark_wdir/ \
├── segmentation/ \
│   └── deepcell_output/ \
│       ├── fov0_whole_cell.tiff \
│       ├── fov0_nuclear.tiff \
│       ├── ... \
└── image_data/ \
    └── fov0/ \
        ├── DAPI.tiff \
        ├── CK19.tiff \
        └── ... \


⸻

Notes
	•	You may re-run from a specific step using --start-from X
	•	Ensure markers.csv and markers_bs.csv are prepared beforehand
	•	This script currently assumes background-subtracted inputs exist in background/

⸻

## Next Steps

Proceed to quantification or feature extraction based on the generated segmentation masks and image tiles.

## Acknowledgements

The pyramid_assemble.py script used in Step 3 was adapted from the ome-tiff-pyramid-tools (https://github.com/labsyspharm/ome-tiff-pyramid-tools) repository developed by the Laboratory of Systems Pharmacology at Harvard Medical School. 
We gratefully acknowledge their contribution to the open-source imaging community.

If you use this tool or adapted pipeline in your work, please cite the original repository or its associated documentation when appropriate.
