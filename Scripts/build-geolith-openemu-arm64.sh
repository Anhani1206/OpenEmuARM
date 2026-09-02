#!/usr/bin/env bash
# Build the Geolith libretro core and wrap it as a portable OpenEmu plugin.

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(dirname "$SCRIPT_DIR")"
GEOLITH_ROOT="${GEOLITH_ROOT:-/tmp/openemu-geolith-source}"
DERIVED_DATA="${DERIVED_DATA:-/tmp/OpenEmu-Geolith-DD}"
PRODUCTS="$DERIVED_DATA/Build/Products/Release"
PLUGIN="$PRODUCTS/Geolith-RetroArch.oecoreplugin"

die() { echo "error: $*" >&2; exit 1; }

command -v git >/dev/null 2>&1 || die "git is required."
command -v make >/dev/null 2>&1 || die "make is required."
command -v xcrun >/dev/null 2>&1 || die "Xcode command-line tools are required."

if [[ ! -d "$GEOLITH_ROOT/.git" ]]; then
    rm -rf "$GEOLITH_ROOT"
    git clone --depth 1 https://github.com/libretro/geolith-libretro.git "$GEOLITH_ROOT"
fi

MAKEFILE="$GEOLITH_ROOT/libretro/Makefile"
[[ -f "$MAKEFILE" ]] || die "Geolith Makefile not found: $MAKEFILE"

echo "Building Geolith libretro (Release arm64)..."
make -C "$GEOLITH_ROOT/libretro" clean platform=osx arch=arm
make -C "$GEOLITH_ROOT/libretro" \
    platform=osx \
    arch=arm \
    CC="xcrun clang -arch arm64" \
    CXX="xcrun clang++ -arch arm64" \
    CFLAGS="-O2 -DNDEBUG -fPIC -mmacosx-version-min=11.0 -D__LIBRETRO__ -DZ7_ST -DHAVE_ZLIB -DHAVE_7ZIP -DHAVE_DR_FLAC -DHAVE_FLAC -DHAVE_ZSTD -DZSTD_DISABLE_ASM -DHAVE_CHDR -I$GEOLITH_ROOT/deps -I$GEOLITH_ROOT/deps/libretro-common/include -I$GEOLITH_ROOT/deps/miniz -I$GEOLITH_ROOT/deps/lzma/include -I$GEOLITH_ROOT/deps/zstd/lib -I$GEOLITH_ROOT/src -I$GEOLITH_ROOT/libretro" \
    CXXFLAGS="-O2 -DNDEBUG -fPIC -mmacosx-version-min=11.0" \
    LDFLAGS="-dynamiclib -arch arm64 -mmacosx-version-min=11.0 -flto" \
    -j"$(sysctl -n hw.ncpu 2>/dev/null || echo 4)"

LIBRETRO="$GEOLITH_ROOT/libretro/geolith_libretro.dylib"
[[ -f "$LIBRETRO" ]] || die "Geolith dylib was not produced."

BRIDGE="${OPENEMU_LIBRETRO_BRIDGE:-$REPO_ROOT/OpenEmu/OpenEmuLibretroBridge.oecoreplugin/Contents/MacOS/OpenEmuLibretroBridge}"
[[ -f "$BRIDGE" ]] || die "OpenEmu libretro bridge not found: $BRIDGE"

rm -rf "$PLUGIN"
mkdir -p "$PLUGIN/Contents/MacOS" "$PLUGIN/Contents/Resources"
cp "$BRIDGE" "$PLUGIN/Contents/MacOS/Geolith-RetroArch"
cp "$LIBRETRO" "$PLUGIN/Contents/Resources/geolith_libretro.dylib"

cat > "$PLUGIN/Contents/Info.plist" <<'PLIST'
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0"><dict>
<key>CFBundleExecutable</key><string>Geolith-RetroArch</string>
<key>CFBundleIdentifier</key><string>org.openemu.Geolith-RetroArch</string>
<key>CFBundleName</key><string>Geolith</string>
<key>CFBundlePackageType</key><string>BNDL</string>
<key>CFBundleShortVersionString</key><string>1.0</string>
<key>CFBundleVersion</key><string>1</string>
<key>NSPrincipalClass</key><string>OEGameCoreController</string>
<key>OEGameCoreClass</key><string>OELibretroCoreTranslator</string>
<key>OEGameCoreName</key><string>Geolith</string>
<key>OELibretroCorePath</key><string>../Resources/geolith_libretro.dylib</string>
<key>OESystemIdentifiers</key><array><string>openemu.system.neogeo</string></array>
<key>OEGameCorePlayerCount</key><integer>2</integer>
<key>OEBridgeVersion</key><string>20</string>
</dict></plist>
PLIST

codesign --force --sign - "$PLUGIN"
codesign --verify --deep --strict "$PLUGIN"
[[ "$(lipo -archs "$PLUGIN/Contents/Resources/geolith_libretro.dylib")" == *arm64* ]] \
    || die "Geolith dylib is not arm64."

echo "Built Geolith plugin: $PLUGIN"
