
#!/bin/bash

# Define the repository to check
REPO="https://cli.github.com/packages stable main"

# Check if the repository is listed in the system's package sources
if grep -rq "$REPO" /etc/apt/sources.list /etc/apt/sources.list.d/; then
    echo "The repository $REPO is already part of the repository list."
else
    echo "The repository $REPO is not yet part of the repository list."
fi
