#!/bin/bash

# setup/install.sh - Server Installation Script

echo "Installing Serphunter Dependencies..."

if [ "$EUID" -ne 0 ]; then 
    echo "Please run as root"
    exit 1
fi

apt-get update
apt-get install -y curl jq git bc

echo "Dependencies installed successfully."
chmod +x ../serphunter.sh
echo "You can now run serphunter.sh"
