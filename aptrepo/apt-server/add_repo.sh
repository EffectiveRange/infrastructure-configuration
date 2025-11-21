#!/bin/bash

set -e

if [ "$#" -ne 2 ]; then
    echo "ℹ️ Usage: $0 <distribution> <component>"
    echo "Example: $0 bookworm main"
    exit 1
fi

REPO_URL="http://aptrepo.effective-range.com"
DISTRIBUTION="${1:-bookworm}"
COMPONENT="${2:-main}"
SOURCE_LIST="/etc/apt/sources.list.d/effective-range.list"

echo "ℹ️ Adding repository to $SOURCE_LIST"
echo "deb $REPO_URL $DISTRIBUTION $COMPONENT" | sudo tee $SOURCE_LIST > /dev/null
echo "✅ Repository added successfully."

echo "ℹ️ Importing repository public key..."
sudo apt-key adv --fetch-keys "$REPO_URL/dists/$DISTRIBUTION/public.key"
echo "✅ Public key imported successfully."

echo "ℹ️ Updating package lists..."
sudo apt-get update
echo "✅ Package lists updated."

echo "✅ Done."
exit 0
