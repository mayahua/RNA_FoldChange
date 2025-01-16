#!/bin/bash

## Run all the scripts one by one automatically

# List of scripts
scripts=("qualitycheck.sh" "align.sh" "counts.sh" "average.sh" "foldchange.sh")

# Iterate over the list of scripts and execute each one
for script in "${scripts[@]}"; do
    if [ -f "$script" ] && [ -x "$script" ]; then
        echo "Executing $script..."
        ./"$script"
    else
        echo "Script $script not found or is not executable."
    fi
done

# Echo message after running all scripts
echo "All scripts executed."
