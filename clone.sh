#!/bin/bash

set -Eeuox pipefail

# Check if the correct number of arguments is provided
if [ "$#" -lt 3 ] || [ "$#" -gt 4 ]; then
    echo "Usage: $0 <extension_name> <repo_url> <commit_hash> [branch_name]"
    exit 1
fi

EXTENSION_NAME="$1"
REPO_URL="$2"
COMMIT_HASH="$3"
BRANCH_NAME="${4:-main}"  # Use 'main' as default if no branch is specified

mkdir -p /custom_nodes/"$EXTENSION_NAME"
cd /custom_nodes/"$EXTENSION_NAME"
git init
git remote add origin "$REPO_URL"
git fetch --all --tags --depth=1
git checkout -b "$BRANCH_NAME" "origin/$BRANCH_NAME" || git checkout -b "$BRANCH_NAME"
git fetch origin "$COMMIT_HASH"
git reset --hard "$COMMIT_HASH"
rm -rf .git
