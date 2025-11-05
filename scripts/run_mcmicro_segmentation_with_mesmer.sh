#!/bin/bash

#SBATCH -A you_project_name.prj
#SBATCH -J mcmicro_pipeline
#SBATCH -o mcmicro_pipeline-%j.out
#SBATCH -e mcmicro_pipeline-%j.err
#SBATCH -p short
#SBATCH -c 30

set -e
set -u

### Activate environment ###
module load Anaconda3/2024.02-1
eval "$(conda shell.bash hook)"

module load Nextflow/24.04.2

conda activate ashlar

### ARGUMENT PARSING ###
START_FROM=1
MEMBRANE_CHANNELS="1"  # default

while [[ $# -gt 0 ]]; do
    case $1 in
        --start-from)
            START_FROM="$2"
            shift 2
            ;;
        --membrane-channels)
            MEMBRANE_CHANNELS="$2"
            shift 2
            ;;
        *)
            WORKDIR="$1"
            shift
            ;;
    esac
done

WORKDIR=${WORKDIR:-$PWD}
cd "$WORKDIR"
echo "Working in: $WORKDIR"

### CONFIG ###
TILE_LIMIT=25000
PIXEL_SIZE=0.325
PYRAMID_ASSEMBLE_PATH="path/to/group/directory/mcmicro/pyramid_assemble.py"
PARAM_TEMPLATE_WHOLE="path/to/group/directory/mcmicro/params_for_whole_cell_seg.yml"
PARAM_TEMPLATE_NUCLEAR="path/to/group/directory/mcmicro/params_for_nuclear_seg.yml"

