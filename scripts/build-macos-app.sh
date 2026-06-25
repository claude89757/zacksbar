#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
MACOS_DIR="${ROOT_DIR}/apps/macos"
CONFIGURATION="${ZACKSBAR_SWIFT_CONFIGURATION:-debug}"
PRODUCTS_DIR="${ZACKSBAR_BUILD_PRODUCTS_DIR:-${MACOS_DIR}/.build/${CONFIGURATION}}"
APP_BUNDLE="${ZACKSBAR_APP_BUNDLE_PATH:-${PRODUCTS_DIR}/ZacksBar.app}"
CONTENTS_DIR="${APP_BUNDLE}/Contents"
MACOS_CONTENTS_DIR="${CONTENTS_DIR}/MacOS"

if [[ "${ZACKSBAR_SKIP_SWIFT_BUILD:-0}" != "1" ]]; then
  swift build --package-path "${MACOS_DIR}" --configuration "${CONFIGURATION}"
fi

APP_EXECUTABLE="${PRODUCTS_DIR}/ZacksBarApp"
NATIVE_HOST_EXECUTABLE="${PRODUCTS_DIR}/zacksbar-native-host"

if [[ ! -x "${APP_EXECUTABLE}" ]]; then
  echo "Missing executable: ${APP_EXECUTABLE}" >&2
  exit 66
fi

if [[ ! -x "${NATIVE_HOST_EXECUTABLE}" ]]; then
  echo "Missing executable: ${NATIVE_HOST_EXECUTABLE}" >&2
  exit 66
fi

rm -rf "${APP_BUNDLE}"
mkdir -p "${MACOS_CONTENTS_DIR}"
cp "${APP_EXECUTABLE}" "${MACOS_CONTENTS_DIR}/ZacksBarApp"
cp "${NATIVE_HOST_EXECUTABLE}" "${MACOS_CONTENTS_DIR}/zacksbar-native-host"
chmod 755 "${MACOS_CONTENTS_DIR}/ZacksBarApp" "${MACOS_CONTENTS_DIR}/zacksbar-native-host"

cat > "${CONTENTS_DIR}/Info.plist" <<'PLIST'
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
  <key>CFBundleDevelopmentRegion</key>
  <string>en</string>
  <key>CFBundleExecutable</key>
  <string>ZacksBarApp</string>
  <key>CFBundleIdentifier</key>
  <string>com.zacksbar.app</string>
  <key>CFBundleInfoDictionaryVersion</key>
  <string>6.0</string>
  <key>CFBundleName</key>
  <string>ZacksBar</string>
  <key>CFBundlePackageType</key>
  <string>APPL</string>
  <key>CFBundleShortVersionString</key>
  <string>0.1.0</string>
  <key>CFBundleVersion</key>
  <string>1</string>
  <key>LSMinimumSystemVersion</key>
  <string>13.0</string>
  <key>LSUIElement</key>
  <true/>
  <key>NSPrincipalClass</key>
  <string>NSApplication</string>
</dict>
</plist>
PLIST

echo "Built ${APP_BUNDLE}"
