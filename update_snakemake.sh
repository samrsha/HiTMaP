#!/bin/bash
set -e
git pull origin snakemake-workflow
conda remove -n hitmap-snakemake --all