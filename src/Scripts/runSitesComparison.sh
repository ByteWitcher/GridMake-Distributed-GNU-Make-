#!/bin/bash

# Install Julia on the master node
source juliaInstaller.sh

# Install Julia on the other nodes
for node in $(uniq $OAR_NODEFILE); do
    if [ "$node" != "$(hostname)" ]; then
        ssh $node 'bash -s' < ./juliaInstaller.sh
    fi
done

# Run the Julia program and output the result to the specified output file
julia pingpong.jl

input_file="pingpong-results.txt"
output_file="pingpong-results-site.txt"

# Extract Average latency (without the unit)
rtt=$(grep -oP 'Average latency: \K[0-9.]+(?= ms)' "$input_file")

# Extract Throughput for 1048576 KB after the "Average metrics by size:" line (without the unit)
throughput=$(awk '/Average metrics by size:/ {flag=1} flag && /Size: 1048576 KB/ {print $(NF-1); exit}' "$input_file")

# Replace results file content
echo "RTT: $rtt ms" > $output_file
echo "Throughput: $throughput Mbytes/s" >> $output_file