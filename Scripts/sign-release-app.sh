#!/usr/bin/env bash
# Sign every code object in a release app with a Developer ID certificate.

set -euo pipefail

[ $# -ge 1 ] || { echo "Usage: $0 <app-path> [identity]" >&2; exit 1; }

APP="$(cd "$(dirname "$1")" && pwd)/$(basename "$1")"
IDENTITY="${2:-Developer ID Application: Marcelo Anhani (TNJWN4AX43)}"
REPO_ROOT="$(cd "$(dirname "$0")/.." && pwd)"
APP_ENTITLEMENTS="$REPO_ROOT/OpenEmu/OpenEmu.entitlements"
HELPER_ENTITLEMENTS="$REPO_ROOT/OpenEmu/OpenEmuHelperApp/OpenEmuHelperApp.entitlements"

[ -d "$APP" ] || { echo "App not found: $APP" >&2; exit 1; }
[ -f "$APP_ENTITLEMENTS" ] || { echo "Missing app entitlements: $APP_ENTITLEMENTS" >&2; exit 1; }
[ -f "$HELPER_ENTITLEMENTS" ] || { echo "Missing helper entitlements: $HELPER_ENTITLEMENTS" >&2; exit 1; }

echo "Signing: $APP"
echo "Identity: $IDENTITY"

# Sign individual Mach-O files first, including loose helper and libretro binaries.
find "$APP" -type f -print0 | while IFS= read -r -d '' item; do
    if file "$item" | grep -q 'Mach-O'; then
        if [ "$(basename "$item")" = "OpenEmuHelperApp" ]; then
            codesign --force --options runtime --timestamp \
                --entitlements "$HELPER_ENTITLEMENTS" --sign "$IDENTITY" "$item"
        else
            codesign --force --options runtime --timestamp --sign "$IDENTITY" "$item"
        fi
    fi
done

# Sign nested bundles from the inside out so their enclosing code seals are valid.
find "$APP/Contents" -type d -depth \( \
    -name '*.framework' -o \
    -name '*.xpc' -o \
    -name '*.app' -o \
    -name '*.oecoreplugin' -o \
    -name '*.oesystemplugin' \
\) -print0 | while IFS= read -r -d '' bundle; do
    codesign --force --options runtime --timestamp --sign "$IDENTITY" "$bundle"
done

codesign --force --options runtime --timestamp \
    --entitlements "$APP_ENTITLEMENTS" --sign "$IDENTITY" "$APP"
codesign --verify --deep --strict "$APP"

echo "Signing and verification completed."
