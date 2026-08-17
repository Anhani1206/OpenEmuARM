# Code Context

## Files Retrieved
1. `.gitmodules` (lines 1-96) - legacy submodule inventory; shows stale/missing Reicast, Frodo-Core, VirtualC64-Core entries and no entries for Dolphin/Flycast/PPSSPP.
2. `OpenEmu-metal.xcworkspace/contents.xcworkspacedata` (lines 1-97) - workspace project inventory for source/build presence.
3. `oecores.xml` (lines 1-343) - downloadable core registry, core-to-system mapping, and appcast URLs.
4. `Appcasts/*.xml` (27 files) - local appcast inventory: 4do, atari800, bliss, bluemsx, bsnes, crabemu, desmume, dolphin, fceu, flycast, gambatte, genesisplus, jollycv, mednafen, mgba, mupen64plus, nestopia, o2em, picodrive, pokemini, potator, ppsspp, prosystem, snes9x, stella, vecxgl, virtualjaguar.
5. Core `Info.plist` files containing `OESystemIdentifiers` (parsed full files) - local updater/feed and system support metadata.
6. `OpenEmu/SystemPlugins/*/*-Info.plist` (parsed full files) - installed system plugin inventory and system IDs.
7. `Flycast/OpenEmu/Info.plist` (lines 88-91) - updater URL differs from `oecores.xml` by missing `?v=2` query.
8. `Mednafen/Info.plist` (lines 214-226) - Mednafen locally registers Saturn, but `oecores.xml` does not list Saturn.
9. `picodrive/Info.plist` (lines 43-47) - Picodrive locally registers only 32X, but `oecores.xml` advertises Sega CD too.

## Key Code

- `.gitmodules` lists historical flattened-submodule paths. Notable stale entries: `Reicast` (lines 61-63), `Frodo-Core` (lines 91-93), `VirtualC64-Core` (lines 94-96). Those directories are not present locally.
- `OpenEmu-metal.xcworkspace/contents.xcworkspacedata` includes 31 project refs. It includes Dolphin/Flycast/PPSSPP (lines 25-38, 94-96) but does not include MAME, Reicast, Frodo-Core, or VirtualC64-Core.
- `oecores.xml` explicitly says Arcade/MAME is excluded because no emulation core exists (lines 102-116), despite a local `MAME/MAME.xcodeproj` directory.
- All 27 `oecores.xml` appcast filenames have a matching file in `Appcasts/`.

## Architecture

System plugins under `OpenEmu/SystemPlugins/` define UI/system IDs. Core plugins define supported systems in `OESystemIdentifiers` and Sparkle updater feeds via `SUFeedURL`. `oecores.xml` is the external install/update registry with appcast URLs. `OpenEmu-metal.xcworkspace` determines which local core projects are available to build from this workspace.

## Matrix

Legend: `Source` = local core `Info.plist`/source present; `WS` = project ref in `OpenEmu-metal.xcworkspace`; `Appcast` = matching `Appcasts/*.xml`; `Updater` = core `Info.plist` has `SUFeedURL`.

