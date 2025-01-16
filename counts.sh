#!/bin/bash

## Classify the 15 sample groups for group-wise comparisons
rm -rf bam_group 
mkdir bam_group
while read -r line;do
    # Get sequence information from the Tco2.fqfiles
    SampleName=$(echo "$line" | awk -F'\t' '{print$1}')
    SampleNumber=${SampleName/Tco/} 
    SampleType=$(echo "$line" | awk -F'\t' '{print$2}')
    Time=$(echo "$line" | awk -F'\t' '{print$4}')
    Treatment=$(echo "$line" | awk -F'\t' '{print$5}')

    # 3 variables for each group
    SampleTypes=("WT" "Clone1" "Clone2") 
    Treatments=( "Uninduced" "Induced") 
    Times=("0" "24" "48")
    
    group=0 #Suffix
    for sampletype in ${SampleTypes[@]};do
        for treatment in ${Treatments[@]};do
            for time in ${Times[@]};do
		((group+=1))
                if  [[ "$time" == "0" && "$treatment" == "Induced" ]];then 
                #When time=0 the treatment is always uninduced
                    ((group-=1)) #skip this group
                fi
                #Rename files
                if [[ "$SampleType" == "$sampletype" && "$Treatment" == "$treatment" && "$Time" == "$time" ]];then
                    if [[ -e bam/Tco-"$SampleNumber".bam ]];then
                        cp bam/Tco-"$SampleNumber".bam bam_group/Tco-"$SampleNumber"_"$sampletype"_"$treatment"_"$time"_g"$group".bam #Add suffix
                    fi
                fi

            done
        done
    done
done < fastq/Tco2.fqfiles

echo "----------------------------------"
echo "15 sample groups classified:"
echo "[1] WT uninduced at 0h"
echo "[2] WT uninduced at 24h"
echo "[3] WT uninduced at 48h"
echo "[4] WT induced at 24h"
echo "[5] WT induced at 48h"
echo "[6] Clone1 uninduced at 0h"
echo "[7] Clone1 uninduced at 24h"
echo "[8] Clone1 uninduced at 48h"
echo "[9] Clone1 induced at 24h"
echo "[10] Clone1 induced at 48h"
echo "[11] Clone2 uninduced at 0h"
echo "[12] Clone2 uninduced at 24h"
echo "[13] Clone2 uninduced at 48h"
echo "[14] Clone2 induced at 24h"
echo "[15] Clone2 induced at 48h"
echo "----------------------------------"

## Copy the reference bedfile to local directory
rm -f TriTrypDB-46_TcongolenseIL3000_2019.bed
cp /localdisk/data/BPSM/ICA1/TriTrypDB-46_TcongolenseIL3000_2019.bed .
echo "Reference bedfile copied to current directory"

## Generate counts data
rm -rf counts
mkdir counts
# Create index
for file in bam_group/*.bam;do
    {
	    samtools index $file
    }&
done
wait
# Generate bed files by group
for ((i=1; i<=15;i++));do
    {
	    bedtools multicov -bed TriTrypDB-46_TcongolenseIL3000_2019.bed -bams bam_group/*g$i.bam > counts/group"$i".bed
    }&
done
wait
echo "Counts data generated, bed files for 15 groups saved to ./counts"
