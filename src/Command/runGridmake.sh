#!/bin/bash

# Install Julia on the master host
source juliaInstaller.sh

# Install Julia on worker hosts
for node in $(uniq $OAR_NODE_FILE); do
    if [ "$node" != "$(hostname)" ]; then
        ssh $node 'bash -s' < ./juliaInstaller.sh
        ssh $node "sudo-g5k sed -i 's/\[\[ -e \$GUIX_PROFILE\/etc\/profile \]\] && \. \$GUIX_PROFILE\/etc\/profile/if [ -e \$GUIX_PROFILE\/etc\/profile ]; then . \$GUIX_PROFILE\/etc\/profile; fi/' /etc/profile.d/guix.sh"
    fi
done

# Run main.jl on the master host and redirect the output
julia src/main.jl
