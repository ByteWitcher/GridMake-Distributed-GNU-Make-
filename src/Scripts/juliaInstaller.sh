#!/bin/bash

# Define Julia version and paths
JULIA_VERSION="1.9.4"
JULIA_TAR_FILE="julia-$JULIA_VERSION-linux-x86_64.tar.gz"
JULIA_INSTALL_PATH="/opt/julia-$JULIA_VERSION"

# Download and extract Julia if not already installed
if [ ! -d "$JULIA_INSTALL_PATH" ]; then
    if [ ! -f "$JULIA_TAR_FILE" ]; then
        # Download Julia if the binary is not present
        wget https://julialang-s3.julialang.org/bin/linux/x64/1.9/$JULIA_TAR_FILE
    fi
    # Extract and move Julia to the desired installation directory in one step
    sudo-g5k tar zxvf $JULIA_TAR_FILE --directory /opt/

    # Add Julia to PATH in ~/.bashrc
    echo 'export PATH="$PATH:'$JULIA_INSTALL_PATH'/bin"' >> ~/.bashrc

    echo "Julia $JULIA_VERSION installed successfully."
else
    echo "Julia $JULIA_VERSION is already installed."
fi

# Reload ~/.bashrc to update the PATH
source ~/.bashrc

# Confirm installation by showing version
julia --version