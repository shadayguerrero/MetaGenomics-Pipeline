#!/bin/bash

threads=$1
patternF=$2
extension=$3
bowtieDB=$4

echo "--------------------- METAPIPELINE:--------------------------------------"
echo "                          Remove Host                                           "
echo "----------------------------------------------------------------------------------"

#Usage: 
#  bowtie2 [options]* -x <bt2-idx> {-1 <m1> -2 <m2> | -U <r> | --interleaved <i> | -b <bam>} [-S <sam>]

#  <bt2-idx>  Index filename prefix (minus trailing .X.bt2).
#             NOTE: Bowtie 1 and Bowtie 2 indexes are not compatible.
#  <m1>       Files with #1 mates, paired with files in <m2>.
#             Could be gzip'ed (extension: .gz) or bzip2'ed (extension: .bz2).
#  <m2>       Files with #2 mates, paired with files in <m1>.
#  -p/--threads <int> number of alignment threads to launch (1)

cd results/
for R1 in ../raw-reads/*$patternF*.$extension;
    do
        base=$(basename $R1 $patternF.$extension) #This will deleate any prefix up to the last "/" and the pattern and file extension
                                                   #in order to keep the sample name
        
        echo "Initializing host remove for" $base
        R1=$base\_1.trim.fq.gz
        #echo $R1
        R2=$base\_2.trim.fq.gz
        #echo $R2


        bowtie2 \
        -p $threads \
        -x $bowtieDB \
        -1 trimmed-reads/$base/$R1 \
        -2 trimmed-reads/$base/$R2 \
        -S host_removed/${base}/${base}_results.sam \
        > host_removed/${base}/bowtie2_verbose.txt

        echo $base 'mapping Done'

        #Conversion sam file to bam file
        samtools \
        view \
        -bS host_removed/$base/${base}_results.sam \
        --threads $threads \
        > host_removed/$base/${base}_results.bam 

        echo $base 'Conversion sam file to bam file Done'

        #Filter unmapped reads
        samtools \
        view -b -f 13 -F 256 \
        host_removed/$base/${base}_results.bam \
        --threads $threads\
        > host_removed/$base/${base}_bothEndsUnmapped.bam 

        echo $base 'Filter unmapped reads Done'

        #Sort BAM file
        samtools sort -n -@ $threads \
        host_removed/$base/${base}_bothEndsUnmapped.bam \
        -o host_removed/$base/${base}_sorted.bam

        echo $base 'Sort BAM file Done'

        #Split pared-end reads into separated fastq files
        samtools fastq -@ $threads host_removed/$base/${base}_sorted.bam \
                -1 host_removed/$base/${base}_host_removed_R1.fastq.gz \
                -2 host_removed/$base/${base}_host_removed_R2.fastq.gz \
        
        echo $base 'Split pared-end reads into separated fastq files Done'

        rm host_removed/${base}/${base}_results.sam
        rm host_removed/$base/${base}_results.bam
        rm host_removed/$base/${base}_bothEndsUnmapped.bam 
        gzip -9 host_removed/$base/${base}_sorted.bam
        echo $base 'Compress sorted BAM file Done'
        done
cd ..
