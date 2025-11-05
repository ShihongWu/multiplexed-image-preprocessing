#!/usr/bin/env python

import os
import argparse
import datetime
from alpineer import io_utils
from ark.segmentation import marker_quantification

# Log current time for tracking
print("Current date and time =", datetime.datetime.now())

# ---- Parse arguments ---- #
parser = argparse.ArgumentParser()

# Base directory (required): path to ark_wdir containing image_data and segmentation outputs
parser.add_argument('--base_dir', required=True, help='Base directory containing ark_wdir structure')

# Batch size for processing images — default is 5
parser.add_argument('--batch_size', type=int, default=5, help='Batch size for processing (default: 5)')

# Nuclear counts are included by default; user can disable by adding --no_nuclear_counts
parser.add_argument('--no_nuclear_counts', action='store_false', dest='nuclear_counts',
                    help='Disable nuclear counts (default: enabled)')

# Fast extraction skips calculating some cell properties — default is False
parser.add_argument('--fast_extraction', action='store_true',
                    help='Use fast extraction to skip detailed cell properties (default: False)')

# Optional compression — e.g., zstd — default is None (no compression)
parser.add_argument('--compression', default=None, help='Compression method for output CSVs (e.g., zstd or None)')

args = parser.parse_args()

# ---- Define paths ---- #
base_dir = args.base_dir
tiff_dir = os.path.join(base_dir, "image_data")
cell_table_dir = os.path.join(base_dir, "segmentation/cell_table")
deepcell_output_dir = os.path.join(base_dir, "segmentation/deepcell_output")

# Ensure output directories exist
os.makedirs(cell_table_dir, exist_ok=True)

# Validate input folders exist
io_utils.validate_paths([base_dir, tiff_dir, deepcell_output_dir])

# Get FOVs (field of view directories inside image_data/)
fovs = io_utils.list_folders(tiff_dir)

# ---- Run marker quantification ---- #
cell_table_size_normalized, cell_table_arcsinh_transformed = \
    marker_quantification.generate_cell_table(
        segmentation_dir=deepcell_output_dir,
        tiff_dir=tiff_dir,
        fovs=fovs,
        batch_size=args.batch_size,
        nuclear_counts=args.nuclear_counts,
        fast_extraction=args.fast_extraction,
    )

# ---- Save outputs to CSV ---- #
cell_table_size_normalized.to_csv(os.path.join(cell_table_dir, 'cell_table_size_normalized.csv'),
                                  compression=args.compression, index=False)
cell_table_arcsinh_transformed.to_csv(os.path.join(cell_table_dir, 'cell_table_arcsinh_transformed.csv'),
                                      compression=args.compression, index=False)

print("Quantification complete. Output saved to:", cell_table_dir)
