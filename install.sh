#!/bin/bash

#####################################################################
#                    METAGENOMICS PIPELINE INSTALLER               #
#                         Auto-Installation Script                 #
#####################################################################

set -e  # Exit on any error

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Logging function
log() {
    echo -e "${GREEN}[$(date +'%Y-%m-%d %H:%M:%S')] $1${NC}"
}

warn() {
    echo -e "${YELLOW}[WARNING] $1${NC}"
}

error() {
    echo -e "${RED}[ERROR] $1${NC}"
    exit 1
}

info() {
    echo -e "${BLUE}[INFO] $1${NC}"
}

# Check if running on supported OS
check_os() {
    log "Checking operating system..."
    if [[ "$OSTYPE" == "linux-gnu"* ]]; then
        info "Linux detected - supported"
    elif [[ "$OSTYPE" == "darwin"* ]]; then
        info "macOS detected - supported"
    else
        error "Unsupported operating system: $OSTYPE"
    fi
}

# Check if micromamba is installed, install if not
install_micromamba() {
    log "Checking for micromamba installation..."
    
    if command -v micromamba &> /dev/null; then
        info "micromamba is already installed"
        return 0
    fi
    
    log "Installing micromamba..."
    
    # Install micromamba
    if [[ "$OSTYPE" == "linux-gnu"* ]]; then
        # Install dependencies
        if command -v apt-get &> /dev/null; then
            sudo apt-get update -qq
            sudo apt-get install -y -qq bzip2 curl
        elif command -v yum &> /dev/null; then
            sudo yum install -y bzip2 curl
        fi
        
        # Download and install micromamba
        curl -Ls https://micro.mamba.pm/api/micromamba/linux-64/latest | tar -xvj bin/micromamba
        sudo mv bin/micromamba /usr/local/bin/
        rm -rf bin/
        
    elif [[ "$OSTYPE" == "darwin"* ]]; then
        # macOS installation
        curl -Ls https://micro.mamba.pm/api/micromamba/osx-64/latest | tar -xvj bin/micromamba
        sudo mv bin/micromamba /usr/local/bin/
        rm -rf bin/
    fi
    
    # Verify installation
    if command -v micromamba &> /dev/null; then
        info "micromamba installed successfully"
    else
        error "Failed to install micromamba"
    fi
}

# Create conda environment
create_environment() {
    log "Creating conda environment for metagenomics pipeline..."
    
    # Initialize micromamba
    eval "$(micromamba shell hook --shell bash)"
    
    # Remove existing environment if it exists
    if micromamba env list | grep -q "metagenomics-pipeline"; then
        warn "Environment 'metagenomics-pipeline' already exists. Removing..."
        micromamba env remove -n metagenomics-pipeline -y
    fi
    
    # Create base environment
    log "Creating base environment with Python 3.9..."
    micromamba create -n metagenomics-pipeline -c conda-forge -c bioconda python=3.9 -y
    
    # Activate environment
    micromamba activate metagenomics-pipeline
    
    # Install core tools in batches to avoid dependency conflicts
    log "Installing core bioinformatics tools..."
    
    # Batch 1: Quality control and preprocessing
    info "Installing quality control tools..."
    micromamba install -c bioconda -c conda-forge fastqc trimmomatic -y
    
    # Batch 2: Alignment and host removal
    info "Installing alignment tools..."
    micromamba install -c bioconda -c conda-forge bowtie2 samtools -y
    
    # Batch 3: Taxonomic classification
    info "Installing taxonomic classification tools..."
    micromamba install -c bioconda -c conda-forge kraken2 kraken-biom -y
    
    # Batch 4: Assembly and binning
    info "Installing assembly tools..."
    micromamba install -c bioconda -c conda-forge spades checkm-genome -y
    
    # Batch 5: Python dependencies
    info "Installing Python dependencies..."
    micromamba install -c conda-forge biopython requests psutil pandas numpy scipy matplotlib seaborn -y
    
    # Batch 6: Phylogenetic analysis
    info "Installing phylogenetic analysis tools..."
    micromamba install -c bioconda phylophlan -y
    
    # Batch 7: Additional tools
    info "Installing additional tools..."
    micromamba install -c conda-forge -c bioconda parallel ruby -y
    
    log "Environment created successfully!"
}

# Install alternative tools for problematic packages
install_alternatives() {
    log "Installing alternative tools for gene and functional annotation..."
    
    eval "$(micromamba shell hook --shell bash)"
    micromamba activate metagenomics-pipeline
    
    # Install Prodigal as alternative to Prokka
    info "Installing Prodigal for gene prediction..."
    micromamba install -c bioconda prodigal -y
    
    # Try to install eggnog-mapper with specific version
    info "Attempting to install eggnog-mapper..."
    micromamba install -c bioconda eggnog-mapper=2.1.12 -y || warn "eggnog-mapper installation failed - will use alternative methods"
    
    # Install HMMER for functional annotation
    info "Installing HMMER for functional annotation..."
    micromamba install -c bioconda hmmer -y
    
    log "Alternative tools installed successfully!"
}

