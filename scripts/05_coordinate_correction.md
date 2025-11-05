# Step 5: Coordinate Correction

After quantification, each FOV (field of view) retains local coordinates. This step adjusts those coordinates to their absolute positions within the full stitched image, allowing for downstream spatial analysis (e.g., neighborhood detection, fiber mapping, etc.).

---

## Overview

The script below parses the original OME-TIFF image shape, determines the row/column layout of 25,000 × 25,000 px tiles, and corrects each cell’s X/Y centroid accordingly.

## Step 5.1 – Preparations
Before we start running the main bash script, we need to do the following preparations:

```bash
cp /path/to/multiplexed-image-preprocessing/scripts/coordinate_correction.py path/to/group/directory/mcmicro/
```
* You only need to do this one time

## Step 5.2 - Activate Environment
Before running the coordinate correction script, activate the Pixie (ARK) virtual environment:

```bash
conda activate ark_env
```

## Step 5.3 – Running Coordinate Correction

```bash
python path/to/group/directory/mcmicro/correct_fov_coordinates.py \
  --image path_to_image/background/sample_bs.ome.tif \
  --cell_table path_to_image/ark_wdir/segmentation/cell_table/cell_table_arcsinh_transformed.csv \
  --tile_size 25000 \
  --output path_to_image/ark_wdir/segmentation/cell_table/cell_table_arcsinh_transformed_corrected.csv
```

```bash
python path/to/group/directory/mcmicro/correct_fov_coordinates.py \
  --image path_to_image/background/sample_bs.ome.tif \
  --cell_table path_to_image/ark_wdir/segmentation/cell_table/cell_table_size_normalized.csv \
  --tile_size 25000 \
  --output path_to_image/ark_wdir/segmentation/cell_table/cell_table_size_normalized_corrected.csv
```

✅ You must update the paths accordingly

