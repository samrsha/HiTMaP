#!/bin/bash
set -e
cd workflow

if ! command -v unzip &> /dev/null; then
    echo "unzip could not be found. Installing unzip..."
    sudo apt-get install unzip
else
    echo "Unzip is installed."
fi

unzip "$1.zip"
rm -rf "$1.zip" __MACOSX "$1.zip:Zone.Identifier"