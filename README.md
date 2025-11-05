# Multiplexed Image Preprocessing

This repository contains preprocessing scripts and pipelines to adapt the [MCMICRO](https://mcmicro.org/) platform for CellDIVE multiplexed imaging data.

## Purpose

To automate the end-to-end preprocessing of high-plex microscopy images, including:
- Channel separation
- Image tiling and registration
- Pyramid assembly for segmentation
- Mesmer-based segmentation (nuclear and whole-cell)

## Folder Structure
multiplexed-image-preprocessing/ \
├── scripts/         # Bash, Python, and Nextflow scripts for pipeline stages \
├── notebooks/       # Exploratory Jupyter or R Markdown notebooks \
├── data/ \
│   ├── raw/         # Raw CellDIVE or OME-TIFF files \
│   └── processed/   # Processed outputs, masks, tiles \
├── figures/         # Output figures and diagnostics \
├── README.md        # Project description and usage \
└── .gitignore       # Files to exclude from version control \

## Usage

1. Organize your raw data in `data/raw/`.
2. Run preprocessing scripts in `scripts/` for channel splitting, tiling, registration, etc.
3. Outputs will be saved in `data/processed/`.

## Dependencies

- Python 3.8+
- Bash
- MCMICRO
- Mesmer (via DeepCell)
- OpenCV, scikit-image, tifffile
- ImageMagick (optional for figure conversion)

## License

MIT
