# OpenEmuARM — Native Apple Silicon Port

<p align="center">
  <img width="500" height="240" alt="logo" src="https://github.com/Anhani1206/OpenEmuARM/blob/80f1525045d8a1c0c98b022684b35ba1c317edc9/docs/images/Logo.png" />
</p>

<p align="center">
  <img width="2276" height="1550" alt="OpenEmu Library" src="https://github.com/Anhani1206/OpenEmuARM/blob/21d31e40a35a31ddf473406fd51a81a8153898aa/Screenshot%202026-08-18%20at%2011.33.31.png" />
</p>

<p align="center">
  <img width="2276" height="1550" alt="OpenEmu Library" src="https://github.com/Anhani1206/OpenEmuARM/blob/540858c62f8c0471a01924830d9efcdb086996e8/Screenshot%202026-08-20%20at%2014.20.33.png" />
</p>

---

## Project Notice

This project is developed as a personal hobby in my free time.

It is completely free to use and is not intended for commercial purposes. I do not make money from this project, nor do I receive any financial compensation for its development, maintenance, or distribution.

I maintain this project because I enjoy working on it and because I hope it can be useful to others in the community.

Since this is a hobby project maintained in my spare time, updates, bug fixes, new features, and support are provided on a best-effort basis and may not follow a fixed schedule.

There are no commercial commitments or guarantees regarding continued development, compatibility, availability, or support.

Contributions, suggestions, bug reports, and constructive feedback are always welcome.

Thank you for using and supporting the project.


## Current Status

**Actively maintained. Runs natively on Apple Silicon (no Rosetta required).**

This is a community-maintained fork of OpenEmu for M-series Macs. The app runs on 26.0+ (Tahoe) and has been tested on macOS 27 (Golden Gate).

---

### Download

