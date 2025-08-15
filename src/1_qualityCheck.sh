#!/bin/bash

threads=$1
patternF=$2
patternR=$3
extension=$4

echo "----------------------------- METAPIPELINE :--------------------------------------"
echo "                              QUALITY CHECK                                       "
echo "----------------------------------------------------------------------------------"

#1: First quality check: ---------------------------------------------------------------------
# Iterate through the folders
cd results/
#Create bases for each sample
for R1 in ../raw-reads/*$patternF*.$extension;
    do
        base=$(basename $R1 $patternF.$extension) #This will deleate any prefix up to the last "/" and the pattern and file extension
                                                   #in order to keep the sample name


        fastqc  ../raw-reads/$base*.$extension -o fastqc/beforeTrimQC/$base/ -t $threads > fastqc/beforeTrimQC/$base/fastqc_verbose.txt

        echo $base 'Samples QC Done'
    #2: Clean the reads: -------------------------------------------------------------------------
    # Usage:
    #       PE [-version] [-threads <threads>] [-phred33|-phred64] [-trimlog <trimLogFile>] 
    #       [-summary <statsSummaryFile>] [-quiet] [-validatePairs] [-basein <inputBase> | <inputFile1> <inputFile2>] 
    #       [-baseout <outputBase> | <outputFile1P> <outputFile1U> <outputFile2P> <outputFile2U>] <trimmer1>...

        R1=$base$patternF.$extension
        #echo $R1
        R2=$base$patternR.$extension
       #echo $R2

        trimmomatic PE ../raw-reads/$R1 ../raw-reads/$R2\
            -threads $threads \
            trimmed-reads/$base/${base}_1.trim.fq.gz \
            untrimmed-reads/$base/${base}_1.unpaired.fq.gz \
            trimmed-reads/$base/${base}_2.trim.fq.gz \
            untrimmed-reads/$base/${base}_2.unpaired.fq.gz\
            HEADCROP:20 SLIDINGWINDOW:4:20 MINLEN:35 \
            > trimmed-reads/$base/trimming_verbose.txt

        echo $base 'Trimming Done'
        #3: Second quality check after trimming: --------------------------------------------------------

        # fastqc  trimmed-reads/$base/*.fq.gz \
        #         -o fastqc/trimQC/$base/ -t $threads > fastqc/trimQC/$base/fastqc_trim_verbose.txt

        # echo $base 'QC after trimming Done'
    done
#3: Second quality check after trimming: --------------------------------------------------------
#Quality control
fastqc -o fastqc/trimQC/ -t $threads trimmed-reads/*/*.fq.gz
echo 'QC after trimming Done'
cd ..
