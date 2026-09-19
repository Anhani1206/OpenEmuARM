## What's New in 2.1.2

- **3DO Opera core** — added the Opera libretro core as an embedded Apple Silicon core for 3DO games.
- **3DO disc images** — `.chd` files are now accepted and can be launched through Opera; native 4DO continues to support `.cue/.bin` and `.iso` images.
- **Core selection** — 3DO games can be launched with a specific core through **Play With…**, and the running game can switch cores through **Select Core** in the game controls menu.
- **Core Preferences** — embedded cores, including Opera, are now shown in Preferences → Cores alongside the other available cores.
- **Core list cleanup** — the bundled RetroArch FinalBurn Neo variant is kept available internally but no longer appears as a duplicate beside the native FBNeo core.
- **Online cheats browser** — added a compact **More…** button to browse all matching cheats in groups of 100 instead of stopping at the first 100 results.
- **Release installer** — the final app keeps the 2.1.1-style background and Loki tribute, and now explicitly bundles Opera together with the other release cores.
- **Embedded core set** — the release package contains 36 cores, including Opera; PokeMini is not included in this release.

## Notes

- Switching cores restarts the game and discards the current unsaved progress. Save states are core-specific.
- Opera is bundled with the application and does not require a separate RetroArch installation.
