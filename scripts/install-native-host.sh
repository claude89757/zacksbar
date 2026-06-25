#!/usr/bin/env bash
set -euo pipefail

HOST_NAME="com.zacksbar.native"
TARGET_DIR="${HOME}/Library/Application Support/Google/Chrome/NativeMessagingHosts"
HOST_PATH="${1:-$(pwd)/apps/macos/.build/debug/zacksbar-native-host}"
EXTENSION_ID="${2:-}"
MANIFEST_PATH="${TARGET_DIR}/${HOST_NAME}.json"

if [[ -z "${EXTENSION_ID}" ]]; then
  echo "Usage: $0 /absolute/path/to/zacksbar-native-host chrome_extension_id" >&2
  exit 64
fi

mkdir -p "${TARGET_DIR}"
cat > "${MANIFEST_PATH}" <<JSON
{
  "name": "${HOST_NAME}",
  "description": "ZacksBar Native Messaging Host",
  "path": "${HOST_PATH}",
  "type": "stdio",
  "allowed_origins": ["chrome-extension://${EXTENSION_ID}/"]
}
JSON

echo "Installed ${MANIFEST_PATH}"
