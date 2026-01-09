#!/bin/bash

set -e

if [ "$(id -u)" -ne 0 ]; then
    echo "❌ This script must be run as root. Please use sudo."
    exit 1
fi

if ! command -v gpg >/dev/null 2>&1; then
    echo "ℹ️ gpg not found. Installing gpg..."
    apt-get update
    apt-get install -y gpg
    echo "✅ gpg installed successfully."
fi

if ! command -v curl >/dev/null 2>&1; then
    echo "ℹ️ curl not found. Installing curl..."
    apt-get update
    apt-get install -y curl
    echo "✅ curl installed successfully."
fi

source /etc/os-release

REPO_URL="http://aptrepo.effective-range.com"
COMPONENT="${@:-main}"
SOURCES="/etc/apt/sources.list.d/effective-range.sources"
KEY_FILE="/usr/share/keyrings/er-keyring.pgp"

echo "ℹ️ Adding repository to $SOURCES"
cat > $SOURCES << EOF
Types: deb
URIs: $REPO_URL
Suites: $VERSION_CODENAME
Components: $COMPONENT
Signed-By: $KEY_FILE
EOF
echo "✅ Repository added successfully."

echo "ℹ️ Importing repository public key..."
mkdir -p /usr/share/keyrings
curl -4 -fSL --connect-timeout 5 --max-time 20 --retry 8 --retry-all-errors --retry-delay 1 http://aptrepo.effective-range.com/effectiverange.gpg.key -o $KEY_FILE
gpg --show-keys $KEY_FILE
echo "✅ Public key imported successfully."

echo "ℹ️ Updating package lists..."
apt-get update
echo "✅ Package lists updated."

echo "✅ Done."
exit 0