| System plugin | System ID | Local core source | WS | Appcast | Updater | Gaps / notes |
|---|---|---|---:|---:|---:|---|
| 3DO | `openemu.system.3do` | 4DO | ✓ | ✓ | ✓ | OK |
| Arcade | `openemu.system.arcade` | MAME dir only | ✗ | ✗ | ✗ | `oecores.xml` says no MAME core; local `MAME/MAME.xcodeproj` exists but is not wired. |
| Atari 2600 | `openemu.system.2600` | Stella | ✓ | ✓ | ✓ | OK |
| Atari 5200 | `openemu.system.5200` | Atari800 | ✓ | ✓ | ✓ | OK |
| Atari 7800 | `openemu.system.7800` | ProSystem | ✓ | ✓ | ✓ | OK |
| Atari 8-bit | `openemu.system.atari8bit` | Atari800 | ✓ | ✓ | ✓ | OK |
| Atari Jaguar | `openemu.system.jaguar` | VirtualJaguar | ✓ | ✓ | ✓ | OK |
| Atari Lynx | `openemu.system.lynx` | Mednafen | ✓ | ✓ | ✓ | OK |
| ColecoVision | `openemu.system.colecovision` | CrabEmu, JollyCV, blueMSX | ✓ | ✓ | ✓ | OK; multiple local cores. |
| Commodore 64 | `openemu.system.c64` | none | ✗ | ✗ | ✗ | System plugin only. `.gitmodules` has stale `Frodo-Core` and `VirtualC64-Core`, but dirs/workspace/appcasts absent. |
| Dreamcast | `openemu.system.dc` | Flycast | ✓ | ✓ | ✓ | Feed mismatch only: `oecores.xml` uses `flycast.xml?v=2`, Info.plist uses `flycast.xml`. |
| Famicom Disk System | `openemu.system.fds` | Nestopia | ✓ | ✓ | ✓ | OK |
| Game Boy | `openemu.system.gb` | Gambatte | ✓ | ✓ | ✓ | OK |
| Game Boy Advance | `openemu.system.gba` | mGBA | ✓ | ✓ | ✓ | OK |
| GameCube | `openemu.system.gc` | Dolphin | ✓ | ✓ | ✓ | OK; Dolphin is not in `.gitmodules`. |
| Game Gear | `openemu.system.gg` | GenesisPlus | ✓ | ✓ | ✓ | OK |
| Genesis / Mega Drive | `openemu.system.sg` | GenesisPlus | ✓ | ✓ | ✓ | OK |
| Intellivision | `openemu.system.intellivision` | Bliss | ✓ | ✓ | ✓ | OK |
| MSX | `openemu.system.msx` | blueMSX | ✓ | ✓ | ✓ | OK |
| Neo Geo Pocket | `openemu.system.ngp` | Mednafen | ✓ | ✓ | ✓ | OK |
| NES | `openemu.system.nes` | Nestopia, FCEU | ✓ | ✓ | ✓ | OK; multiple local cores. |
| Nintendo 64 | `openemu.system.n64` | Mupen64Plus | ✓ | ✓ | ✓ | OK |
| Nintendo DS | `openemu.system.nds` | DeSmuME | ✓ | ✓ | ✓ | OK |
| Odyssey² | `openemu.system.odyssey2` | O2EM | ✓ | ✓ | ✓ | OK |
| PC Engine | `openemu.system.pce` | Mednafen | ✓ | ✓ | ✓ | OK |
| PC Engine CD | `openemu.system.pcecd` | Mednafen | ✓ | ✓ | ✓ | OK |
| PC-FX | `openemu.system.pcfx` | Mednafen | ✓ | ✓ | ✓ | OK |
| PlayStation | `openemu.system.psx` | Mednafen | ✓ | ✓ | ✓ | OK |
| PlayStation 2 | `openemu.system.ps2` | none | ✗ | ✗ | ✗ | System plugin only; no local core registry/source. |
| PSP | `openemu.system.psp` | PPSSPP | ✓ | ✓ | ✓ | OK; PPSSPP is not in `.gitmodules`. |
| Saturn | `openemu.system.saturn` | Mednafen | ✓ | ✓ | ✓ | Local Info.plist registers Saturn, but `oecores.xml` omits Saturn under Mednafen. |
| Sega 32X | `openemu.system.32x` | Picodrive | ✓ | ✓ | ✓ | OK for 32X. |
| Sega CD | `openemu.system.scd` | GenesisPlus; Picodrive advertised | ✓ | ✓ | ✓ | GenesisPlus OK. `oecores.xml` advertises Picodrive for Sega CD, but Picodrive Info.plist registers only 32X. |
| Sega Master System | `openemu.system.sms` | GenesisPlus | ✓ | ✓ | ✓ | OK |
| SG-1000 | `openemu.system.sg1000` | GenesisPlus | ✓ | ✓ | ✓ | OK |
| SuperNES | `openemu.system.snes` | SNES9x, BSNES | ✓ | ✓ | ✓ | OK; multiple local cores. |
| Supervision | `openemu.system.sv` | Potator | ✓ | ✓ | ✓ | OK |
| Vectrex | `openemu.system.vectrex` | VecXGL | ✓ | ✓ | ✓ | OK |
| Virtual Boy | `openemu.system.vb` | Mednafen | ✓ | ✓ | ✓ | OK |
| VMU | `openemu.system.vmu` | none | ✗ | ✗ | ✗ | System plugin exists; no core registry/source found. |
| Wii | `openemu.system.wii` | Dolphin | ✓ | ✓ | ✓ | OK; Dolphin is not in `.gitmodules`. |
| WonderSwan | `openemu.system.ws` | Mednafen | ✓ | ✓ | ✓ | OK |

## Gaps / Risks

1. **System plugins without wired cores:** Arcade, Commodore 64, PlayStation 2, VMU.
2. **Local source present but not fully wired:** `MAME/MAME.xcodeproj` exists but is absent from workspace, core Info/updater/appcast, and `oecores.xml` explicitly excludes Arcade/MAME.
3. **Registry mismatch:** Mednafen `Info.plist` includes `openemu.system.saturn`; `oecores.xml` does not advertise Saturn for Mednafen.
4. **Registry mismatch:** `oecores.xml` advertises Picodrive for Sega CD; `picodrive/Info.plist` only lists `openemu.system.32x`.
5. **Feed URL mismatch:** Flycast `oecores.xml` appcast URL has `?v=2`; Flycast Info.plist `SUFeedURL` does not. Both resolve to `Appcasts/flycast.xml`, but strings differ.
6. **Inventory drift:** `.gitmodules` has missing/stale `Reicast`, `Frodo-Core`, and `VirtualC64-Core`; workspace has newer Dolphin/Flycast/PPSSPP not listed in `.gitmodules`.

## Start Here

Open `oecores.xml` first. It is the central registry that ties systems to downloadable cores and reveals most mismatches against local core `Info.plist` metadata and system plugins.
