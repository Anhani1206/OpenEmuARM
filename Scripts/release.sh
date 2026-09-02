#!/usr/bin/env bash
# release.sh — Full local release: archive → sign → notarize → DMG → appcast → GitHub draft
#
# Usage:
#   ./Scripts/release.sh <version>              # e.g. 1.0.4
#   ./Scripts/release.sh <version> [notes.md]  # optional release notes file
#
# What it does:
#   1. Archives the app with xcodebuild
#   2. Calls notarize.sh (re-sign, notarize, DMG, staple)
#   3. Runs sign_update to get the EdDSA signature
#   4. Prepends a new entry to appcast.xml
#   5. Commits and pushes the updated appcast, cask, notes, and version files
#   6. Tags that exact release commit
#   7. Creates a draft GitHub Release and uploads the DMG
#
# What it does NOT do:
#   - Publish the GitHub Release (stays as draft — you review and publish manually)
#   - Bump version numbers in the Xcode project (do that before running this script)
#
# Requirements:
#   - xcrun notarytool credentials stored: xcrun notarytool store-credentials OpenEmu
#   - gh CLI authenticated: gh auth status
#   - Developer ID cert in your keychain

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(dirname "$SCRIPT_DIR")"
APPCAST="$REPO_ROOT/appcast.xml"
DMG="$REPO_ROOT/Releases/OpenEmuARM.dmg"
IDENTITY="Developer ID Application"

die() { echo ""; echo "ERROR: $*" >&2; exit 1; }
step() { echo ""; echo "══════════════════════════════════════"; echo "  $*"; echo "══════════════════════════════════════"; }

