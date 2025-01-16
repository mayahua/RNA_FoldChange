#!/bin/bash

## Copy the reference genome to local directory
rm -rf Tcongo_genome
cp -r /localdisk/data/BPSM/ICA1/Tcongo_genome/ Tcongo_genome
echo "Reference genome copied to ./Tcongo_genome"

## Build the index with Bowtie2
rm -rf bowtie2index
mkdir bowtie2index
echo "Building index"
bowtie2-build -q --threads 30 Tcongo_genome/TriTrypDB-46_TcongolenseIL3000_2019_Genome.fasta.gz bowtie2index/index
echo "Index built"

## Filter unpaired sequences (if there is any)
rm -rf qc_pass_paired
mkdir qc_pass_paired

for file in qc_pass/*_1_summary.txt; do
    base=${file%_1_summary.txt}
    if [[ -f "${base}_2_summary.txt" ]]; then
        cp "$file" "${base}_2_summary.txt" qc_pass_paired
    fi
done
echo "Unpaired sequences removed"

## Align the read pairs to the Trypanosoma congolense genome
rm -rf aligned
mkdir aligned
echo "Aligning" 
for file in qc_pass_paired/*_1_summary.txt;do
    filename=$(basename $file _1_summary.txt)
    filename1="${filename}_1.fq.gz"
    filename2="${filename1/_1.fq.gz/_2.fq.gz}"
    outputname=$(basename $filename1 _1.fq.gz)
    {
        bowtie2 --quiet -x bowtie2index/index -1 fastq/$filename1 -2 fastq/$filename2 -p 25 -S aligned/$outputname.sam
    }&
done
wait
echo "Alignment done, sam files stored in ./aligned"

## Convert output sam file to bam format
rm -rf bam
mkdir bam
echo "Converting output sam files to bam format"
for file in aligned/*.sam;do
    filename=$(basename "$file" .sam)
    {
        samtools view -b "$file" | samtools sort -@ 30 -o bam/$filename.bam >/dev/null 2>&1
    }&
done
wait
echo "Done, bam files stored in ./bam"
