#!/bin/bash

#####################################################################
#                    IMPROVED QUALITY CHECK SCRIPT                 #
#                         Enhanced Version                         #
#####################################################################

set -euo pipefail  # Exit on error, undefined vars, pipe failures

# Script parameters
THREADS=${1:-4}
PATTERN_F=${2:-"_R1"}
PATTERN_R=${3:-"_R2"}
EXTENSION=${4:-"fastq.gz"}

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Logging functions
log() {
    echo -e "${GREEN}[$(date +'%Y-%m-%d %H:%M:%S')] [QC] $1${NC}" | tee -a quality_check.log
}

warn() {
    echo -e "${YELLOW}[$(date +'%Y-%m-%d %H:%M:%S')] [QC] WARNING: $1${NC}" | tee -a quality_check.log
}

error() {
    echo -e "${RED}[$(date +'%Y-%m-%d %H:%M:%S')] [QC] ERROR: $1${NC}" | tee -a quality_check.log
    exit 1
}

info() {
    echo -e "${BLUE}[$(date +'%Y-%m-%d %H:%M:%S')] [QC] INFO: $1${NC}" | tee -a quality_check.log
}

# Function to check if command exists
check_command() {
    if ! command -v "$1" &> /dev/null; then
        error "Required command '$1' not found. Please install it first."
    fi
}

# Function to check file existence
check_file() {
    if [[ ! -f "$1" ]]; then
        error "Required file not found: $1"
    fi
}

# Function to check directory existence
check_directory() {
    if [[ ! -d "$1" ]]; then
        error "Required directory not found: $1"
    fi
}

# Function to create directory if it doesn't exist
create_directory() {
    if [[ ! -d "$1" ]]; then
        mkdir -p "$1"
        log "Created directory: $1"
    fi
}

# Function to get file size in human readable format
get_file_size() {
    if [[ -f "$1" ]]; then
        du -h "$1" | cut -f1
    else
        echo "N/A"
    fi
}

# Function to count reads in fastq file
count_reads() {
    local file="$1"
    if [[ "$file" == *.gz ]]; then
        echo $(($(zcat "$file" | wc -l) / 4))
    else
        echo $(($(wc -l < "$file") / 4))
    fi
}

