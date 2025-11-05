#!/usr/bin/env python3

import pandas as pd
import tifffile
import os
import re
import argparse

parser = argparse.ArgumentParser(description="Correct X/Y coordinates in cell table based on tile layout")
parser.add_argument('--image', type=str, required=True, help="Path to full original OME-TIFF image")
parser.add_argument('--cell_table', type=str, required=True, help="Path to cell_table.csv from Pixie")
parser.add_argument('--tile_size', type=int, default=25000, help="Tile size used during image cropping")
parser.add_argument('--output', type=str, default="cell_table_corrected.csv", help="Output CSV file")
args = parser.parse_args()

# Load image size from OME-TIFF
with tifffile.TiffFile(args.image) as tif:
    _, height, width = tif.series[0].shape  # assume (C, Y, X)

n_cols = (width + args.tile_size - 1) // args.tile_size
n_rows = (height + args.tile_size - 1) // args.tile_size

# Load and rename columns in cell table
meta = pd.read_csv(args.cell_table)
meta = meta.rename(columns={'centroid-0': 'Y_centroid', 'centroid-1': 'X_centroid'})

# Coordinate correction
def correct(row):
    fov_match = re.search(r'fov(\d+)', row['fov'])
    if fov_match:
        fov_idx = int(fov_match.group(1))
        row_idx = fov_idx // n_cols
        col_idx = fov_idx % n_cols
        row['X_centroid'] += col_idx * args.tile_size
        row['Y_centroid'] += row_idx * args.tile_size
    return row

meta_corrected = meta.apply(correct, axis=1)

# Save
meta_corrected.to_csv(args.output, index=False)
print(f"✅ Corrected coordinates saved to: {args.output}")
