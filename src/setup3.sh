#!/bin/bash
echo "--------------------------METAPIPELINE-----------------------------------"
echo "                       Setup metapipeline                                "
echo "-------------------------------------------------------------------------"

samples=$1 #folder path where the samples are stored. 
wd=$2 #Shoul be absolute path
pattern=$3 #Identifier of number of read (Eg. _L1, _R1, _F, etc)
extension=$4 #File extension (Eg. fq, fastq, fq.gz, fastq.gz)
prefix=$5 #Prefix of the samples of interest

cd $wd
mkdir raw-reads
#Copy/move all the fastq files to raw-reads base

for read in $samples/*; 
do
    cp $read raw-reads/
done

#Create folders for results
mkdir results
mkdir results/fastqc
mkdir results/fastqc/beforeTrimQC
mkdir results/fastqc/trimQC
mkdir results/taxonomy
mkdir results/taxonomy/reads
mkdir results/taxonomy/contigs
mkdir results/taxonomy/MAGS
mkdir results/taxonomy/reads/kraken
mkdir results/taxonomy/contigs/kraken
mkdir results/taxonomy/MAGS/phylophlan
mkdir results/assemblies
mkdir results/trimmed-reads
mkdir results/untrimmed-reads
mkdir results/host_removed
mkdir results/geneAnnotation/
mkdir results/functionalAnnotation/
mkdir results/functionalAnnotation/eggNOG
mkdir results/functionalAnnotation/kofam

#Create bases for each sample
for R1 in raw-reads/*$pattern*.$extension;
    do
        base=$(basename $R1 $pattern.$extension) #This will deleate any prefix up to the last "/" and the pattern and file extension
                                                   #in order to keep the sample name
        echo "Creating result bases for" $base "sample"
        mkdir results/taxonomy/reads/kraken/$base
        mkdir results/taxonomy/contigs/kraken/$base
        mkdir results/taxonomy/MAGS/phylophlan/$base
        mkdir results/assemblies/$base
        mkdir results/fastqc/beforeTrimQC/$base
        mkdir results/fastqc/trimQC/$base
        mkdir results/trimmed-reads/$base
        mkdir results/untrimmed-reads/$base
        mkdir results/host_removed/$base
        mkdir results/functionalAnnotation/eggNOG/$base
        mkdir results/functionalAnnotation/kofam/$base
        echo "Folders created for" $base
    done

