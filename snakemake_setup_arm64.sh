#!/bin/bash
set -e
eval "$(conda shell.bash hook)"
CONDA_SUBDIR=osx-64 conda env create -n hitmap-snakemake -f workflow/env/conda_local.yaml
conda activate hitmap-snakemake
conda config --env --set subdir osx-64
R -e 'install.packages(".", repos = NULL, type = "source")'
