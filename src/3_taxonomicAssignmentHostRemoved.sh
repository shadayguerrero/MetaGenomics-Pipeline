#!/bin/bash

echo "--------------------- METAPIPELINE ---------------------------------------"
echo "                       TAXONOMIC ASSIGNMENT HOST REMOVED                                   "
echo "----------------------------------------------------------------------------------"

threads=$1
patternF=$2
extension=$3
krakenDB=$4


# Taxonomic assignment ---------------------------------------------------
cd results/
for R1 in ../raw-reads/*$patternF*.$extension;
    do
        base=$(basename $R1 $patternF.$extension) #This will deleate any prefix up to the last "/" and the pattern and file extension
                                                   #in order to keep the sample name
		echo "taxonomic assignment sample $base"
		R1=${base}_host_removed_R1.fastq.gz
		#echo $R1
		R2=${base}_host_removed_R2.fastq.gz
		#echo $R2


		wdir=taxonomy/reads/kraken/${base}/hostRemoved
			
		if [ -d "$wdir" ]; then 
			echo IMPORTANT:
			echo There is a previous run for sample: ${base}
			echo The directory ${wdir} will be deleted 
			rm -r $wdir
		fi
		mkdir $wdir
		echo New directory ${wdir} created for sample ${base}

		kraken2 --db $krakenDB \
			--threads $threads \
			--gzip-compressed \
			--output ${wdir}/${base}.kraken.out \
			--report ${wdir}/${base}.kraken.report \
			--paired host_removed/$base/$R1 host_removed/$base/$R2 

		echo $base 'taxonomy assignment Done'
	done
	echo "---------------------- METAPIPELINE ---------------------------------------"
	echo "                       PARSING KRAKEN'S OUTPUT                                     "
	echo "-----------------------------------------------------------------------------------"
# Create json file for R analysis ------------------------------------
#	 kraken-biom parses the .report files.
# 	 The option --min P can be used to keep assignments that have 
#	 at least phylum taxa, but this can also be filtered during
#	 the R analysis

kraken-biom taxonomy/reads/kraken/*/hostRemoved/*.report \
	-o taxonomy/taxonomy_kraken.json \
	--fmt json  
echo 'Kraken-biom file created'
cd ..