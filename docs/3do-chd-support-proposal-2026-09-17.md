# 3DO CHD Support Proposal

Date: 2026-09-17

## Status

The native 4DO core remains unchanged for `.cue/.bin` and `.iso`. Opera is now built as a bundled Libretro alternative for `.chd` support.

## Current situation

The native 4DO core currently loads `.cue/.bin` and `.iso` images. The Libretro Opera documentation lists `.chd` as a supported 3DO format, but the native 4DO code has no CHD reader.

The Opera source is vendored under `Opera/` at upstream commit `a501a27`. Its Makefile builds the Libretro core with CHD support for macOS arm64.

## Proposed implementation

1. Keep the native 4DO core for `.cue/.bin` and `.iso`.
2. Build `Opera/opera_libretro.dylib` for arm64.
3. Create `Opera-RetroArch.oecoreplugin` with the bundled Libretro bridge and Opera dylib.
4. Embed the wrapper in `OpenEmu.app/Contents/PlugIns/`.
5. Select Opera from the 3DO core picker when CHD support is needed.
6. Test with a simple single-track 3DO CHD and with a title containing audio or multiple track metadata.

## Risks

- The bundled Opera core must continue to be rebuilt for arm64 as part of the app build.
- CHD track metadata and audio behavior still need runtime testing with real 3DO CHDs.
- Opera's modified LGPL/non-commercial licensing terms must remain included with distributions.

## Reference

Libretro Opera documents `.iso`, `.bin`, `.chd`, and `.cue` as supported extensions:

<https://docs.libretro.com/library/opera/#extensions>
