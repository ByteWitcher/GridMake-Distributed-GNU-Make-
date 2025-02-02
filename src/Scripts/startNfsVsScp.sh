#!/bin/bash

# Interactive prompts for user input
read -p "Enter the Grid'5000 site (e.g., lyon): " SITE
read -p "Enter the number of hosts: " NUM_HOSTS
read -p "Enter the walltime (e.g., 0:10 for 10 minutes): " WALLTIME
read -p "Enter the sleep interval (in seconds): " SLEEP_INTERVAL

SITE="$SITE.g5k"

# Confirm inputs
echo "Configuration:"
echo "Site: $SITE"
echo "Number of Hosts: $NUM_HOSTS"
echo "Walltime: $WALLTIME"
echo "Sleep Interval: $SLEEP_INTERVAL seconds"



# Get the script path
SCRIPT_PATH="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

# Copy the necessary files to the remote machine
scp $SCRIPT_PATH/../NfsVsScp/nfsVsScp.jl $SITE:~/nfsVsScp.jl
scp $SCRIPT_PATH/runNfsVsScp.sh $SITE:~/runNfsVsScp.sh
scp $SCRIPT_PATH/juliaInstaller.sh $SITE:~/juliaInstaller.sh

# Submit the job using oarsub on the remote machine and capture the JOB ID
JOB_ID=$(ssh $SITE "oarsub -l host=$NUM_HOSTS,walltime=$WALLTIME 'source ~/runNfsVsScp.sh'" | grep "OAR_JOB_ID" | cut -d= -f2)

# Wait for the job to finish
while true; do
    JOB_STATUS=$(ssh $SITE "oarstat -s -j $JOB_ID")
    if [[ "$JOB_STATUS" =~ ": Terminated" ]]; then
        break
    fi
    sleep $SLEEP_INTERVAL
done

# After the job finishes, copy the results to our local machine
scp $SITE:~/nfs-vs-scp-log.txt $SCRIPT_PATH/Results/Logs/
scp $SITE:~/nfs-results.txt $SCRIPT_PATH/Results/
scp $SITE:~/scp-results.txt $SCRIPT_PATH/Results/

# Cleaning
ssh $SITE "rm -rf *"