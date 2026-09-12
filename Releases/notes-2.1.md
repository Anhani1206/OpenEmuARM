# What's New in OpenEmuARM 2.1


## Libretro Cheat Database

- Inspired by the work of [@leocck](https://github.com/leocck) in the [OpenEmu-Silicon repository](https://github.com/OpenEmu-Silicon/OpenEmu-Silicon), who added extensive cheat-related features to OpenEmu, including cheat code search, browsing, and the Browse Online Cheats window backed by the Libretro Cheat Database, with per-code status feedback, personal notes, and duplicate cleanup (thanks [@leocck](https://github.com/leocck); see [OpenEmu-Silicon PR #687](https://github.com/OpenEmu-Silicon/OpenEmu-Silicon/pull/687) and [PR #715](https://github.com/OpenEmu-Silicon/OpenEmu-Silicon/pull/715)).
- Added an online cheat browser for supported systems and validated cores.
- Integrated the Libretro Cheat Database (`.cht`) as an online provider.
- Added Libretro metadata lookup using ROM hashes, serial numbers, and game names where appropriate.
- Added local caching so previously downloaded cheats remain available when the network is unavailable.
- Added support for refreshing cached cheat files.
- Added cheat code normalization, deduplication, and core-specific format validation.
- Preserved the existing bundled OpenEmu XML cheat database as a fallback provider.
- Added filtering by cheat name and user feedback states: Working, Not Working, and Not set.
- Added local persistence for imported cheats, feedback, and user notes.
- Restricted the online browser to the validated system/core matrix.
- Added the expanded Mednafen coverage inspired by [OpenEmu-Silicon PR #725](https://github.com/OpenEmu-Silicon/OpenEmu-Silicon/pull/725): Atari Lynx, Neo Geo Pocket/Color, PC Engine/TurboGrafx-16, PC Engine CD/TurboGrafx-CD, PC-FX, Sega Saturn, Virtual Boy, and WonderSwan/Color.
- Added raw provider-code retention in the local cache and feedback records so normalized codes can still be correlated with their original Libretro entries.
- Added validation and normalization for Saturn, PC Engine, and Virtual Boy cheat formats, plus direct WonderSwan ROM-patch handling with restoration when a cheat is disabled.
- Made the online cheat menu available for supported cores that expose online cheats even when their native cheat-code capability is disabled; native “Add Cheat…” remains unavailable in that case.
- The implementation is based on the work in the separate [OpenEmu-Silicon repository](https://github.com/OpenEmu-Silicon/OpenEmu-Silicon); PR #725 is cited as the upstream reference and is not a commit in this repository.

### Validated systems and cores

- Atari 2600 — Stella
- ColecoVision — CrabEmu
- Famicom Disk System — Nestopia
- Game Boy — Gambatte
- Game Boy Color — Gambatte
- Game Boy Advance — mGBA
- Game Gear — GenesisPlus
- Genesis / Mega Drive — GenesisPlus
- Master System — GenesisPlus and CrabEmu
- NES / Famicom — FCEU and Nestopia
- Nintendo 64 — Mupen64Plus
- Nintendo DS — DeSmuME
- PlayStation — Mednafen
- Sega CD — GenesisPlus
- SG-1000 — GenesisPlus
- SNES — BSNES and SNES9x
- Atari Lynx — Mednafen
- Neo Geo Pocket / Color — Mednafen
- PC Engine / TurboGrafx-16 — Mednafen
- PC Engine CD / TurboGrafx-CD — Mednafen
- PC-FX — Mednafen
- Sega Saturn — Mednafen
- Virtual Boy — Mednafen
- WonderSwan / Color — Mednafen


## Fixes

- Fixed bundled core plugins silently failing after their update-feed address was migrated by re-signing the updated plugin bundle.
- Fixed RetroAchievements sign-in for valid usernames and passwords.
- Improved large-library opening and scrolling by retaining fetch/prefetch and coalesced artwork-refresh paths.
- Fixed overlapping labels in the Controls preferences layout.
- Fixed Atari Jaguar's default aspect ratio so games render in landscape.
- Fixed long failed-import alerts by constraining their height and making the message body scrollable.
- Replaced the deprecated library toolbar search field with the OpenEmu search field implementation.
- Added the RetroAchievements hardcore shield visibility preference without disabling other HUD notifications.

- Fixed an issue where the PlayStation 1 window changed from the selected 2x scale to Fit to Window when the game changed resolution.
- The automatic resize triggered by the PlayStation startup logo is now distinguished from a manual window resize.
- The selected integral scale is preserved when the core changes its video resolution.
- Kept the automatically resized PlayStation window inside the visible screen area when a resolution change occurs near a screen edge.

## Bundled core updates

- Updated the bundled Dolphin core.
- Updated the bundled DeSmuME core.
- Updated the bundled GenesisPlus core.
- Updated the bundled mGBA core.
- Updated the bundled Mednafen core.
- Updated the bundled PPSSPP core.
- Updated the bundled Nestopia core.
- Kept all bundled cores inside the application package, including the Apple Silicon ARMSX2 bundle.
- Expanded the Arcade package to include the three validated RetroArch core plugins.

## Update channel

- The app now uses the OpenEmuARM appcast hosted at `https://raw.githubusercontent.com/Anhani1206/OpenEmuARM/main/appcast.xml`.
- Automatic Sparkle checks are enabled so users can be notified about new releases when the app launches.
- Existing OpenEmuARM 2.0.0 installations still require a one-time 2.0.1 migration build, because the already-installed 2.0.0 binary still contains the old upstream appcast URL.
- The 2.0.1 migration build must be published before 2.1.0 so the normal update path is `2.0.0 → 2.0.1 → 2.1.0`.
