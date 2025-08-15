#!/bin/bash

echo "--------------------- METAPIPELINE---------------------------------------"
echo "                       Raw reads check                                   "
echo "                       MD5SUM CHECK                                      "
echo "-------------------------------------------------------------------------"

#Parameters needed
samples=$1 #Path of the folder where the samples are
md5file=$2 #Unique file with md5file sended by the sequencing center
extension=$3 #file extension of the read
output=$4 #path and name of output csv file

data=() #create empty array to save results
data+=(sample,md5sum_Original,md5sum_fileDownload,result)
for read in $samples/*;
    do
        base=$(basename $read .$extension) #This will deleate any prefix up to the last "/" and the file extension
        md5tocompare=$(grep $base $md5file | awk '{print $1}')
        md5Read=$(md5sum $read | awk '{print $1}')
        if [ "$md5tocompare" == "$md5Read" ]; then
            result="correct"
        else
            result="incorrect"
        fi 
        data+=($base,$md5tocompare,$md5Read,$result)
    done

#Save data to CSV
for line in "${data[@]}"; do
    echo "$line" >> "$output.csv"
done

