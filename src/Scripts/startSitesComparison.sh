#!/bin/bash

# Interactive prompts for user input
read -p "Enter the number of hosts: " NUM_HOSTS
read -p "Enter the walltime (e.g., 0:10 for 10 minutes): " WALLTIME
read -p "Enter the sleep interval (in seconds): " SLEEP_INTERVAL

SITES=("grenoble.g5k" "lille.g5k" "luxembourg.g5k" "lyon.g5k" "nancy.g5k" "nantes.g5k" "rennes.g5k" "toulouse.g5k")

# Confirm inputs
echo "Configuration:"
echo "Site: ${SITES[@]}"
echo "Number of Hosts: $NUM_HOSTS"
echo "Walltime: $WALLTIME"
echo "Sleep Interval: $SLEEP_INTERVAL seconds"

# Get the script path
SCRIPT_PATH="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

# Create tmp directory
mkdir $SCRIPT_PATH/Results/tmp

# Empty log and results files
> $SCRIPT_PATH/Results/Logs/sites-comparison-log.txt
> $SCRIPT_PATH/Results/sites-comparison-results.txt

for SITE in "${SITES[@]}"; do
    # Copy the necessary files to the remote machine
    scp $SCRIPT_PATH/../Pingpong/pingpong.jl $SITE:~/pingpong.jl
    scp $SCRIPT_PATH/runSitesComparison.sh $SITE:~/runSitesComparison.sh
    scp $SCRIPT_PATH/juliaInstaller.sh $SITE:~/juliaInstaller.sh

    # Submit the job using oarsub on the remote machine and capture the JOB ID
    JOB_ID=$(ssh $SITE "oarsub -l host=$NUM_HOSTS,walltime=$WALLTIME 'source ~/runSitesComparison.sh'" | grep "OAR_JOB_ID" | cut -d= -f2)

    # Wait for the job to finish
    while true; do
        JOB_STATUS=$(ssh $SITE "oarstat -s -j $JOB_ID")
        if [[ "$JOB_STATUS" =~ ": Terminated" ]]; then
            break
        fi
        sleep $SLEEP_INTERVAL
    done

    # After the job finishes, copy the results to our local machine
    scp $SITE:~/pingpong-results.txt $SCRIPT_PATH/Results/tmp/
    scp $SITE:~/pingpong-results-site.txt $SCRIPT_PATH/Results/tmp/

    # Cleaning
    ssh $SITE "rm -rf *"

    # Printing log
    echo "---" >> $SCRIPT_PATH/Results/Logs/sites-comparison-log.txt
    echo ${SITE%%.*} >> $SCRIPT_PATH/Results/Logs/sites-comparison-log.txt
    cat $SCRIPT_PATH/Results/tmp/pingpong-results.txt >> $SCRIPT_PATH/Results/Logs/sites-comparison-log.txt
    rm $SCRIPT_PATH/Results/tmp/pingpong-results.txt

    # Printing results
    echo ${SITE%%.*} >> $SCRIPT_PATH/Results/sites-comparison-results.txt
    cat $SCRIPT_PATH/Results/tmp/pingpong-results-site.txt >> $SCRIPT_PATH/Results/sites-comparison-results.txt
    rm $SCRIPT_PATH/Results/tmp/pingpong-results-site.txt
done

rmdir $SCRIPT_PATH/Results/tmp