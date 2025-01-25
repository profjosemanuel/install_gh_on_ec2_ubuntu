#!/bin/env/ bash

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


# Repositorio Docker a buscar
github_repo="https://cli.github.com/packages"

# Archivos sources.list a revisar
sources_file="/etc/apt/sources.list"
sources_directories="/etc/apt/sources.list.d"
# Función para buscar el repositorio en un archivo
find_repo() {
    local file="$1"
    grep -q "$github_repo" "$file" && echo "El repositorio de Docker SI se encontró en $file" || echo "El repositorio de Docker NO se encontró en $file"
}

find_repo_2() {
    local file="$1"
    if  grep -q "$github_repo" "$file"; then
        echo "El repositorio de github SI se encontró en $file"
        encontrado=true;
    else
        echo "El repositorio de github NO se encontró en $file"
   fi
}

find_repo_in_sources_list() {
# Iterar sobre cada archivo de /etc/apt/sources.list.d
   encontrado=false
   find_repo_2 $sources_file
   if ! $encontrado; then

       for file in "$sources_directories"/*.list; do
            echo "$file"
            find_repo_2 $file
       done
       if $encontrado; then
            return 1
       else
            return 0
       fi
   fi
}

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
    if ! find_repo_in_sources_list; then
        add_repository
    fi

    if find_repo_in_sources_list; then
        install_gh
    fi
else
    echo "Nothing to do. The gh program is already installed."
fi
