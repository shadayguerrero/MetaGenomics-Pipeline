#!/usr/bin/bash

echo "--------------------- METAPIPELINE [PASO 10]---------------------------------------"
echo "                       FUNCTIONAL ANNOTATION                                    "
echo "----------------------------------------------------------------------------------"

threads=$1
prefix=$2
eggnogDB=$3
profile=$4
koList=$5

cd results/
start_time=$(date +"%T")
echo $start_time

for d in assemblies/*;
    do
    base=${d:11}
    for mags in assemblies/${base}/maxbin/$base\.*.fasta;
        do
        sample1=$(basename "$mags"| sed 's/\.fasta$//') # name for MAG assembled
        sample=$(basename "$mags"| sed 's/\./\_/'| cut -d. -f1 ) #Directory Name for MAGS

        mkdir functionalAnnotation/eggNOG/$base/$sample # Create MAGS directories
        emapper.py \
        -m diamond\
        --no_annot \
        --no_file_comments \
        --report_no_hits \
        --override \
        --data_dir $eggnogDB \
        --cpu $threads\
        --itype metagenome\
        --pfam_realign denovo \
        -i assemblies/${base}/${base}-scaffolds.fasta \
        -o $sample\_diamond \
        --output_dir functionalAnnotation/eggNOG/$base/$sample

    
        done
    echo $base 'Functional eggnog annotation done'
    done
# for d in assemblies/*;
#     do
#     base=${d:11}

#     # emapper.py \
#     # -m diamond\
#     # --no_annot \
#     # --no_file_comments \
#     # --report_no_hits \
#     # --override \
#     # --data_dir $eggnogDB \
#     # --cpu $threads\
#     # --itype metagenome\
#     # --pfam_realign denovo \
#     # -i assemblies/${base}/${base}-scaffolds.fasta \
#     # -o $base\_diamond \
#     # --output_dir functionalAnnotation/eggNOG/${base}

#     # echo $base 'Functional diamond annotation done'

#     # emapper.py \
#     # -m no_search\
#     # --annotate_hits_table functionalAnnotation/eggNOG/${base}/$base\_diamond.emapper.seed_orthologs\
#     # --no_file_comments \
#     # --override \
#     # --cpu $threads\
#     # --data_dir $eggnogDB \
#     # --itype metagenome\
#     # -i assemblies/${base}/${base}-scaffolds.fasta \
#     # -o $base\_nosearch\
#     # --output_dir functionalAnnotation/eggNOG/${base}

#     # echo $base 'Functional no_search annotation done'

#     exec_annotation \
#     --cpu $threads\
#     -o functionalAnnotation/kofam/${base}\
#     -p $profile\
#     -k $koList\
#     --create-alignment \
#     -f detail-tsv \
#     assemblies/${base}/${base}-scaffolds.fasta

#     echo $base 'Functional kofam annotation done'

#     done
end_time=$(date +"%T")
echo $end_time
cd ..