#!/bin/bash

rm -rf foldchange
mkdir foldchange

## Calculate pair-wise fold change for all groups
echo "Calculating group-wise fold change"
read -p "Enter the column to sort by (6 for log2 fold change, 7 for absolute value of log2 fold change): " choice
            if (( choice == 6 )); then
                sort_column=6
            elif (( choice == 7 )); then
                sort_column=7
            else
                echo "Invalid choice. Sorting by default column 7."
                sort_column=7
            fi

for file in average/*.txt;do
    for i in {1..15};do
        for ((j=i+1; j<=15; j++));do
            
            {
                awk -F '\t' -v sort_column="$sort_column" 'NR==FNR{a[FNR]=$3; next} {
                    if ($3 == 0 && a[FNR] == 0) {
                        print $1 "\t" $2 "\t" $3 "\t" a[FNR] "\t" 0 "\t" 0 "\t" 0
                    } else {
                        if ($3 == 0 && a[FNR] != 0) {
                            fc = 1/a[FNR]
                        }
                        if ($3 != 0 && a[FNR] == 0) {
                            fc = $3/1
                        } #This part is different from the pdf that the values of a[fNR] and $3 is unchanged, so their original values can be print.
                        log2fc = log(fc) / log(2)
                        log2fc_abs = (log2fc >= 0) ? log2fc : -log2fc
                        print $1 "\t" $2 "\t" a[FNR] "\t" $3 "\t" fc "\t" log2fc "\t" log2fc_abs
                     }
                }' average/group${i}.txt average/group${j}.txt | sort -t "$(printf '\t')" -k"$sort_column","$sort_column"nr > foldchange/foldchange_${i}_${j}.txt
            }&
            #If 0 reads in both group, report the fold change as 0; if 0 read in one of the groups, treat the 0 read as 1 for ease of calculation
	    done
    done
done
wait
echo "Pair-wise fold change for all groups calculated, results saved to ./foldchange"
