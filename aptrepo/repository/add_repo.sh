#!/bin/bash

set -e

function retry {
    set +e
    attempt_num=0
    attempt_max=5
    retry_delay=2
    echo "🔄 Executing: $*"
    until "$@"; do
        ((attempt_num++))
        if [ "$attempt_num" -ge "$attempt_max" ]; then
            echo "❌ Attempt $attempt_num failed! No more attempts left."
            set -e
            return 1
        else
          echo "⚠️ Attempt $attempt_num failed! Retrying in $retry_delay seconds..."
          sleep $retry_delay
          retry_delay=$((retry_delay * 2))
        fi
    done
    set -e
}

if [ "$(id -u)" -ne 0 ]; then
    echo "❌ This script must be run as root. Please use sudo."
    exit 1
fi

if ! command -v gpg >/dev/null 2>&1; then
    echo "ℹ️ gpg not found. Installing gpg..."
    retry apt-get update -y
    retry apt-get install -y gpg
    echo "✅ gpg installed successfully."
fi

if ! command -v curl >/dev/null 2>&1; then
    echo "ℹ️ curl not found. Installing curl..."
    retry apt-get update -y
    retry apt-get install -y curl
    echo "✅ curl installed successfully."
fi

source /etc/os-release

REPO_URL="http://aptrepo.effective-range.com"
COMPONENTS="${*:-main}"
SOURCES="/etc/apt/sources.list.d/effective-range.sources"
KEY_FILE="/usr/share/keyrings/er-keyring.pgp"
KEY_URL="http://aptrepo.effective-range.com/effectiverange.gpg.key"

echo "ℹ️ Adding repository to $SOURCES"
cat > $SOURCES << EOF
Types: deb
URIs: $REPO_URL
Suites: $VERSION_CODENAME
Components: $COMPONENTS
Signed-By: $KEY_FILE
EOF
echo "✅ Repository added successfully."

echo "ℹ️ Importing repository public key $KEY_URL"
mkdir -p /usr/share/keyrings
retry curl -4 -fSL --connect-timeout 5 --max-time 20 --retry 4 --retry-all-errors --retry-delay 1 "$KEY_URL" -o $KEY_FILE
gpg --show-keys $KEY_FILE
echo "✅ Public key imported successfully."

echo "ℹ️ Updating package lists..."
retry apt-get update -y
echo "✅ Package lists updated."

echo "✅ Done."
exit 0
