# Backup: before PS1 window centering

This local checkpoint documents the state before changing the PlayStation window
resize behavior to match the upstream OpenEmu-Silicon v1.3.0 approach.

- Repository: OpenEmuARM
- Branch: `fix/refresh-v2.1.1-dmg`
- Existing source file: `OpenEmu/GameWindowController.swift`
- Scope of the planned change: recenter the window when the core changes the
  game resolution, while keeping the window inside the visible screen frame.
- Existing unrelated working-tree changes were preserved and are not part of
  this adjustment.
