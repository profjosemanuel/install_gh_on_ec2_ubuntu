#!/bin/bash

# Ensure the script is being run as root
if [ "$(id -u)" -ne 0 ]; then
    echo "Error: You must have root permissions to run this script."
    exit 1
fi

# Define variables
REPO_URL="https://cli.github.com/packages"
REPO_ENTRY="deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/githubcli-archive-keyring.gpg] $REPO_URL stable main"
KEYRING_PATH="/etc/apt/keyrings/githubcli-archive-keyring.gpg"
SOURCE_LIST="/etc/apt/sources.list.d/github-cli.list"

# Check if wget is installed, and install it if not
if ! command -v wget >/dev/null 2>&1; then
    echo "wget is not installed. Installing wget..."
    apt update
    apt-get install wget -y
    if [ $? -ne 0 ]; then
        echo "Error: Failed to install wget."
        exit 1
    fi
else
    echo "wget is already installed."
fi

# Create the keyring directory if it doesn't exist
if [ ! -d "/etc/apt/keyrings" ]; then
    echo "Creating /etc/apt/keyrings directory..."
    mkdir -p -m 755 /etc/apt/keyrings
    if [ $? -ne 0 ]; then
        echo "Error: Failed to create /etc/apt/keyrings directory."
        exit 1
    fi
fi

# Download the GitHub CLI keyring
echo "Downloading the GitHub CLI keyring..."
TEMP_KEYRING=$(mktemp)
wget -nv -O "$TEMP_KEYRING" "$REPO_URL/githubcli-archive-keyring.gpg"
if [ $? -ne 0 ]; then
    echo "Error: Failed to download the keyring."
    exit 1
fi

# Move the keyring to the appropriate location
echo "Installing the keyring..."
cat "$TEMP_KEYRING" | tee "$KEYRING_PATH" >/dev/null
chmod go+r "$KEYRING_PATH"
rm "$TEMP_KEYRING"

# Check if the repository entry already exists
if grep -q "$REPO_URL stable main" "$SOURCE_LIST" 2>/dev/null; then
    echo "The repository $REPO_URL stable main is already part of the repository list."
else
    echo "Adding the repository to the source list..."
    echo "$REPO_ENTRY" | tee "$SOURCE_LIST" >/dev/null
fi

# Update package lists and install GitHub CLI
echo "Updating package lists..."
apt update
if [ $? -ne 0 ]; then
    echo "Error: Failed to update package lists."
    exit 1
fi

echo "Installing GitHub CLI..."
apt install gh -y
if [ $? -ne 0 ]; then
    echo "Error: Failed to install GitHub CLI."
    exit 1
fi

echo "GitHub CLI installed successfully!"
