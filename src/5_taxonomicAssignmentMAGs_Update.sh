#!/bin/bash

echo "--------------------- METAPIPELINE ---------------------------------------"
echo "                       Taxonomic AssignmentMAGs                                   "
echo "----------------------------------------------------------------------------------"

threads=$1
phylophlanDB=$2
prefix=$3
option=$4

cd results/

if (($option == 1)); then
    for d in assemblies/$prefix*;
        do
        base=${d:11}
            #echo $base
            #Assign taxonomy labels to each bin
            phylophlan_assign_sgbs \
            -i assemblies/${base}/maxbin/ \
            -o taxonomy/MAGS/phylophlan/$base/$base\_metagenomic \
            --nproc $threads \
            -n 1 \
            -d SGB.Jul20 \
            --database_folder $phylophlanDB \
            -e .fasta \
            --verbose 2>&1 | tee taxonomy/MAGS/phylophlan/$base/phylophlan_metagenomic.log

            echo $base 'Taxonomy Assignment MAGs Done'
        done

        #Heatmap
        #This step allows you to visualize the top 20 separate by sample

        # cat taxonomy/MAGS/phylophlan/$prefix*/*\_metagenomic.tsv > taxonomy/MAGS/$prefix\_phylophlanReport.tsv

        # phylophlan_draw_metagenomic \
        # -i taxonomy/MAGS/$prefix\_phylophlanReport.tsv \
        # -o taxonomy/MAGS/phylophlan/$prefix\_output_heatmap \
        # --map taxonomy/MAGS/$prefix\Meta_Bins.tsv \
        # --dpi 1500 \
        # --top 20 \
        # --verbose 2>&1

        # echo 'heatmaps MAGs Done'
else
    for d in assemblies/$prefix*;
        do
        base=${d:11}
        krakenDB=$5
        kraken2 --db $krakenDB \
        	--threads $threads \
            --memory-mapping \
        	--output taxonomy/contigs/${base}.kraken.out \
        	--report taxonomy/contigs/${base}.kraken.report \
        	assemblies/${base}/${base}-scaffolds.fasta

        echo $base 'taxonomy assignment Done'
        done

    kraken-biom taxonomy/contigs/*.report \
    -o taxonomy/contigs/taxonomy_krakenCONTIGS.json \
    --fmt json  
    echo 'Kraken-biom file created'
fi  



cd ..