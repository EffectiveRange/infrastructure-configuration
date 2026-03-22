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

APT_UPDATED=0

check_executable() {
    local exe="$1"
    local pkg="${2:-$exe}"
    if ! command -v "$exe" >/dev/null 2>&1; then
        echo "⚠️ Executable '$exe' not found. Installing package '$pkg'..."
        if [ $APT_UPDATED -eq 0 ]; then
            apt-get update -y >/dev/null 2>&1
            APT_UPDATED=1
        fi
        apt-get install -y --no-install-recommends "$pkg" >/dev/null 2>&1
        command -v "$exe"
        echo "✅ Package '$pkg' installed successfully."
    fi
}

if [ "$(id -u)" -ne 0 ]; then
    echo "❌ This script must be run as root. Please use sudo."
    exit 1
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

echo

echo "ℹ️ Importing repository public key $KEY_URL"
mkdir -p /usr/share/keyrings
check_executable curl
retry curl -4 -fSL --connect-timeout 5 --max-time 20 --retry 4 --retry-all-errors --retry-delay 1 "$KEY_URL" -o $KEY_FILE
check_executable gpg
gpg --show-keys $KEY_FILE
echo "✅ Public key imported successfully."

echo

echo "ℹ️ Updating package lists..."
retry apt-get update -y
echo "✅ Package lists updated."

echo

echo "✅ Done."
exit 0
