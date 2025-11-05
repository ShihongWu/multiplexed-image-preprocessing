# Step 4: Quantification with Pixie (ARK)

This step quantifies per-cell marker expression using the Pixie (ARK) pipeline after segmentation.

---

## Overview

After generating whole-cell and nuclear segmentation masks, this step uses ARK’s `marker_quantification` to compute:

- Marker expression per segmented cell  
  - Nuclear vs. whole-cell intensity values in arcsinh-transformed and size-normalized cell tables  
- Spatial features such as cell centroids, areas, and other morphological metrics

## Step 4.1 – Preparations
Before running the quantification, ensure you have:
1. Segmented images (nuclear and whole-cell masks) from Step 3.
2. build a virtual environment from Pixie called ark_env (tutorial could be found: https://github.com/angelolab/ark-analysis)

Before we start running the main bash script, we need to do the following preparations:

```bash
cp /path/to/multiplexed-image-preprocessing/scripts/ark_segment_image_data.py path/to/group/directory/mcmicro/
cp /path/to/multiplexed-image-preprocessing/scripts/ark_segment_image_data.sh path/to/group/directory/mcmicro/
```
* You only need to do this one time
* Then change the paths inside ark_segment_image_data.sh accordingly

## Step 4.2 – Submitting the Quantification Job

Run the provided SLURM script from your working directory:

```bash
sbatch /gpfs3/well/immune-rep/users/tma392/python/ark_segment_image_data.sh \
<image_folder_name>
```
✅ You must update `<image_folder_name>` to reflect your image folder name.

## Acknowledgements

This quantification pipeline adopts the marker quantification script (1_Segment_Image_Data.ipynb) from the ARK analysis toolkit developed by the Angelo Lab. 
We gratefully acknowledge their contribution to the spatial single-cell analysis community.

Please cite the original ARK publications if using this pipeline in a publication: \
https://github.com/angelolab/ark-analysis \
https://www.nature.com/articles/s41587-021-01094-0 \
https://doi.org/10.1038/s41467-023-40068-5

