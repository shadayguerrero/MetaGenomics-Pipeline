#!/bin/bash

# Initialize micromamba
eval "$(micromamba shell hook --shell bash)"

# Activate environment
micromamba activate metagenomics-pipeline

echo "MetaGenomics Pipeline environment activated!"
echo "Available commands:"
echo "  - fastqc --version"
echo "  - trimmomatic -version"
echo "  - bowtie2 --version"
echo "  - kraken2 --version"
echo "  - spades.py --version"
echo "  - checkm -h"
echo "  - phylophlan --version"
echo ""
echo "To run the pipeline: ./run_pipeline.sh --help"
