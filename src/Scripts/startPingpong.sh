#!/bin/bash

# Interactive prompts for user input
read -p "Enter the Grid'5000 site (e.g., lyon): " SITE
read -p "Enter the number of hosts: " NUM_HOSTS
read -p "Enter the walltime (e.g., 0:10 for 10 minutes): " WALLTIME
read -p "Enter the sleep interval (in seconds): " SLEEP_INTERVAL
# Ask for the ping pong type
read -p "Enter the type of ping pong (normal or io): " PING_PONG_TYPE

SITE="$SITE.g5k"

# Confirm inputs
echo "Configuration:"
echo "Site: $SITE"
echo "Number of Hosts: $NUM_HOSTS"
echo "Walltime: $WALLTIME"
echo "Sleep Interval: $SLEEP_INTERVAL seconds"
echo "Pingpong type: $PING_PONG_TYPE"

# If no input is provided, show an error message and exit
if [ -z "$PING_PONG_TYPE" ]; then
    echo "Error: No PING_PONG_TYPE provided."
    echo "Usage: Please enter 'normal' or 'io'."
    read -p "Press Enter to exit..."
    exit 1
fi

# Check the PING_PONG_TYPE and set the corresponding files
if [ "$PING_PONG_TYPE" == "normal" ]; then
    PING_PONG_FILE="pingpong.jl"
    OUTPUT_FILE="pingpong-log.txt"
elif [ "$PING_PONG_TYPE" == "io" ]; then
    PING_PONG_FILE="pingpongIo.jl"
    OUTPUT_FILE="pingpong-io-log.txt"
else
    echo "Invalid PING_PONG_TYPE: $PING_PONG_TYPE. Exiting."
    read -p "Press Enter to exit..."
    exit 1
fi

# Get the script path
SCRIPT_PATH="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

# Copy the necessary files to the remote machine
if [ "$PING_PONG_TYPE" == "normal" ]; then
    scp $SCRIPT_PATH/../Pingpong/pingpong.jl $SITE:~/pingpong.jl
else
    scp $SCRIPT_PATH/../PingpongIo/pingpongIo.jl $SITE:~/pingpongIo.jl
fi
scp $SCRIPT_PATH/runPingpong.sh $SITE:~/runPingpong.sh
scp $SCRIPT_PATH/juliaInstaller.sh $SITE:~/juliaInstaller.sh

# Submit the job using oarsub on the remote machine and capture the JOB ID
JOB_ID=$(ssh $SITE "oarsub -l host=$NUM_HOSTS,walltime=$WALLTIME 'source ~/runPingpong.sh $PING_PONG_FILE $OUTPUT_FILE'" | grep "OAR_JOB_ID" | cut -d= -f2)

# Wait for the job to finish
while true; do
    JOB_STATUS=$(ssh $SITE "oarstat -s -j $JOB_ID")
    if [[ "$JOB_STATUS" =~ ": Terminated" ]]; then
        break
    fi
    sleep $SLEEP_INTERVAL
done

# After the job finishes, copy the results to our local machine
if [ "$PING_PONG_TYPE" == "normal" ]; then
    scp $SITE:~/pingpong-log.txt $SCRIPT_PATH/Results/Logs/
    scp $SITE:~/pingpong-results.txt $SCRIPT_PATH/Results/
else
    scp $SITE:~/pingpong-io-log.txt $SCRIPT_PATH/Results/Logs/
    scp $SITE:~/pingpong-io-results.txt $SCRIPT_PATH/Results/
fi

# Cleaning
ssh $SITE "rm -rf *"