# Create configuration files
create_config() {
    log "Creating configuration files..."
    
    # Create improved environment.yml
    cat > config/environment-full.yml << 'EOF'
name: metagenomics-pipeline
channels:
  - conda-forge
  - bioconda
  - defaults
dependencies:
  - python=3.9
  # Quality control
  - fastqc
  - trimmomatic
  # Alignment and host removal
  - bowtie2
  - samtools
  # Taxonomic classification
  - kraken2
  - kraken-biom
  # Assembly and binning
  - spades
  - checkm-genome
  # Phylogenetic analysis
  - phylophlan
  # Gene prediction
  - prodigal
  # Functional annotation
  - hmmer
  # Python dependencies
  - biopython
  - requests
  - psutil
  - pandas
  - numpy
  - scipy
  - matplotlib
  - seaborn
  # Utilities
  - parallel
  - ruby
EOF

    # Create pipeline configuration
    cat > config/pipeline.conf << 'EOF'
# MetaGenomics Pipeline Configuration File

[DEFAULT]
# Number of threads to use (0 = auto-detect)
threads = 0

# Temporary directory
temp_dir = ./tmp

# Keep intermediate files (true/false)
keep_intermediate = false

[QUALITY_CONTROL]
# Trimmomatic parameters
trimmomatic_params = HEADCROP:20 SLIDINGWINDOW:4:20 MINLEN:35

[HOST_REMOVAL]
# Bowtie2 parameters
bowtie2_params = --very-sensitive-local

[TAXONOMY]
# Kraken2 confidence threshold
kraken2_confidence = 0.1

[ASSEMBLY]
# SPAdes parameters
spades_params = --meta

[ANNOTATION]
# Prodigal parameters
prodigal_params = -p meta
EOF

    log "Configuration files created successfully!"
}

# Set up directory structure
setup_directories() {
    log "Setting up directory structure..."
    
    # Create additional directories
    mkdir -p {logs,tmp,databases,results}
    mkdir -p results/{fastqc,trimmed-reads,host-removed,taxonomy,assemblies,annotation}
    
    # Create .gitignore
    cat > .gitignore << 'EOF'
# Temporary files
tmp/
*.tmp
*.temp

# Log files
logs/*.log

# Results (comment out if you want to track results)
results/

# Databases (too large for git)
databases/

# Python cache
__pycache__/
*.pyc
*.pyo

# OS files
.DS_Store
Thumbs.db

# IDE files
.vscode/
.idea/
*.swp
*.swo
EOF

    log "Directory structure created successfully!"
}

# Create wrapper scripts
create_wrappers() {
    log "Creating wrapper scripts..."
    
    # Create main pipeline wrapper
    cat > run_pipeline.sh << 'EOF'
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
EOF

    chmod +x run_pipeline.sh
    
    # Create environment activation script
    cat > activate_env.sh << 'EOF'
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
EOF

    chmod +x activate_env.sh
    
    log "Wrapper scripts created successfully!"
}

# Verify installation
verify_installation() {
    log "Verifying installation..."
    
    eval "$(micromamba shell hook --shell bash)"
    micromamba activate metagenomics-pipeline
    
    # Check core tools
    local tools=("fastqc" "trimmomatic" "bowtie2" "samtools" "kraken2" "spades.py" "checkm" "phylophlan" "prodigal")
    local missing_tools=()
    
    for tool in "${tools[@]}"; do
        if command -v "$tool" &> /dev/null; then
            info "✓ $tool is available"
        else
            warn "✗ $tool is not available"
            missing_tools+=("$tool")
        fi
    done
    
    if [ ${#missing_tools[@]} -eq 0 ]; then
        log "All core tools are installed and available!"
        return 0
    else
        warn "Some tools are missing: ${missing_tools[*]}"
        warn "The pipeline may still work with alternative tools."
        return 1
    fi
}

# Main installation function
main() {
    log "Starting MetaGenomics Pipeline installation..."
    
    check_os
    install_micromamba
    create_environment
    install_alternatives
    create_config
    setup_directories
    create_wrappers
    
    if verify_installation; then
        log "Installation completed successfully!"
        echo ""
        info "To get started:"
        info "1. Activate the environment: source activate_env.sh"
        info "2. Run the pipeline: ./run_pipeline.sh --help"
        info "3. Check documentation in docs/ directory"
    else
        warn "Installation completed with some warnings."
        warn "Check the output above for missing tools."
    fi
}

# Run main function
main "$@"