# ── Args ──────────────────────────────────────────────────────────────────────
[ $# -ge 1 ] || die "Usage: $0 <version> [release-notes.md]"
VERSION="$1"
NOTES_FILE="${2:-}"

# Validate version format
[[ "$VERSION" =~ ^[0-9]+\.[0-9]+\.[0-9]+$ ]] || die "Version must be in format X.Y.Z (e.g. 1.0.4)"

# ── Find sign_update ──────────────────────────────────────────────────────────
SIGN_UPDATE=$(find ~/Library/Developer/Xcode/DerivedData \
  -path "*/artifacts/sparkle/Sparkle/bin/sign_update" \
  -not -path "*/old_dsa_scripts/*" \
  2>/dev/null | head -1)

# Fallback: search the repo's SPM cache
if [ -z "$SIGN_UPDATE" ]; then
  SIGN_UPDATE=$(find "$REPO_ROOT" -path "*/Sparkle/bin/sign_update" \
    -not -path "*/old_dsa_scripts/*" 2>/dev/null | head -1)
fi

[ -n "$SIGN_UPDATE" ] || die "sign_update not found. Build the project in Xcode first to resolve the Sparkle package."
echo "sign_update: $SIGN_UPDATE"

# ── Preflight checks ─────────────────────────────────────────────────────────
step "Preflight checks"

# Check notarytool credentials
# Credentials are stored in keychain under the profile name "OpenEmu" from a prior run of:
#   xcrun notarytool store-credentials OpenEmu --apple-id <id> --team-id AJC82Q6789 --password <app-specific-password>
# App-specific passwords are generated at appleid.apple.com → Security → App-Specific Passwords.
# If you see a 403 error here, a Developer Program agreement likely needs re-acceptance at
# appstoreconnect.apple.com (look for a banner at the top of the page).
xcrun notarytool history --keychain-profile "OpenEmu" &>/dev/null \
  || die "No notarytool credentials found. Run: xcrun notarytool store-credentials OpenEmu --apple-id <id> --team-id AJC82Q6789 --password <app-specific-password>"
echo "OK: notarytool credentials"

# Check gh CLI
gh auth status &>/dev/null || die "gh CLI not authenticated. Run: gh auth login"
echo "OK: gh CLI authenticated"

CURRENT_BRANCH=$(git -C "$REPO_ROOT" rev-parse --abbrev-ref HEAD)
RELEASE_BRANCH="chore/release-v$VERSION"
if [ "$CURRENT_BRANCH" = "main" ]; then
  echo "OK: on main — will create release branch $RELEASE_BRANCH"
elif [ "$CURRENT_BRANCH" = "$RELEASE_BRANCH" ]; then
  echo "OK: already on release branch $RELEASE_BRANCH"
else
  die "release.sh must run from main or $RELEASE_BRANCH. Current branch: $CURRENT_BRANCH"
fi

# Check sentry-cli auth. Release builds must upload matching dSYMs so Sentry
# can symbolicate user crashes.
command -v sentry-cli &>/dev/null \
  || die "sentry-cli is not installed. Install with: brew install getsentry/tools/sentry-cli"
sentry-cli info &>/dev/null \
  || die "sentry-cli is not authenticated. Run: sentry-cli login  (or set SENTRY_AUTH_TOKEN env var)"
echo "OK: sentry-cli authenticated"

# Check cert
security find-identity -v | grep -q "Developer ID Application" \
  || die "Developer ID Application certificate not found in keychain."
echo "OK: Developer ID certificate"

# Warn if working tree is dirty (non-appcast files)
DIRTY=$(git -C "$REPO_ROOT" status --porcelain | grep -v "appcast.xml" | grep -v "Releases/" | grep -v "Dolphin/" | grep -v "OpenEmu-Info.plist" | grep -v "project.pbxproj" | grep -v "SECURITY.md" || true)
if [ -n "$DIRTY" ]; then
  echo ""
  echo "WARNING: Working tree has uncommitted changes:"
  echo "$DIRTY"
  echo ""
  read -r -p "Continue anyway? [y/N] " CONFIRM
  [[ "$CONFIRM" =~ ^[Yy]$ ]] || { echo "Aborted."; exit 0; }
fi

# Verify CFBundleVersion in the plist matches the sparkle:version this script
# will write into the appcast. Catches the case where the plist was not bumped
# before running the release script, which causes Sparkle to loop forever.
PLIST="$REPO_ROOT/OpenEmu/OpenEmu-Info.plist"
PLIST_BUILD_VERSION=$(/usr/libexec/PlistBuddy -c "Print CFBundleVersion" "$PLIST" 2>/dev/null || true)
CURRENT_MAX=$(grep -o 'sparkle:version="[0-9]*"' "$APPCAST" | grep -o '[0-9]*' | sort -n | tail -1)
NEXT_VERSION=$((CURRENT_MAX + 1))

if [ "$PLIST_BUILD_VERSION" != "$NEXT_VERSION" ]; then
  die "CFBundleVersion mismatch.
  OpenEmu-Info.plist has CFBundleVersion = \"$PLIST_BUILD_VERSION\"
  appcast.xml will write sparkle:version = \"$NEXT_VERSION\"
  These must match or Sparkle will offer the update in a loop.
  Fix: set CFBundleVersion to $NEXT_VERSION in OpenEmu-Info.plist before running this script."
fi
echo "OK: CFBundleVersion ($PLIST_BUILD_VERSION) matches next sparkle:version ($NEXT_VERSION)"

# ── 1. Archive ────────────────────────────────────────────────────────────────
step "1/5  Archiving OpenEmu (Release)"

ARCHIVE_PATH="$HOME/Library/Developer/Xcode/Archives/$(date +%Y-%m-%d)/OpenEmu-Silicon-$VERSION.xcarchive"
mkdir -p "$(dirname "$ARCHIVE_PATH")"

xcodebuild archive \
  -workspace "$REPO_ROOT/OpenEmu-metal.xcworkspace" \
  -scheme OpenEmu \
  -configuration Release \
  -destination generic/platform=macOS \
  -archivePath "$ARCHIVE_PATH" \
  CODE_SIGN_IDENTITY="$IDENTITY" \
  CODE_SIGN_STYLE=Manual \
  DEVELOPMENT_TEAM=AJC82Q6789 \
  ENABLE_HARDENED_RUNTIME=YES \
  2>&1 | grep -E "^(Archive|error:|warning:|BUILD)" | tail -20

[ -d "$ARCHIVE_PATH" ] || die "Archive not found at expected path: $ARCHIVE_PATH"
echo "Archive: $ARCHIVE_PATH"

# ARMSX2 is built outside the main OpenEmu scheme. Stage it explicitly and
# make its Homebrew dependencies portable before the notarization pipeline.
step "Bundling portable PlayStation 2 core"

APP_IN_ARCHIVE="$ARCHIVE_PATH/Products/Applications/OpenEmu.app"
ARMSX2_DESTINATION="$APP_IN_ARCHIVE/Contents/PlugIns/Cores/ARMSX2.oecoreplugin"
PS2_SYSTEM_PLUGIN="$APP_IN_ARCHIVE/Contents/PlugIns/Systems/PlayStation 2.oesystemplugin"

# These core bundles are staged inside the app, then copied to Application
# Support on first launch. This keeps a fresh installation independent of
# appcasts and network access.
BUNDLED_CORE_REFRESH_REVISION="${BUNDLED_CORE_REFRESH_REVISION:-20260901.1}"

stamp_bundled_core() {
  local core_path="$1"
  local plist="$core_path/Contents/Info.plist"
  /usr/libexec/PlistBuddy -c "Delete :OEBundledCoreRefreshRevision" "$plist" 2>/dev/null || true
  /usr/libexec/PlistBuddy -c "Add :OEBundledCoreRefreshRevision string $BUNDLED_CORE_REFRESH_REVISION" "$plist"
}

stage_xcode_core() {
  local project="$1"
  local scheme="$2"
  local bundle_name="$3"
  local derived_data="$4"
  local source="$derived_data/Build/Products/Release/$bundle_name.oecoreplugin"
  local destination="$APP_IN_ARCHIVE/Contents/PlugIns/Cores/$bundle_name.oecoreplugin"
  local build_setting_args=()

  if [ -n "${FRAMEWORK_SEARCH_PATHS:-}" ]; then
    build_setting_args+=("FRAMEWORK_SEARCH_PATHS=$FRAMEWORK_SEARCH_PATHS")
  fi
  if [ -n "${HEADER_SEARCH_PATHS:-}" ]; then
    build_setting_args+=("HEADER_SEARCH_PATHS=$HEADER_SEARCH_PATHS")
  fi
  if [ -n "${CORE_MACOS_DEPLOYMENT_TARGET:-}" ]; then
    build_setting_args+=("MACOSX_DEPLOYMENT_TARGET=$CORE_MACOS_DEPLOYMENT_TARGET")
  fi
  if [ -n "${CORE_EXCLUDED_SOURCE_FILE_NAMES:-}" ]; then
    build_setting_args+=("EXCLUDED_SOURCE_FILE_NAMES=$CORE_EXCLUDED_SOURCE_FILE_NAMES")
  fi

  local build_status=0
  local build_log="/tmp/OpenEmu-${scheme}-Release-build.log"
  xcodebuild \
    -project "$REPO_ROOT/$project" \
    -scheme "$scheme" \
    -configuration Release \
    -derivedDataPath "$derived_data" \
    -destination 'platform=macOS,arch=arm64' \
    "${build_setting_args[@]}" build > "$build_log" 2>&1 || build_status=$?
  cat "$build_log"

  if [ "$build_status" -ne 0 ] && [ "$scheme" = "PPSSPP" ]; then
    # The flattened PPSSPP project omits glew.c from its target. Xcode still
    # produces every static library, so finish the bundle with the original
    # linker command plus a locally compiled arm64 GLEW object.
    local ppsspp_root="$REPO_ROOT/PPSSPP/PPSSPP-Core/ppsspp"
    local glew_object="$derived_data/glew-arm64.o"
    clang -c -arch arm64 -mmacosx-version-min=12.0 \
      -I"$ppsspp_root/ext/glew" \
      -isysroot "$(xcrun --sdk macosx --show-sdk-path)" \
      "$ppsspp_root/ext/glew/glew.c" -o "$glew_object"
    local link_line
    link_line="$(sed -n '/clang++ -Xlinker -reproducible/ p' "$build_log" | tail -1)"
    [ -n "$link_line" ] || die "PPSSPP linker command was not captured."
    link_line="$(printf '%s' "$link_line" | sed 's/^[[:space:]]*//; s# -Xlinker -no_adhoc_codesign# '"$glew_object"' -Xlinker -no_adhoc_codesign#')"
    (cd "$REPO_ROOT/PPSSPP/PPSSPP-Core" && eval "$link_line") \
      || die "PPSSPP Release relink failed."
  elif [ "$build_status" -ne 0 ]; then
    die "Release build failed for $scheme."
  fi

  [ -d "$source" ] || die "Release core was not produced: $source"
  rm -rf "$destination"
  mkdir -p "$(dirname "$destination")"
  ditto "$source" "$destination"
  stamp_bundled_core "$destination"
  codesign --force --deep --sign - "$destination"
  codesign --verify --deep --strict "$destination" \
    || die "$bundle_name core failed codesign verification."
  echo "OK: $bundle_name core staged in archive"
}

[ -d "$APP_IN_ARCHIVE" ] || die "OpenEmu.app not found inside archive."
[ -d "$PS2_SYSTEM_PLUGIN" ] || die "PlayStation 2 system plugin is missing from archive."

step "Bundling 4DO core"
OPENEMU_SDK_DERIVED_DATA="${OPENEMU_SDK_DERIVED_DATA:-/tmp/OpenEmu-SDK-Release-DD}"
xcodebuild \
  -project "$REPO_ROOT/OpenEmu-SDK/OpenEmu-SDK.xcodeproj" \
  -scheme OpenEmuBase \
  -configuration Release \
  -derivedDataPath "$OPENEMU_SDK_DERIVED_DATA" \
  -destination 'platform=macOS,arch=arm64' build

OPENEMU_BASE_PRODUCTS="$OPENEMU_SDK_DERIVED_DATA/Build/Products/Release"
[ -d "$OPENEMU_BASE_PRODUCTS/OpenEmuBase.framework" ] \
  || die "OpenEmuBase Release framework was not produced."

FOURDO_DERIVED_DATA="${FOURDO_DERIVED_DATA:-/tmp/OpenEmu-4DO-DD}"
FRAMEWORK_SEARCH_PATHS="$OPENEMU_BASE_PRODUCTS" \
  HEADER_SEARCH_PATHS="$REPO_ROOT/OpenEmu-SDK" \
  stage_xcode_core "4DO/4DO.xcodeproj" "4DO" "4DO" "$FOURDO_DERIVED_DATA"

step "Bundling Mupen64Plus core"
MUPEN64PLUS_DERIVED_DATA="${MUPEN64PLUS_DERIVED_DATA:-/tmp/OpenEmu-Mupen64Plus-DD}"
FRAMEWORK_SEARCH_PATHS="$OPENEMU_BASE_PRODUCTS" \
  stage_xcode_core "Mupen64Plus/Mupen64Plus.xcodeproj" "Mupen64Plus" "Mupen64Plus" "$MUPEN64PLUS_DERIVED_DATA"

# The main application target only embeds the libretro bridge. Every native
# core must therefore be built and staged explicitly for an offline DMG.
# Pokémon Mini is intentionally absent from the offline distribution.
NATIVE_CORE_SPECS=(
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
  "Picodrive|Picodrive|Picodrive"
  "SNES9x|SNES9x|SNES9x"
  "BSNES|BSNES|BSNES"
  "VecXGL|VecXGL|VecXGL"
  "Potator-Core|Potator|Potator"
  "DeSmuME/src/frontend/cocoa/DeSmuME (Latest)|DeSmuME|DeSmuME"
  "PPSSPP/PPSSPP-Core|PPSSPP|PPSSPP"
)

for core_spec in "${NATIVE_CORE_SPECS[@]}"; do
  IFS='|' read -r core_project core_scheme core_bundle <<< "$core_spec"
  step "Bundling $core_bundle core"
  core_derived_data="${CORE_DERIVED_DATA_ROOT:-/tmp/OpenEmu-Native-Cores-DD}/$core_bundle"
  CORE_MACOS_DEPLOYMENT_TARGET=""
  HEADER_SEARCH_PATHS=""
  CORE_EXCLUDED_SOURCE_FILE_NAMES=""
  if [ "$core_bundle" = "PPSSPP" ]; then
    CORE_MACOS_DEPLOYMENT_TARGET="12.0"
    PPSSPP_ROOT="$REPO_ROOT/PPSSPP/PPSSPP-Core/ppsspp"
    mkdir -p "$PPSSPP_ROOT/assets/flash0"
    touch "$PPSSPP_ROOT/assets/flash0/.empty"
    cat > "$PPSSPP_ROOT/git-version.cpp" <<'EOF'
// Generated for the flattened OpenEmu PPSSPP source tree.
const char *PPSSPP_GIT_VERSION = "openemu-bundled";
EOF
    HEADER_SEARCH_PATHS="$PPSSPP_ROOT/ext/glew $PPSSPP_ROOT/ext/openxr/include $PPSSPP_ROOT $PPSSPP_ROOT/Common $PPSSPP_ROOT/ext/libpng17 $PPSSPP_ROOT/ext/snappy $PPSSPP_ROOT/ext/glslang $PPSSPP_ROOT/ext/zstd/lib $PPSSPP_ROOT/ext/armips $PPSSPP_ROOT/ext/armips/ext/tinyformat $PPSSPP_ROOT/ext/armips/ext/filesystem/include $PPSSPP_ROOT/ffmpeg/macosx/universal/include $REPO_ROOT/OpenEmu/SystemPlugins/PSP $REPO_ROOT/OpenEmu-SDK"
    CORE_EXCLUDED_SOURCE_FILE_NAMES="gl3stub.c"
  fi
  FRAMEWORK_SEARCH_PATHS="$OPENEMU_BASE_PRODUCTS" \
    HEADER_SEARCH_PATHS="$HEADER_SEARCH_PATHS" \
    CORE_EXCLUDED_SOURCE_FILE_NAMES="$CORE_EXCLUDED_SOURCE_FILE_NAMES" \
    stage_xcode_core "$core_project/$core_scheme.xcodeproj" "$core_scheme" "$core_bundle" "$core_derived_data"
done

CONFIGURATION=Release "$SCRIPT_DIR/build-armsx2-libretro-arm64.sh"
ARMSX2_SOURCE="${DERIVED_DATA:-/tmp/OpenEmu-Shared-DD}/Build/Products/Release/ARMSX2.oecoreplugin"
[ -d "$ARMSX2_SOURCE" ] || die "ARMSX2 Release core was not produced."

rm -rf "$ARMSX2_DESTINATION"
mkdir -p "$(dirname "$ARMSX2_DESTINATION")"
ditto "$ARMSX2_SOURCE" "$ARMSX2_DESTINATION"
"$SCRIPT_DIR/bundle-armsx2-dependencies.sh" "$ARMSX2_DESTINATION"
stamp_bundled_core "$ARMSX2_DESTINATION"

if otool -L "$ARMSX2_DESTINATION/Contents/Resources/armsx2_libretro.dylib" | grep -q '/opt/homebrew'; then
  die "ARMSX2 still references Homebrew after bundling."
fi
echo "OK: portable ARMSX2 core staged in archive"

# FBNeo is built outside the OpenEmu application target as well. Without this
# step a clean Release archive contains the app but loses the native Arcade
# and Neo Geo core.
step "Bundling portable FBNeo core"

FBNEO_DERIVED_DATA="${FBNEO_DERIVED_DATA:-/tmp/OpenEmu-FBNeo-DD}"
CONFIGURATION=Release DERIVED_DATA="$FBNEO_DERIVED_DATA" \
  "$SCRIPT_DIR/build-fbneo-openemu-arm64.sh"
FBNEO_SOURCE="$FBNEO_DERIVED_DATA/Build/Products/Release/FBNeo.oecoreplugin"
FBNEO_DESTINATION="$APP_IN_ARCHIVE/Contents/PlugIns/Cores/FBNeo.oecoreplugin"

[ -d "$FBNEO_SOURCE" ] || die "FBNeo Release core was not produced."
rm -rf "$FBNEO_DESTINATION"
mkdir -p "$(dirname "$FBNEO_DESTINATION")"
ditto "$FBNEO_SOURCE" "$FBNEO_DESTINATION"
stamp_bundled_core "$FBNEO_DESTINATION"
codesign --force --deep --sign - "$FBNEO_DESTINATION"
codesign --verify --deep --strict "$FBNEO_DESTINATION" \
  || die "FBNeo core failed codesign verification."
echo "OK: portable FBNeo core staged in archive"

# Commodore 64 is bundled through the VICE libretro engine. The dylib and its
# embedded machine data are copied into the app, so a user does not need
# RetroArch, Appcast access, or a separate core download.
step "Bundling portable VICE core"

VICE_DERIVED_DATA="${VICE_DERIVED_DATA:-/tmp/OpenEmu-VICE-DD}"
OPENEMU_LIBRETRO_BRIDGE="$APP_IN_ARCHIVE/Contents/PlugIns/OpenEmuLibretroBridge.oecoreplugin/Contents/MacOS/OpenEmuLibretroBridge" \
  DERIVED_DATA="$VICE_DERIVED_DATA" \
  "$SCRIPT_DIR/build-vice-openemu-arm64.sh"
VICE_SOURCE="$VICE_DERIVED_DATA/Build/Products/Release/VICE.oecoreplugin"
VICE_DESTINATION="$APP_IN_ARCHIVE/Contents/PlugIns/Cores/VICE.oecoreplugin"

[ -d "$VICE_SOURCE" ] || die "VICE Release core was not produced."
rm -rf "$VICE_DESTINATION"
mkdir -p "$(dirname "$VICE_DESTINATION")"
ditto "$VICE_SOURCE" "$VICE_DESTINATION"
stamp_bundled_core "$VICE_DESTINATION"
codesign --force --deep --sign - "$VICE_DESTINATION"
codesign --verify --deep --strict "$VICE_DESTINATION" \
  || die "VICE core failed codesign verification."
echo "OK: portable VICE core staged in archive"

# Geolith is an external libretro core, so it has no Xcode project in this
# workspace. Build it from the official source and package it as a relative,
# self-contained plugin for the Release archive.
step "Bundling portable Geolith core"

GEOLITH_DERIVED_DATA="${GEOLITH_DERIVED_DATA:-/tmp/OpenEmu-Geolith-DD}"
OPENEMU_LIBRETRO_BRIDGE="$APP_IN_ARCHIVE/Contents/PlugIns/OpenEmuLibretroBridge.oecoreplugin/Contents/MacOS/OpenEmuLibretroBridge" \
  DERIVED_DATA="$GEOLITH_DERIVED_DATA" \
  "$SCRIPT_DIR/build-geolith-openemu-arm64.sh"
GEOLITH_SOURCE="$GEOLITH_DERIVED_DATA/Build/Products/Release/Geolith-RetroArch.oecoreplugin"
GEOLITH_DESTINATION="$APP_IN_ARCHIVE/Contents/PlugIns/Cores/Geolith-RetroArch.oecoreplugin"

[ -d "$GEOLITH_SOURCE" ] || die "Geolith Release core was not produced."
rm -rf "$GEOLITH_DESTINATION"
mkdir -p "$(dirname "$GEOLITH_DESTINATION")"
ditto "$GEOLITH_SOURCE" "$GEOLITH_DESTINATION"
stamp_bundled_core "$GEOLITH_DESTINATION"
codesign --force --deep --sign - "$GEOLITH_DESTINATION"
codesign --verify --deep --strict "$GEOLITH_DESTINATION" \
  || die "Geolith core failed codesign verification."
echo "OK: portable Geolith core staged in archive"

# ── 1.5. Verify and upload dSYMs to Sentry ────────────────────────────────────
step "Verifying and uploading dSYMs to Sentry (symbolicated crash reports)"

DERIVED_DATA=$(ls -td ~/Library/Developer/Xcode/DerivedData/OpenEmu-metal-* 2>/dev/null | head -1 || true)
SYMBOL_ARGS=(
  --upload
  --wait-for 120
  --binary-root "$ARCHIVE_PATH/Products/Applications/OpenEmu.app"
  --dsym-root "$ARCHIVE_PATH/dSYMs"
  --generated-dsym-root "$ARCHIVE_PATH/dSYMs/Generated"
)
if [ -n "$DERIVED_DATA" ]; then
  # Includes dSYMs supplied by binary dependencies such as Sentry's xcframework.
  SYMBOL_ARGS+=(--dsym-root "$DERIVED_DATA")
fi

"$SCRIPT_DIR/verify-sentry-symbols.sh" "${SYMBOL_ARGS[@]}"

# ── 1.6. Register release in Sentry ──────────────────────────────────────────
# Sentry uses this marker to show "First seen in vX.Y.Z" on issues, link
# suspect commits between the previous tag and HEAD, and track per-release
# crash-free session rates. The release name must match options.releaseName
# in SentryService.swift exactly: "openemu-silicon@<version>+<build>".
step "Registering release marker in Sentry"

SENTRY_RELEASE="openemu-silicon@${VERSION}+${PLIST_BUILD_VERSION}"
sentry-cli releases new "$SENTRY_RELEASE" \
  --org openemu-silicon --project openemu-silicon \
  || echo "WARNING: sentry-cli releases new failed — Sentry crash tracking will work but release metadata won't show."
sentry-cli releases set-commits "$SENTRY_RELEASE" --auto \
  --org openemu-silicon --project openemu-silicon \
  || echo "WARNING: sentry-cli releases set-commits failed — suspect commit linking won't work for this release."
sentry-cli releases finalize "$SENTRY_RELEASE" \
  --org openemu-silicon --project openemu-silicon \
  || echo "WARNING: sentry-cli releases finalize failed."
echo "OK: Sentry release marker: $SENTRY_RELEASE"

# ── 2. Notarize (re-sign + notarize + DMG + staple) ──────────────────────────
step "2/5  Re-signing, notarizing, and creating DMG"

"$SCRIPT_DIR/notarize.sh" "$ARCHIVE_PATH"

[ -f "$DMG" ] || die "DMG not found at $DMG after notarize.sh. Check notarize.sh output above."

# ── 2.5. Update Homebrew cask ─────────────────────────────────────────────────
step "2.5/5  Updating Homebrew cask (Casks/openemu-silicon.rb)"

CASK_FILE="$REPO_ROOT/Casks/openemu-silicon.rb"
DMG_SHA256=$(shasum -a 256 "$DMG" | awk '{print $1}')
echo "DMG SHA256: $DMG_SHA256"

# Update version and sha256 in the cask file
sed -i '' "s/version \"[^\"]*\"/version \"$VERSION\"/" "$CASK_FILE"
sed -i '' "s/sha256 \"[^\"]*\"/sha256 \"$DMG_SHA256\"/" "$CASK_FILE"
echo "Updated $CASK_FILE → version $VERSION, sha256 $DMG_SHA256"

# ── 3. Sign for Sparkle ───────────────────────────────────────────────────────
step "3/5  Generating Sparkle EdDSA signature"

SIGN_OUTPUT=$("$SIGN_UPDATE" "$DMG" 2>&1)
echo "$SIGN_OUTPUT"

ED_SIG=$(echo "$SIGN_OUTPUT" | grep -o 'sparkle:edSignature="[^"]*"' | cut -d'"' -f2)
DMG_LENGTH=$(echo "$SIGN_OUTPUT" | grep -o 'length="[0-9]*"' | cut -d'"' -f2)

[ -n "$ED_SIG" ]    || die "Could not parse edSignature from sign_update output."
[ -n "$DMG_LENGTH" ] || die "Could not parse length from sign_update output."

echo "edSignature: $ED_SIG"
echo "length:      $DMG_LENGTH"

# ── 4. Update appcast.xml ─────────────────────────────────────────────────────
step "4/5  Updating appcast.xml"

# NEXT_VERSION was already computed and validated in the preflight check above.
PUB_DATE=$(date -u "+%a, %d %b %Y %H:%M:%S +0000")

if [ -z "$NOTES_FILE" ] || [ ! -f "$NOTES_FILE" ]; then
  echo "NOTE: No release notes file provided. Appcast entry will contain a placeholder."
  echo "      Edit appcast.xml before publishing, or re-run with: $0 $VERSION path/to/notes.md"
fi

# Prepend new <item> to appcast.xml
python3 "$SCRIPT_DIR/update_appcast.py" \
  "$APPCAST" "$VERSION" "$NEXT_VERSION" "$PUB_DATE" "$ED_SIG" "$DMG_LENGTH" \
  ${NOTES_FILE:+"$NOTES_FILE"}

# ── 5. Commit to release branch, open PR, tag, and create GitHub draft release ─
step "5/5  Committing release metadata, opening PR, and creating GitHub draft release"

TAG="v$VERSION"

# Switch to (or create) the release branch so the commit goes through PR review
# rather than landing directly on main. CI lint and version checks run on the PR.
if [ "$CURRENT_BRANCH" = "main" ]; then
  git -C "$REPO_ROOT" checkout -b "$RELEASE_BRANCH"
fi

# Stage all release metadata files
git -C "$REPO_ROOT" add "$APPCAST" "$CASK_FILE" \
  "OpenEmu/OpenEmu-Info.plist" \
  "OpenEmu/OpenEmu.xcodeproj/project.pbxproj" \
  ".github/SECURITY.md"
if [ ! -f "$REPO_ROOT/Releases/notes-${VERSION}.md" ]; then
  die "Release notes not found: Releases/notes-${VERSION}.md — run prep-release first."
fi
git -C "$REPO_ROOT" add -f "Releases/notes-${VERSION}.md"
if git -C "$REPO_ROOT" diff --cached --quiet; then
  echo "No release metadata changes to commit; using current HEAD."
else
  git -C "$REPO_ROOT" commit -m "chore: release v$VERSION — update appcast, cask, and version bump"
fi

# Push the release branch
git -C "$REPO_ROOT" push -u origin "$RELEASE_BRANCH"

# Tag the release commit so the GitHub Release download URL is valid immediately.
# The tag points at this branch commit; after PR merges it remains reachable from main.
if git -C "$REPO_ROOT" tag -l | grep -qx "$TAG"; then
  TAG_TARGET=$(git -C "$REPO_ROOT" rev-list -n 1 "$TAG")
  HEAD_TARGET=$(git -C "$REPO_ROOT" rev-parse HEAD)
  [ "$TAG_TARGET" = "$HEAD_TARGET" ] || die "Tag $TAG already exists but does not point at HEAD. Delete or move it manually before continuing."
else
  echo "Creating git tag $TAG..."
  git -C "$REPO_ROOT" tag "$TAG"
fi
echo "Pushing tag $TAG..."
git -C "$REPO_ROOT" push origin "$TAG"

# Build release notes body for GitHub (use notes file if provided, else placeholder)
if [ -n "$NOTES_FILE" ] && [ -f "$NOTES_FILE" ]; then
  GH_NOTES_ARGS=(--notes-file "$NOTES_FILE")
else
  GH_NOTES_ARGS=(--notes "Release notes — edit before publishing.")
fi

# Create or update GitHub draft release
if gh release view "$TAG" --repo Anhani1206/OpenEmuARM &>/dev/null; then
  echo "Release $TAG already exists — uploading DMG and updating notes..."
  gh release upload "$TAG" "$DMG" \
    --repo Anhani1206/OpenEmuARM \
    --clobber
  gh release edit "$TAG" \
    --repo Anhani1206/OpenEmuARM \
    "${GH_NOTES_ARGS[@]}"
else
  echo "Creating draft release $TAG..."
  gh release create "$TAG" "$DMG" \
    --repo Anhani1206/OpenEmuARM \
    --title "OpenEmu-Silicon $VERSION" \
    --draft \
    "${GH_NOTES_ARGS[@]}"
fi

echo "DMG uploaded to draft release $TAG."

# Open a draft PR so CI version checks run before the appcast lands on main
PR_NOTES=""
if [ -n "$NOTES_FILE" ] && [ -f "$NOTES_FILE" ]; then
  PR_NOTES=$(cat "$NOTES_FILE")
fi

PR_URL=$(gh pr create \
  --repo Anhani1206/OpenEmuARM \
  --base main \
  --head "$RELEASE_BRANCH" \
  --draft \
  --title "chore: release v$VERSION" \
  --body "## Release v$VERSION

This PR lands the appcast update, Homebrew cask, and version files for v$VERSION. Merging makes the Sparkle update live for existing users.

**Before merging:**
- [ ] CI build check passes
- [ ] Draft GitHub Release reviewed — notes look good
- [ ] DMG tested (launch, quick smoke, check version in About)

**After merging:**
Publish the GitHub Release:
\`\`\`
gh release edit $TAG --draft=false --repo Anhani1206/OpenEmuARM
\`\`\`

---
${PR_NOTES}")

echo ""
echo "╔══════════════════════════════════════════════════════╗"
echo "║  Release $VERSION prepared — review PR then publish  ║"
echo "╚══════════════════════════════════════════════════════╝"
echo ""
echo "  DMG:    $DMG"
echo "  Tag:    $TAG (pushed — download URL is live)"
echo "  PR:     $PR_URL"
echo "  Draft:  https://github.com/Anhani1206/OpenEmuARM/releases/tag/$TAG"
echo ""
echo "  Next steps:"
echo "  1. Let CI run on the PR — check for version lint failures"
echo "  2. Review draft release notes on GitHub"
echo "  3. Test the DMG"
echo "  4. Merge the PR (makes appcast live for Sparkle)"
echo "  5. Publish the GitHub Release:"
echo "     gh release edit $TAG --draft=false --repo Anhani1206/OpenEmuARM"
echo ""
