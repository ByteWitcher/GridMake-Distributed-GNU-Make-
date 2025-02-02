#!/bin/bash

# Type of ping pong to run
PING_PONG_FILE=$1
OUTPUT_FILE=$2

# Install Julia on the master node
source juliaInstaller.sh

# Install Julia on the other nodes
for node in $(uniq $OAR_NODEFILE); do
    if [ "$node" != "$(hostname)" ]; then
        ssh $node 'bash -s' < ./juliaInstaller.sh
    fi
done

# Run the Julia program and output the result to the specified output file
julia $PING_PONG_FILE > $OUTPUT_FILE