#!/usr/bin/env bash
set -euo pipefail

# Neo Geo uses the same arcade ROM and input contract as MAME.  The system
# plugin must therefore include the complete Arcade responder implementation,
# not a lightweight controller-only replacement.  Build a distinct Neo Geo
# plugin by cloning the Arcade plugin produced by the same Xcode build.

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
WORKSPACE_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
CONFIGURATION="${1:-Debug}"
DERIVED_DATA="${DERIVED_DATA:-/tmp/OpenEmu-Shared-DD}"
OUTPUT_DIR="${OUTPUT_DIR:-$DERIVED_DATA/Build/Products/$CONFIGURATION}"
ARCADE_PLUGIN="$OUTPUT_DIR/Arcade.oesystemplugin"
SOURCE_NEOGEO_PLUGIN="$OUTPUT_DIR/NeoGeo.oesystemplugin"
NEOGEO_PLUGIN="$OUTPUT_DIR/NeoGeo-ArcadeResponder.oesystemplugin"
OPENEMU_APP_OVERRIDE="${OPENEMU_APP:-}"
OPENEMU_APP="${OPENEMU_APP_OVERRIDE:-$OUTPUT_DIR/OpenEmu.app}"

if [[ ! -d "$ARCADE_PLUGIN" ]]; then
    DETECTED_ARCADE="$(find "$HOME/Library/Developer/Xcode/DerivedData" \
        ! -path '*/Index.noindex/*' \
        -path "*/Build/Products/$CONFIGURATION/Arcade.oesystemplugin" \
        -type d -print -quit 2>/dev/null || true)"
    if [[ -z "$DETECTED_ARCADE" ]]; then
        echo "Arcade.oesystemplugin was not found at: $ARCADE_PLUGIN" >&2
        echo "Build the OpenEmu target in $CONFIGURATION first." >&2
        exit 66
    fi

    ARCADE_PLUGIN="$DETECTED_ARCADE"
    OUTPUT_DIR="$(dirname "$ARCADE_PLUGIN")"
    SOURCE_NEOGEO_PLUGIN="$OUTPUT_DIR/NeoGeo.oesystemplugin"
    NEOGEO_PLUGIN="$OUTPUT_DIR/NeoGeo-ArcadeResponder.oesystemplugin"
    OPENEMU_APP="${OPENEMU_APP_OVERRIDE:-$OUTPUT_DIR/OpenEmu.app}"
fi

rm -rf "$NEOGEO_PLUGIN"
ditto "$ARCADE_PLUGIN" "$NEOGEO_PLUGIN"

PLIST="$NEOGEO_PLUGIN/Contents/Info.plist"
PLIST_BUDDY=/usr/libexec/PlistBuddy
"$PLIST_BUDDY" -c 'Set :CFBundleIdentifier org.openemu.NeoGeo' "$PLIST"
"$PLIST_BUDDY" -c 'Set :CFBundleName NeoGeo' "$PLIST"
"$PLIST_BUDDY" -c 'Set :OESystemIdentifier openemu.system.neogeo' "$PLIST"
"$PLIST_BUDDY" -c 'Set :OESystemName Neo Geo' "$PLIST"
"$PLIST_BUDDY" -c 'Set :OENumberOfPlayersKey 4' "$PLIST"
"$PLIST_BUDDY" -c 'Set :OESystemIcon neogeo_icon' "$PLIST"
# Neo Geo cartridge images are handled by the Geolith RetroArch core.
"$PLIST_BUDDY" -c 'Add :OEFileSuffixes:1 string neo' "$PLIST"

# Keep the purpose-built Neo Geo artwork while retaining Arcade's executable,
# controller responder and mapping resources.
if [[ -f "$SOURCE_NEOGEO_PLUGIN/Contents/Resources/Assets.car" ]]; then
    cp -f "$SOURCE_NEOGEO_PLUGIN/Contents/Resources/Assets.car" \
        "$NEOGEO_PLUGIN/Contents/Resources/Assets.car"
fi

plutil -lint "$PLIST"
codesign --force --deep --sign - "$NEOGEO_PLUGIN"

if [[ -d "$OPENEMU_APP" ]]; then
    APP_PLUGIN="$OPENEMU_APP/Contents/PlugIns/Systems/NeoGeo.oesystemplugin"
    rm -rf "$APP_PLUGIN"
    mv "$NEOGEO_PLUGIN" "$APP_PLUGIN"
    codesign --force --deep --sign - "$APP_PLUGIN"
    echo "Installed Neo Geo system plugin into $OPENEMU_APP"
else
    echo "Built $NEOGEO_PLUGIN"
fi
