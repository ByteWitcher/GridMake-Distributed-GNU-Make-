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

# Parameters
NUM_HOSTS=3
WALLTIME="0:10"
SLEEP_INTERVAL=5

scp juliaInstaller.sh lyon.g5k:~/juliaInstaller.sh

# Submit the job using oarsub on the remote machine and capture the JOB ID
JOB_ID=$(ssh lyon.g5k "oarsub -l host=$NUM_HOSTS,walltime=$WALLTIME 'sudo-g5k; source ~/juliaInstaller.sh'" | grep "OAR_JOB_ID" | cut -d= -f2)

# Wait for the job to complete
while true; do
    JOB_STATUS=$(ssh lyon.g5k "oarstat -s -j $JOB_ID")
    if [[ "$JOB_STATUS" =~ ": Terminated" ]]; then
        break
    fi
    sleep $SLEEP_INTERVAL
done