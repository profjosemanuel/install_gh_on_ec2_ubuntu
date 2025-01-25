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

# Function to check if the gh program is installed
check_gh_installed() {
    if command -v gh >/dev/null 2>&1; then
        echo "The GitHub CLI (gh) program is already installed."
        return 0
    else
        echo "The GitHub CLI (gh) program is not installed."
        return 1
    fi
}

# Function to check if the repository is added
check_repo_added() {
    if grep -q "$REPO_URL stable main" "$SOURCE_LIST" 2>/dev/null; then
        echo "The repository $REPO_URL stable main is already added."
        return 0
    else
        echo "The repository $REPO_URL stable main is not added."
        return 1
    fi
}

# Function to add the repository
add_repository() {
    echo "Adding the repository $REPO_URL stable main..."
    mkdir -p -m 755 /etc/apt/keyrings
    TEMP_KEYRING=$(mktemp)
    wget -nv -O "$TEMP_KEYRING" "$REPO_URL/githubcli-archive-keyring.gpg"
    if [ $? -ne 0 ]; then
        echo "Error: Failed to download the keyring."
        exit 1
    fi

    cat "$TEMP_KEYRING" | tee "$KEYRING_PATH" >/dev/null
    chmod go+r "$KEYRING_PATH"
    rm "$TEMP_KEYRING"

    echo "$REPO_ENTRY" | tee "$SOURCE_LIST" >/dev/null
    echo "Repository added successfully."
}

# Function to install the gh program
install_gh() {
    echo "Updating package lists..."
    apt update
    if [ $? -ne 0 ]; then
        echo "Error: Failed to update package lists."
        exit 1
    fi

    echo "Installing the GitHub CLI (gh)..."
    apt install gh -y
    if [ $? -ne 0 ]; then
        echo "Error: Failed to install the GitHub CLI."
        exit 1
    fi

    echo "GitHub CLI (gh) installed successfully!"
}

# Main logic
if ! check_gh_installed; then
    if ! check_repo_added; then
        add_repository
    fi

    if check_repo_added; then
        install_gh
    else
        echo "Error: Repository could not be added. Exiting."
        exit 1
    fi
else
    echo "Nothing to do. The gh program is already installed."
fi
