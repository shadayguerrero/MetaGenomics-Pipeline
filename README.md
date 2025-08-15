# MetaGenomics Pipeline


## 🚀 Quick Start

### Option 1: Automatic Installation (Recommended)

```bash
# Clone the repository
git clone https://github.com/your-username/MetaGenomics-Pipeline.git
cd MetaGenomics-Pipeline

# Run automatic installation
./install.sh

# Activate environment and run pipeline
source activate_env.sh
./run_pipeline.sh --help
```

### Option 2: Docker (Easiest)

```bash
# Build Docker image
cd docker
./build.sh

# Run with docker-compose
docker-compose up

# Or run directly
docker run --rm -v $(pwd)/data:/data metagenomics-pipeline:latest python3 /app/metapipeline_improved.py --help
```

## 📋 Features

- **Complete Workflow**: From raw reads to functional annotation
- **Quality Control**: FastQC and Trimmomatic integration
- **Host Removal**: Bowtie2-based host sequence filtering
- **Taxonomic Classification**: Kraken2 for rapid taxonomic assignment
- **Metagenome Assembly**: SPAdes for high-quality assemblies
- **Binning**: MaxBin2 for genome binning
- **Quality Assessment**: CheckM for bin quality evaluation
- **Phylogenetic Analysis**: PhyloPhlan for phylogenetic placement
- **Gene Prediction**: Prodigal for gene calling
- **Functional Annotation**: Multiple annotation databases
- **Robust Error Handling**: Comprehensive logging and error recovery
- **Multiple Deployment Options**: Native, Conda, Docker
- **Scalable**: Configurable thread usage and resource management

## 🔧 Pipeline Steps

1. **Quality Check** - FastQC analysis and read trimming
2. **Host Removal** - Remove host contamination using Bowtie2
3. **Taxonomic Assignment** - Classify reads with Kraken2
4. **Metagenome Assembly** - Assemble contigs with SPAdes
5. **Genome Binning** - Bin contigs into MAGs
6. **Quality Assessment** - Evaluate MAG quality with CheckM
7. **Phylogenetic Analysis** - Phylogenetic placement of MAGs
8. **Gene Annotation** - Predict genes with Prodigal
9. **Functional Annotation** - Annotate gene functions

## 📁 Directory Structure


## 🛠️ Requirements

### System Requirements


### Software Dependencies
- Python 3.9+
- Conda/Mamba/Micromamba
- Docker (optional)

### Bioinformatics Tools
All tools are automatically installed via the installation script:
- FastQC
- Trimmomatic
- Bowtie2
- Samtools
- Kraken2
- SPAdes
- MaxBin2
- CheckM
- PhyloPhlan
- Prodigal

## 📖 Documentation

- [Installation Guide](docs/installation.md)

## 🎯 Usage Examples

### Basic Usage


### Docker Usage


## 🗃️ Database Setup

The pipeline requires several databases. Download scripts are provided:

```bash
# Download Kraken2 database
./scripts/download_kraken_db.sh

# Download host genome for Bowtie2
./scripts/download_host_genome.sh

# Download PhyloPhlan database
./scripts/download_phylophlan_db.sh
```

## ⚙️ Configuration

The pipeline can be configured via:


## 🧪 Testing


