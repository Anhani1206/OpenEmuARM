#!/usr/bin/env bash
# Build the bundled FBNeo libretro engine as an OpenEmu-owned core plugin.

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(dirname "$SCRIPT_DIR")"
FBNEO_ROOT="${FBNEO_ROOT:-$REPO_ROOT/FBNeo}"
DERIVED_DATA="${DERIVED_DATA:-/tmp/OpenEmu-FBNeo-DD}"
CONFIGURATION="${CONFIGURATION:-Release}"
PRODUCTS="$DERIVED_DATA/Build/Products/$CONFIGURATION"
PLUGIN="$PRODUCTS/FBNeo.oecoreplugin"

[[ -f "$FBNEO_ROOT/src/burner/libretro/Makefile" ]] || {
    echo "error: FBNeo source not found at $FBNEO_ROOT" >&2
    exit 1
}

echo "Building OpenEmuBase ($CONFIGURATION)..."
xcodebuild \
    -project "$REPO_ROOT/OpenEmu-SDK/OpenEmu-SDK.xcodeproj" \
    -scheme OpenEmuBase \
    -configuration "$CONFIGURATION" \
    -derivedDataPath "$DERIVED_DATA" \
    -destination 'platform=macOS,arch=arm64' build

echo "Building FBNeo libretro (arm64)..."
make -C "$FBNEO_ROOT/src/burner/libretro" clean SUBSET=all
make -C "$FBNEO_ROOT/src/burner/libretro" \
    platform=osx \
    SUBSET=all \
    INCLUDE_CHD_SUPPORT=1 \
    CHD_LIBRETRO=1 \
    UNIVERSAL=1 \
    ARCHFLAGS="-arch arm64" \
    -j"$(sysctl -n hw.ncpu 2>/dev/null || echo 4)"

LIBRETRO="$FBNEO_ROOT/src/burner/libretro/fbneo_all_libretro.dylib"
[[ -f "$LIBRETRO" ]] || { echo "error: FBNeo dylib was not produced" >&2; exit 1; }

rm -rf "$PLUGIN"
mkdir -p "$PLUGIN/Contents/MacOS" "$PLUGIN/Contents/Resources"

echo "Building OpenEmu wrapper..."
xcrun clang++ -dynamiclib -fobjc-arc -std=c++17 \
    -arch arm64 -mmacosx-version-min=11.0 \
    -I"$REPO_ROOT/FBNeo" \
    -F"$PRODUCTS" \
    "$REPO_ROOT/FBNeo/FBNeoGameCore.mm" \
    -framework Cocoa -framework OpenEmuBase \
    -o "$PLUGIN/Contents/MacOS/FBNeo"

cp "$REPO_ROOT/FBNeo/Info.plist" "$PLUGIN/Contents/Info.plist"
cp "$LIBRETRO" "$PLUGIN/Contents/Resources/fbneo_libretro.dylib"
codesign --force --sign - "$PLUGIN"
codesign --verify --deep --strict "$PLUGIN"

[[ "$(lipo -archs "$PLUGIN/Contents/MacOS/FBNeo")" == *arm64* ]] || exit 1
[[ "$(lipo -archs "$PLUGIN/Contents/Resources/fbneo_libretro.dylib")" == *arm64* ]] || exit 1
echo "Built FBNeo plugin: $PLUGIN"
