#!/bin/bash
eval "$(conda shell.bash hook)"
conda env create -n hitmap-snakemake -f workflow/env/conda_local.yaml
conda activate hitmap-snakemake
R -e 'install.packages(".", repos = NULL, type = "source")'
