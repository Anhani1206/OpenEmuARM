#!/usr/bin/env bash
# Install a Debug ARMSX2 plugin without merging old bundle contents.

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(dirname "$SCRIPT_DIR")"
DEFAULT_PLUGIN="/tmp/OpenEmu-Shared-DD/Build/Products/Debug/ARMSX2.oecoreplugin"
SOURCE_PLUGIN="${1:-$DEFAULT_PLUGIN}"
DESTINATION="$HOME/Library/Application Support/OpenEmu/Cores/ARMSX2.oecoreplugin"

die() {
    echo "error: $*" >&2
    exit 1
}

WRAPPER="$SOURCE_PLUGIN/Contents/MacOS/ARMSX2"
LIBRETRO="$SOURCE_PLUGIN/Contents/Resources/armsx2_libretro.dylib"
[[ -f "$WRAPPER" ]] || die "ARMSX2 wrapper not found: $WRAPPER"
[[ -f "$LIBRETRO" ]] || die "ARMSX2 libretro dylib not found: $LIBRETRO"

if pgrep -xq OpenEmu 2>/dev/null; then
    osascript -e 'tell application "OpenEmu" to quit'
    sleep 2
    pgrep -xq OpenEmu 2>/dev/null && die "OpenEmu is still running. Quit it and retry."
fi

for binary in "$WRAPPER" "$LIBRETRO"; do
    architectures="$(lipo -archs "$binary")"
    [[ "$architectures" == *"arm64"* ]] || die "Expected arm64 binary: $binary ($architectures)"
done

mkdir -p "$(dirname "$DESTINATION")"
TEMP_DESTINATION="${DESTINATION}.tmp.$$"
rm -rf "$TEMP_DESTINATION"
ditto "$SOURCE_PLUGIN" "$TEMP_DESTINATION"
codesign --force --sign - "$TEMP_DESTINATION"
codesign --verify --deep --strict "$TEMP_DESTINATION"
rm -rf "$DESTINATION"
mv "$TEMP_DESTINATION" "$DESTINATION"
: > /tmp/openemu-armsx2-metal.log

echo "Installed: $DESTINATION"
echo "Run: ./Scripts/verify-core-installed.sh ARMSX2"
