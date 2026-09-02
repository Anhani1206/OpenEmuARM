#!/usr/bin/env bash
# Build and embed every native OpenEmu core in a Release app.
# This creates a local validation app; notarization is handled separately.

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(dirname "$SCRIPT_DIR")"

die() { echo "error: $*" >&2; exit 1; }

[ "$#" -ge 1 ] && [ "$#" -le 2 ] || die "usage: $0 /path/to/OpenEmu.xcarchive [output-app]"

ARCHIVE="$1"
SOURCE_APP="$ARCHIVE/Products/Applications/OpenEmu.app"
OUTPUT_APP="${2:-$(dirname "$ARCHIVE")/OpenEmu-with-all-cores.app}"
APP="$OUTPUT_APP"
PLUGINS="$APP/Contents/PlugIns/Cores"
BRIDGE="$APP/Contents/PlugIns/OpenEmuLibretroBridge.oecoreplugin/Contents/MacOS/OpenEmuLibretroBridge"
DERIVED_ROOT="${CORE_DERIVED_DATA_ROOT:-/tmp/OpenEmu-All-Cores-DD}"

[ -d "$ARCHIVE" ] || die "archive not found: $ARCHIVE"
[ -d "$SOURCE_APP" ] || die "OpenEmu.app not found in archive: $SOURCE_APP"

rm -rf "$OUTPUT_APP"
ditto "$SOURCE_APP" "$OUTPUT_APP"
[ -x "$BRIDGE" ] || die "OpenEmu libretro bridge not found in archive"
mkdir -p "$PLUGINS" "$DERIVED_ROOT"

stage_core() {
    local source="$1"
    local name="$2"
    local destination="$PLUGINS/$name.oecoreplugin"
    [ -d "$source" ] || die "core was not produced: $source"
    rm -rf "$destination"
    ditto "$source" "$destination"
    stamp_core "$destination"
    codesign --force --deep --sign - "$destination"
    codesign --verify --deep --strict "$destination" || die "codesign failed: $name"
    echo "staged: $name"
}

stamp_core() {
    local plist="$1/Contents/Info.plist"
    /usr/libexec/PlistBuddy -c "Delete :OEBundledCoreRefreshRevision" "$plist" 2>/dev/null || true
    /usr/libexec/PlistBuddy -c "Add :OEBundledCoreRefreshRevision string 20260901.1" "$plist"
}

OPENEMU_SDK_DERIVED_DATA="${OPENEMU_SDK_DERIVED_DATA:-$DERIVED_ROOT/OpenEmu-SDK}"
xcodebuild -project "$REPO_ROOT/OpenEmu-SDK/OpenEmu-SDK.xcodeproj" \
    -scheme OpenEmuBase -configuration Release \
    -derivedDataPath "$OPENEMU_SDK_DERIVED_DATA" \
    -destination 'platform=macOS,arch=arm64' build

SDK_PRODUCTS="$OPENEMU_SDK_DERIVED_DATA/Build/Products/Release"
[ -d "$SDK_PRODUCTS/OpenEmuBase.framework" ] || die "OpenEmuBase framework was not produced"

stage_xcode_core() {
    local project="$1" scheme="$2" bundle="$3"
    local dd="$DERIVED_ROOT/$bundle"
    local source="$dd/Build/Products/Release/$bundle.oecoreplugin"
    local project_path="$REPO_ROOT/$project/$scheme.xcodeproj"
    [ -d "$project_path" ] || die "project not found: $project_path"
    local build_args=("FRAMEWORK_SEARCH_PATHS=$SDK_PRODUCTS")
    if [ "$bundle" = "4DO" ]; then
        build_args+=("HEADER_SEARCH_PATHS=$REPO_ROOT/OpenEmu-SDK")
    elif [ "$bundle" = "Mupen64Plus" ]; then
        build_args+=("HEADER_SEARCH_PATHS=$REPO_ROOT/OpenEmu-SDK $REPO_ROOT/OpenEmuKit/Source $REPO_ROOT/Vendor/rcheevos/include $REPO_ROOT/Mupen64Plus/GLideN64/src $REPO_ROOT/Mupen64Plus/GLideN64/src/inc $REPO_ROOT/Mupen64Plus/GLideN64/src/osal $REPO_ROOT/Mupen64Plus/GLideN64/src/xxHash $REPO_ROOT/Mupen64Plus/mupen64plus-core/src $REPO_ROOT/Mupen64Plus/mupen64plus-core/subprojects/md5 $REPO_ROOT/Mupen64Plus/mupen64plus-core/subprojects/minizip $REPO_ROOT/Mupen64Plus/mupen64plus-core/subprojects/xxhash $REPO_ROOT/Mupen64Plus/angrylion-rdp-plus/src $REPO_ROOT/Mupen64Plus/angrylion-rdp-plus/src/plugin/mupen64plus $REPO_ROOT/Mupen64Plus/Compatibility $REPO_ROOT/Mupen64Plus/Compatibility/SDL")
    elif [ "$bundle" = "VecXGL" ]; then
        build_args+=("HEADER_SEARCH_PATHS=$REPO_ROOT/OpenEmu-SDK $REPO_ROOT/OpenEmuKit/Source")
    fi
    xcodebuild -project "$project_path" -scheme "$scheme" -configuration Release \
        -derivedDataPath "$dd" -destination 'platform=macOS,arch=arm64' \
        "${build_args[@]}" build
    stage_core "$source" "$bundle"
}

