#!/bin/bash

#####################################################################
#                    IMPROVED HOST REMOVAL SCRIPT                  #
#                         Enhanced Version                         #
#####################################################################

set -euo pipefail  # Exit on error, undefined vars, pipe failures

# Script parameters
THREADS=${1:-4}
PATTERN_F=${2:-"_R1"}
EXTENSION=${3:-"fastq.gz"}
BOWTIE_DB=${4:-""}

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Logging functions
log() {
    echo -e "${GREEN}[$(date +'%Y-%m-%d %H:%M:%S')] [HOST_REMOVAL] $1${NC}" | tee -a host_removal.log
}

warn() {
    echo -e "${YELLOW}[$(date +'%Y-%m-%d %H:%M:%S')] [HOST_REMOVAL] WARNING: $1${NC}" | tee -a host_removal.log
}

error() {
    echo -e "${RED}[$(date +'%Y-%m-%d %H:%M:%S')] [HOST_REMOVAL] ERROR: $1${NC}" | tee -a host_removal.log
    exit 1
}

info() {
    echo -e "${BLUE}[$(date +'%Y-%m-%d %H:%M:%S')] [HOST_REMOVAL] INFO: $1${NC}" | tee -a host_removal.log
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

# Function to check Bowtie2 database
check_bowtie_db() {
    local db_path="$1"
    
    if [[ -z "$db_path" ]]; then
        error "Bowtie2 database path not provided"
    fi
    
    # Check if database files exist
    local db_files=("${db_path}.1.bt2" "${db_path}.2.bt2" "${db_path}.3.bt2" "${db_path}.4.bt2" "${db_path}.rev.1.bt2" "${db_path}.rev.2.bt2")
    
    for db_file in "${db_files[@]}"; do
        if [[ ! -f "$db_file" ]]; then
            error "Bowtie2 database file not found: $db_file"
        fi
    done
    
    log "Bowtie2 database validated: $db_path"
}

# Function to get alignment statistics
get_alignment_stats() {
    local sam_file="$1"
    local total_reads=$(samtools view -c "$sam_file")
    local mapped_reads=$(samtools view -c -F 4 "$sam_file")
    local unmapped_reads=$(samtools view -c -f 4 "$sam_file")
    local mapping_rate=$(echo "scale=2; ($mapped_reads * 100) / $total_reads" | bc -l 2>/dev/null || echo "N/A")
    
    echo "Total reads: $total_reads, Mapped: $mapped_reads, Unmapped: $unmapped_reads, Mapping rate: ${mapping_rate}%"
}

# Main function
main() {
    log "Starting Host Removal Pipeline"
    log "Parameters: THREADS=$THREADS, PATTERN_F=$PATTERN_F, EXTENSION=$EXTENSION, BOWTIE_DB=$BOWTIE_DB"
    
    # Check required commands
    log "Checking required tools..."
    check_command "bowtie2"
    check_command "samtools"
    
    # Check Bowtie2 database
    log "Validating Bowtie2 database..."
    check_bowtie_db "$BOWTIE_DB"
    
    # Check directory structure
    log "Checking directory structure..."
    check_directory "results"
    check_directory "results/trimmed-reads"
    
    # Create output directories
    log "Creating output directories..."
    create_directory "results/host_removed"
    
    # Change to results directory
    cd results/
    
    # Initialize counters
    local total_samples=0
    local processed_samples=0
    local failed_samples=0
    
    # Count total samples
    for trim_dir in trimmed-reads/*/; do
        if [[ -d "$trim_dir" ]]; then
            ((total_samples++))
        fi
    done
    
    if [[ $total_samples -eq 0 ]]; then
        error "No trimmed samples found in results/trimmed-reads/"
    fi
    
    log "Found $total_samples samples to process"
    
    # Process each sample
    for trim_dir in trimmed-reads/*/; do
        if [[ ! -d "$trim_dir" ]]; then
            continue
        fi
        
        # Extract base name
        base=$(basename "$trim_dir")
        
        log "Processing sample: $base"
        
        # Define input files
        local input_r1="trimmed-reads/$base/${base}_1.trim.fq.gz"
        local input_r2="trimmed-reads/$base/${base}_2.trim.fq.gz"
        
        # Check if input files exist
        if [[ ! -f "$input_r1" ]] || [[ ! -f "$input_r2" ]]; then
            warn "Trimmed files not found for sample $base"
            warn "Expected: $input_r1, $input_r2"
            ((failed_samples++))
            continue
        fi
        
        # Create sample-specific directory
        create_directory "host_removed/$base"
        
        # Log input file information
        info "Input file sizes - R1: $(get_file_size "$input_r1"), R2: $(get_file_size "$input_r2")"
        
        # Count input reads
        local input_reads_r1=$(count_reads "$input_r1")
        local input_reads_r2=$(count_reads "$input_r2")
        info "Input read counts - R1: $input_reads_r1, R2: $input_reads_r2"
        
        # Define output files
        local sam_file="host_removed/$base/${base}_aligned.sam"
        local output_r1="host_removed/$base/${base}_1.host_removed.fq.gz"
        local output_r2="host_removed/$base/${base}_2.host_removed.fq.gz"
        local log_file="host_removed/$base/${base}_bowtie2.log"
        
        # Step 1: Align reads to host genome with Bowtie2
        log "Aligning reads to host genome for sample: $base"
        
        if bowtie2 \
            -x "$BOWTIE_DB" \
            -1 "$input_r1" \
            -2 "$input_r2" \
            -S "$sam_file" \
            -p "$THREADS" \
            --very-sensitive-local \
            --no-unal \
            2> "$log_file"; then
            
            log "Bowtie2 alignment completed for $base"
            
            # Get alignment statistics
            local stats=$(get_alignment_stats "$sam_file")
            info "Alignment statistics: $stats"
            
        else
            error "Bowtie2 alignment failed for sample: $base"
        fi
        
        # Step 2: Extract unmapped reads (non-host reads)
        log "Extracting unmapped reads for sample: $base"
        
        # Extract unmapped read IDs
        local unmapped_ids="host_removed/$base/${base}_unmapped_ids.txt"
        
        if samtools view -f 4 "$sam_file" | cut -f1 | sort | uniq > "$unmapped_ids"; then
            log "Extracted unmapped read IDs for $base"
            local unmapped_count=$(wc -l < "$unmapped_ids")
            info "Number of unmapped read pairs: $unmapped_count"
        else
            error "Failed to extract unmapped read IDs for sample: $base"
        fi
        
        # Step 3: Filter original reads to keep only unmapped ones
        log "Filtering reads to remove host sequences for sample: $base"
        
        # Use seqtk or custom script to extract unmapped reads
        if command -v seqtk &> /dev/null; then
            # Use seqtk if available
            if seqtk subseq "$input_r1" "$unmapped_ids" | gzip > "$output_r1" && \
               seqtk subseq "$input_r2" "$unmapped_ids" | gzip > "$output_r2"; then
                log "Host removal completed using seqtk for $base"
            else
                error "seqtk filtering failed for sample: $base"
            fi
        else
            # Use alternative method with awk
            log "Using awk-based filtering (seqtk not available)"
            
            # Create temporary files
            local temp_r1="host_removed/$base/${base}_temp_1.fq"
            local temp_r2="host_removed/$base/${base}_temp_2.fq"
            
            # Extract reads using awk
            if zcat "$input_r1" | awk 'NR==FNR{ids[$1]=1; next} /^@/{if(substr($1,2) in ids){p=1}else{p=0}} p' "$unmapped_ids" - > "$temp_r1" && \
               zcat "$input_r2" | awk 'NR==FNR{ids[$1]=1; next} /^@/{if(substr($1,2) in ids){p=1}else{p=0}} p' "$unmapped_ids" - > "$temp_r2"; then
                
                # Compress output files
                gzip -c "$temp_r1" > "$output_r1"
                gzip -c "$temp_r2" > "$output_r2"
                
                # Clean up temporary files
                rm -f "$temp_r1" "$temp_r2"
                
                log "Host removal completed using awk for $base"
            else
                error "awk-based filtering failed for sample: $base"
            fi
        fi
        
        # Count output reads
        local output_reads_r1=$(count_reads "$output_r1")
        local output_reads_r2=$(count_reads "$output_r2")
        local retention_rate=$(echo "scale=2; ($output_reads_r1 * 100) / $input_reads_r1" | bc -l 2>/dev/null || echo "N/A")
        
        info "Output read counts - R1: $output_reads_r1, R2: $output_reads_r2"
        info "Non-host read retention rate: ${retention_rate}%"
        
        # Log output file sizes
        info "Output file sizes - R1: $(get_file_size "$output_r1"), R2: $(get_file_size "$output_r2")"
        
        # Clean up intermediate files
        rm -f "$sam_file" "$unmapped_ids"
        
        ((processed_samples++))
        log "Sample $base completed successfully ($processed_samples/$total_samples)"
    done
    
    # Summary
    log "Host Removal Pipeline completed"
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

