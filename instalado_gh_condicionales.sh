#!/bin/bash

# Check if the script is run with root permissions
if [ "$EUID" -ne 0 ]; then
    echo "You must run this script as root. Please use sudo or log in as root."
    exit 1
fi

# Check if the 'wget' command is installed
if ! type -p wget >/dev/null 2>&1; then
    echo "The 'wget' package is not installed. Installing it now..."
    apt update
    apt-get install wget -y
else
    echo "The 'wget' package is already installed."
fi

# Create the keyrings directory if it does not exist
if [ ! -d "/etc/apt/keyrings" ]; then
    echo "Creating the /etc/apt/keyrings directory..."
    mkdir -p -m 755 /etc/apt/keyrings
else
    echo "The /etc/apt/keyrings directory already exists."
fi

# Download and install the GitHub CLI keyring
echo "Downloading and installing the GitHub CLI keyring..."
out=$(mktemp)
wget -nv -O "$out" https://cli.github.com/packages/githubcli-archive-keyring.gpg
cat "$out" | tee /etc/apt/keyrings/githubcli-archive-keyring.gpg >/dev/null
chmod go+r /etc/apt/keyrings/githubcli-archive-keyring.gpg

# Add the GitHub CLI repository to the sources list
repo_entry="deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/githubcli-archive-keyring.gpg] https://cli.github.com/packages stable main"
if ! grep -rq "$repo_entry" /etc/apt/sources.list /etc/apt/sources.list.d/; then
    echo "Adding the GitHub CLI repository to the sources list..."
    echo "$repo_entry" | tee /etc/apt/sources.list.d/github-cli.list >/dev/null
else
    echo "The GitHub CLI repository is already part of the repository list."
fi

# Update the package list
echo "Updating the package list..."
apt update

# Install the GitHub CLI
if ! type -p gh >/dev/null 2>&1; then
    echo "Installing the GitHub CLI..."
    apt install gh -y
else
    echo "The GitHub CLI is already installed."
fi