### STEP 1: Check image size and optionally run direct segmentation ###
if [ "$START_FROM" -le 1 ]; then
    echo "Step 1: Image size check"

    INPUT_IMAGE=$(ls background/*.ome.tif)
    read HEIGHT WIDTH CHANNELS <<< $(python3 - <<EOF
import tifffile
img = tifffile.imread("$INPUT_IMAGE", key=0)
n_channels = tifffile.TiffFile("$INPUT_IMAGE").series[0].shape[0]
print(f"{img.shape[0]} {img.shape[1]} {n_channels}")
EOF
)
    echo " - Image size: ${HEIGHT}x${WIDTH}, Channels: ${CHANNELS}"

    if [ "$HEIGHT" -le "$TILE_LIMIT" ] && [ "$WIDTH" -le "$TILE_LIMIT" ]; then
        echo "Running direct MCMICRO..."
        sed "s|--membrane-channel .*|--membrane-channel ${MEMBRANE_CHANNELS}|" "$PARAM_TEMPLATE_WHOLE" > params.yml
        mkdir -p ark_wdir/segmentation/deepcell_output ark_wdir/image_data/fov0
        nextflow run labsyspharm/mcmicro --in "$PWD" -profile singularity -c /gpfs3/well/immune-rep/users/tma392/mcmicro/custom.config
        mv segmentation/mesmer-*/cell.tif ark_wdir/segmentation/deepcell_output/fov0_whole_cell.tiff
        cp "$PARAM_TEMPLATE_NUCLEAR" params.yml
        nextflow run labsyspharm/mcmicro --in "$PWD" -profile singularity -c /gpfs3/well/immune-rep/users/tma392/mcmicro/custom.config
        mv segmentation/mesmer-*/cell.tif ark_wdir/segmentation/deepcell_output/fov0_nuclear.tiff

        for ((c=0; c<CHANNELS; c++)); do
            MARKER_NAME=$(awk -F',' -v row=$((c+2)) 'NR==1{for(i=1;i<=NF;i++) if($i=="marker_name") col=i} NR==row{print $col}' background/markers_bs.csv)
            python3 - <<EOF
import tifffile
img = tifffile.imread("$INPUT_IMAGE", key=$c)
tifffile.imwrite(f"ark_wdir/image_data/fov0/${MARKER_NAME}.tif", img)
EOF
        done
        echo "Done (non-tiled)."
        exit 0
    fi
fi

### STEP 2: Separate & tile channels ###
if [ "$START_FROM" -le 2 ]; then
    echo "Step 2: Tiling & separation"
    python3 /gpfs3/well/immune-rep/users/tma392/python/separate_channel_tile_up_image.py "$INPUT_IMAGE" "$CHANNELS"
fi

### STEP 3: Assemble OME TIFFs ###
if [ "$START_FROM" -le 3 ]; then
    echo "Step 3: Assemble OME-TIFFs"
    TILES=($(ls background/c0_r*c*.tiff | sed -E 's|background/c0_(r[0-9]+c[0-9]+).tiff|\1|' | sort -u))
    mkdir -p ark_wdir/image_data ark_wdir/segmentation/deepcell_output
    for i in "${!TILES[@]}"; do
        TILE=${TILES[$i]}
        FOV=fov${i}
        FOV_DIR=for_seg/${FOV}/background
        mkdir -p "$FOV_DIR"
        TILE_SET=()
        for ((c=0; c<CHANNELS; c++)); do
            TILE_SET+=("background/c${c}_${TILE}.tiff")
        done
        python3 "$PYRAMID_ASSEMBLE_PATH" "${TILE_SET[@]}" "$FOV_DIR/${TILE^^}.ome.tif" --pixel-size $PIXEL_SIZE
        cp markers.csv for_seg/$FOV/
        cp background/markers_bs.csv "$FOV_DIR/"
        sed "s|--membrane-channel .*|--membrane-channel ${MEMBRANE_CHANNELS}|" "$PARAM_TEMPLATE_WHOLE" > for_seg/$FOV/params.yml
    done
fi

### STEP 5: Run whole-cell segmentation ###
if [ "$START_FROM" -le 5 ]; then
    echo "Step 5: Whole-cell segmentation"
    for i in "${!TILES[@]}"; do
        FOV=fov${i}
        nextflow run labsyspharm/mcmicro --in "$PWD/for_seg/$FOV" -profile singularity -c /gpfs3/well/immune-rep/users/tma392/mcmicro/custom.config
    done
fi

### STEP 6: Move whole-cell masks ###
if [ "$START_FROM" -le 6 ]; then
    for i in "${!TILES[@]}"; do
        FOV=fov${i}
        TILE=${TILES[$i]}
        SRC=for_seg/$FOV/segmentation/mesmer-${TILE^^}/cell.tif
        DST=ark_wdir/segmentation/deepcell_output/${FOV}_whole_cell.tiff
        mv "$SRC" "$DST"
    done
fi

### STEP 7-9: Nuclear segmentation & move ###
if [ "$START_FROM" -le 7 ]; then
    for i in "${!TILES[@]}"; do
        cp "$PARAM_TEMPLATE_NUCLEAR" for_seg/fov${i}/params.yml
    done
fi
if [ "$START_FROM" -le 8 ]; then
    for i in "${!TILES[@]}"; do
        FOV=fov${i}
        nextflow run labsyspharm/mcmicro --in "$PWD/for_seg/$FOV" -profile singularity -c /gpfs3/well/immune-rep/users/tma392/mcmicro/custom.config
    done
fi
if [ "$START_FROM" -le 9 ]; then
    for i in "${!TILES[@]}"; do
        FOV=fov${i}
        TILE=${TILES[$i]}
        SRC=for_seg/$FOV/segmentation/mesmer-${TILE^^}/cell.tif
        DST=ark_wdir/segmentation/deepcell_output/${FOV}_nuclear.tiff
        mv "$SRC" "$DST"
    done
fi

### STEP 10: Rename and move per-channel tiles ###
if [ "$START_FROM" -le 10 ]; then
    for i in "${!TILES[@]}"; do
        FOV=fov${i}
        TILE=${TILES[$i]}
        mkdir -p ark_wdir/image_data/$FOV
        for ((c=0; c<CHANNELS; c++)); do
            MARKER_NAME=$(awk -F',' -v row=$((c+2)) 'NR==1{for(i=1;i<=NF;i++) if($i=="marker_name") col=i} NR==row{print $col}' background/markers_bs.csv)
            SRC=background/c${c}_${TILE}.tiff
            DST=ark_wdir/image_data/$FOV/${MARKER_NAME}.tiff
            mv "$SRC" "$DST"
        done
    done
fi

### STEP 11: Cleanup ###
if [ "$START_FROM" -le 11 ]; then
    echo "Cleaning up intermediate files..."
    rm -rf for_seg work/
fi

echo "✅ Pipeline complete. Outputs in ark_wdir/segmentation and ark_wdir/image_data."
