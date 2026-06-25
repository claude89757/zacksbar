#!/usr/bin/env bash
set -euo pipefail

HOST_NAME="com.zacksbar.native"
ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
TARGET_DIR="${ZACKSBAR_CHROME_NATIVE_HOST_DIR:-${HOME}/Library/Application Support/Google/Chrome/NativeMessagingHosts}"
HOST_PATH="${1:-${ROOT_DIR}/apps/macos/.build/debug/ZacksBar.app/Contents/MacOS/zacksbar-native-host}"
EXTENSION_ID="${2:-}"
EXTENSION_MANIFEST="${ZACKSBAR_EXTENSION_MANIFEST_PATH:-${ROOT_DIR}/extensions/chrome/manifest.json}"
MANIFEST_PATH="${TARGET_DIR}/${HOST_NAME}.json"

if [[ -z "${EXTENSION_ID}" ]]; then
  EXTENSION_ID="$(node "${ROOT_DIR}/scripts/chrome-extension-id.mjs" "${EXTENSION_MANIFEST}")"
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
