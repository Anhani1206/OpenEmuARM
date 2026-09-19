#!/bin/sh

set -eu

REPO_ROOT="${SRCROOT}/.."
OPERA_SOURCE="${REPO_ROOT}/Opera"
BUILD_SOURCE="${DERIVED_FILES_DIR}/OperaSource"
APP_PLUGINS="${TARGET_BUILD_DIR}/${WRAPPER_NAME}/Contents/PlugIns"
# OECorePlugin scans the app's built-in PlugIns/Cores folder.
PLUGIN_DIR="${APP_PLUGINS}/Cores/Opera-RetroArch.oecoreplugin"
LEGACY_PLUGIN_DIR="${APP_PLUGINS}/Opera-RetroArch.oecoreplugin"
BRIDGE_BINARY="${BUILT_PRODUCTS_DIR}/OpenEmuLibretroBridge.oecoreplugin/Contents/MacOS/OpenEmuLibretroBridge"

if [ ! -f "${OPERA_SOURCE}/Makefile" ]; then
    echo "error: Opera source is missing at ${OPERA_SOURCE}" >&2
    exit 1
fi

if [ ! -f "${BRIDGE_BINARY}" ]; then
    echo "error: bundled Libretro bridge is missing at ${BRIDGE_BINARY}" >&2
    exit 1
fi

rm -rf "${BUILD_SOURCE}"
mkdir -p "${BUILD_SOURCE}"
ditto "${OPERA_SOURCE}" "${BUILD_SOURCE}"

make -C "${BUILD_SOURCE}" platform=osx arch=arm64 ARCHFLAGS="-arch arm64" -j2

mkdir -p "${APP_PLUGINS}/Cores"
rm -rf "${LEGACY_PLUGIN_DIR}"
rm -rf "${PLUGIN_DIR}"
mkdir -p "${PLUGIN_DIR}/Contents/MacOS"
cp "${BUILD_SOURCE}/opera_libretro.dylib" "${PLUGIN_DIR}/Contents/MacOS/opera_libretro.dylib"
cp "${BRIDGE_BINARY}" "${PLUGIN_DIR}/Contents/MacOS/Opera-RetroArch"

cat > "${PLUGIN_DIR}/Contents/Info.plist" <<'PLIST'
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>CFBundleExecutable</key>
    <string>Opera-RetroArch</string>
    <key>CFBundleIdentifier</key>
    <string>org.openemu.Opera-RetroArch</string>
    <key>CFBundleName</key>
    <string>Opera</string>
    <key>CFBundlePackageType</key>
    <string>BNDL</string>
    <key>NSPrincipalClass</key>
    <string>OEGameCoreController</string>
    <key>OEGameCoreClass</key>
    <string>OELibretroCoreTranslator</string>
    <key>OELibretroCorePath</key>
    <string>opera_libretro.dylib</string>
    <key>OEGameCoreName</key>
    <string>Opera (Libretro)</string>
    <key>OEGameCorePlayerCount</key>
    <string>8</string>
    <key>OESystemIdentifiers</key>
    <array>
        <string>openemu.system.3do</string>
    </array>
</dict>
</plist>
PLIST

codesign --force --sign - --deep "${PLUGIN_DIR}"
