# App icon

The OpenEmu app icon was replaced with the **Default** export from
`Downloads/Icon Exports/Icon-iOS-Default-1024@1x.png` on 21 August 2026.

The active icon source is the Xcode asset catalog:

`OpenEmu/Graphics.xcassets/OpenEmu.appiconset`

All 28 size, colour-gamut, and dark-appearance variants were regenerated from
that Default image. `OpenEmu/OpenEmu.icns` was also updated for legacy icon
lookups, but the app target uses the asset catalog as its primary icon source.

## Backups

The previous files are retained locally in:

- `Backups/app-icon-before-default-20260821-104226` — legacy `.icns` file.
- `Backups/app-icon-assets-before-default-20260821-105042` — complete previous
  asset-catalog icon set.

After changing an icon, stop and relaunch the app from Xcode. The Dock or Finder
may temporarily retain the old image because macOS caches application icons.
