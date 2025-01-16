#!/bin/bash

## Statisticla mean of the counts per gene in each group
rm -rf average
mkdir average

for file in counts/*;do
    name=$(basename $file counts/)
    output1=${name/.bed/.txt} 
    output2=${output1/all/mean} 
    numcol=$(awk -F '\t' '{print NF}' $file | head -1 ) #number of columns in a bedfile
    awk -F '\t' -v numcol=$numcol '{
        sum=0;
        n=0;
        for( i = 6 ; i <= numcol ; i++) {
          sum += $i;
          n ++
        }
        mean=sum/n;
        { print $4 "\t" $5 "\t" mean }
    }'  $file > average/$output2
done
echo "Mean gene expression levels in each group calculated, results saved to ./average"