Get the latest signed DMG from the [Releases page](https://github.com/Anhani1206/OpenEmuARM/releases). The app is notarized — no Gatekeeper workaround needed.
Download

---

### Recent Updates OpenEmuARM 2.1.3

- Added Move to System… to the game context menu, allowing a ROM that was detected under the wrong console to be reassigned to the correct system. ROMs already inside the Game Library are moved to the selected system folder; external ROMs are reclassified without being copied or deleted.
- Improved 3DO ISO detection to support both CD-ROM and CD_ROM disc-header signatures, allowing fan-made releases such as MK2 V12.iso to be imported as 3DO games.
Added Help → What's New so the 2.1.3 highlights can be reviewed again after the first launch.
- Fixed Quit Game for ARMSX2/PlayStation 2 so the game window closes after a single confirmation instead of requiring a second click.

---

## Supported Systems

> **Full details — working status, known issues, in-progress cores, and what's planned — are on the [Supported Systems](https://github.com/anhani1206/OpenEmuARM/wiki/Supported-Systems) wiki page.**

Quick summary: 30+ systems work today, including NES, SNES, Game Boy, GBA, N64, Nintendo DS, PlayStation, Playstation 2, Dreamcast, GameCube/Wii, and more. A handful have known issues (PSP, Saturn, Game Boy Color categorization). 

---

## Known Issues

- **Save state compatibility** — Save states from certain older cores are incompatible with current ARM64 builds and will crash if loaded. On launch, the app detects these and shows a warning dialog. **Back up your save states before your first launch** — see [Migrating from OpenEmu](https://github.com/anhani1206/OpenEmuARM/wiki/Migrating-from-OpenEmu) for the full list and instructions.
- Input Monitoring permission may need to be granted manually in System Settings → Privacy & Security.
- A few cores have quirks on Apple Silicon still being investigated (see open issues).

---

## Requirements

- macOS 26 (Tahoe) or later
- Apple Silicon Mac (M1 / M2 / M3 / M4 / M5)

---

## About This Project

The original OpenEmu is still an amazing piece of Mac software. [stuartcarnie](https://github.com/stuartcarnie) brought Metal rendering to the app in 2019. [MaddTheSane](https://github.com/MaddTheSane) ported the emulation cores to ARM64 starting in 2021. [cyco](https://github.com/cyco), [clobber](https://github.com/clobber), [J-rg](https://github.com/J-rg), and the rest of the OpenEmu team built the application, the plugin architecture, and the library experience over more than a decade. That work is the foundation everything here stands on.

The original project went quiet around 2024 after the last release. By that time, the original team had already done significant work on the ARM64 cores. The ARM64 core work was real and substantial, but it was never assembled into a release — the last official binary (December 2023) was stated as Intel-only. [bazley82](https://github.com/bazley82) published a downloadable ARM64 build in early 2026, pulling together the ARM64-capable core submodules the original team had prepared into a single repo and release. This fork continued from there: RetroAchievements shipped across 9+ cores; a Libretro Bridge was built to load RetroArch cores directly inside OpenEmu; ScreenScraper cover art was integrated; Dreamcast was migrated from Reicast to Flycast; save persistence, system detection, and the core update pipeline were all fixed; and the app was hardened for macOS 26 (Tahoe).
Now we managed to implement NEO GEO using the core Final Burn Neo and the first functional implementation of Playstation 2 (ARMSX2), but still experimental and support for Screen rotation for Shoot 'em Up games.

**Lineage:**
- [OpenEmu/OpenEmu](https://github.com/OpenEmu/OpenEmu) — the original project
- [bazley82/OpenEmuARM64](https://github.com/bazley82/OpenEmuARM64) — ARM64 build, built on the original team's core work and what I started building upon
- [@nickybmon](https://github.com/nickybmon) By OpenEmu-Silicon and others.

---

## A Note on AI-Assisted Development

The vast majority of the code in this repo is still from the original developers. I have not changed the underlying architecture or approach for the app (apart form having it in a single repo to make it easier for a small team to maintain), it is still the same work done by an exceptional team of engineers. I work on this project with AI assisted development practices. These tools help me write and debug code I couldn't write alone. That said, I review every change, test everything, and make all the calls about direction and quality. I'm transparent about this because honesty with the community matters more than maintaining an illusion of expertise I don't have. The goal is to keep something good alive and make it genuinely usable for players.

---

## Documentation

| Doc | What's in it |
|-----|-------------|
| [Wiki](https://github.com/anhani1206/OpenEmuARM/wiki) | User guides: getting started, BIOS files, importing, CD games, controllers, troubleshooting |
| [Migrating from OpenEmu](https://github.com/anhani1206/OpenEmuARM/wiki/Migrating-from-OpenEmu) | Switching from the original OpenEmu: what carries over, what doesn't, and how to back up |
| [Supported Systems](https://github.com/anhani1206/OpenEmuARM/wiki/Supported-Systems) | Every system: working status, known issues, in-progress cores, what's planned, and BIOS requirements |
| [Dolphin GameCube and Wii troubleshooting](docs/dolphin-gamecube-troubleshooting.md) | Diagnose and replace a stale Dolphin debug/libretro wrapper; verify Wii game formats and controls |
| [Neo Geo with FBNeo](docs/fbneo-neogeo.md) | Install the optional FBNeo libretro core, its matching ROM set, and `neogeo.zip` BIOS |
| [Game display preferences](docs/game-display-preferences.md) | Per-game shader and integer-scaling persistence |
| [`CREDITS.md`](.github/CREDITS.md) | Everyone who contributed — original OpenEmu team, ARM64 port, core sources, illustrators, and this repo's contributors |

---

## Contributing

Issues, PRs, and testing feedback are all welcome. If something breaks for you, open an issue and describe your Mac model, macOS version, and which system/game you were running. That context is the most valuable thing you can provide.

If you want to contribute code, check the open issues for good starting points. A clear PR description of what it fixes is the best kind of contribution.

---

## License

The main OpenEmu app and SDK are licensed under the **BSD 2-Clause License**. Individual emulation cores carry their own licenses (GPL v2, MPL 2.0, LGPL 2.1, and others) — see each core's directory for details.

Note: [picodrive](https://github.com/notaz/picodrive) includes a non-commercial clause. This project is and will remain free.
