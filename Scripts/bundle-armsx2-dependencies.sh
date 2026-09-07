#!/bin/bash
#
# Makes an ARMSX2 core bundle self-contained for distribution.
#
# The PS2 libretro binary is linked on the maintainer machine against
# Homebrew libraries. Those paths do not exist on a clean Mac, so copy the
# full Homebrew dependency closure into the core and rewrite load paths to
# use the bundled copies.
#
# Usage:
#   ./Scripts/bundle-armsx2-dependencies.sh /path/to/ARMSX2.oecoreplugin

set -euo pipefail

if [ "$#" -ne 1 ]; then
    echo "Usage: $0 /path/to/ARMSX2.oecoreplugin" >&2
    exit 2
fi

CORE_BUNDLE="$1"
ROOT_BINARY="$CORE_BUNDLE/Contents/Resources/armsx2_libretro.dylib"
FRAMEWORKS_DIRECTORY="$CORE_BUNDLE/Contents/Frameworks"
HOMEBREW_PREFIXES=("/opt/homebrew/" "/usr/local/")

if [ ! -f "$ROOT_BINARY" ]; then
    echo "error: ARMSX2 libretro binary was not found: $ROOT_BINARY" >&2
    exit 1
fi

mkdir -p "$FRAMEWORKS_DIRECTORY"

dependencies_for() {
    /usr/bin/otool -L "$1" | /usr/bin/sed 1d | /usr/bin/awk '{ print $1 }'
}

homebrew_dependency_path() {
    dependency="$1"
    for prefix in "${HOMEBREW_PREFIXES[@]}"; do
        case "$dependency" in
            "$prefix"*) printf '%s\n' "$dependency"; return 0 ;;
        esac
    done
    return 1
}

# Copy recursively: Homebrew libraries often depend on other Homebrew
# libraries, not only on the ones directly referenced by ARMSX2.
while :; do
    copied_any=0
    scan_list="$(mktemp)"
    printf '%s\n' "$ROOT_BINARY" > "$scan_list"
    /usr/bin/find "$FRAMEWORKS_DIRECTORY" -type f -name '*.dylib' -print >> "$scan_list"

    while IFS= read -r binary; do
        while IFS= read -r dependency; do
            if resolved_dependency="$(homebrew_dependency_path "$dependency")"; then
                    if [ ! -f "$resolved_dependency" ]; then
                        echo "error: required Homebrew library is missing: $dependency" >&2
                        rm -f "$scan_list"
                        exit 1
                    fi

                    destination="$FRAMEWORKS_DIRECTORY/$(basename "$resolved_dependency")"
                    if [ ! -f "$destination" ]; then
                        echo "Bundling $(basename "$resolved_dependency")"
                        /bin/cp -L "$resolved_dependency" "$destination"
                        copied_any=1
                    fi
            elif case "$dependency" in @rpath/*) true;; *) false;; esac; then
                    # Some Homebrew libraries (notably libwebp) reference a
                    # sibling through @rpath instead of an absolute path.
                    # If Homebrew supplies that sibling, bundle it too.
                    candidate=""
                    for prefix in "${HOMEBREW_PREFIXES[@]}"; do
                        candidate="${prefix}lib/$(basename "$dependency")"
                        [ -f "$candidate" ] && break
                        candidate=""
                    done
                    if [ -n "$candidate" ]; then
                        destination="$FRAMEWORKS_DIRECTORY/$(basename "$dependency")"
                        if [ ! -f "$destination" ]; then
                            echo "Bundling $(basename "$dependency")"
                            /bin/cp -L "$candidate" "$destination"
                            copied_any=1
                        fi
                    fi
            fi
        done < <(dependencies_for "$binary")
    done < "$scan_list"
    rm -f "$scan_list"

    [ "$copied_any" -eq 1 ] || break
done

rewrite_homebrew_paths() {
    binary="$1"
    replacement_prefix="$2"

    while IFS= read -r dependency; do
        case "$dependency" in
            "$HOMEBREW_PREFIX"*)
                bundled_name="$(basename "$dependency")"
                /usr/bin/install_name_tool -change "$dependency" "$replacement_prefix/$bundled_name" "$binary"
                ;;
            @rpath/*)
                bundled_name="$(basename "$dependency")"
                if [ -f "$FRAMEWORKS_DIRECTORY/$bundled_name" ]; then
                    /usr/bin/install_name_tool -change "$dependency" "$replacement_prefix/$bundled_name" "$binary"
                fi
                ;;
        esac
    done < <(dependencies_for "$binary")
}

rewrite_homebrew_paths "$ROOT_BINARY" "@loader_path/../Frameworks"

while IFS= read -r library; do
    rewrite_homebrew_paths "$library" "@loader_path"
    /usr/bin/install_name_tool -id "@rpath/$(basename "$library")" "$library"
done < <(/usr/bin/find "$FRAMEWORKS_DIRECTORY" -type f -name '*.dylib' -print)

while IFS= read -r library; do
    if /usr/bin/otool -L "$library" | /usr/bin/sed 1,2d | \
        /usr/bin/grep -E -q '(/opt/homebrew|/usr/local|@rpath/)'; then
        echo "error: ARMSX2 still has an external dependency: $library" >&2
        exit 1
    fi
done < <(/usr/bin/find "$FRAMEWORKS_DIRECTORY" -type f -name '*.dylib' -print)

if /usr/bin/otool -L "$ROOT_BINARY" | /usr/bin/sed 1,2d | \
    /usr/bin/grep -E -q '(/opt/homebrew|/usr/local|@rpath/)'; then
    echo "error: ARMSX2 still references an external dependency." >&2
    exit 1
fi

/usr/bin/codesign --force --deep --sign - "$CORE_BUNDLE"
echo "ARMSX2 dependencies bundled successfully in: $CORE_BUNDLE"
