#!/usr/bin/env bash
# Completes a local OpenEmu archive with cores that are built outside the
# main Xcode application target.

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(dirname "$SCRIPT_DIR")"

die() {
    echo "error: $*" >&2
    exit 1
}

[ "$#" -ge 1 ] && [ "$#" -le 2 ] || die "usage: $0 /path/to/OpenEmu.xcarchive [output-app]"

ARCHIVE="$1"
SOURCE_APP="$ARCHIVE/Products/Applications/OpenEmu.app"
OUTPUT_APP="${2:-$(dirname "$ARCHIVE")/OpenEmu-with-cores.app}"
APP="$OUTPUT_APP"
PLUGINS="$APP/Contents/PlugIns/Cores"
BRIDGE="$APP/Contents/PlugIns/OpenEmuLibretroBridge.oecoreplugin/Contents/MacOS/OpenEmuLibretroBridge"

[ -d "$ARCHIVE" ] || die "archive not found: $ARCHIVE"
[ -d "$SOURCE_APP" ] || die "OpenEmu.app not found in archive: $SOURCE_APP"

rm -rf "$OUTPUT_APP"
ditto "$SOURCE_APP" "$OUTPUT_APP"
[ -x "$BRIDGE" ] || die "OpenEmu libretro bridge not found in archive"

mkdir -p "$PLUGINS"

stage_core() {
    local source="$1"
    local destination="$2"

    [ -d "$source" ] || die "core was not produced: $source"
    rm -rf "$destination"
    ditto "$source" "$destination"
    codesign --force --deep --sign - "$destination"
    codesign --verify --deep --strict "$destination" \
        || die "codesign verification failed: $destination"
    echo "staged: $(basename "$destination")"
}

echo "Building ARMSX2 (PlayStation 2)..."
CONFIGURATION=Release "$SCRIPT_DIR/build-armsx2-libretro-arm64.sh"
stage_core \
    "${DERIVED_DATA:-/tmp/OpenEmu-Shared-DD}/Build/Products/Release/ARMSX2.oecoreplugin" \
    "$PLUGINS/ARMSX2.oecoreplugin"

echo "Building FBNeo (Neo Geo .zip)..."
FBNEO_DERIVED_DATA="${FBNEO_DERIVED_DATA:-/tmp/OpenEmu-FBNeo-DD}"
CONFIGURATION=Release DERIVED_DATA="$FBNEO_DERIVED_DATA" \
    "$SCRIPT_DIR/build-fbneo-openemu-arm64.sh"
stage_core \
    "$FBNEO_DERIVED_DATA/Build/Products/Release/FBNeo.oecoreplugin" \
    "$PLUGINS/FBNeo.oecoreplugin"

echo "Building VICE (Commodore 64)..."
VICE_DERIVED_DATA="${VICE_DERIVED_DATA:-/tmp/OpenEmu-VICE-DD}"
OPENEMU_LIBRETRO_BRIDGE="$BRIDGE" DERIVED_DATA="$VICE_DERIVED_DATA" \
    "$SCRIPT_DIR/build-vice-openemu-arm64.sh"
stage_core \
    "$VICE_DERIVED_DATA/Build/Products/Release/VICE.oecoreplugin" \
    "$PLUGINS/VICE.oecoreplugin"

echo "Building Geolith (Neo Geo .neo)..."
GEOLITH_DERIVED_DATA="${GEOLITH_DERIVED_DATA:-/tmp/OpenEmu-Geolith-DD}"
OPENEMU_LIBRETRO_BRIDGE="$BRIDGE" DERIVED_DATA="$GEOLITH_DERIVED_DATA" \
    "$SCRIPT_DIR/build-geolith-openemu-arm64.sh"
stage_core \
    "$GEOLITH_DERIVED_DATA/Build/Products/Release/Geolith-RetroArch.oecoreplugin" \
    "$PLUGINS/Geolith-RetroArch.oecoreplugin"

codesign --force --deep --sign - "$APP"
codesign --verify --deep --strict "$APP" \
    || die "final app codesign verification failed"

echo "All special cores were added to: $PLUGINS"
echo "Complete app: $APP"
