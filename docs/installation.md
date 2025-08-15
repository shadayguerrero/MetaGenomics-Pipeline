# Installation Guide

This guide provides detailed instructions for installing the MetaGenomics Pipeline on different systems and deployment scenarios.

## Table of Contents

1. [System Requirements](#system-requirements)
2. [Automatic Installation](#automatic-installation)
3. [Manual Installation](#manual-installation)
4. [Docker Installation](#docker-installation)
5. [Conda Environment Setup](#conda-environment-setup)
6. [Database Setup](#database-setup)
7. [Verification](#verification)
8. [Troubleshooting](#troubleshooting)

## System Requirements

### Minimum Requirements
- **Operating System**: Linux (Ubuntu 18.04+, CentOS 7+) or macOS 10.14+
- **CPU**: 4 cores
- **RAM**: 8 GB
- **Storage**: 50 GB free space
- **Network**: Internet connection for downloads

### Recommended Requirements
- **CPU**: 8+ cores
- **RAM**: 16+ GB
- **Storage**: 100+ GB free space (databases can be large)
- **SSD**: Recommended for better I/O performance

### Software Prerequisites
- **Python**: 3.9 or higher
- **Git**: For cloning the repository
- **Curl/Wget**: For downloading files
- **Bash**: Version 4.0 or higher

## Automatic Installation

The easiest way to install the pipeline is using the automatic installation script.

### Step 1: Clone Repository

```bash
git clone https://github.com/your-username/MetaGenomics-Pipeline.git
cd MetaGenomics-Pipeline
```

### Step 2: Run Installation Script

```bash
./install.sh
```

The installation script will:
1. Check system compatibility
2. Install micromamba (if not present)
3. Create conda environment
4. Install all required tools
5. Set up directory structure
6. Create wrapper scripts
7. Verify installation

### Step 3: Activate Environment

```bash
source activate_env.sh
```

### Installation Options

The installation script supports several options:

```bash
# Install with specific number of threads
./install.sh --threads 8

# Skip dependency checks
./install.sh --skip-checks

# Install in custom directory
./install.sh --prefix /custom/path

# Verbose output
./install.sh --verbose
```

## Manual Installation

If you prefer manual installation or the automatic script fails:

### Step 1: Install Micromamba

```bash
# Linux
curl -Ls https://micro.mamba.pm/api/micromamba/linux-64/latest | tar -xvj bin/micromamba
sudo mv bin/micromamba /usr/local/bin/

# macOS
curl -Ls https://micro.mamba.pm/api/micromamba/osx-64/latest | tar -xvj bin/micromamba
sudo mv bin/micromamba /usr/local/bin/
```

### Step 2: Create Environment

```bash
# Initialize micromamba
eval "$(micromamba shell hook --shell bash)"

# Create environment
micromamba create -n metagenomics-pipeline -c conda-forge -c bioconda python=3.9 -y

# Activate environment
micromamba activate metagenomics-pipeline
```

### Step 3: Install Core Tools

```bash
# Quality control tools
micromamba install -c bioconda fastqc trimmomatic -y

# Alignment tools
micromamba install -c bioconda bowtie2 samtools -y

# Taxonomic classification
micromamba install -c bioconda kraken2 kraken-biom -y

# Assembly tools
micromamba install -c bioconda spades checkm-genome -y

# Python dependencies
micromamba install -c conda-forge biopython requests psutil pandas numpy scipy matplotlib seaborn -y

# Phylogenetic analysis
micromamba install -c bioconda phylophlan -y

# Additional tools
micromamba install -c conda-forge parallel ruby -y
micromamba install -c bioconda prodigal hmmer -y
```

### Step 4: Set Up Directory Structure

```bash
mkdir -p {logs,tmp,databases,results}
mkdir -p results/{fastqc,trimmed-reads,host-removed,taxonomy,assemblies,annotation}
```

## Docker Installation

Docker provides an isolated and reproducible environment.

### Step 1: Install Docker

Follow the official Docker installation guide for your system:
- [Docker for Linux](https://docs.docker.com/engine/install/)
- [Docker for macOS](https://docs.docker.com/docker-for-mac/install/)
- [Docker for Windows](https://docs.docker.com/docker-for-windows/install/)

### Step 2: Build Docker Image

```bash
cd MetaGenomics-Pipeline/docker
./build.sh
```

### Step 3: Run with Docker Compose

```bash
# Create necessary directories
mkdir -p data results logs databases

# Start services
docker-compose up -d

# Check status
docker-compose ps
```

### Docker Configuration

Edit `docker/docker-compose.yml` to customize:

```yaml
services:
  metagenomics-pipeline:
    environment:
      - PIPELINE_THREADS=8
      - PIPELINE_MEMORY=16G
    
    deploy:
      resources:
        limits:
          cpus: '8.0'
          memory: 16G
```

## Conda Environment Setup

For advanced users who want to customize the environment:

### Create Custom Environment

```bash
# Create environment from file
micromamba create -f config/environment-full.yml

# Or create minimal environment
micromamba create -n metagenomics-minimal -c conda-forge python=3.9 -y
micromamba activate metagenomics-minimal

# Install only required tools
micromamba install -c bioconda fastqc trimmomatic bowtie2 samtools kraken2 spades -y
```

### Environment Management

```bash
# List environments
micromamba env list

# Export environment
micromamba env export -n metagenomics-pipeline > my-environment.yml

# Remove environment
micromamba env remove -n metagenomics-pipeline
```

## Database Setup

The pipeline requires several reference databases:

### Kraken2 Database

```bash
# Download standard database (8GB)
kraken2-build --standard --threads 8 --db kraken2_standard

# Or download pre-built database
wget https://genome-idx.s3.amazonaws.com/kraken/k2_standard_20210517.tar.gz
tar -xzf k2_standard_20210517.tar.gz
```

### Host Genome Database

```bash
# Human genome (for human microbiome studies)
wget https://ftp.ncbi.nlm.nih.gov/genomes/all/GCF/000/001/405/GCF_000001405.39_GRCh38.p13/GCF_000001405.39_GRCh38.p13_genomic.fna.gz
gunzip GCF_000001405.39_GRCh38.p13_genomic.fna.gz

# Build Bowtie2 index
bowtie2-build GCF_000001405.39_GRCh38.p13_genomic.fna human_genome
```

### PhyloPhlan Database

```bash
# Download and setup PhyloPhlan database
phylophlan_setup_database -g s__SGB --output_dir phylophlan_db
```

### Database Directory Structure

```
databases/
├── kraken2/
│   ├── hash.k2d
│   ├── opts.k2d
│   └── taxo.k2d
├── bowtie2/
│   ├── host_genome.1.bt2
│   ├── host_genome.2.bt2
│   └── ...
└── phylophlan/
    └── ...
```

## Verification

### Test Installation

```bash
# Activate environment
source activate_env.sh

# Check tool versions
fastqc --version
trimmomatic -version
bowtie2 --version
kraken2 --version
spades.py --version

# Run pipeline help
./run_pipeline.sh --help
python3 metapipeline_improved.py --help
```

### Run Test Data

```bash
# Download test data
wget https://example.com/test_data.tar.gz
tar -xzf test_data.tar.gz

# Run test
python3 metapipeline_improved.py metapipeline -m qc -t 2 -p1 _R1 -p2 _R2 -e fastq.gz
```

## Troubleshooting

### Common Issues

#### 1. Micromamba Installation Fails

```bash
# Check if bzip2 is installed
sudo apt-get install bzip2  # Ubuntu/Debian
sudo yum install bzip2      # CentOS/RHEL

# Manual installation
curl -Ls https://micro.mamba.pm/api/micromamba/linux-64/latest > micromamba.tar.bz2
tar -xjf micromamba.tar.bz2
sudo mv bin/micromamba /usr/local/bin/
```

#### 2. Environment Creation Fails

```bash
# Clear conda cache
micromamba clean --all

# Update micromamba
micromamba self-update

# Try with different channels
micromamba create -n test -c conda-forge -c bioconda -c defaults python=3.9 -y
```

#### 3. Tool Installation Fails

```bash
# Install tools individually
micromamba install -c bioconda fastqc -y
micromamba install -c bioconda trimmomatic -y

# Check for conflicts
micromamba install --dry-run -c bioconda tool_name
```

#### 4. Permission Issues

```bash
# Fix permissions
chmod +x install.sh
chmod +x run_pipeline.sh
chmod +x src/*.sh

# Run with sudo if needed (not recommended)
sudo ./install.sh
```

#### 5. Memory Issues

```bash
# Reduce parallel processes
export OMP_NUM_THREADS=2

# Use swap space
sudo fallocate -l 4G /swapfile
sudo chmod 600 /swapfile
sudo mkswap /swapfile
sudo swapon /swapfile
```

### Getting Help

If you encounter issues:

1. Check the [troubleshooting guide](troubleshooting.md)
2. Search [existing issues](https://github.com/your-username/MetaGenomics-Pipeline/issues)
3. Create a [new issue](https://github.com/your-username/MetaGenomics-Pipeline/issues/new) with:
   - System information (`uname -a`)
   - Error messages
   - Installation log
   - Steps to reproduce

### Log Files

Installation and execution logs are stored in:
- `logs/installation.log`
- `logs/metapipeline_*.log`
- Individual step logs in respective directories

Check these files for detailed error information.

