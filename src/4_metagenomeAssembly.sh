#!/bin/bash

echo "--------------------- METAPIPELINE ---------------------------------------"
echo "                        METAGENOME ASSEMBLY                                       "
echo "----------------------------------------------------------------------------------"

threads=$1
patternF=$2
extension=$3


# GENOME ASSEMBLY ---------------------------------------------------------------

cd results/
for R1 in ../raw-reads/*$patternF*.$extension;
        do
                base=$(basename $R1 $patternF.$extension) #This will deleate any prefix up to the last "/" and the pattern and file extension
                #                                         #in order to keep the sample name
                R1=$base\_host_removed_R1.fastq.gz 
                R2=$base\_host_removed_R2.fastq.gz 

                metaspades.py -1 host_removed/$base/$R1 -2 host_removed/$base/$R2 \
                        -o assemblies/$base \
                        --threads $threads \
                        > assemblies/$base/metaspades_$base\_verbose.txt

                echo $base 'Assembly Done'
        done

for d in assemblies/$prefix*;
        do
                base=${d:11}
                cp ${d}/scaffolds.fasta assemblies/${base}/${base}-scaffolds.fasta
                rm ${d}/scaffolds.fasta
        done

echo "--------------------- METAPIPELINE ---------------------------------------"
echo "                           BINNING                                                "
echo "----------------------------------------------------------------------------------"


# BINNING  ---------------------------------------------------------------------

for d in assemblies/*;
        do
                # # Create a working directory for maxbin
                base=${d:11}
                mkdir assemblies/${base}/maxbin

                # MaxBin call
                run_MaxBin.pl -thread $threads \
                        -contig assemblies/${base}/${base}-scaffolds.fasta \
                        -reads host_removed/$base/${base}_host_removed_R1.fastq.gz \
                        -reads2 host_removed/$base/${base}_host_removed_R2.fastq.gz \
                        -out assemblies/${base}/maxbin/${base} \
                                > assemblies/${base}/maxbin/maxbin_${base}.log

                echo $base 'Binning Done'
        done



echo "--------------------- METAPIPELINE ---------------------------------------"
echo "                      QUALITY OF THE BINNING                                      "
echo "----------------------------------------------------------------------------------"


# QUALITY OF THE BINNING ---------------------------------------------------------------

for d in assemblies/$prefix*;
       do
                # Create a working directory for checkm
                base=${d:11}
                mkdir assemblies/${base}/checkm

                # CheckM call
                checkm lineage_wf \
                        -t $threads \
                        -x fasta assemblies/${base}/maxbin \
                        assemblies/${base}/checkm \
                        > assemblies/${base}/checkm/checkm_${base}_verbose.txt

                echo $base 'Quality of the binning Done'
        done


for d in assemblies/*;
    do
    base=${d:11}
    for mags in assemblies/${base}/maxbin/$base\.*.fasta;
        do
        sample=$(basename "$mags"| sed 's/\./\_/'| cut -d. -f1 )

        seqkit seq -m 500 \
        -j $threads \
        $mags > assemblies/${base}/maxbin/$sample\_filtered.fasta.gz
        done
    echo $base 'MAGS length filter Done'
    done
cd ..
