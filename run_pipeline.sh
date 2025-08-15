#!/bin/bash

#####################################################################
#                    METAGENOMICS PIPELINE RUNNER                  #
#####################################################################

# Get script directory
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Source configuration
source "$SCRIPT_DIR/config/pipeline.conf" 2>/dev/null || true

# Initialize micromamba
eval "$(micromamba shell hook --shell bash)" 2>/dev/null || {
    echo "Error: micromamba not found. Please run install.sh first."
    exit 1
}

# Activate environment
micromamba activate metagenomics-pipeline || {
    echo "Error: Could not activate metagenomics-pipeline environment."
    echo "Please run install.sh first."
    exit 1
}

# Run the pipeline
python3 "$SCRIPT_DIR/metapipeline.py" "$@"