# Main function
main() {
    log "Starting Quality Check Pipeline"
    log "Parameters: THREADS=$THREADS, PATTERN_F=$PATTERN_F, PATTERN_R=$PATTERN_R, EXTENSION=$EXTENSION"
    
    # Check required commands
    log "Checking required tools..."
    check_command "fastqc"
    check_command "trimmomatic"
    
    # Check directory structure
    log "Checking directory structure..."
    check_directory "raw-reads"
    check_directory "results"
    
    # Create output directories
    log "Creating output directories..."
    create_directory "results/fastqc"
    create_directory "results/fastqc/beforeTrimQC"
    create_directory "results/fastqc/trimQC"
    create_directory "results/trimmed-reads"
    create_directory "results/untrimmed-reads"
    
    # Change to results directory
    cd results/
    
    # Initialize counters
    local total_samples=0
    local processed_samples=0
    local failed_samples=0
    
    # Count total samples
    for R1 in ../raw-reads/*${PATTERN_F}*.${EXTENSION}; do
        if [[ -f "$R1" ]]; then
            ((total_samples++))
        fi
    done
    
    if [[ $total_samples -eq 0 ]]; then
        error "No input files found matching pattern: *${PATTERN_F}*.${EXTENSION}"
    fi
    
    log "Found $total_samples samples to process"
    
    # Process each sample
    for R1 in ../raw-reads/*${PATTERN_F}*.${EXTENSION}; do
        if [[ ! -f "$R1" ]]; then
            continue
        fi
        
        # Extract base name
        base=$(basename "$R1" "${PATTERN_F}.${EXTENSION}")
        R2="../raw-reads/${base}${PATTERN_R}.${EXTENSION}"
        
        log "Processing sample: $base"
        
        # Check if R2 exists for paired-end data
        if [[ ! -f "$R2" ]]; then
            warn "Reverse read not found for $base: $R2"
            warn "Skipping sample $base"
            ((failed_samples++))
            continue
        fi
        
        # Create sample-specific directories
        create_directory "fastqc/beforeTrimQC/$base"
        create_directory "fastqc/trimQC/$base"
        create_directory "trimmed-reads/$base"
        create_directory "untrimmed-reads/$base"
        
        # Log file sizes
        info "Input file sizes - R1: $(get_file_size "$R1"), R2: $(get_file_size "$R2")"
        
        # Count input reads
        local reads_r1=$(count_reads "$R1")
        local reads_r2=$(count_reads "$R2")
        info "Input read counts - R1: $reads_r1, R2: $reads_r2"
        
        # Step 1: Initial quality check with FastQC
        log "Running initial FastQC for sample: $base"
        
        if fastqc "$R1" "$R2" -o "fastqc/beforeTrimQC/$base/" -t "$THREADS" > "fastqc/beforeTrimQC/$base/fastqc_verbose.txt" 2>&1; then
            log "FastQC completed successfully for $base"
        else
            error "FastQC failed for sample: $base"
        fi
        
        # Step 2: Trimming with Trimmomatic
        log "Running Trimmomatic for sample: $base"
        
        local trim_output_r1="trimmed-reads/$base/${base}_1.trim.fq.gz"
        local trim_output_r2="trimmed-reads/$base/${base}_2.trim.fq.gz"
        local untrim_output_r1="untrimmed-reads/$base/${base}_1.unpaired.fq.gz"
        local untrim_output_r2="untrimmed-reads/$base/${base}_2.unpaired.fq.gz"
        
        if trimmomatic PE \
            "$R1" "$R2" \
            -threads "$THREADS" \
            "$trim_output_r1" "$untrim_output_r1" \
            "$trim_output_r2" "$untrim_output_r2" \
            HEADCROP:20 SLIDINGWINDOW:4:20 MINLEN:35 \
            > "trimmed-reads/$base/trimming_verbose.txt" 2>&1; then
            
            log "Trimmomatic completed successfully for $base"
            
            # Count output reads
            local trimmed_reads_r1=$(count_reads "$trim_output_r1")
            local trimmed_reads_r2=$(count_reads "$trim_output_r2")
            local retention_rate=$(echo "scale=2; ($trimmed_reads_r1 * 100) / $reads_r1" | bc -l 2>/dev/null || echo "N/A")
            
            info "Trimmed read counts - R1: $trimmed_reads_r1, R2: $trimmed_reads_r2"
            info "Read retention rate: ${retention_rate}%"
            
            # Log output file sizes
            info "Trimmed file sizes - R1: $(get_file_size "$trim_output_r1"), R2: $(get_file_size "$trim_output_r2")"
            
        else
            error "Trimmomatic failed for sample: $base"
        fi
        
        # Step 3: Post-trimming quality check (optional)
        log "Running post-trimming FastQC for sample: $base"
        
        if fastqc "$trim_output_r1" "$trim_output_r2" \
            -o "fastqc/trimQC/$base/" -t "$THREADS" > "fastqc/trimQC/$base/fastqc_trim_verbose.txt" 2>&1; then
            log "Post-trimming FastQC completed successfully for $base"
        else
            warn "Post-trimming FastQC failed for sample: $base"
        fi
        
        ((processed_samples++))
        log "Sample $base completed successfully ($processed_samples/$total_samples)"
    done
    
    # Summary
    log "Quality Check Pipeline completed"
    log "Total samples: $total_samples"
    log "Successfully processed: $processed_samples"
    log "Failed samples: $failed_samples"
    
    if [[ $failed_samples -gt 0 ]]; then
        warn "Some samples failed processing. Check logs for details."
        exit 1
    fi
    
    log "All samples processed successfully!"
}

# Trap to handle script interruption
trap 'error "Script interrupted by user"' INT TERM

# Run main function
main "$@"

