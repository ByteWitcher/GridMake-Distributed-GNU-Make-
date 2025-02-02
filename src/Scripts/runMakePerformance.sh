#!/bin/bash

# Install Julia on the master host
source src/Scripts/juliaInstaller.sh

# Install necessary Julia packages on the master host
# julia -e 'import Pkg; Pkg.add("PyPlot")'

cat $OAR_NODE_FILE > make-performance-nodes.output

# Install Julia on worker hosts
for node in $(uniq $OAR_NODE_FILE); do
    if [ "$node" != "$(hostname)" ]; then
        ssh $node 'bash -s' < ./src/Scripts/juliaInstaller.sh
        ssh $node "sudo-g5k sed -i 's/\[\[ -e \$GUIX_PROFILE\/etc\/profile \]\] && \. \$GUIX_PROFILE\/etc\/profile/if [ -e \$GUIX_PROFILE\/etc\/profile ]; then . \$GUIX_PROFILE\/etc\/profile; fi/' /etc/profile.d/guix.sh"
        # ssh $node "julia -e 'import Pkg; Pkg.add(\"PyPlot\")'"
    fi
done

# Run main.jl on the master host and redirect the output
julia src/Performances/makePerformance.jl > make-performance-log.txt