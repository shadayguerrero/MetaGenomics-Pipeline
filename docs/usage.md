# Usage Guide

This guide provides comprehensive instructions for using the MetaGenomics Pipeline to analyze metagenomic sequencing data.

## Table of Contents

1. [Quick Start](#quick-start)
2. [Input Data Preparation](#input-data-preparation)
3. [Pipeline Modes](#pipeline-modes)
4. [Command Line Interface](#command-line-interface)
5. [Configuration](#configuration)
6. [Output Interpretation](#output-interpretation)
7. [Best Practices](#best-practices)
8. [Examples](#examples)

## Quick Start

### 1. Prepare Your Data

```bash
# Create project directory
mkdir my_metagenomics_project
cd my_metagenomics_project

# Copy your raw reads
cp /path/to/your/reads/*.fastq.gz raw-reads/
```

### 2. Setup Project

```bash
# Setup directory structure
python3 /path/to/MetaGenomics-Pipeline/metapipeline_improved.py setup \
  raw-reads/ \
  $(pwd) \
  _R1 \
  fastq.gz \
  --prefix my_sample
```

### 3. Run Pipeline

```bash
# Run complete pipeline
python3 /path/to/MetaGenomics-Pipeline/metapipeline_improved.py metapipeline \
  -m all \
  -t 8 \
  -p1 _R1 \
  -p2 _R2 \
  -e fastq.gz \
  -bDB /path/to/bowtie_db \
  -kDB /path/to/kraken_db \
  -pDB /path/to/phylophlan_db \
  -opt 1 \
  -n my_sample
```

## Input Data Preparation

### Supported File Formats

- **FASTQ**: `.fastq`, `.fq`
- **Compressed FASTQ**: `.fastq.gz`, `.fq.gz`
- **Paired-end reads**: Required for most analyses

### File Naming Convention

The pipeline expects paired-end reads with consistent naming:

```
sample1_R1.fastq.gz  # Forward reads
sample1_R2.fastq.gz  # Reverse reads

sample2_L001_R1_001.fastq.gz  # Alternative naming
sample2_L001_R2_001.fastq.gz
```

### Directory Structure

```
project_directory/
├── raw-reads/
│   ├── sample1_R1.fastq.gz
│   ├── sample1_R2.fastq.gz
│   ├── sample2_R1.fastq.gz
│   └── sample2_R2.fastq.gz
└── results/
    ├── fastqc/
    ├── trimmed-reads/
    ├── host_removed/
    ├── taxonomy/
    ├── assemblies/
    └── annotation/
```

### Data Quality Requirements

- **Read length**: Minimum 50 bp
- **Quality scores**: Phred+33 encoding
- **Coverage**: Minimum 1M read pairs per sample
- **Insert size**: 200-800 bp for paired-end libraries

## Pipeline Modes

### Complete Pipeline (`all`)

Runs all analysis steps sequentially:

```bash
python3 metapipeline_improved.py metapipeline -m all [options]
```

### Individual Steps

#### Quality Control (`qc`)

```bash
python3 metapipeline_improved.py metapipeline -m qc \
  -t 8 -p1 _R1 -p2 _R2 -e fastq.gz
```

**What it does:**
- FastQC analysis of raw reads
- Trimmomatic read trimming
- Post-trimming quality assessment

#### Host Removal (`rmHost`)

```bash
python3 metapipeline_improved.py metapipeline -m rmHost \
  -t 8 -p1 _R1 -e fastq.gz -bDB /path/to/bowtie_db
```

**What it does:**
- Aligns reads to host genome
- Removes host-derived sequences
- Retains microbial reads

#### Taxonomic Assignment (`taxAssignment`)

```bash
python3 metapipeline_improved.py metapipeline -m taxAssignment \
  -t 8 -p1 _R1 -e fastq.gz -kDB /path/to/kraken_db
```

**What it does:**
- Classifies reads using Kraken2
- Generates taxonomic profiles
- Creates abundance tables

#### Assembly (`assembly`)

```bash
python3 metapipeline_improved.py metapipeline -m assembly \
  -t 8 -p1 _R1 -e fastq.gz
```

**What it does:**
- Assembles contigs with SPAdes
- Performs genome binning
- Evaluates bin quality

#### MAG Taxonomy (`taxMags`)

```bash
python3 metapipeline_improved.py metapipeline -m taxMags \
  -t 8 -pDB /path/to/phylophlan_db -n sample_prefix -opt 1
```

**What it does:**
- Phylogenetic placement of MAGs
- Taxonomic assignment of bins
- Phylogenetic tree construction

#### Gene Annotation (`geneAnnotation`)

```bash
python3 metapipeline_improved.py metapipeline -m geneAnnotation -t 8
```

**What it does:**
- Predicts genes with Prodigal
- Annotates protein sequences
- Identifies functional domains

#### Functional Annotation (`funcAnnotation`)

```bash
python3 metapipeline_improved.py metapipeline -m funcAnnotation \
  -t 8 -n sample_prefix \
  -eDB /path/to/eggnog_db \
  -profile /path/to/kofam_profiles \
  -kL /path/to/ko_list
```

**What it does:**
- Functional annotation with eggNOG
- KEGG pathway analysis
- COG classification

## Command Line Interface

### Main Commands

#### Setup Project

```bash
python3 metapipeline_improved.py setup <reads_dir> <work_dir> <pattern> <extension> [--prefix PREFIX]
```

**Parameters:**
- `reads_dir`: Directory containing raw reads
- `work_dir`: Working directory for analysis
- `pattern`: Read identifier pattern (e.g., _R1)
- `extension`: File extension (e.g., fastq.gz)
- `--prefix`: Sample prefix (optional)

#### MD5 Verification

```bash
python3 metapipeline_improved.py md5 <reads_dir> <md5_file> <extension> <output>
```

**Parameters:**
- `reads_dir`: Directory containing reads
- `md5_file`: MD5 checksum file
- `extension`: File extension
- `output`: Output report name

#### Environment Setup

```bash
python3 metapipeline_improved.py env [micromamba] [config/environment-full.yml]
```

### Pipeline Options

#### Required Parameters

- `-m, --mode`: Pipeline mode (all, qc, rmHost, etc.)
- `-t, --cpus`: Number of threads
- `-p1, --pForward`: Forward read pattern
- `-p2, --pReverse`: Reverse read pattern
- `-e, --extension`: File extension

#### Database Parameters

- `-bDB, --bowtieDB`: Bowtie2 database path
- `-kDB, --krakenDB`: Kraken2 database path
- `-pDB, --phylophlanDB`: PhyloPhlan database path
- `-eDB, --eggNOGDB`: eggNOG database path
- `-profile, --koProfiles`: KofamDB profiles path
- `-kL, --koList`: KofamDB list path

#### Analysis Parameters

- `-opt, --option`: Taxonomic assignment option (1: MAGs, 2: reads, 3: contigs)
- `-n, --prefix`: Sample prefix

### Examples

#### Basic Quality Control

```bash
python3 metapipeline_improved.py metapipeline \
  -m qc \
  -t 4 \
  -p1 _R1 \
  -p2 _R2 \
  -e fastq.gz
```

#### Host Removal Only

```bash
python3 metapipeline_improved.py metapipeline \
  -m rmHost \
  -t 8 \
  -p1 _R1 \
  -e fastq.gz \
  -bDB databases/human_genome
```

#### Complete Analysis

```bash
python3 metapipeline_improved.py metapipeline \
  -m all \
  -t 16 \
  -p1 _R1 \
  -p2 _R2 \
  -e fastq.gz \
  -bDB databases/human_genome \
  -kDB databases/kraken2_standard \
  -pDB databases/phylophlan \
  -opt 1 \
  -n gut_microbiome \
  -eDB databases/eggnog \
  -profile databases/kofam/profiles \
  -kL databases/kofam/ko_list
```

## Configuration

### Configuration File

Edit `config/pipeline.conf`:

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

[ASSEMBLY]
spades_params = --meta

[ANNOTATION]
prodigal_params = -p meta
```

### Environment Variables

```bash
export PIPELINE_THREADS=8
export PIPELINE_MEMORY=16G
export TMPDIR=/tmp
```

## Output Interpretation

### Quality Control Results

**Location**: `results/fastqc/`

- **beforeTrimQC/**: Raw read quality reports
- **trimQC/**: Post-trimming quality reports
- **Files**: HTML reports, summary statistics

**Key Metrics:**
- Per base sequence quality
- Sequence length distribution
- GC content
- Adapter contamination

### Taxonomic Classification

**Location**: `results/taxonomy/reads/kraken/`

- **sample.kraken**: Kraken2 classification output
- **sample.report**: Taxonomic abundance report
- **sample.biom**: BIOM format abundance table

**Interpretation:**
- Taxonomic composition at different levels
- Relative abundances
- Unclassified fraction

### Assembly Results

**Location**: `results/assemblies/`

- **contigs.fasta**: Assembled contigs
- **scaffolds.fasta**: Scaffolded sequences
- **assembly_stats.txt**: Assembly statistics

**Quality Metrics:**
- N50 length
- Total assembly size
- Number of contigs
- Largest contig size

### MAG Quality

**Location**: `results/taxonomy/MAGS/phylophlan/`

- **checkm_results.txt**: CheckM quality assessment
- **phylophlan_tree.nwk**: Phylogenetic tree

**Quality Categories:**
- High quality: >90% completeness, <5% contamination
- Medium quality: >50% completeness, <10% contamination
- Low quality: <50% completeness or >10% contamination

### Functional Annotation

**Location**: `results/functionalAnnotation/`

- **eggNOG/**: eggNOG annotation results
- **kofam/**: KEGG annotation results
- **summary_tables/**: Aggregated functional profiles

## Best Practices

### Resource Management

1. **CPU Usage**: Use 75% of available cores
2. **Memory**: Ensure 2-4 GB RAM per thread
3. **Storage**: Monitor disk space during analysis
4. **Temporary Files**: Clean up intermediate files

### Quality Control

1. **Check FastQC reports** before proceeding
2. **Adjust trimming parameters** based on data quality
3. **Monitor read retention rates** after each step
4. **Validate assembly quality** before annotation

### Database Selection

1. **Host genome**: Match to sample source
2. **Kraken2 database**: Use appropriate size for system
3. **Functional databases**: Keep updated versions

### Troubleshooting

1. **Check log files** for error messages
2. **Verify input file formats** and naming
3. **Ensure sufficient disk space**
4. **Monitor memory usage**

### Performance Optimization

1. **Use SSD storage** for better I/O
2. **Optimize thread usage** for your system
3. **Use appropriate database sizes**
4. **Consider sample multiplexing**

## Examples

### Example 1: Human Gut Microbiome

```bash
# Setup
python3 metapipeline_improved.py setup \
  raw_reads/ $(pwd) _R1 fastq.gz --prefix gut_sample

# Run pipeline
python3 metapipeline_improved.py metapipeline \
  -m all -t 12 -p1 _R1 -p2 _R2 -e fastq.gz \
  -bDB databases/human_genome \
  -kDB databases/kraken2_standard \
  -pDB databases/phylophlan \
  -opt 1 -n gut_microbiome
```

### Example 2: Soil Metagenome

```bash
# No host removal needed
python3 metapipeline_improved.py metapipeline \
  -m qc -t 8 -p1 _R1 -p2 _R2 -e fastq.gz

python3 metapipeline_improved.py metapipeline \
  -m taxAssignment -t 8 -p1 _R1 -e fastq.gz \
  -kDB databases/kraken2_standard

python3 metapipeline_improved.py metapipeline \
  -m assembly -t 8 -p1 _R1 -e fastq.gz
```

### Example 3: Marine Microbiome

```bash
# Custom trimming for marine samples
# Edit config/pipeline.conf:
# trimmomatic_params = HEADCROP:15 SLIDINGWINDOW:4:15 MINLEN:50

python3 metapipeline_improved.py metapipeline \
  -m all -t 16 -p1 _R1 -p2 _R2 -e fastq.gz \
  -kDB databases/kraken2_marine \
  -pDB databases/phylophlan \
  -opt 1 -n marine_sample
```

For more examples and advanced usage, see the [examples/](../examples/) directory.