stage_xcode_core "4DO" "4DO" "4DO"
stage_xcode_core "Mupen64Plus" "Mupen64Plus" "Mupen64Plus"

CORE_SPECS=(
  "MAME|MAME|MAME"
  "Stella|Stella|Stella"
  "Atari800|Atari800|Atari800"
  "ProSystem|ProSystem|ProSystem"
  "VirtualJaguar|VirtualJaguar|VirtualJaguar"
  "Mednafen|Mednafen|Mednafen"
  "JollyCV|JollyCV|JollyCV"
  "CrabEmu|CrabEmu|CrabEmu"
  "blueMSX|blueMSX|blueMSX"
  "Nestopia|Nestopia|Nestopia"
  "FCEU|FCEU|FCEU"
  "Gambatte|Gambatte|Gambatte"
  "mGBA|mGBA|mGBA"
  "Dolphin|Dolphin|Dolphin"
  "Bliss|Bliss|Bliss"
  "O2EM|O2EM|O2EM"
  "GenesisPlus|GenesisPlus|GenesisPlus"
  "Flycast|Flycast|Flycast"
  "picodrive|Picodrive|Picodrive"
  "SNES9x|SNES9x|SNES9x"
  "BSNES|BSNES|BSNES"
  "VecXGL|VecXGL|VecXGL"
  "Potator-Core|Potator|Potator"
  "PokeMini|PokeMini|PokeMini"
  "DeSmuME/src/frontend/cocoa|DeSmuME (Latest)|DeSmuME"
  "PPSSPP/PPSSPP-Core|PPSSPP|PPSSPP"
)

for spec in "${CORE_SPECS[@]}"; do
    IFS='|' read -r project scheme bundle <<< "$spec"
    echo "building: $bundle"
    if [ "$bundle" = "MAME" ]; then
        "$SCRIPT_DIR/build-mame-core.sh"
        stage_core "$REPO_ROOT/MAME/build/XcodeDerived/Build/Products/Release/MAME.oecoreplugin" "$bundle"
        continue
    fi
    if [ "$bundle" = "PPSSPP" ]; then
        ppsspp_root="$REPO_ROOT/PPSSPP/PPSSPP-Core/ppsspp"
        mkdir -p "$ppsspp_root/assets/flash0"
        touch "$ppsspp_root/assets/flash0/.empty"
        if [ ! -f "$ppsspp_root/git-version.cpp" ]; then
            printf '%s\n' '// Generated for the flattened OpenEmu PPSSPP source tree.' 'const char *PPSSPP_GIT_VERSION = "openemu-bundled";' > "$ppsspp_root/git-version.cpp"
        fi
        xcodebuild -project "$REPO_ROOT/$project/$scheme.xcodeproj" -scheme "$scheme" \
            -configuration Release -derivedDataPath "$DERIVED_ROOT/$bundle" \
            -destination 'platform=macOS,arch=arm64' \
            FRAMEWORK_SEARCH_PATHS="$SDK_PRODUCTS" \
            HEADER_SEARCH_PATHS="$REPO_ROOT/OpenEmu-SDK $ppsspp_root $ppsspp_root/Common $ppsspp_root/ext/glew $ppsspp_root/ext/glslang $ppsspp_root/ext/zstd/lib $ppsspp_root/ext/armips" \
            MACOSX_DEPLOYMENT_TARGET=12.0 EXCLUDED_SOURCE_FILE_NAMES=gl3stub.c build
    else
        stage_xcode_core "$project" "$scheme" "$bundle"
        continue
    fi
    stage_core "$DERIVED_ROOT/$bundle/Build/Products/Release/$bundle.oecoreplugin" "$bundle"
done

echo "building: ARMSX2"
CONFIGURATION=Release DERIVED_DATA="$DERIVED_ROOT/ARMSX2" "$SCRIPT_DIR/build-armsx2-libretro-arm64.sh"
stage_core "$DERIVED_ROOT/ARMSX2/Build/Products/Release/ARMSX2.oecoreplugin" "ARMSX2"

echo "building: FBNeo"
CONFIGURATION=Release DERIVED_DATA="$DERIVED_ROOT/FBNeo" "$SCRIPT_DIR/build-fbneo-openemu-arm64.sh"
stage_core "$DERIVED_ROOT/FBNeo/Build/Products/Release/FBNeo.oecoreplugin" "FBNeo"

echo "building: VICE"
OPENEMU_LIBRETRO_BRIDGE="$BRIDGE" DERIVED_DATA="$DERIVED_ROOT/VICE" \
    "$SCRIPT_DIR/build-vice-openemu-arm64.sh"
stage_core "$DERIVED_ROOT/VICE/Build/Products/Release/VICE.oecoreplugin" "VICE"

echo "building: Geolith-RetroArch"
OPENEMU_LIBRETRO_BRIDGE="$BRIDGE" DERIVED_DATA="$DERIVED_ROOT/Geolith" \
    "$SCRIPT_DIR/build-geolith-openemu-arm64.sh"
stage_core "$DERIVED_ROOT/Geolith/Build/Products/Release/Geolith-RetroArch.oecoreplugin" "Geolith-RetroArch"

codesign --force --deep --sign - "$APP"
codesign --verify --deep --strict "$APP" || die "final app codesign verification failed"

echo "Complete app: $APP"
du -sh "$APP"
echo "Embedded cores: $(find "$PLUGINS" -maxdepth 1 -type d -name '*.oecoreplugin' | wc -l | tr -d ' ')"
