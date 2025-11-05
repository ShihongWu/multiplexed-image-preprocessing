# BMRC Setup Guide: Running MCMICRO for CellDIVE Data

This guide documents how to install and run the MCMICRO pipeline on the ** Oxford BMRC HPC cluster** using **Singularity containers** and **Nextflow**, tailored for **CellDIVE multiplexed imaging**.

---

## 📁 1. Directory Setup

```bash
ssh username@cluster1.bmrc.ox.ac.uk

# Work in your group directory, not your home directory
cd path/to/group/directory

# Create project structure
mkdir -p mcmicro/images
cd mcmicro
```

---

## ⚙️ 2. Create `custom.config` for Singularity

```bash
nano custom.config
```

Paste the following (edit your username as needed):

```groovy
singularity {
    enabled = true
    autoMounts = true
    cacheDir  = 'path/to/group/directory/mcmicro/images'
    runOptions = '-C -H "$PWD" -B path/to/group/directory/mcmicro/images:/mounted_images'
}
```

---

## 🚀 3. Load Modules & Pull the Pipeline

> Stay on the **root node** (don’t request CPUs yet)

```bash
module load Nextflow/23.04.2

# Pull pipeline
nextflow pull labsyspharm/mcmicro

# Run example dataset
nextflow run labsyspharm/mcmicro/exemplar.nf \
  --name exemplar-001 \
  --path path/to/group/directory/mcmicro
```

---

## 🛆 4. Set Image Cache Location & Pull Containers

```bash
export APPTAINER_CACHEDIR=path/to/group/directory/.apptainer
cd path/to/group/directory/mcmicro/images

# Pull containers
singularity pull docker://labsyspharm/ashlar:1.17.0
singularity pull docker://labsyspharm/basic-illumination:1.1.1
singularity pull docker://vanvalenlab/deepcell-applications:0.4.0
singularity pull docker://labsyspharm/s3segmenter:1.5.3
singularity pull docker://labsyspharm/quantification:1.5.3
singularity pull docker://labsyspharm/mc-flowsom:1.0.2
```

### 🏷 Rename the images

```bash
mv ashlar_1.17.0.sif                          labsyspharm-ashlar-1.17.0.img
mv deepcell-applications_0.4.0.sif            vanvalenlab-deepcell-applications-0.4.0.img
mv quantification_1.5.3.sif                   labsyspharm-quantification-1.5.3.img
mv mc-flowsom_1.0.2.sif                       labsyspharm-mc-flowsom-1.0.2.img
```

---

## 🧠 5. Fix `mesmer.py` Model Path Issue (Custom Image)

### Option A: Use My Prebuilt Image

```bash
singularity pull docker://monicawu95/new_deepcell_image:0.4.0
mv new_deepcell_image_0.4.0.sif vanvalenlab-deepcell-applications-0.4.0.img
```

### Option B: Build It Yourself (local laptop)

1. Create `mesmer.py` with updated model loading path:

   ```python
   archive_path = '/mounted_images/MultiplexSegmentation-9.tar.gz'
   ```

2. Create `my_image.def`:

   ```Dockerfile
   FROM vanvalenlab/deepcell-applications:0.4.0
   RUN rm /usr/local/lib/python3.8/dist-packages/deepcell/applications/mesmer.py
   COPY mesmer.py /usr/local/lib/python3.8/dist-packages/deepcell/applications/
   ```

3. Build, export, and push to Docker Hub:

   ```bash
   docker build -t new_deepcell_image -f my_image.def .
   docker save -o new_deepcell_image.tar new_deepcell_image
   docker load -i new_deepcell_image.tar
   docker tag new_deepcell_image monicawu95/new_deepcell_image:0.4.0
   docker push monicawu95/new_deepcell_image:0.4.0
   ```

---

## 📅 6. Download DeepCell Pretrained Model

```bash
cd path/to/group/directory/mcmicro/images
wget https://deepcell-data.s3-us-west-1.amazonaws.com/saved-models/MultiplexSegmentation-9.tar.gz
```

---

## 🛠 7. Run MCMICRO Pipeline (Production)

### Request CPUs and run:

```bash
srun -p short --cpus-per-task 5 --pty bash
module load Nextflow/23.04.2
export SINGULARITY_USER_BIND_CONTROL=1
export SINGULARITY_BIND="path/to/group/directory/mcmicro/images:/mounted_images"
export APPTAINER_CACHEDIR=path/to/group/directory/.apptainer

nextflow run labsyspharm/mcmicro \
  --in path/to/group/directory/mcmicro/example_cell_dive_image \
  -profile singularity \
  -c /gpfs3/well/immune-rep/users/tma392/mcmicro/custom.config
```

---

## 🗂 8. Alternate Way to Pull Images (Fallback)

On the **root node**, if MCMICRO fails to automatically pull some images:

```bash
singularity pull --name labsyspharm-roadie-2023-03-08.img docker://labsyspharm/roadie:2023-03-08
# Then rename as:
mv labsyspharm-roadie-2023-03-08.img.pulling.* labsyspharm-roadie-2023-03-08.img
```

Repeat for other missing images as needed.

---

> ✅ All setup steps ensure reproducibility and full container-based execution of the MCMICRO pipeline for CellDIVE imaging data on BMRC.

