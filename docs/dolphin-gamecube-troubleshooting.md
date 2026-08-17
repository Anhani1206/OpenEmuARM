# Dolphin GameCube and Wii Troubleshooting

## GameCube core quits immediately

If OpenEmu reports that the **dolphin core has quit unexpectedly** when launching a GameCube game, inspect the installed plugin:

```zsh
plutil -extract CFBundleVersion raw "$HOME/Library/Application Support/OpenEmu/Cores/Dolphin.oecoreplugin/Contents/Info.plist"
plutil -extract OEGameCoreClass raw "$HOME/Library/Application Support/OpenEmu/Cores/Dolphin.oecoreplugin/Contents/Info.plist"
```

The corrected native core reports:

```text
5.0.16211.1
DolphinGameCore
```

An affected development wrapper instead reports a value similar to `libretro-arm64-metal-debug` and the class `OELibretroDolphinGameCore`.

## Cause

The old Dolphin core could crash on the first GameCube boot because its controller interface was initialized after `BootCore` created Dolphin's emulation thread. Dolphin then hit an internal assertion. The native 5.0.16211.1 core initializes input before `BootCore`; this is the fix for [issue #615](https://github.com/nickybmon/OpenEmu-Silicon/issues/615), published in [Emulation Cores v1.3.7](https://github.com/nickybmon/OpenEmu-Silicon/releases/tag/cores-v1.3.7).

## Resolution

Prefer OpenEmu's core updater to install **Dolphin 5.0.16211.1**. If a stale development wrapper remains installed, replace the whole bundle with the official release. The following preserves the previous plugin as a backup:

```zsh
cores_dir="$HOME/Library/Application Support/OpenEmu/Cores"
archive_path="/private/tmp/OpenEmu-Silicon-Dolphin-5.0.16211.1.zip"
staging_dir="$(mktemp -d /private/tmp/dolphin-update.XXXXXX)"

curl --fail --location --output "$archive_path" \
  "https://github.com/nickybmon/OpenEmu-Silicon/releases/download/cores-v1.3.7/Dolphin.oecoreplugin.zip"
osascript -e 'tell application "OpenEmu" to quit'
unzip -q "$archive_path" -d "$staging_dir"
mv "$cores_dir/Dolphin.oecoreplugin" "$cores_dir/Dolphin.oecoreplugin.backup-libretro-debug"
mv "$staging_dir/Dolphin.oecoreplugin" "$cores_dir/Dolphin.oecoreplugin"
codesign --verify --deep --strict "$cores_dir/Dolphin.oecoreplugin"
```

Launch OpenEmu again and test a GameCube game. Keep the backup bundle until the game has started successfully.

## Wii support

Wii uses the same native Dolphin core. The installed core must report both system identifiers:

```zsh
plutil -extract OESystemIdentifiers json -o - \
  "$HOME/Library/Application Support/OpenEmu/Cores/Dolphin.oecoreplugin/Contents/Info.plist"
```

The expected result includes `openemu.system.gc` and `openemu.system.wii`.

OpenEmu ships a separate Wii system plugin inside the app. It declares Wii as a console with optical-disc media, so it appears in the console sidebar and the controller preferences. Existing libraries are migrated once to re-enable Wii if an older build stored it as unavailable. The plugin recognizes Wii disc images in `iso`, `wbfs`, `ciso`, and `rvz` formats, plus `wad` packages. RVZ files are identified from the embedded disc header, so Wii RVZ games are no longer mistaken for GameCube games. On the first launch after this fix, existing GameCube entries are moved to Wii only when that same header proves they are Wii discs; ROM files are not moved or deleted. The Dolphin integration supplies mappings for emulated Wiimote, Nunchuk, Classic Controller, motion controls, and real Wiimotes. Wii remains experimental: test the selected controller setup with each game, especially games that require pointing or motion input.
