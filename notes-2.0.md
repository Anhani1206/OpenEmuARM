# OpenEmuARM 2.0.0

OpenEmuARM 2.0.0 expands the Apple Silicon release with a more complete,
portable, and easier-to-distribute core package.

## What's New

- Expanded the bundled core package so the native cores are available without
  an initial download.
- Added Commodore 64 support through the VICE core.
- Added Neo Geo support with both core options:
  - Geolith for `.neo` ROMs.
  - FBNeo for `.zip` ROMs.
- Added automatic core update checking when the Preferences → Cores window is
  opened.
- Update alerts now show the number of available updates, each core name, and
  the new version.
- Kept optional cores available for installation on demand.
- Updated the application, About screen, and disk image branding to
  OpenEmuARM.

## Fixes

- Fixed bundled cores that were missing or unavailable when the app was opened
  on another Mac.
- Fixed Release packaging for the special cores, including ARMSX2, VICE,
  Geolith, and FBNeo.
- Fixed Neo Geo core selection so the ROM extension determines the appropriate
  core format.
- Fixed the About screen to display the public application version instead of
  the internal build number.
- Renamed the distribution disk image to `OpenEmuARM.dmg`.
- Corrected core update feed URLs to use the OpenEmuARM appcasts.

## Distribution

- Prepared a self-contained Release application with all bundled native cores.
- Release disk image packaging uses the `OpenEmuARM.dmg` name.
- The app remains compatible with macOS 11.0 or later.
