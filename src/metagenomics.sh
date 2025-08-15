#!/bin/bash

#####################################################################
#       PIPELINE PARA EL PROCESAMIENTO DE MUESTRAS METAGENÓMICAS    #
#                       Dulce I. Valdivia                           #
#                       Erika Cruz-Bonilla                          #   
#                       Augusto Franco                              #  
#####################################################################

threads=$1
patternF=$2
patternR=$3
extension=$4
bowtieDB=$5
krakenDB=$6
phylophlanDB=$7
option=$8
prefix=$9
eggnogDB=$10
profile=$11
koList=$12

start_time=$(date +"%T")
echo $start_time

# SCRIPT 1 ----------------------------------------------------------
# Run:
        ./src/1_qualityCheck.sh $threads $patternF $patternR $extension >> metagenomics.log

# SCRIPT 2 ----------------------------------------------------------
# Config:
        # bowtieDB="/home/afranco/datos/afranco_data/Metagenomics-main_v3/bowtieDB/ref_genomes/hostDB"
# Run:
        ./src/2_hostRemove.sh $threads $patternF $extension $bowtieDB >> metagenomics.log

# SCRIPT 3 ----------------------------------------------------------
# Config:
        # dirKrakenDB="/data/dvaldivia_data/krakenDB_PlusPFP_20230314"
# Run:
        ./src/3_taxonomicAssignmentHostRemoved.sh $threads $patternF $extension $krakenDB >> metagenomics.log

# SCRIPT 4 ----------------------------------------------------------
# Config:
        # export PATH="/home/metagenomics/projects/biodigestores/metaPipeline/lib/SPAdes-3.15.5-Linux/bin:$PATH"
        # export PATH="/home/metagenomics/projects/biodigestores/metaPipeline/lib/MaxBin-2.2.7/:$PATH"
        # export CHECKM_DATA_PATH="/home/metagenomics/projects/biodigestores/metaPipeline/lib/checkm_data"

# Run:
       ./src/4_metagenomeAssembly.sh $threads $patternF $extension >> metagenomics.log

# SCRIPT 5 ----------------------------------------------------------
# Run:
       ./src/5_taxonomicAssignmentMAGs_Update.sh $threads $phylophlanDB $prefix $option >> metagenomics.log

# SCRIPT 6 ----------------------------------------------------------
# Run:
        ./src/6_geneAnnotation.sh $threads >> metagenomics.log
# # SCRIPT 7 ----------------------------------------------------------

# # Config:
        # eggnogDB="/home/afranco/datos/Metagenomics-main_v3/eggnogDB"
        # profile="/home/afranco/datos/Metagenomics-main_v3/kofamDB/profiles"
        # koList="/home/afranco/datos/Metagenomics-main_v3/kofamDB/ko_list"
# Run:
        
        ./src/7_functionalAnnotation.sh $threads $prefix $eggnogDB $profile $koList >> metagenomics.log

end_time=$(date +"%T")
echo $end_time