# 3DO ISO Support

Date: 2026-09-17

## Summary

The native 3DO core now accepts raw `.iso` disc images in addition to the existing `.cue` format.

## Changes

- Added `iso` to the 3DO system plugin file suffixes.
- Allowed the 3DO system controller to validate ISO files using the existing 3DO disc-header checks.
- Updated the 4DO core to open ISO files directly as Mode 1/2048-byte-sector images.
- Kept the existing CUE/BIN loading path intact.
- Added failure checks for unreadable CUE files, invalid CUE track counts, and missing disc-image files.

## Files

- `OpenEmu/SystemPlugins/3DO/3DO-Info.plist`
- `OpenEmu/SystemPlugins/3DO/OE3DOSystemController.m`
- `4DO/FreeDOGameCore.mm`

## Validation

The project was built successfully with Xcode after the changes, with no build errors. Runtime testing with a real 3DO ISO was not performed in this session.

## Limitation

This change does not add `.chd` support. CHD support still requires integrating a CHD reader such as `libchdr` and adapting the sector-reading path.
