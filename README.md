# MetaGenomics Pipeline

[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)
[![Docker](https://img.shields.io/badge/Docker-Available-blue.svg)](https://docker.com)
[![Conda](https://img.shields.io/badge/Conda-Supported-green.svg)](https://conda.io)

A comprehensive, robust, and user-friendly metagenomics analysis pipeline for processing metagenomic sequencing data from raw reads to functional annotation.

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

```
MetaGenomics-Pipeline/
├── README.md                 # This file
├── install.sh               # Automatic installation script
├── run_pipeline.sh          # Pipeline runner script
├── activate_env.sh          # Environment activation script
├── metapipeline_improved.py # Enhanced pipeline controller
├── config/                  # Configuration files
│   ├── pipeline.conf        # Pipeline configuration
│   └── environment-full.yml # Conda environment specification
├── src/                     # Pipeline scripts
│   ├── 1_qualityCheck_improved.sh
│   ├── 2_hostRemove_improved.sh
│   └── ...
├── docker/                  # Docker deployment files
│   ├── Dockerfile
│   ├── docker-compose.yml
│   └── build.sh
├── docs/                    # Documentation
├── examples/                # Example data and configurations
└── tests/                   # Test scripts
```

## 🛠️ Requirements

### System Requirements
- Linux or macOS
- 8+ GB RAM (16+ GB recommended)
- 50+ GB free disk space
- Internet connection for database downloads

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
- [Usage Guide](docs/usage.md)
- [Configuration](docs/configuration.md)
- [Docker Deployment](docs/docker.md)
- [Troubleshooting](docs/troubleshooting.md)
- [API Reference](docs/api.md)

## 🎯 Usage Examples

### Basic Usage

```bash
# Setup project directory
python3 metapipeline_improved.py setup /path/to/reads /path/to/workdir _R1 fastq.gz --prefix sample

# Run quality control only
python3 metapipeline_improved.py metapipeline -m qc -t 8 -p1 _R1 -p2 _R2 -e fastq.gz

# Run complete pipeline
python3 metapipeline_improved.py metapipeline -m all -t 8 \
  -p1 _R1 -p2 _R2 -e fastq.gz \
  -bDB /path/to/bowtie_db \
  -kDB /path/to/kraken_db \
  -pDB /path/to/phylophlan_db \
  -opt 1 -n sample_prefix
```

### Docker Usage

```bash
# Run with Docker
docker run --rm \
  -v $(pwd)/data:/data \
  -v $(pwd)/results:/app/results \
  metagenomics-pipeline:latest \
  python3 /app/metapipeline_improved.py metapipeline -m all -t 4 \
  -p1 _R1 -p2 _R2 -e fastq.gz \
  -bDB /app/databases/host_db \
  -kDB /app/databases/kraken_db
```

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

1. **Configuration file**: `config/pipeline.conf`
2. **Command-line arguments**: Override config file settings
3. **Environment variables**: For Docker deployments

Example configuration:

```ini
[DEFAULT]
threads = 8
temp_dir = ./tmp
keep_intermediate = false

[QUALITY_CONTROL]
trimmomatic_params = HEADCROP:20 SLIDINGWINDOW:4:20 MINLEN:35

[HOST_REMOVAL]
bowtie2_params = --very-sensitive-local

[TAXONOMY]
kraken2_confidence = 0.1
```

## 🧪 Testing

Run the test suite to verify installation:

```bash
# Run all tests
./tests/run_tests.sh

# Run specific test
./tests/test_quality_control.sh
```

## 📊 Output

The pipeline generates:

- **Quality reports**: FastQC HTML reports
- **Cleaned reads**: Host-removed, quality-filtered reads
- **Taxonomic profiles**: Kraken2 classification results
- **Assemblies**: Contigs and scaffolds
- **MAGs**: Metagenome-assembled genomes
- **Annotations**: Gene predictions and functional annotations
- **Logs**: Detailed execution logs for troubleshooting

## 🤝 Contributing

We welcome contributions! Please see [CONTRIBUTING.md](CONTRIBUTING.md) for guidelines.

## 📄 License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## 📞 Support

- **Issues**: [GitHub Issues](https://github.com/your-username/MetaGenomics-Pipeline/issues)
- **Discussions**: [GitHub Discussions](https://github.com/your-username/MetaGenomics-Pipeline/discussions)
- **Email**: support@metagenomics-pipeline.org

## 🙏 Acknowledgments

- Original pipeline developers: Dulce I. Valdivia, Erika Cruz-Bonilla, Augusto Franco
- Bioinformatics tools developers and maintainers
- Open source community

## 📚 Citation

If you use this pipeline in your research, please cite:

```
MetaGenomics Pipeline: A comprehensive metagenomics analysis workflow
[Your Name et al.] (2024)
GitHub: https://github.com/your-username/MetaGenomics-Pipeline
```

---

**Made with ❤️ for the metagenomics community**

