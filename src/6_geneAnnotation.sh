#!/bin/bash

echo "--------------------- METAPIPELINE [PASO 9]---------------------------------------"
echo "                       GENE ANNOTATION                                    "
echo "----------------------------------------------------------------------------------"

threads=$1

cd results/
for d in assemblies/*;
    do
    base=${d:11}
    for mags in assemblies/${base}/maxbin/$base.*.fasta;
        do
        sample1=$(basename "$mags"| sed 's/\.fasta$//') # name for MAG assembled
        sample=$(basename "$mags"| sed 's/\./\_/'| cut -d. -f1 ) #Directory Name for MAGS
        echo $sample
        mkdir geneAnnotation/$base/$sample # Create MAGS directories
        #Extrar Genus information for annotation
        genus=$(grep "$sample1" taxonomy/phylophlan/$base/$base\_metagenomic.tsv | grep -o 'g__[^|]*' | sed 's/g__//') 
        # Check if the substring exists in the string
        if [[ $genus == *"GGB"* ]]; then
            prokka \
            --outdir geneAnnotation/$base/$sample \
            --metagenome \
            --kingdom Bacteria \
            --centre X \
            --compliant \
            --cpus $threads \
            --quiet \
            --force \
            assemblies/${base}/maxbin/$sample\_filtered.fasta.gz
        else
            prokka \
            --outdir geneAnnotation/$base/$sample \
            --kingdom Bacteria \
            --usegenus \
            --genus $genus \
            --metagenome \
            --centre X \
            --compliant \
            --cpus $threads \
            --quiet \
            --force \
            assemblies/${base}/maxbin/$sample\_filtered.fasta.gz
        fi
        done
    echo $base 'Gene annotation Done'
    done
cd ..