#!/usr/bin/env bash
# Build the VICE C64 libretro engine and wrap it as an offline OpenEmu core.

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(dirname "$SCRIPT_DIR")"
VICE_ROOT="${VICE_ROOT:-/tmp/openemu-vice-libretro-source}"
DERIVED_DATA="${DERIVED_DATA:-/tmp/OpenEmu-VICE-DD}"
CONFIGURATION="${CONFIGURATION:-Release}"
PRODUCTS="$DERIVED_DATA/Build/Products/$CONFIGURATION"
PLUGIN="$PRODUCTS/VICE.oecoreplugin"

die() { echo "error: $*" >&2; exit 1; }

command -v git >/dev/null 2>&1 || die "git is required."
command -v make >/dev/null 2>&1 || die "make is required."
command -v xcrun >/dev/null 2>&1 || die "Xcode command-line tools are required."

if [[ ! -d "$VICE_ROOT/.git" ]]; then
    rm -rf "$VICE_ROOT"
    git clone --depth 1 https://github.com/libretro/vice-libretro.git "$VICE_ROOT"
fi

[[ -f "$VICE_ROOT/Makefile" ]] || die "VICE libretro Makefile not found: $VICE_ROOT/Makefile"

# The current Xcode SDK exposes fdopen on macOS. The vendored zlib compatibility
# header predates that SDK and incorrectly replaces it with a macro. Keep this
# workaround local to the build checkout; no upstream source is changed in git.
if grep -q '#if defined(MACOS) || defined(TARGET_OS_MAC)' "$VICE_ROOT/deps/libz/zutil.h"; then
    sed -i '' 's/#if defined(MACOS) || defined(TARGET_OS_MAC)/#if (defined(MACOS) || defined(TARGET_OS_MAC)) \&\& !defined(__APPLE__)/' "$VICE_ROOT/deps/libz/zutil.h"
fi

if ! grep -q -- '-I$(EMU)/crtc' "$VICE_ROOT/Makefile.common"; then
    sed -i '' '8i\
    -I$(EMU)/crtc \\
' "$VICE_ROOT/Makefile.common"
fi

echo "Building VICE libretro (Release arm64)..."
make -C "$VICE_ROOT" clean EMUTYPE=x64
MACOSX_DEPLOYMENT_TARGET=11.0 make -C "$VICE_ROOT" \
    platform=osx \
    EMUTYPE=x64 \
    arch=arm \
    CC="xcrun clang -arch arm64" \
    CXX="xcrun clang++ -arch arm64" \
    LDFLAGS="-dynamiclib -arch arm64 -mmacosx-version-min=11.0" \
    -j"$(sysctl -n hw.ncpu 2>/dev/null || echo 4)"

LIBRETRO="$VICE_ROOT/vice_x64_libretro.dylib"
[[ -f "$LIBRETRO" ]] || die "VICE libretro dylib was not produced."

BRIDGE="${OPENEMU_LIBRETRO_BRIDGE:-$REPO_ROOT/OpenEmu/OpenEmuLibretroBridge.oecoreplugin/Contents/MacOS/OpenEmuLibretroBridge}"
[[ -f "$BRIDGE" ]] || die "OpenEmu libretro bridge not found: $BRIDGE"

rm -rf "$PLUGIN"
mkdir -p "$PLUGIN/Contents/MacOS" "$PLUGIN/Contents/Resources"
cp "$BRIDGE" "$PLUGIN/Contents/MacOS/VICE"
cp "$LIBRETRO" "$PLUGIN/Contents/Resources/vice_x64_libretro.dylib"

cat > "$PLUGIN/Contents/Info.plist" <<'PLIST'
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0"><dict>
<key>CFBundleExecutable</key><string>VICE</string>
<key>CFBundleIdentifier</key><string>org.openemu.VICE</string>
<key>CFBundleName</key><string>VICE</string>
<key>CFBundlePackageType</key><string>BNDL</string>
<key>CFBundleShortVersionString</key><string>3.8</string>
<key>CFBundleVersion</key><string>1</string>
<key>NSPrincipalClass</key><string>OEGameCoreController</string>
<key>OEGameCoreClass</key><string>OELibretroCoreTranslator</string>
<key>OEGameCoreName</key><string>VICE</string>
<key>OELibretroCorePath</key><string>../Resources/vice_x64_libretro.dylib</string>
<key>OESystemIdentifiers</key><array><string>openemu.system.c64</string></array>
<key>OEGameCorePlayerCount</key><integer>2</integer>
<key>OEBridgeVersion</key><string>20</string>
</dict></plist>
PLIST

codesign --force --sign - "$PLUGIN"
codesign --verify --deep --strict "$PLUGIN"
[[ "$(lipo -archs "$PLUGIN/Contents/MacOS/VICE")" == *arm64* ]] || die "VICE wrapper is not arm64."
[[ "$(lipo -archs "$PLUGIN/Contents/Resources/vice_x64_libretro.dylib")" == *arm64* ]] || die "VICE dylib is not arm64."

echo "Built VICE plugin: $PLUGIN"
