#!/bin/bash

## Copy the paired-end RNAseq sequence data to local directory
rm -rf fastq
cp -r /localdisk/data/BPSM/ICA1/fastq fastq
echo "RNAseq sequence data copied to ./fastq"

## Create output directory
rm -rf qcresults
mkdir qcresults

## Run FASTQC
echo "FASTQC started"
fastqc -o qcresults -q -t 30 fastq/*.gz
echo "FASTQC finished"

## Unzip summary files in the FASTQC results
rm -rf qcresults_summary
mkdir qcresults_summary
for file in qcresults/*.zip; do
	name=$(basename $file .zip)
	name_out=${name/_fastqc/_summary.txt}
	unzip -jp $file $name/summary.txt > qcresults_summary/$name_out
done
echo "FASTQC results extracted"

## Assess the numbers and quality of the raw sequence data based on the output of fastqc
rm -rf qc_pass
rm -rf qc_fail
mkdir qc_pass
mkdir qc_fail

# Create mapping of stats in the summary txt files with corresponding numbers for user to select
declare -A stats_mapping=(
    [1]="Per base sequence quality"
    [2]="Per sequence quality scores"
    [3]="Per base sequence content"
    [4]="Per sequence GC content"
    [5]="Per base N content"
    [6]="Sequence Length Distribution"
    [7]="Sequence Duplication Levels"
    [8]="Overrepresented sequences"
    [9]="Adapter Content"
)

echo "-----------------------------------------------------"
echo "Example of the summary txt file in fastqc output:"
echo "PASS    Basic Statistics                Tco-106_1.fq.gz"
echo "PASS    Per base sequence quality       Tco-106_1.fq.gz"
echo "PASS    Per sequence quality scores     Tco-106_1.fq.gz"
echo "FAIL    Per base sequence content       Tco-106_1.fq.gz"
echo "PASS    Per sequence GC content         Tco-106_1.fq.gz"
echo "PASS    Per base N content              Tco-106_1.fq.gz"
echo "PASS    Sequence Length Distribution    Tco-106_1.fq.gz"
echo "PASS    Sequence Duplication Levels     Tco-106_1.fq.gz"
echo "WARN    Overrepresented sequences       Tco-106_1.fq.gz"
echo "PASS    Adapter Content                 Tco-106_1.fq.gz"
echo "-----------------------------------------------------"
echo "Choose the assessment method:"
echo "1. Assess by the number of PASS per summary file"
echo "2. Assess by PASS in specific stats"

read -p "Enter your choice (1 or 2): " choice

if [ "$choice" == "1" ]; then
    # Assess by number of PASS
    read -p "Enter the threshold number of PASS per summary file [1-10]: " threshold
    for file in qcresults_summary/*.txt; do
        num_pass=$(grep "PASS" "$file" | wc -l)
        if ((num_pass >= threshold)); then
            cp "$file" qc_pass
        else
            cp "$file" qc_fail
        fi
    done
elif [ "$choice" == "2" ]; then
    # Assess by PASS in specific stats
    echo "Choose the stats you would like to have a PASS (enter space-separated numbers):"
    echo "[1]="Per base sequence quality""
    echo "[2]="Per sequence quality scores""
    echo "[3]="Per base sequence content""
    echo "[4]="Per sequence GC content""
    echo "[5]="Per base N content""
    echo "[6]="Sequence Length Distribution""
    echo "[7]="Sequence Duplication Levels""
    echo "[8]="Overrepresented sequences""
    echo "[9]="Adapter Content""    
    read -a selected_stats
    pattern=""
    for stat in "${selected_stats[@]}"; do
        pattern+="|| /${stats_mapping[$stat]}/"
    done

    for file in qcresults_summary/*.txt; do
        if awk "${pattern:2}" "$file" | grep "PASS" >/dev/null; then
            cp "$file" qc_pass
        else
            cp "$file" qc_fail
        fi
    done
else
    echo "Invalid choice. Please enter 1 or 2."
fi

echo "Summary files for sequences that passed the quality check have been copied to ./qc_pass"
