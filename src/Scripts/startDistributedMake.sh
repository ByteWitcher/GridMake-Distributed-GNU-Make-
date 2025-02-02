#!/bin/bash

## First, setup an alias for the global access machine

# Alias for the gateway (not really needed, but convenient)
# Host g5k
#   User g5k_login
#   Hostname access.grid5000.fr
#   ForwardAgent no

## Second, setup the glob alias for the access to any machine inside Grid'5000

# Direct connection to hosts within Grid'5000 which are not reachable directly
# Host *.g5k
#   User g5k_login
#   ProxyCommand ssh g5k -W "$(basename %h .g5k):%p"
#   ForwardAgent no

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

# Parameters
# NUM_HOSTS=6
# WALLTIME="0:10"
# SLEEP_INTERVAL=5

# Get the script path
SCRIPT_PATH="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

echo "Transferring files to $SITE..."
scp -r $SCRIPT_PATH/../../* $SITE:~/

# Submit the job using oarsub on the remote machine and capture the JOB ID
JOB_ID=$(ssh $SITE "oarsub -p "cpuarch='x86_64'" -l host=$NUM_HOSTS,walltime=$WALLTIME 'source ~/src/Scripts/runMain.sh'" | grep "OAR_JOB_ID" | cut -d= -f2)

loading_animation "Loading, please wait" &
loading_pid=$!

# Wait for the job to complete
while true; do
    JOB_STATUS=$(ssh $SITE "oarstat -s -j $JOB_ID")
    if [[ "$JOB_STATUS" =~ ": Terminated" ]]; then
        break
    fi
    sleep $SLEEP_INTERVAL
done


# After the job finishes, copy the results to our local machine
scp $SITE:~/distributed-make-log.txt $SCRIPT_PATH/Results/Logs/

# Cleaning
ssh $SITE "rm -rf *"