#!/bin/bash

# Check if the 'gh' package is installed
if command -v gh >/dev/null 2>&1; then
    echo "The gh package is already installed."
else
    echo "The gh package is not yet installed."
fi
