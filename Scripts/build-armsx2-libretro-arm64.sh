#!/usr/bin/env bash
# Build the native arm64 ARMSX2 libretro core as an OpenEmu plugin.

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(dirname "$SCRIPT_DIR")"
ARMSX2_ROOT="${ARMSX2_ROOT:-$REPO_ROOT/ARMSX2-Core}"
ARMSX2_BUILD_DIR="${ARMSX2_BUILD_DIR:-/tmp/openemu-silicon-armsx2-libretro-build}"
DERIVED_DATA="${DERIVED_DATA:-/tmp/OpenEmu-Shared-DD}"
CONFIGURATION="${CONFIGURATION:-Debug}"
PRODUCTS="$DERIVED_DATA/Build/Products/$CONFIGURATION"
PLUGIN="$PRODUCTS/ARMSX2.oecoreplugin"
RESOURCES="$PLUGIN/Contents/Resources"
METAL_SOURCE_DIR="$ARMSX2_ROOT/pcsx2/GS/Renderers/Metal"

die() {
    echo "error: $*" >&2
    exit 1
}

require_file() {
    [[ -f "$1" ]] || die "Required file not found: $1"
}

require_command() {
    command -v "$1" >/dev/null 2>&1 || die "Required command not found: $1"
}

[[ "$(uname -s)" == "Darwin" ]] || die "ARMSX2 OpenEmu builds require macOS."
[[ "$(uname -m)" == "arm64" ]] || die "ARMSX2 OpenEmu builds require an Apple Silicon host."
[[ -d "$ARMSX2_ROOT" ]] || die "ARMSX2 source tree not found: $ARMSX2_ROOT"

require_command cmake
require_command xcrun
require_command xcodebuild
require_file "$ARMSX2_ROOT/pcsx2-libretro/Main.cpp"
require_file "$ARMSX2_ROOT/OpenEmu/ARMSX2GameCore.mm"
require_file "$ARMSX2_ROOT/OpenEmu/Info.plist"

if ! xcrun --find metal >/dev/null 2>&1 || ! xcrun --find metallib >/dev/null 2>&1; then
    for xcode in /Applications/Xcode.app /Applications/Xcode-beta.app; do
        if [[ -d "$xcode/Contents/Developer" ]]; then
            export DEVELOPER_DIR="$xcode/Contents/Developer"
            break
        fi
    done
fi

METAL_TOOL=(xcrun metal)
METALLIB_TOOL=(xcrun metallib)

# Newer Xcode versions can install Metal as an optional toolchain under
# DVTDownloads. In that case xcrun finds the shim in XcodeDefault.xctoolchain,
# but executing it fails until the downloaded toolchain is selected explicitly.
if ! xcrun metal --version >/dev/null 2>&1; then
    METAL_MOUNT="$(find "/Users/$(id -un)/Library/Developer/DVTDownloads/MetalToolchain/mounts" \
        -path '*/Metal.xctoolchain/usr/bin/metal' -print -quit 2>/dev/null)"
    METALLIB_MOUNT="$(find "/Users/$(id -un)/Library/Developer/DVTDownloads/MetalToolchain/mounts" \
        -path '*/Metal.xctoolchain/usr/bin/metallib' -print -quit 2>/dev/null)"
    if [[ -n "$METAL_MOUNT" && -n "$METALLIB_MOUNT" ]]; then
        METAL_TOOL=("$METAL_MOUNT")
        METALLIB_TOOL=("$METALLIB_MOUNT")
    fi
fi

if ! "${METAL_TOOL[@]}" --version >/dev/null 2>&1 || ! "${METALLIB_TOOL[@]}" --version >/dev/null 2>&1; then
    die "The complete Xcode Metal toolchain is required. Select Xcode.app with xcode-select."
fi

echo "Building OpenEmuBase ($CONFIGURATION)..."
xcodebuild \
    -project "$REPO_ROOT/OpenEmu-SDK/OpenEmu-SDK.xcodeproj" \
    -scheme OpenEmuBase \
    -configuration "$CONFIGURATION" \
    -derivedDataPath "$DERIVED_DATA" \
    -destination 'platform=macOS,arch=arm64' \
    build

OPENEMU_BASE_FRAMEWORK="${OPENEMU_BASE_FRAMEWORK:-$PRODUCTS/OpenEmuBase.framework}"
[[ -d "$OPENEMU_BASE_FRAMEWORK" ]] || die "OpenEmuBase.framework not found: $OPENEMU_BASE_FRAMEWORK"

echo "Configuring ARMSX2 libretro..."
cmake -S "$ARMSX2_ROOT" -B "$ARMSX2_BUILD_DIR" \
    -DCMAKE_BUILD_TYPE="$CONFIGURATION" \
    -DCMAKE_OSX_ARCHITECTURES=arm64 \
    -DCMAKE_OSX_DEPLOYMENT_TARGET=12.0 \
    -DENABLE_QT_UI=OFF \
    -DENABLE_SDL_FRONTEND=OFF \
    -DENABLE_LIBRETRO=ON \
    -DUSE_VULKAN=OFF

echo "Building ARMSX2 libretro..."
BUILD_JOBS="$(sysctl -n hw.ncpu 2>/dev/null || echo 4)"
cmake --build "$ARMSX2_BUILD_DIR" --target armsx2_libretro --config "$CONFIGURATION" -j"$BUILD_JOBS"

LIBRETRO_DYLIB="$(find "$ARMSX2_BUILD_DIR" -type f -name 'armsx2_libretro.dylib' -print -quit)"
[[ -n "$LIBRETRO_DYLIB" ]] || die "ARMSX2 libretro dylib was not produced."

rm -rf "$PLUGIN"
mkdir -p "$PLUGIN/Contents/MacOS" "$RESOURCES/resources"

echo "Compiling ARMSX2 Metal shader libraries..."
export CLANG_MODULE_CACHE_PATH="$ARMSX2_BUILD_DIR/metal-module-cache"
mkdir -p "$CLANG_MODULE_CACHE_PATH"
metal_sources=(cas convert fxaa interlace merge misc present tfx)
for standard in 2.0 2.2 2.3; do
    output="default.metallib"
    [[ "$standard" == "2.2" ]] && output="Metal22.metallib"
    [[ "$standard" == "2.3" ]] && output="Metal23.metallib"

    air_files=()
    for source in "${metal_sources[@]}"; do
        air="$ARMSX2_BUILD_DIR/${source}-${standard}.air"
        "${METAL_TOOL[@]}" -c -std=macos-metal"$standard" -mmacosx-version-min=12.0 \
            -fmodules-cache-path="$CLANG_MODULE_CACHE_PATH" \
            "$METAL_SOURCE_DIR/${source}.metal" -o "$air"
        air_files+=("$air")
    done
    "${METALLIB_TOOL[@]}" "${air_files[@]}" -o "$RESOURCES/resources/$output"
done

echo "Building OpenEmu wrapper..."
xcrun clang++ -dynamiclib -fobjc-arc -std=c++17 \
    -arch arm64 -mmacosx-version-min=12.0 \
    -I"$ARMSX2_ROOT/OpenEmu" \
    -I"$ARMSX2_ROOT/3rdparty/libretro" \
    -I"$REPO_ROOT/OpenEmu/SystemPlugins/PlayStation 2" \
    -F"$PRODUCTS" \
    "$ARMSX2_ROOT/OpenEmu/ARMSX2GameCore.mm" \
    -framework Cocoa -framework Metal -framework OpenEmuBase \
    -o "$PLUGIN/Contents/MacOS/ARMSX2"

cp "$ARMSX2_ROOT/OpenEmu/Info.plist" "$PLUGIN/Contents/Info.plist"
cp "$LIBRETRO_DYLIB" "$RESOURCES/armsx2_libretro.dylib"
if [[ -f "$ARMSX2_ROOT/bin/resources/GameIndex.yaml" ]]; then
    cp "$ARMSX2_ROOT/bin/resources/GameIndex.yaml" "$RESOURCES/GameIndex.yaml"
fi

codesign --force --sign - "$PLUGIN"
codesign --verify --deep --strict "$PLUGIN"

for binary in "$PLUGIN/Contents/MacOS/ARMSX2" "$RESOURCES/armsx2_libretro.dylib"; do
    architectures="$(lipo -archs "$binary")"
    [[ "$architectures" == *"arm64"* ]] || die "Expected arm64 binary: $binary ($architectures)"
done

echo ""
echo "Built ARMSX2 plugin: $PLUGIN"
